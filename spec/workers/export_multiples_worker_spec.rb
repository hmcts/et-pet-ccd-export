require 'rails_helper'
RSpec.describe ExportMultiplesWorker do
  subject(:worker) { described_class.new }
  let(:example_export) { build(:export, :for_claim, claim_traits: [:default_multiple_claimants]) }

  describe '#perform' do
    include_context 'with stubbed ccd'
    let(:test_ccd_client) { EtCcdClient::UiClient.new.tap {|c| c.login(username: 'm@m.com', password: 'Pa55word11')} }

    let(:example_ccd_data) do
      {
        "receiptDate": "2019-06-12",
        "ethosCaseReference": "exampleEthosCaseReference",
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
    let(:example_ccd_data_primary) do
      {
        "receiptDate": "2019-06-12",
        "ethosCaseReference": "exampleEthosCaseReferencePrimary",
        "feeGroupReference": "222000000100",
        "claimant_TypeOfClaimant": "Individual",
        "claimantIndType": {
          "claimant_title1": "Mr",
          "claimant_first_names": "First",
          "claimant_last_name": "Last",
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

    # Note - currently, we send to ethosCaseReference because CCD says its mandatory.
    # however, in the future we will not send it and CCD will auto populate it.
    # This will then mean that this test is not real life in some respects, so the
    # fake ccd server will have to be modified to do the same thing as CCD and pre populate it
    it 'adds to the correct redis list when done' do
      # Act - Call the worker
      batch=Sidekiq::Batch.new
      batch.jobs do
        worker.perform(example_ccd_data.to_json, 'Manchester_Dev', 1, 1)
      end

      # Assert - Check in redis
      references = Sidekiq.redis { |r| r.lrange("BID-#{batch.bid}-references", 0, -1) }
      expect(references).to contain_exactly('exampleEthosCaseReference')
    end

    it 'stores the entry first in the list if primary flag is set' do
      # Act - Call the worker
      batch=Sidekiq::Batch.new
      batch.jobs do
        worker.perform(example_ccd_data.to_json, 'Manchester_Dev', 1, 10)
        worker.perform(example_ccd_data_primary.to_json, 'Manchester_Dev', 1, 10, true)
      end

      # Assert - Check in redis
      references = Sidekiq.redis { |r| r.lrange("BID-#{batch.bid}-references", 0, -1) }
      expect(references.first).to eql 'exampleEthosCaseReferencePrimary'

    end

  end

end
