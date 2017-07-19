module Lair
  class TokensApi < Grape::API
    namespace :tokens do
      helpers do
        def update_record_from_params record
          record.expiration = Time.parse params[:expiresAt].to_s if params[:expiresAt].present?
          record.scopes = Array.wrap(params[:scopes]).flatten.collect &:to_s if params.key? :scopes
        end
      end

      post do
        authorize! AccessToken, :create

        # TODO analysis: validate access token
        token = AccessToken.new current_user
        update_record_from_params token

        {
          token: token.encode
        }
      end
    end
  end
end
