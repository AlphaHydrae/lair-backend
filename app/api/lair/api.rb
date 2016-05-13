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
      elsif e.kind_of? Pundit::NotAuthorizedError
        403
      elsif e.kind_of? ActiveRecord::RecordNotFound
        404
      elsif e.kind_of? ActiveRecord::RecordInvalid
        422
      else
        Rails.logger.error e
        500
      end

      headers = { 'Content-Type' => 'application/json' }
      if e.kind_of? LairError
        headers.merge! e.headers
      end

      Rack::Response.new([ JSON.dump({ errors: [ { message: e.message } ] }) ], code, headers).finish
    end

    helpers ApiAuthenticationHelper
    helpers ApiAuthorizationHelper
    helpers ApiImageableHelper
    helpers ApiPaginationHelper
    helpers ApiParamsHelper
    helpers ApiResourceHelper
    helpers ApiSerializationHelper
    helpers ImageSearchHelper::Api

    helpers do
      def language tag
        Language.find_or_create_by!(tag: tag)
      end
    end

    before do
      authenticate
    end

    include ImageSearchesApi
    mount CollectionsApi
    mount EventsApi
    mount ImagesApi
    mount ItemsApi
    mount LanguagesApi
    mount OwnershipsApi
    mount PartsApi
    mount PeopleApi
    mount StatsApi
    mount UsersApi

    get :ping do
      authorize! :api, :ping
      'pong'
    end

    get :bookPublishers do
      authorize! ItemPart, :index
      Book.order(:publisher).pluck('distinct(publisher)').compact.collect{ |publisher| { name: publisher } }
    end

    get :partEditions do
      authorize! ItemPart, :index
      Book.order(:publisher).pluck('distinct(publisher)').compact.collect{ |publisher| { name: publisher } }
      ItemPart.order(:edition).pluck('distinct(edition)').compact.collect{ |edition| { name: edition } }
    end

    get :partFormats do
      authorize! ItemPart, :index
      ItemPart.order(:format).pluck('distinct(format)').compact.collect{ |format| { name: format } }
    end
  end
end
