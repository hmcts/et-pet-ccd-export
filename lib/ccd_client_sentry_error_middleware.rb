require 'raven'
require 'et_ccd_client'
class CcdClientSentryErrorMiddleware
  def call(ex, context)
    return unless ex.is_a?(EtCcdClient::Exceptions::Base)
    req = ex&.request || {}
    Raven.context.extra.merge! ccd_response: ex.response.to_s, ccd_request: req
  end
end
