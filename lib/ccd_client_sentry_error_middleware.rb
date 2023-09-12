require 'sentry-ruby'
require 'et_ccd_client'
class CcdClientSentryErrorMiddleware
  def call(exception, _context)
    return unless exception.is_a?(EtCcdClient::Exceptions::Base)

    req = exception.try(:request) || {}
    Sentry.with_scope do |scope|
      scope.set_extras(ccd_response: exception.response.to_s, ccd_request: req)
    end
  end
end
