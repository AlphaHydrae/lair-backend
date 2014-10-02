require_dependency 'errors'

module Lair

  class API < Grape::API
    version 'v1', using: :accept_version_header, vendor: 'lair'
    format :json

    cascade false
    rescue_from :all do |e|
      if Rails.env != 'production'
        puts e.message
        puts e.backtrace.join("\n")
      end
      Rack::Response.new([ JSON.dump({ errors: [ { message: e.message } ] }) ], 500, { "Content-type" => "application/json" }).finish
    end

    helpers do
      def language iso_code
        Language.find_or_create_by(iso_code: iso_code)
      end

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

      def current_user
        User.where(email: @auth_token['iss']).first!
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

    namespace :ownerships do
      post do

        item = Item.where(key: params[:itemKey]).first!
        user = params.key?(:userKey) ? User.where(key: params[:userKey]).first! : current_user

        Ownership.transaction do
          ownership = Ownership.new item: item, user: user
          ownership.gotten_at = Time.parse(params[:gottenAt]) if params[:gottenAt]

          ownership.save!
          ownership.to_builder.attributes!
        end
      end
    end

    namespace :parts do
      post do

        item = Item.where(key: params[:itemKey]).first!
        title = item.titles.where(key: params[:titleKey]).first!
        language = language(params[:language])

        ItemPart.transaction do
          part = Book.new
          part.item = item
          part.title = title
          part.language = language
          part.range_start = params[:start] if params.key?(:start)
          part.range_end = params[:end] if params.key?(:end)
          part.edition = params[:edition]
          part.version = params[:version] if params.key?(:version)
          part.format = params[:format] if params.key?(:format)
          part.length = params[:length] if params.key?(:length)
          part.publisher = params[:publisher] if params.key?(:publisher)
          part.isbn = params[:isbn] if params.key?(:isbn)
          part.save!

          part.to_builder.attributes!
        end
      end
    end

    namespace :items do
      post do
        language = language(params[:language])

        Item.transaction do
          item = Item.new category: params[:category], start_year: params[:startYear], language: language
          item.end_year = params[:endYear] if params.key?(:endYear)
          item.number_of_parts = params[:numberOfParts] if params.key?(:numberOfParts)

          params[:titles].each.with_index do |title,i|
            title = item.titles.build contents: title[:text], language: language(title[:language]), display_position: i
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
