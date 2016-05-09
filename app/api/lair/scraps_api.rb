module Lair
  class ScrapsApi < Grape::API
    namespace :scraps do
      helpers do
        def serialization_options *args
          {
            include_error: include_in_response?(:error)
          }
        end

        def with_serialization_includes rel
          rel = rel.includes :media_url
          rel
        end
      end

      namespace '/:id' do
        helpers do
          def record
            @record ||= load_resource!(Scrap.where(api_id: params[:id].to_s))
          end
        end

        get do
          authorize! record, :show
          serialize record
        end
      end
    end
  end
end
