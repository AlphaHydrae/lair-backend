require_dependency 'errors'

module Lair

  class API < Grape::API
    version 'v1', using: :accept_version_header, vendor: 'lair'
    format :json

    cascade false
    rescue_from :all do |e|
      Rack::Response.new([ JSON.dump({ errors: [ { message: e.message } ] }) ], 500, { "Content-type" => "application/json" }).finish
    end

    helpers do
      def authenticate!

        if headers['Authorization'].blank?
          raise AuthError.new('Missing credentials')
        end

        unless m = headers['Authorization'].match(/\ABearer ([a-zA-Z0-9\-\_\/\:\=\.]+)\Z/)
          raise AuthError.new('Wrong credentials')
        end

        @raw_token = m[1]

        begin
          token = JWT.decode @raw_token, Rails.application.secrets.jwt_hmac_key
        rescue JWT::DecodeError
          raise AuthError.new('Wrong credentials')
        end

        @token = token[0]
      end
    end

    before do
      authenticate!
    end

    get :ping do
      'pong'
    end

    get :auth do
      { token: @raw_token }
    end

    class Error < LairError
    end

    class AuthError < Error
    end
  end
end
