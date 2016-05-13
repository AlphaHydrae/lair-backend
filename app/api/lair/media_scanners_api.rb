module Lair
  class MediaScannersApi < Grape::API
    namespace :scanners do
      helpers do
        def with_serialization_includes rel
          rel.includes :user
        end

        def update_record_from_params record
          record.set_properties_from_params params[:properties]
        end
      end

      post do

        record = MediaScanner.new
        record.user = params.key?(:userId) ? User.where(api_id: params[:userId].to_s).first! : current_user

        authorize! record, :create

        MediaScanner.transaction do
          update_record_from_params record
          record.save!
          serialize record
        end
      end

      get do
        authorize! MediaScanner, :index

        rel = policy_scope MediaScanner.joins(:user).order('users.normalized_name ASC, media_scanners.api_id ASC')

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
            @record ||= load_resource!(MediaScanner.where(api_id: params[:id].to_s))
          end
        end

        get do
          authorize! record, :show
          serialize record
        end

        patch do
          authorize! record, :update

          MediaScanner.transaction do
            update_record_from_params record
            record.save!
            serialize record
          end
        end

        namespace :properties do
          patch do
            authorize! record, :update

            MediaScanner.transaction do
              record.set_properties_from_params params.except(:id)
              record.save!
            end

            record.properties
          end

          namespace '/:key' do
            get do
              authorize! record, :show

              properties = record.properties
              unless properties.key? params[:key].to_s
                raise ActiveRecord::RecordNotFound, %/Unknown property #{params[:key].to_s.inspect}/
              end

              properties[params[:key].to_s]
            end
          end
        end
      end
    end
  end
end
