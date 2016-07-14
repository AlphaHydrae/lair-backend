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

      code = 500
      errors = [ { message: e.message } ]

      if e.kind_of? LairError
        code = e.http_status_code
        errors.first[:message] = e.reason if e.reason.present?
      end

      if e.kind_of? Pundit::NotAuthorizedError
        code = 403
      elsif e.kind_of? ActiveRecord::RecordNotFound
        code = 404
      elsif e.kind_of? ValidationError
        errors.clear
        errors += e.errors
      elsif e.kind_of? ActiveRecord::RecordInvalid
        code = 422
        errors.clear
        e.record.errors.each do |attr,errs|
          Array.wrap(errs).each do |err|
            errors << { message: "#{attr.to_s.humanize} #{err}", path: "/#{attr.to_s.camelize(:lower).gsub(/\./, '/')}" }
          end
        end
      else
        Rails.logger.error %/#{e.message}\n#{e.backtrace.join("\n")}/
      end

      headers = { 'Content-Type' => 'application/json' }
      if e.kind_of? LairError
        headers.merge! e.headers
      end

      Rack::Response.new([ JSON.dump({ errors: errors }) ], code, headers).finish
    end

    helpers ApiAuthenticationHelper
    helpers ApiAuthorizationHelper
    helpers ApiImageableHelper
    helpers ApiPaginationHelper
    helpers ApiParamsHelper
    helpers ApiResourceHelper
    helpers ApiSerializationHelper
    helpers RedisHelper

    helpers do
      def language tag
        Language.find_or_create_by!(tag: tag)
      end
    end

    before do
      authenticate
    end

    mount CollectionsApi
    mount CompaniesApi
    mount EventsApi
    mount ImagesApi
    mount ImageSearchesApi
    mount WorksApi
    mount LanguagesApi
    mount OwnershipsApi
    mount ItemsApi
    mount PeopleApi
    mount StatsApi
    mount TokensApi
    mount UsersApi

    namespace :media do
      mount MediaFilesApi
      mount MediaFingerprintsApi
      mount MediaScannersApi
      mount MediaScansApi
      mount MediaScrapsApi
      mount MediaSearchesApi
      mount MediaSourcesApi
      mount MediaUrlsApi
    end

    get do
      {
        version: Rails.application.version,
        apiVersion: Rails.application.api_version,
        authenticated: current_user.present?
      }
    end

    get :ping do
      authorize! :api, :ping
      'pong'
    end

    get :itemPublishers do
      authorize! Item, :index
      Item.order(:publisher).pluck('distinct(publisher)').compact.collect{ |publisher| { name: publisher } }
    end

    get :itemEditions do
      authorize! Item, :index
      Item.order(:edition).pluck('distinct(edition)').compact.collect{ |edition| { name: edition } }
    end

    get :itemFormats do
      authorize! Item, :index
      Item.order(:format).pluck('distinct(format)').compact.collect{ |format| { name: format } }
    end
  end
end
