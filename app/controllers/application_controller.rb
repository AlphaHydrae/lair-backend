require_dependency 'errors'

class ApplicationController < ActionController::Base
  include ApiAuthorizationHelper
  include ApiSerializationHelper

  rescue_from LairError do |exception|

    reason = exception.reason || 'error'
    message = reason ? exception.message : 'An unexpected error occurred.'

    render json: { errors: [ { reason: reason, message: message } ] }, status: exception.http_status_code || :internal_server_error
  end
end
