module Lair
  class MediaFilesApi < Grape::API
    namespace :files do
      helpers do
        def serialization_options *args
          {
            include_media_search: include_in_response?(:mediaSearch),
            include_media_url: include_in_response?(:mediaUrl)
          }
        end

        def with_serialization_includes rel
          rel = rel.includes :source
          rel = rel.preload :searches if params[:type] == 'directory' && include_in_response?(:mediaSearch)
          rel
        end
      end

      get do
        authorize! MediaAbstractFile, :index

        rel = if !params.key?(:type)
          MediaAbstractFile
        elsif params[:type] == 'file'
          MediaFile
        elsif params[:type] == 'directory'
          MediaDirectory
        else
          MediaAbstractFile.none
        end

        rel = policy_scope rel.joins(source: :user).order('media_sources.name ASC, media_files.path ASC')

        rel = paginated rel do |rel|

          if current_user.admin? && params.key?(:userId)
            rel = rel.where 'users.api_id = ?', params[:userId].to_s
          end

          if true_flag? :mine
            rel = rel.where 'users.api_id = ?', current_user.api_id
          end

          if true_flag? :nfo
            rel = rel.where '(media_files.type = ? AND media_files.extension = ?) OR (media_files.type = ? AND media_files.nfo_files_count >= 1)', MediaFile.name, 'nfo', MediaDirectory.name
          elsif false_flag? :nfo
            rel = rel.where '(media_files.type = ? AND media_files.extension != ?) OR (media_files.type = ? AND media_files.nfo_files_count <= 0)', MediaFile.name, 'nfo', MediaDirectory.name
          end

          if true_flag? :linked
            rel = rel.where '(media_files.type = ? AND media_files.media_url_id IS NOT NULL) OR (media_files.type = ? AND media_files.linked_files_count = media_files.files_count)', MediaFile.name, MediaDirectory.name
          elsif false_flag? :linked
            rel = rel.where '(media_files.type = ? AND media_files.media_url_id IS NULL) OR (media_files.type = ? AND media_files.linked_files_count < media_files.files_count)', MediaFile.name, MediaDirectory.name
          end

          if params.key? :sourceId
            rel = rel.where 'media_sources.api_id = ?', params[:sourceId].to_s

            if params.key?(:directory)

              paths = params[:directory].kind_of?(Array) ? params[:directory].collect(&:to_s) : params[:directory].to_s
              dirs = MediaDirectory.joins(:source).where('media_sources.api_id = ?', params[:sourceId]).where(path: paths).to_a

              if dirs.blank?
                rel = rel.none
              elsif root_dir = dirs.find{ |dir| dir.depth == 0 }
                rel = rel.where 'media_files.id != ?', root_dir.id
                rel = rel.where 'media_files.depth = ?', params[:maxDepth].to_i if params.key? :maxDepth
              elsif dirs.present?

                conditions = []
                values = []

                dirs.each do |dir|
                  condition = "media_files.id IN (#{dir.child_files_sql})"

                  if params.key? :maxDepth
                    condition += ' AND media_files.depth <= ?'
                    values << dir.depth + params[:maxDepth].to_i
                  end

                  conditions << condition
                end

                where_clause = [ conditions.collect{ |cond| "(#{cond})" }.join(' OR ') ] + values
                rel = rel.where *where_clause
              end
            end
          else
            if params.key? :maxDepth
              rel = rel.where 'media_files.depth <= ?', params[:maxDepth].to_i
            end
          end

          if params.key? :path
            rel = rel.where 'media_files.path = ?', params[:path].to_s
          end

          if true_flag? :deleted
            rel = rel.where deleted: true
          elsif !all_flag?(:deleted)
            rel = rel.where deleted: false
          end

          if params[:type] == 'directory'
            if true_flag? :mediaSearchCompleted
              rel = rel.joins(:searches).where 'media_searches.selected_url IS NOT NULL'
            elsif false_flag? :mediaSearchCompleted
              rel = rel
                .joins('LEFT OUTER JOIN media_directories_searches ON media_files.id = media_directories_searches.media_directory_id')
                .joins('LEFT OUTER JOIN media_searches ON media_directories_searches.media_search_id = media_searches.id')
                .where 'media_searches.selected_url IS NULL'
            elsif true_flag? :mediaSearch
              rel = rel.joins(:searches).where 'media_searches.id IS NOT NULL'
            elsif false_flag? :mediaSearch
              rel = rel
                .joins('LEFT OUTER JOIN media_directories_searches ON media_files.id = media_directories_searches.media_directory_id')
                .joins('LEFT OUTER JOIN media_searches ON media_directories_searches.media_search_id = media_searches.id')
                .where 'media_searches.id IS NULL'
            end
          end

          rel
        end

        files = load_resources rel

        options = serialization_options

        if include_in_response? :mediaUrl
          options[:media_urls] = MediaUrl.where(id: files.collect(&:media_url_id).compact.uniq).includes(:work).to_a
        else
          options[:media_urls] = MediaUrl.where(id: files.collect(&:media_url_id).compact.uniq).to_a
        end

        serialize files, options
      end

      namespace '/:id' do
        helpers do
          def record
            @record ||= load_resource!(MediaFile.where(api_id: params[:id].to_s))
          end
        end

        get do
          authorize! record, :show
          serialize record
        end

        namespace '/analysis' do
          post do
            record.update_column :analyzed, false
            AnalyzeMediaFileJob.enqueue record
            status 204
          end
        end
      end
    end
  end
end
