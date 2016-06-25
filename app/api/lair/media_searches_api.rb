module Lair
  class MediaSearchesApi < Grape::API
    namespace :searches do
      helpers do
        def serialization_options *args
          {
            include_results: include_in_response?(:results)
          }
        end

        def with_serialization_includes rel
          rel
        end

        def update_record_from_params record

          if params.key?(:sourceId) && params.key?(:directory)

            directory = MediaDirectory
              .joins(:source)
              .where('media_sources.api_id = ? AND media_files.path = ?', params[:sourceId].to_s, params[:directory].to_s)
              .includes(:source)
              .first

            if directory.present?

              record.query = File.basename directory.path

              scan_path = directory.source.scan_paths.find{ |sp| directory.path.index(sp.path) == 0 }
              if scan_path.try :category
                record.provider = MediaUrl.resolve_provider category: scan_path.category
              end
            end
          end

          record.query = params[:query].to_s if params.key? :query
          record.provider = params[:provider].to_s if params.key? :provider
          record.selected = params[:selected] if !record.new_record? && params.key?(:selected)
        end
      end

      post do
        media_search = MediaSearch.new user: current_user
        update_record_from_params media_search

        authorize! media_search, :create

        MediaSearch.transaction do

          if media_search.valid?
            media_search.results = MediaUrl.search provider: media_search.provider, query: media_search.query
          end

          media_search.save!
          serialize media_search
        end
      end

      get do
        authorize! MediaSearch, :index

        rel = policy_scope MediaSearch.order('created_at DESC')

        rel = paginated rel do |rel|

          rel = rel.where query: params[:query].to_s if params.key? :query

          rel
        end

        serialize load_resources(rel)
      end
    end
  end
end
