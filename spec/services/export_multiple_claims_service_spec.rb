require 'rails_helper'
require 'ice_nine'
require 'securerandom'
RSpec.describe ExportMultipleClaimsService do
  subject(:service) { described_class.new presenter: mock_presenter, header_presenter: mock_header_presenter, envelope_presenter: mock_envelope_presenter, disallow_file_extensions: [] }

  let(:mock_presenter) { class_spy(MultipleClaimsPresenter, present: '{"some"=>"json", "claim" => "data"}') }
  let(:mock_header_presenter) do
    self.class::MockHeaderPresenter = class_spy(MultipleClaimsHeaderPresenter, present: '{"some"=>"json","claim"=>"header"}')
  end
  let(:mock_envelope_presenter) { class_spy(MultipleClaimsEnvelopePresenter) }

  describe '#call' do
    def primaryClaimantIndTypeMatcher(claimant, has_gender: true)
      a_hash_including 'claimant_title1' => claimant.title,
                       'claimant_first_names' => claimant.first_name,
                       'claimant_last_name' => claimant.last_name,
                       'claimant_date_of_birth' => claimant.date_of_birth,
                       'claimant_gender' => has_gender ? claimant.gender : nil
    end

    def primaryClaimantTypeMatcher(claimant)
      a_hash_including 'claimant_addressUK' => address_matcher(claimant.address),
                       'claimant_phone_number' => claimant.address_telephone_number,
                       'claimant_mobile_number' => claimant.mobile_number,
                       'claimant_email_address' => claimant.email_address,
                       'claimant_contact_preference' => claimant.contact_preference&.humanize
    end

    def address_matcher(address, has_country: true)
      a_hash_including 'AddressLine1' => address.building,
                       'AddressLine2' => address.street,
                       'PostTown' => address.locality,
                       'County' => address.county,
                       'PostCode' => address.post_code,
                       'Country' => has_country && ['United Kingdom'].include?(address.country) ? address.country : nil
    end

    def secondaryClaimantIndTypeMatcher(claimant)
      primaryClaimantIndTypeMatcher(claimant, has_gender: false)
    end

    def secondaryClaimantTypeMatcher(claimant)
      a_hash_including 'claimant_addressUK' => address_matcher(claimant.address, has_country: false),
                       'claimant_phone_number' => nil,
                       'claimant_mobile_number' => nil,
                       'claimant_email_address' => nil,
                       'claimant_contact_preference' => nil
    end

    def primaryClaimantOtherTypeMatcher(claimant, claim)
      hash_for_comparison = {
        'claimant_disabled' => claimant.special_needs.present? ? 'Yes' : 'No'

      }
      if claim.employment_details.present?
        hash_for_comparison.merge! \
          'claimant_employed_currently' => currently_employed?(claim) ? 'Yes' : 'No',
          'claimant_occupation' => claim.employment_details.job_title,
          'claimant_employed_from' => claim.employment_details.start_date,
          'claimant_employed_to' => claim.employment_details.end_date,
          'claimant_employed_notice_period' => claim.employment_details.notice_period_end_date
      end
      hash_for_comparison['claimant_disabled_details'] = claimant.special_needs if claimant.special_needs.present?
      a_hash_including hash_for_comparison
    end

    def primaryClaimantWorkAddressMatcher(claimant, claim)
      address = claim.primary_respondent.work_address.present? ? claim.primary_respondent.work_address : claim.primary_respondent.address
      a_hash_including('claimant_work_address' => address_matcher(address, has_country: false))
    end

    def currently_employed?(claim)
      return nil unless claim.employment_details.present?

      claim.employment_details.start_date.present? && (claim.employment_details.end_date.nil? || Date.parse(claim.employment_details.end_date) > Date.today)
    end

    RSpec::Matchers.define :json_matching do |sub_matcher|
      match do |actual|
        json = JSON.parse(actual)
        expect(json).to sub_matcher
      end
    end

    shared_context 'with mock workers' do
      let(:mock_worker_class) do
        calls = mock_worker_calls
        instance = nil
        reference = 1000001
        self.class::MockWorker = Class.new do
          include ::Sidekiq::Worker
          define_singleton_method(:new) { instance ||= super() }
          define_method :perform do |*args|
            calls << args
            ::Sidekiq.redis { |r| r.lpush("BID-#{bid}-references", reference) }
            reference += 1
          end
        end
        self.class::MockWorker
      end

      let(:mock_worker_calls) do
        []
      end

      let(:mock_header_worker_class) do
        instance = mock_header_worker
        self.class::MockHeaderWorker = Class.new do
          include ::Sidekiq::Worker
          define_singleton_method(:new) { instance }
        end
        self.class::MockHeaderWorker
      end

      let(:mock_header_worker) do
        fake_class_to_spy_on = Class.new do
          include ::Sidekiq::Worker
          define_method(:perform) { |*| }
        end
        instance_spy(fake_class_to_spy_on)
      end
    end

    context 'with secondary claimants from csv file' do
      include_context 'with stubbed ccd'
      include_context 'with mock workers'

      before do
        stub_request(:get, "http://dummy.com/examplepdf").
          to_return(status: 200, body: File.new(File.absolute_path('../fixtures/chloe_goodwin.pdf', __dir__)), headers: { 'Content-Type' => 'application/pdf'})
        stub_request(:get, "http://dummy.com/examplecsv").
          to_return(status: 200, body: File.new(File.absolute_path('../fixtures/example.csv', __dir__)), headers: { 'Content-Type' => 'text/csv'})
      end

      let(:example_export) { build(:export, :for_claim, claim_traits: [:default_multiple_claimants]) }

      it 'queues the header worker when done with the data from the header presenter' do
        # Act - Call the service
        service.call(example_export.as_json, worker: mock_worker_class, header_worker: mock_header_worker_class, sidekiq_job_data: { jid: 'examplejid' })
        drain_all_our_sidekiq_jobs

        # Assert - Check the batch
        expect(mock_header_worker).to have_received(:perform).with(example_export.resource.reference, example_export.resource.primary_respondent.name, match_array((1000001..(1000001 + example_export.resource.secondary_claimants.length)).to_a.map(&:to_s)), 'Manchester_Multiples_Dev', example_export.id)
      end

      it 'queues the worker 11 times with the data from the presenter' do
        # Arrange - Setup the presenter to return different values each time
        presented_values = [
          '{"claim"=>"1"}',
          '{"claim"=>"2"}',
          '{"claim"=>"3"}',
          '{"claim"=>"4"}',
          '{"claim"=>"5"}',
          '{"claim"=>"6"}',
          '{"claim"=>"7"}',
          '{"claim"=>"8"}',
          '{"claim"=>"9"}',
          '{"claim"=>"10"}',
          '{"claim"=>"11"}'
        ]
        allow(mock_presenter).to receive(:present).and_return(*presented_values)

        # Act - Call the service
        service.call(example_export.as_json, worker: mock_worker_class, header_worker: mock_header_worker_class, sidekiq_job_data: { jid: 'examplejid' })
        drain_all_our_sidekiq_jobs

        # Assert - Check the worker has been queued, first time with the primary set to true
        aggregate_failures 'validating calls' do
          expect(mock_worker_calls.first).to eql(['{"claim"=>"1"}', 'Manchester_Dev', example_export.id, 11, true])
          expect(mock_worker_calls[1..-1]).to eql presented_values[1..-1].map {|data| [data, 'Manchester_Dev', example_export.id, 11]}
        end
      end

      it 'calls the presenter 11 times with the correct parameters' do
        # Act - Call the service
        service.call(example_export.as_json, worker: mock_worker_class, header_worker: mock_header_worker_class, sidekiq_job_data: { jid: 'examplejid' })
        drain_all_our_sidekiq_jobs

        # Assert - Check the worker has been queued
        aggregate_failures "validate all calls in one" do
          expect(mock_presenter).to have_received(:present).exactly(example_export.resource.secondary_claimants.length + 1).times
          expect(mock_presenter).to have_received(:present).with(example_export.resource.as_json, claimant: example_export.resource.primary_claimant.as_json, files: an_instance_of(Array), lead_claimant: true, ethos_case_reference: anything)
          example_export.resource.secondary_claimants.each do |claimant|
            expect(mock_presenter).to have_received(:present).with(example_export.resource.as_json, claimant: claimant.as_json, lead_claimant: false, ethos_case_reference: anything)
          end
        end
      end

      # # The supervisor will receive an add_job call for each job it needs to supervise.
      # # This add_job is called with the json from the original ET JSON but modified
      # # so that the primary claimant is the secondary claimant of interest
      # # and the secondary claimants are empty.  This shrinks the json size down as the
      # # secondary claimants are not relevant - as each secondary claimant gets its own job
      # it 'schedules all claimants with the correct fee group references' do
      #   # Act - Call the service
      #   service.call(example_export.as_json)
      #
      #   # Assert - Calculate the expected json and check for it
      #   claimant_count = example_export.resource.secondary_claimants.length + 1
      #   json_matcher = json_matching(a_hash_including 'feeGroupReference' => example_export.resource.reference)
      #   expect(mock_supervisor).to have_received(:add_job).with(json_matcher, group_name: example_export.resource.reference).exactly(claimant_count).times
      # end
      #
      # it 'schedules the primary claimant with the correct claimantIndType via the supervisor' do
      #   # Act - Call the service
      #   service.call(example_export.as_json)
      #
      #   # Assert - Calculate the expected json and check for it
      #   json_matcher = json_matching(a_hash_including 'claimantIndType' => primaryClaimantIndTypeMatcher(example_export.resource.primary_claimant))
      #   expect(mock_supervisor).to have_received(:add_job).with(json_matcher, group_name: example_export.resource.reference).once
      # end
      #
      # it 'schedules the primary claimant with the correct claimantType via the supervisor' do
      #   # Act - Call the service
      #   service.call(example_export.as_json)
      #
      #   # Assert - Calculate the expected json and check for it
      #   json_matcher = json_matching(a_hash_including 'claimantType' => primaryClaimantTypeMatcher(example_export.resource.primary_claimant))
      #   expect(mock_supervisor).to have_received(:add_job).with(json_matcher, group_name: example_export.resource.reference).once
      # end
      #
      # it 'schedules the primary claimant with the correct claimantOtherType via the supervisor' do
      #   # Act - Call the service
      #   service.call(example_export.as_json)
      #
      #   # Assert - Calculate the expected json and check for it
      #   json_matcher = json_matching(a_hash_including 'claimantOtherType' => primaryClaimantOtherTypeMatcher(example_export.resource.primary_claimant, example_export.resource))
      #   expect(mock_supervisor).to have_received(:add_job).with(json_matcher, group_name: example_export.resource.reference).once
      # end
      #
      # it 'schedules the primary claimant with the correct claimantWorkAddress via the supervisor' do
      #   # Act - Call the service
      #   service.call(example_export.as_json)
      #
      #   # Assert - Calculate the expected json and check for it
      #   json_matcher = json_matching(a_hash_including 'claimantWorkAddress' => primaryClaimantWorkAddressMatcher(example_export.resource.primary_claimant, example_export.resource))
      #   expect(mock_supervisor).to have_received(:add_job).with(json_matcher, group_name: example_export.resource.reference).once
      # end
      #
      #
      #
      #
      #
      #
      # it 'schedules the secondary claimants with  the correct claimantIndType' do
      #   # Act - Call the service
      #   service.call(example_export.as_json)
      #
      #   example_export.resource.secondary_claimants.each do |claimant|
      #     json_matcher = json_matching(a_hash_including 'claimantIndType' => secondaryClaimantIndTypeMatcher(claimant))
      #     expect(mock_supervisor).to have_received(:add_job).with(json_matcher, group_name: example_export.resource.reference).once
      #   end
      # end
      #
      # it 'schedules the secondary claimants with  the correct claimantType' do
      #   # Act - Call the service
      #   service.call(example_export.as_json)
      #
      #   example_export.resource.secondary_claimants.each do |claimant|
      #     json_matcher = json_matching(a_hash_including 'claimantType' => secondaryClaimantTypeMatcher(claimant))
      #     expect(mock_supervisor).to have_received(:add_job).with(json_matcher, group_name: example_export.resource.reference).once
      #   end
      # end
      #
      # it 'schedules the secondary claimants with the correct claimantOtherType' do
      #   # Act - Call the service
      #   service.call(example_export.as_json)
      #
      #   # Assert - all 'n' times the job has been added, it should have had empty claimantOtherType
      #   json_matcher = json_matching(a_hash_including 'claimantOtherType' => {})
      #   expect(mock_supervisor).to have_received(:add_job).
      #     with(json_matcher, group_name: example_export.resource.reference).
      #     exactly(example_export.resource.secondary_claimants.length).times
      # end
      #
      # it 'schedules the secondary claimants with the correct claimantWorkAddress' do
      #   # Act - Call the service
      #   service.call(example_export.as_json)
      #
      #   # Assert - all 'n' times the job has been added, it should have and empty claimantWorkAddress for all secondaries
      #   json_matcher = json_matching(a_hash_including 'claimantWorkAddress' => {})
      #   expect(mock_supervisor).to have_received(:add_job).
      #     with(json_matcher, group_name: example_export.resource.reference).
      #     exactly(example_export.resource.secondary_claimants.length).times
      # end
      #
      # it 'must not modify original data' do
      #   # Arrange - Deep freeze the original
      #   data = example_export.as_json
      #   IceNine.deep_freeze(data)
      #
      #   # Act - Call the service
      #   action = -> { service.call(data) }
      #
      #   # Assert - Make sure it does not raise frozen error
      #   expect(action).not_to raise_exception(FrozenError)
      # end
    end
  end

  describe '#export' do
    include_context 'with stubbed ccd'
    let(:test_ccd_client) { EtCcdClient::UiClient.new.tap {|c| c.login(username: 'm@m.com', password: 'Pa55word11')} }
    let(:example_ccd_data) do
      {
        "receiptDate": "2019-06-12",
        "feeGroupReference": "222000000100",
        "claimant_TypeOfClaimant": "Individual",
        "claimantIndType": {
          "claimant_title1": "Mrs",
          "claimant_first_names": "tamara",
          "claimant_last_name": "swift",
          "claimant_date_of_birth": "1957-07-06",
          "claimant_gender": nil
        },
        "claimantType": {
          "claimant_addressUK": {
            "AddressLine1": "71088",
            "AddressLine2": "nova loaf",
            "PostTown": "keelingborough",
            "County": "hawaii",
            "Country": nil,
            "PostCode": "yy9a 2la"
          },
          "claimant_phone_number": nil,
          "claimant_mobile_number": nil,
          "claimant_email_address": nil,
          "claimant_contact_preference": nil
        },
        "caseType": "Single",
        "respondentSumType": {
          "respondent_name": "dodgy_co",
          "respondent_ACAS_question": "Yes",
          "respondent_address": {
            "AddressLine1": "1",
            "AddressLine2": "street",
            "PostTown": "locality",
            "County": "county",
            "PostCode": "post code"
          },
          "respondent_phone1": "01234 567890",
          "respondent_ACAS": "AC123456/78/90"
        },
        "claimantWorkAddress": {},
        "respondentCollection": [],
        "claimantOtherType": {},
        "claimantRepresentedQuestion": "Yes",
        "representativeClaimantType": {
          "representative_occupation": "Solicitor",
          "name_of_organisation": "Org name",
          "name_of_representative": "Rep Name",
          "representative_address": {
            "AddressLine1": "1",
            "AddressLine2": "street",
            "PostTown": "locality",
            "County": "county",
            "PostCode": "post code"
          },
          "representative_phone_number": "01234 565899",
          "representative_mobile_number": "07771 666555",
          "representative_email_address": "test@email.com",
          "representative_dx": "dx1234567890"
        }
      }
    end

    it 'stores the data in fake ccd' do
      # Arrange - Setup the envelope presenter to do what it should do (roughly - just to keep fake ccd happy)
      allow(mock_envelope_presenter).to receive(:present) do |data, event_token:|
        <<-JSON
          {"data": #{data},"event": {"id": "initiateCase"},"event_token": "eyJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJ1cHY5dTBvb2o3NWUzdG1kbW43YThtaGNoZSIsInN1YiI6IjY4OGNmYjVjLTU2MTctNDE0Yi04MzY1LTdlMTY4ODRmNGZiNyIsImlhdCI6MTU2MzE4NDA2NSwiZXZlbnQtaWQiOiJpbml0aWF0ZUNhc2UiLCJjYXNlLXR5cGUtaWQiOiJFbXBUcmliX01WUF8xLjBfTWFuYyIsImp1cmlzZGljdGlvbi1pZCI6IkVNUExPWU1FTlQiLCJjYXNlLXZlcnNpb24iOiJiZjIxYTllOGZiYzVhMzg0NmZiMDViNGZhMDg1OWUwOTE3YjIyMDJmIn0.n-cR9MXeIuCIr1LSJtJW4mTaX_slK9qB4JNl3ggsda4"}
        JSON
      end
      # Act - call the service
      begin
        old_file = EtFakeCcd.config.create_case_schema_file
        EtFakeCcd.config.create_case_schema_file = nil
        service.export(example_ccd_data.to_json, 'Manchester_Dev', sidekiq_job_data: { jid: 'examplejid' }, bid: 'examplebid', export_id: 1, claimant_count: 10)
      ensure
        EtFakeCcd.config.create_case_schema_file = old_file
      end

      # Assert - ensure it has arrived in CCD
      ccd_case = test_ccd_client.caseworker_search_latest_by_reference(example_ccd_data[:feeGroupReference], case_type_id: 'Manchester_Dev')
      expect(ccd_case['case_fields']).to include 'feeGroupReference' => example_ccd_data[:feeGroupReference]
    end
  end
end
