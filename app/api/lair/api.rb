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

        unless m = headers['Authorization'].match(/\ABearer ([a-zA-Z0-9\-\_\/\:\=]+)\Z/)
          raise AuthError.new('Wrong credentials')
        end

        begin
          token = JWT.decode m[1], Rails.application.secrets.jwt_hmac_key
        rescue JWT::DecodeError
          raise AuthError.new('Wrong credentials')
        end

        @token = token
      end
    end

    before do
      authenticate!
    end

    get :ping do
      'pong'
    end

    class Error < LairError
    end

    class AuthError < Error
    end
  end
end
