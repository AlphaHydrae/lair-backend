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
            authorize! record, :update

            MediaScrap.transaction do
              if %w(scraping_failed).include? record.state
                record.retry_scraping!
              elsif %w(expansion_failed).include? record.state
                record.retry_expansion!
              else
                error = ValidationError.new
                error.add "Scraping can only be retried from the scrapingFailed or expansionFailed states"
                error.raise_if_any
              end

              serialize record
            end
          end
        end
      end
    end
  end
end
