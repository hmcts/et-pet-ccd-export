EtCcdClient.config do |c|
  c.auth_base_url = ENV.fetch('CCD_AUTH_BASE_URL', 'http://localhost:4502')
  c.idam_base_url = ENV.fetch('CCD_IDAM_BASE_URL', 'http://localhost:5000')
  c.data_store_base_url = ENV.fetch('CCD_DATA_STORE_BASE_URL', 'http://localhost:4452')
  c.gateway_api_url = ENV.fetch('CCD_GATEWAY_API_URL', 'http://localhost:3453')
  c.jurisdiction_id = ENV.fetch('CCD_JURISDICTION_ID', 'EMPLOYMENT')
  c.microservice = ENV.fetch('CCD_MICROSERVICE_ID', 'ccd_gw')
  c.microservice_secret = ENV.fetch('CCD_MICROSERVICE_SECRET', 'AAAAAAAAAAAAAAAC')
  c.use_sidam = ENV.fetch('CCD_USE_SIDAM', 'true').downcase == 'true'
  c.sidam_username = ENV.fetch('CCD_SIDAM_USERNAME', 'm@m.com')
  c.sidam_password = ENV.fetch('CCD_SIDAM_PASSWORD', 'Pa55word11')
  c.case_management_ui_base_url = ENV.fetch('CCD_CASE_MANAGEMENT_UI_BASE_URL', 'http://localhost:3451')
  c.case_management_ui_redirect_url = ENV.fetch('CCD_CASE_MANAGEMENT_UI_REDIRECT_URL', "#{c.case_management_ui_base_url}/oauth2redirect")
  c.verify_ssl = ENV.fetch('CCD_SSL_VERIFICATION', 'true') == 'true'
  c.pool_size = ENV.fetch('CCD_CLIENT_POOL_SIZE', '5').to_i
  c.pool_timeout = ENV.fetch('CCD_CLIENT_POOL_TIMEOUT', '30').to_i
  c.logger = Rails.logger
end
