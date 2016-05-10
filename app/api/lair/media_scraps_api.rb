module Lair
  class MediaScrapsApi < Grape::API
    namespace :scraps do
      helpers do
        def serialization_options *args
          {
            include_error: include_in_response?(:error),
            include_contents: include_in_response?(:contents)
          }
        end

        def with_serialization_includes rel
          rel = rel.without_contents if request.get? && !include_in_response?(:contents)
          rel = rel.includes :media_url
          rel
        end

        def update_record_from_params record
          record.state = params[:state].to_s if params.key? :state
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
              if %w(scraping_canceled scraping_failed).include? record.state
                record.retry_scraping!
              elsif %w(expansion_failed).include? record.state
                record.retry_expansion!
              else
                error = ValidationError.new
                error.add "Scraping can only be retried from the scrapingCanceled, scrapingFailed or expansionFailed states"
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
