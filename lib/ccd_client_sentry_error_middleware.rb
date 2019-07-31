require 'raven'
require 'et_ccd_client'
class CcdClientSentryErrorMiddleware
  def call(ex, context)
    return unless ex.is_a?(EtCcdClient::Exceptions::Base)
    req = {}
    if ex&.request
      req[:url] = ex.request.url
      req[:method] = ex.request.method
      req[:payload] = ex.request.payload
      req[:headers] = ex.request.headers
      req[:cookies] = ex.request.cookies
    end
    Raven.context.extra.merge! ccd_response: ex.response.to_s, ccd_request: req
  end
end
