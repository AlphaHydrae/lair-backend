module Lair
  class MediaFilesApi < Grape::API
    namespace :files do
      helpers do
        def serialization_options *args
          {
            include_media_url: include_in_response?(:mediaUrl),
            include_files_count: include_in_response?(:filesCount),
            include_linked_files_count: include_in_response?(:linkedFilesCount)
          }
        end

        def with_serialization_includes rel
          rel = rel.includes :source
          rel
        end
      end

      get do
        authorize! MediaAbstractFile, :index

        rel = policy_scope MediaAbstractFile.order('media_sources.name ASC, media_files.path ASC')

        rel = paginated rel do |rel|

          if params.key? :type
            if params[:type] == 'file'
              rel = rel.where 'media_files.type = ?', MediaFile.name
            elsif params[:type] == 'directory'
              rel = rel.where 'media_files.type = ?', MediaDirectory.name
            else
              rel = rel.none
            end
          end

          if current_user.admin? && params.key?(:userId)
            rel = rel.where 'users.api_id = ?', params[:userId].to_s
          end

          if true_flag? :mine
            rel = rel.where 'users.api_id = ?', current_user.api_id
          end

          if params.key? :sourceId
            rel = rel.where 'media_sources.api_id = ?', params[:sourceId].to_s
          end

          if params.key? :path
            rel = rel.where 'media_files.path = ?', params[:path].to_s
          end

          if true_flag? :deleted
            rel = rel.where deleted: true
          elsif !all_flag?(:deleted)
            rel = rel.where deleted: false
          end

          if params.key? :directory
            dir = MediaDirectory.where(path: params[:directory].to_s).first
            if dir
              rel = rel.where 'media_files.id != ?', dir.id
              rel = rel.where "media_files.id IN (#{dir.child_files_sql})" unless dir.depth == 0

              if params.key? :maxDepth
                rel = rel.where 'media_files.depth <= ?', dir.depth + params[:maxDepth].to_i
              end
            else
              rel = rel.none
            end
          elsif params.key? :maxDepth
            rel = rel.where 'media_files.depth <= ?', params[:maxDepth].to_i
          end

          rel
        end

        files = load_resources rel

        options = {}

        if %i(filesCount linkedFilesCount).any?{ |attr| include_in_response? attr }
          options[:directory_counts] = {}

          directories = files.select &:directory?
          directories.each do |dir|

            dir_files_rel = MediaFile
              .where(source_id: dir.source_id, deleted: false)

            dir_files_rel = dir_files_rel.where("media_files.id IN (#{dir.child_files_sql})") unless dir.depth == 0

            options[:directory_counts][dir.api_id] = {}
            options[:directory_counts][dir.api_id][:files_count] = dir_files_rel.count if include_in_response? :filesCount

            if include_in_response? :linkedFilesCount
              options[:directory_counts][dir.api_id][:linked_files_count] = dir_files_rel.where('media_files.state = ?', 'linked').count
            end
          end
        end

        if include_in_response? :mediaUrl
          options[:media_urls] = MediaUrl.where(id: files.collect(&:media_url_id).compact.uniq).includes(:work).to_a
        else
          options[:media_urls] = MediaUrl.where(id: files.collect(&:media_url_id).compact.uniq).to_a
        end

        serialize files, options
      end
    end
  end
end
