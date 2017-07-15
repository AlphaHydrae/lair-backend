module Lair
  class MediaSourcesApi < Grape::API
    namespace :sources do
      helpers do
        def with_serialization_includes rel
          rel.includes :user
        end

        def serialization_options *args
          Hash.new.tap do |options|
            options[:include_user] = include_in_response? :user
            options[:include_scan_paths] = include_in_response? :scanPaths
          end
        end

        def update_record_from_params record
          record.name = params[:name].to_s if params.key? :name
          record.set_properties_from_params params[:properties] if params[:properties].kind_of? Hash
        end
      end

      post do

        record = MediaSource.new
        record.user = params.key?(:userId) ? User.where(api_id: params[:userId].to_s).first! : current_user

        authorize! record, :create

        MediaSource.transaction do
          update_record_from_params record
          record.save!
          serialize record
        end
      end

      get do
        authorize! MediaSource, :index

        rel = policy_scope MediaSource.joins(:user).order('users.normalized_name ASC, media_sources.normalized_name ASC')

        rel = paginated rel do |rel|

          if (current_user.admin? || current_user.media_manager?) && params.key?(:userId)
            rel = rel.where 'users.api_id = ?', params[:userId].to_s
          end

          if true_flag? :mine
            rel = rel.where 'users.api_id = ?', current_user.api_id
          end

          if params.key? :name
            if params[:name].kind_of? Array
              rel = rel.where normalized_name: params[:name].collect(&:to_s).collect(&:downcase)
            else
              rel = rel.where normalized_name: params[:name].to_s.downcase
            end
          end

          rel
        end

        serialize load_resources(rel)
      end

      namespace '/:id' do
        helpers do
          def record
            @record ||= load_resource!(MediaSource.where(api_id: params[:id].to_s))
          end
        end

        get do
          authorize! record, :show
          serialize record
        end

        patch do
          authorize! record, :update

          MediaSource.transaction do
            update_record_from_params record
            record.save!
            serialize record
          end
        end

        delete do
          authorize! record, :destroy
          record.destroy
          status 204
          nil
        end

        namespace :scanPaths do
          get do
            authorize! record, :show

            scan_paths = record.scan_paths.sort

            if params.key? :path
              scan_paths = scan_paths.select{ |sp| sp.path == params[:path].to_s }
            end

            scan_paths.collect(&:to_h)
          end

          post do
            authorize! record, :update

            path = MediaScanPath.new
            path.source = record
            path.path = params[:path].try(:to_s)
            path.category = params[:category].try(:to_s)

            raise ActiveRecord::RecordInvalid.new(path) unless path.valid?

            MediaSource.transaction do
              path.generate_id
              record.scan_paths << path
              record.save!
              path.to_h
            end
          end

          namespace '/:id' do
            helpers do
              def scan_path_resource
                @scan_path_resource ||= record.scan_paths.find{ |sp| sp.id == params[:id].to_s }
                raise ActiveRecord::RecordNotFound, 'Scan path not found' unless @scan_path_resource
              end
            end

            delete do
              authorize! record, :update

              MediaSource.transaction do
                record.scan_paths.delete scan_path_resource
                record.save!
                status 204
                nil
              end
            end
          end
        end
      end
    end
  end
end
