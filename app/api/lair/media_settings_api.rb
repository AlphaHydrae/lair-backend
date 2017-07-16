module Lair
  class MediaSettingsApi < Grape::API
    namespace :settings do
      helpers do
        def with_serialization_includes rel
          rel.includes :user
        end

        def update_record_from_params record
          record.ignores = Array.wrap(params[:ignores]).collect &:to_s if params.key? :ignores
        end

        def media_settings
          @media_settings ||= MediaSettings.where(user: current_user).first_or_create!
        end
      end

      get do
        authorize! MediaSettings, :show
        serialize media_settings
      end

      patch do
        authorize! MediaSettings, :update
        update_record_from_params media_settings
        media_settings.save!
        serialize media_settings
      end
    end
  end
end
