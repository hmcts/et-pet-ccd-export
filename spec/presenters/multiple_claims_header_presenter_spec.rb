require 'rails_helper'
RSpec.describe MultipleClaimsHeaderPresenter do
  subject(:presenter) { described_class }
  let(:example_primary_reference) { "123456789012" }
  let(:example_respondent_name) { 'Dodgy Co' }
  let(:example_case_references) do
    [
      'ExampleCase01',
      'ExampleCase02',
      'ExampleCase03',
      'ExampleCase04',
      'ExampleCase05',
      'ExampleCase06',
      'ExampleCase07',
      'ExampleCase08',
      'ExampleCase09',
      'ExampleCase10'
    ]
  end
  let(:example_event_token) { 'example-token-12345' }

  it 'presents the bulkCaseTitle' do
    # Act
    result = JSON.parse(subject.present(primary_reference: example_primary_reference, respondent_name: example_respondent_name, case_references: example_case_references, event_token: example_event_token))

    # Assert
    expect(result.dig('data', 'bulkCaseTitle')).to eql example_respondent_name
  end

  it 'presents the caseIdCollection' do
    # Act
    result = JSON.parse(subject.present(primary_reference: example_primary_reference, respondent_name: example_respondent_name, case_references: example_case_references, event_token: example_event_token))

    # Assert
    expected_collection = example_case_references.map do |ref|
      {
        "id" => nil,
        "value" => {
          "ethos_CaseReference" => ref
        }
      }
    end
    expect(result.dig('data', 'caseIdCollection')).to match_array(expected_collection)
  end

  it 'presents the event object' do
    # Act
    result = JSON.parse(subject.present(primary_reference: example_primary_reference, respondent_name: example_respondent_name, case_references: example_case_references, event_token: example_event_token))

    # Assert
    expect(result['event']).to include 'id' => 'createBulkAction',
                                       'summary' => instance_of(String),
                                       'description' => instance_of(String)
  end

  it 'presents the event_token' do
    # Act
    result = JSON.parse(subject.present(primary_reference: example_primary_reference, respondent_name: example_respondent_name, case_references: example_case_references, event_token: example_event_token))

    # Assert
    expect(result['event_token']).to eql example_event_token
  end
end
