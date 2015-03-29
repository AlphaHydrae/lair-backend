module Lair

  # TODO: use hyphenation rather than camel-case for multi-word resource paths
  class API < Grape::API
    version 'v1', using: :accept_version_header
    format :json

    cascade false
    rescue_from :all do |e|
      if Rails.env == 'development'
        puts e.message
        puts e.backtrace.join("\n")
      end

      code = if e.kind_of? LairError
        e.http_status_code
      elsif e.kind_of? ActiveRecord::RecordNotFound
        404
      elsif e.kind_of? ActiveRecord::RecordInvalid
        422
      else
        500
      end

      headers = { 'Content-Type' => 'application/json' }
      if e.kind_of? LairError
        headers.merge! e.headers
      end

      Rack::Response.new([ JSON.dump({ errors: [ { message: e.message } ] }) ], code, headers).finish
    end

    helpers ApiAuthenticationHelper
    helpers ImageSearchHelper::Api
    helpers ApiImageableHelper
    helpers ApiPaginationHelper
    helpers ApiParamsHelper

    helpers do
      def language tag
        Language.find_or_create_by!(tag: tag)
      end

      def authenticate
        authenticate_with_header headers['Authorization'], required: false
      end

      def authenticate!
        authenticate_with_header headers['Authorization'], required: true
      end

      def current_user
        @auth_token ? User.where(email: @auth_token['iss']).first! : nil
      end
    end

    include ImageSearchesApi
    mount ItemsApi
    mount LanguagesApi
    mount OwnershipsApi
    mount PartsApi
    mount PeopleApi
    mount UsersApi

    get :ping do
      authenticate!
      'pong'
    end

    get :bookPublishers do
      authenticate!
      Book.order(:publisher).pluck('distinct(publisher)').compact.collect{ |publisher| { name: publisher } }
    end

    get :partEditions do
      authenticate!
      ItemPart.order(:edition).pluck('distinct(edition)').compact.collect{ |edition| { name: edition } }
    end

    get :partFormats do
      authenticate!
      ItemPart.order(:format).pluck('distinct(format)').compact.collect{ |format| { name: format } }
    end
  end
end
