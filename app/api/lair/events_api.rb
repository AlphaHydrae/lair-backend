module Lair
  class EventsApi < Grape::API
    namespace :events do
      helpers do
        def serialization_options *args
          Hash.new.tap do |options|
            options[:with_user] = true_flag? :withUser
          end
        end
      end

      get do
        authorize! Event, :index
        rel = Event.order('created_at DESC').includes :trackable, :user

        rel = paginated rel do |rel|

          if params[:resource].present?
            rel = rel.where trackable_type: params[:resource].to_s.gsub(/-/, '_').singularize.camelize
          end

          rel
        end

        serialize load_resources(rel)
      end
    end
  end
end
