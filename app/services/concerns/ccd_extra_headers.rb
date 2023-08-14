module CcdExtraHeaders
  extend ActiveSupport::Concern

  # Calculates any extra header that are to be sent to ccd
  # @param [Hash] export The export object
  # @param [String, Nil] request_id A unique identifier that must remain the same on retries - normally the job id
  #   If this is nil, the request id is not included
  def extra_headers_for(export, request_id = nil)
    headers = parsed_extra_headers_from_export(export)
    request_id.present? && send_request_id?(export) ? headers.merge('request_id' => request_id) : headers
  end

  def send_request_id?(export)
    config = export.dig('external_system', 'configurations').detect { |c| c['key'] == 'send_request_id' }
    return false if config.nil?

    config.fetch('value', 'false') == 'true'
  end

  private

  def parsed_extra_headers_from_export(export)
    headers = export.dig('external_system', 'configurations').detect { |c| c['key'] == 'extra_headers' }&.fetch('value', '{}')
    headers ||= '{}'
    headers = begin
      JSON.parse(headers)
    rescue JSON::ParserError
      {}
    end
    headers.each_with_object({}) do |(key, value), acc|
      acc[key] = JSON.generate(value)
      acc
    end
  end
end
