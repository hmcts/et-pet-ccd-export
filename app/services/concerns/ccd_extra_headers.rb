module CcdExtraHeaders
  extend ActiveSupport::Concern

  # Calculates any extra header that are to be sent to ccd
  # @param [Hash] export The export object
  # @param [String] request_id A unique identifier that must remain the same on retries - normally the job id
  def extra_headers_for(export, request_id)
    send_request_id?(export) ? { request_id: request_id } : {}
  end

  def send_request_id?(export)
    config = export.dig('external_system', 'configurations').detect {|c| c['key'] == 'send_request_id'}
    return false if config.nil?

    config.fetch('value', 'false') == 'true'
  end
end
