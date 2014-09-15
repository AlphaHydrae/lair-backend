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

        @raw_auth_token = m[1]

        begin
          token = JWT.decode @raw_auth_token, Rails.application.secrets.jwt_hmac_key
        rescue JWT::DecodeError
          raise AuthError.new('Wrong credentials')
        end

        @auth_token = token[0]
      end
    end

    before do
      authenticate!
    end

    get :ping do
      'pong'
    end

    get :auth do
      { token: @raw_auth_token }
    end

    namespace :items do

      params do
        requires :titles do
          requires :text
        end
        requires :year, type: Integer
        requires :language, type: String, regexp: /\A[a-z]{2}(?:\-[A-Z]{2})?\Z/
      end

      post do

        Item.transaction do
          item = Item.new year: params[:year], language: params[:language]

          params[:titles].each.with_index do |title,i|
            title = item.titles.build contents: title[:text], display_position: i
          end

          item.save!

          item.original_title = item.titles.first
          item.save!

          item.to_builder.attributes!
        end
      end

      get do

        limit = params[:pageSize].to_i
        limit = 10 if limit < 1

        offset = (params[:page].to_i - 1) * limit
        offset = 0 if offset < 1

        header 'X-Pagination-Total', Item.count(:all).to_s

        Item.joins(:titles).where('item_titles.id = items.original_title_id').order('item_titles.contents asc').offset(offset).limit(limit).includes(:titles).all.to_a.collect{ |item| item.to_builder.attributes! }
      end
    end

    class Error < LairError
    end

    class AuthError < Error
    end
  end
end
