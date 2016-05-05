module Lair
  class MediaFilesApi < Grape::API
    namespace :files do
      helpers do
        def with_serialization_includes rel
          rel = rel.includes :source
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

          if params.key? :directory
            dir = MediaDirectory.where(path: params[:directory].to_s).first!
            rel = rel.where 'media_files.depth > ?', dir.depth
            rel = rel.where 'media_files.path LIKE ?', "#{dir.path.gsub(/_/, '\\_').gsub(/\%/, '\\%')}/%" unless dir.depth == 0

            if params.key? :maxDepth
              rel = rel.where 'media_files.depth <= ?', dir.depth + params[:maxDepth].to_i
            end
          elsif params.key? :maxDepth
            rel = rel.where 'media_files.depth <= ?', params[:maxDepth].to_i
          end

          rel
        end

        serialize load_resources(rel)
      end
    end
  end
end
