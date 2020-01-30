EtCcdClient.config do |c|
  c.auth_base_url = 'http://localhost:8080/auth'
  c.idam_base_url = 'http://localhost:8080/idam'
  c.data_store_base_url = 'http://localhost:8080/data_store'
  c.document_store_base_url = 'http://localhost:8080/document_store'
  c.document_store_url_rewrite = false
  c.gateway_api_url = 'http://localhost:8080/api-gateway'
  c.jurisdiction_id = 'EMPLOYMENT'
  c.microservice = 'ccd_gw'
  c.microservice_secret = 'AAAAAAAAAAAAAAAC'
  c.use_sidam = true
  c.sidam_username = 'm@m.com'
  c.sidam_password = 'Pa55word11'
  c.case_management_ui_base_url = 'http://localhost:8080/case-management-web'
  c.case_management_ui_redirect_url = "#{c.case_management_ui_base_url}/oauth2redirect"
  c.verify_ssl = false
end
