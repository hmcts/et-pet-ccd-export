EtFakeCcd.config.tap do |c|
  c.create_case_schema_file = File.absolute_path('../json_schemas/case_create.json', __dir__)
end
