require 'rails_helper'
RSpec.describe ExportClaimService do
  subject(:service) { described_class.new(disallow_file_extensions: []) }

  describe '#call' do
    let(:export) { create(:export, :for_claim) }
    # include_context 'with stubbed ccd'

    it 'requests a token as it doesnt have one' do
      #service.call(export.as_json)
    end

    it 'only requests a token the first time'
    it 'performs a request to create a case with a valid token'
    it 'performs a request to create a case with valid primary claim data'
    it 'performs a request to create a case with valid primary claimant data'
    it 'performs a request to create a case with valid primary respondent data'
    it 'performs a request to create a case with valid primary representative data'
    it 'performs a request to create a case with valid pdf document'
    it 'returns a success when the service responds positively'
    it 'returns a failure when the service respondes negatively'

  end
end
