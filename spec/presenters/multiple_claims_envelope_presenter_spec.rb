require 'rails_helper'
RSpec.describe MultipleClaimsEnvelopePresenter do
  subject(:presenter) { described_class }

  describe '.present' do
    let(:example_data) do
      {
        "test" => "data"
      }
    end
    let(:example_event_token) { 'eventtoken12345' }

    it 'presents a wrapper around the data' do
      # Act - call the presenter
      result = JSON.parse(presenter.present(example_data.to_json, event_token: example_event_token))

      # Assert - check the json
      expect(result['data']).to eql example_data
    end

    it 'adds the event block' do
      # Act - call the presenter
      result = JSON.parse(presenter.present(example_data.to_json, event_token: example_event_token))

      # Assert - check the json
      expect(result['event']).to include 'id' => 'initiateCase',
                                         'summary' => instance_of(String),
                                         'description' => instance_of(String)
    end

    it 'adds the event token' do
      # Act - call the presenter
      result = JSON.parse(presenter.present(example_data.to_json, event_token: example_event_token))

      # Assert - check the json
      expect(result['event_token']).to eql example_event_token
    end
  end
end
