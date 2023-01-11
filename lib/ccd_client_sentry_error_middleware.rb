require 'sentry-ruby'
require 'et_ccd_client'
class CcdClientSentryErrorMiddleware
  def call(ex, context)
    return unless ex.is_a?(EtCcdClient::Exceptions::Base)
    req = ex.try(:request) || {}
    Sentry.with_scope do |scope|
      scope.set_extras(ccd_response: ex.response.to_s, ccd_request: req)
    end
  end
end
