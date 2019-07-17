json.data do
  json.bulkCaseTitle ""
  json.multipleReference primary_reference
  json.caseIdCollection(case_references) do |case_ref|
    json.id nil
    json.value do
      json.ethos_CaseReference case_ref
    end
  end
end
json.event do
  json.id "createBulkAction"
  json.summary ""
  json.description ""
end
json.event_token event_token
json.ignore_warning false
json.draft_id nil