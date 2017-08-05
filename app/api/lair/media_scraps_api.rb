module Lair
  class MediaScrapsApi < Grape::API
    namespace :scraps do
      helpers do
        def serialization_options *args
          {
            include_errors: include_in_response?(:errors),
            include_contents: include_in_response?(:contents),
            include_warnings: include_in_response?(:warnings)
          }
        end

        def with_serialization_includes rel
          rel = rel.without_contents if request.get? && !include_in_response?(:contents)
          rel = rel.includes :job_errors if include_in_response?(:errors)
          rel = rel.includes :media_url
          rel
        end

        def filter_rel_from_params rel
          if params[:states].present?
            rel = rel.where 'media_scraps.state IN (?)', Array.wrap(params[:states]).collect(&:to_s).collect(&:underscore)
          end

          if true_flag? :warnings
            rel = rel.where 'media_scraps.warnings_count >= 1'
          elsif false_flag? :warnings
            rel = rel.where 'media_scraps.warnings_count <= 0'
          end

          rel
        end

        def retry_scraping scrap
          if %w(scraping_failed).include?(scrap.state)
            scrap.retry_scraping!
          elsif %w(expansion_failed expanded).include?(scrap.state)
            scrap.retry_expansion!
          else
            error = ValidationError.new
            error.add "Scraping #{scrap.api_id} can only be retried from the scrapingFailed, expansionFailed or expanded states"
            error.raise_if_any
          end
        end
      end

      post :retry do
        authorize! MediaScrap, :retry

        MediaScrap.transaction do
          rel = policy_scope MediaScrap
          rel = filter_rel_from_params rel

          rel.find_each do |scrap|
            retry_scraping scrap
            status 202
            nil
          end
        end
      end

      namespace '/:id' do
        helpers do
          def record
            @record ||= load_resource!(MediaScrap.where(api_id: params[:id].to_s))
          end
        end

        get do
          @contents_optional = true
          authorize! record, :show
          serialize record
        end

        namespace :retry do
          post do
            authorize! record, :retry

            MediaScrap.transaction do
              retry_scraping record
              serialize record
            end
          end
        end
      end
    end
  end
end
