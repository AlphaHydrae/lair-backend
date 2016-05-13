module Lair
  class TokensApi < Grape::API
    namespace :tokens do
      post do
        authorize! AccessToken, :create
        { token: AccessToken.new(current_user).encode }
      end
    end
  end
end