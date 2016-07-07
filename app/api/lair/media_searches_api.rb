module Lair
  class MediaSearchesApi < Grape::API
    namespace :searches do
      helpers do
        def serialization_options *args
          {
            include_directories: include_in_response?(:directories),
            include_results: include_in_response?(:results)
          }
        end

        def with_serialization_includes rel
          if include_in_response? :directories
            rel.includes directories: :source
          else
            rel.includes :directories
          end
        end

        def update_record_from_params record

          if new_record? && params[:directoryIds].kind_of?(Array)
            directories = MediaDirectory.where(api_id: params[:directoryIds].collect(&:to_s)).includes(:source).to_a
            record.directories = directories

            if record.directories.present?
              directory = record.directories.first
              record.query = File.basename directory.path

              scan_path = directory.source.scan_paths.find{ |sp| directory.path.index(sp.path) == 0 }
              if scan_path.try :category
                record.provider = MediaUrl.resolve_provider category: scan_path.category
              end
            end
          end

          record.query = params[:query].to_s if record.new_record? && params.key?(:query)
          record.provider = params[:provider].to_s if record.new_record? && params.key?(:provider)
          record.selected_url = params[:selectedUrl] if !record.new_record? && params.key?(:selectedUrl)
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

        rel = policy_scope MediaSearch.order('media_searches.created_at DESC')

        rel = paginated rel do |rel|

          rel = rel.where query: params[:query].to_s if params.key? :query

          if params.key? :provider
            rel = rel.where provider: params[:provider].to_s
          elsif params.key? :category
            if provider = MediaUrl.resolve_provider(category: params[:category].to_s)
              rel = rel.where provider: provider
            else
              rel = rel.none
            end
          end

          if params.key?(:directory) || params.key?(:directoryId) || params.key?(:sourceId)

            rel = if params.key? :sourceId
              rel.joins directories: :source
            else
              rel.joins :directories
            end

            if params.key? :sourceId
              rel = rel.where 'media_sources.api_id IN (?)', Array.wrap(params[:sourceId]).collect(&:to_s)
            end

            if params.key? :directory
              rel = rel.where 'media_files.type = ? AND media_files.path IN (?)', MediaDirectory.name, Array.wrap(params[:directory]).collect(&:to_s)
            end

            if params.key? :directoryId
              rel = rel.where 'media_files.type = ? AND media_files.api_id IN (?)', MediaDirectory.name, Array.wrap(params[:directoryId]).collect(&:to_s)
            end
          end

          if true_flag? :completed
            rel = rel.where 'media_searches.selected_url IS NOT NULL'
          elsif false_flag? :completed
            rel = rel.where 'media_searches.selected_url IS NULL'
          end

          rel
        end

        serialize load_resources(rel)
      end

      namespace '/:id' do
        helpers do
          def record
            @record ||= load_resource!(MediaSearch.where(api_id: params[:id].to_s))
          end
        end

        patch do
          authorize! record, :update

          MediaSource.transaction do
            update_record_from_params record
            record.save!
            serialize record
          end
        end

        namespace :directoryIds do
          post do
            authorize! record, :update

            new_ids = JSON.parse request.body.read

            if new_ids.kind_of? Array
              new_directories = MediaDirectory.where(api_id: new_ids).to_a
              record.directories = (record.directories + new_directories).uniq
            end

            record.directories.collect &:api_id
          end
        end

        namespace :results do
          post do
            authorize! record, :update

            MediaSearch.transaction do
              record.results = MediaUrl.search provider: record.provider, query: record.query
              record.save!
              record.results
            end
          end
        end
      end
    end
  end
end
