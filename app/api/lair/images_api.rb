module Lair
  class ImagesApi < Grape::API
    namespace :images do
      helpers do
        def with_serialization_includes rel
          rel = rel.includes :works if true_flag? :withWorks
          rel = rel.includes :items if true_flag? :withItems
          rel
        end

        def serialization_options *args
          Hash.new.tap do |options|
            options[:with_image_works] = true_flag? :withWorks
            options[:with_image_items] = true_flag? :withItems
          end
        end
      end

      get do
        authorize! Image, :index

        rel = Image

        rel = paginated rel do |rel|

          if params.key? :orphan
            rel = true_flag?(:orphan) ? Image.orphaned : Image.linked
          end

          if params[:state].present?
            rel = rel.where state: Array.wrap(params[:state]).collect(&:to_s)
          end

          rel
        end

        rel = rel.order 'created_at'

        serialize load_resources(rel)
      end

      namespace '/:id' do

        helpers do
          def record
            Image.where(api_id: params[:id].to_s).first!
          end
        end

        get :'uploadError' do
          authorize! Image, :update
          record.upload_error
        end

        patch do
          authorize! Image, :update

          # TODO: validate image state
          if params[:state].present?
            if record.state == 'upload_failed' && params[:state].to_s == 'created'
              record.retry_upload!
              UploadImageJob.enqueue record
            end
          end

          serialize record
        end

        delete do
          authorize! Image, :destroy

          if record.works.count >= 1 || record.items.count >= 1
            status 409
            return { errors: [ { message: 'Image cannot be deleted because it is still linked to a work or item.' } ] }
          end

          record.destroy

          status 204
          nil
        end
      end
    end
  end
end
