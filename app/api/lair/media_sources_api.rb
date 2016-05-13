module Lair
  class MediaSourcesApi < Grape::API
    namespace :sources do
      helpers do
        def with_serialization_includes rel
          rel.includes :user
        end

        def serialization_options *args
          Hash.new.tap do |options|
            options[:with_scan_paths] = true_flag? :withScanPaths
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

          if params.key? :userId
            rel = rel.where 'users.api_id = ?', params[:userId].to_s
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

        namespace :scanPaths do
          get do
            authorize! record, :show
            record.scan_paths.sort.collect(&:to_h)
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
        end
      end
    end
  end
end
