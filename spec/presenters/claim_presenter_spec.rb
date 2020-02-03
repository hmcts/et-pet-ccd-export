require 'rails_helper'
require 'jsonpath'
RSpec.describe ClaimPresenter do
  subject(:presenter) { described_class }

  def ccd_field(result, path)
    result_json = JSON.parse(result)
    result_json.dig('data', *path.split('.'))
  end

  describe '#present' do
    context 'with claimantIndType.claimant_title1' do
      it { is_expected.to present_ccd_field('claimantIndType.claimant_title1').using(:claim, primary_claimant_attrs: { title: 'Mrs' }).with_result('Mrs') }
      it { is_expected.to present_ccd_field('claimantIndType.claimant_title1').using(:claim, primary_claimant_attrs: { title: 'Mr' }).with_result('Mr') }
      it { is_expected.to present_ccd_field('claimantIndType.claimant_title1').using(:claim, primary_claimant_attrs: { title: nil }).with_result(nil) }
    end

    context 'with claimantIndType.claimant_first_names' do
      it { is_expected.to present_ccd_field('claimantIndType.claimant_first_names').using(:claim, primary_claimant_attrs: { first_name: 'Example1 Name' }).with_result('Example1 Name') }
      it { is_expected.to present_ccd_field('claimantIndType.claimant_first_names').using(:claim, primary_claimant_attrs: { first_name: 'Example2 Name' }).with_result('Example2 Name') }
    end

    context 'with claimantIndType.claimant_last_name' do
      it { is_expected.to present_ccd_field('claimantIndType.claimant_last_name').using(:claim, primary_claimant_attrs: { last_name: 'Example1' }).with_result('Example1') }
      it { is_expected.to present_ccd_field('claimantIndType.claimant_last_name').using(:claim, primary_claimant_attrs: { last_name: 'Example2' }).with_result('Example2') }
    end

    context 'with claimantIndType.claimant_date_of_birth' do
      it { is_expected.to present_ccd_field('claimantIndType.claimant_date_of_birth').using(:claim, primary_claimant_attrs: { date_of_birth: '1970-07-06' }).with_result('1970-07-06') }
      it { is_expected.to present_ccd_field('claimantIndType.claimant_date_of_birth').using(:claim, primary_claimant_attrs: { date_of_birth: '1984-12-31' }).with_result('1984-12-31') }
    end

    context 'with claimantIndType.claimant_gender' do
      it { is_expected.to present_ccd_field('claimantIndType.claimant_gender').using(:claim, primary_claimant_attrs: { gender: 'Male' }).with_result('Male') }
      it { is_expected.to present_ccd_field('claimantIndType.claimant_gender').using(:claim, primary_claimant_attrs: { gender: 'Female' }).with_result('Female') }
      it { is_expected.to present_ccd_field('claimantIndType.claimant_gender').using(:claim, primary_claimant_attrs: { gender: 'N/K' }).with_result('Not Known') }
      it { is_expected.to present_ccd_field('claimantIndType.claimant_gender').using(:claim, primary_claimant_attrs: { gender: 'Something Wrong' }).with_result(nil) }
      it { is_expected.to present_ccd_field('claimantIndType.claimant_gender').using(:claim, primary_claimant_attrs: { gender: nil }).with_result(nil) }
    end

    context 'with claimantOtherType.claimant_disabled' do
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_disabled').using(:claim, primary_claimant_attrs: { special_needs: 'Some special needs' }).with_result('Yes') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_disabled').using(:claim, primary_claimant_attrs: { special_needs: '' }).with_result('No') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_disabled').using(:claim, primary_claimant_attrs: { special_needs: nil }).with_result('No') }
    end

    context 'with claimantOtherType.claimant_disabled_details' do
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_disabled_details').using(:claim, primary_claimant_attrs: { special_needs: 'Example1 special needs' }).with_result('Example1 special needs') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_disabled_details').using(:claim, primary_claimant_attrs: { special_needs: 'Example2 special needs' }).with_result('Example2 special needs') }
      it { is_expected.not_to present_ccd_field('claimantOtherType.claimant_disabled_details').using(:claim, primary_claimant_attrs: { special_needs: nil }) }
      it { is_expected.not_to present_ccd_field('claimantOtherType.claimant_disabled_details').using(:claim, primary_claimant_attrs: { special_needs: '' }) }
    end

    context 'with claimantType.claimant_addressUK.AddressLine1' do
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.AddressLine1').using(:claim, primary_claimant_attrs: { address: { 'building' => 'Example1 Building' } }).with_result('Example1 Building') }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.AddressLine1').using(:claim, primary_claimant_attrs: { address: { 'building' => 'Example2 Building' } }).with_result('Example2 Building') }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.AddressLine1').using(:claim, primary_claimant_attrs: { address: { 'building' => nil } }).with_result(nil) }
    end

    context 'with claimantType.claimant_addressUK.AddressLine2' do

      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.AddressLine2').using(:claim, primary_claimant_attrs: { address: { 'street' => 'Example1 Street' } }).with_result('Example1 Street') }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.AddressLine2').using(:claim, primary_claimant_attrs: { address: { 'street' => 'Example2 Street' } }).with_result('Example2 Street') }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.AddressLine2').using(:claim, primary_claimant_attrs: { address: { 'street' => nil } }).with_result(nil) }
    end

    context 'with claimantType.claimant_addressUK.AddressLine3' do
      it { is_expected.not_to present_ccd_field('claimantType.claimant_addressUK.AddressLine3').using(:claim) }
    end

    context 'with claimantType.claimant_addressUK.PostTown' do
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.PostTown').using(:claim, primary_claimant_attrs: { address: { 'locality' => 'Example1 Town' } }).with_result('Example1 Town') }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.PostTown').using(:claim, primary_claimant_attrs: { address: { 'locality' => 'Example2 Town' } }).with_result('Example2 Town') }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.PostTown').using(:claim, primary_claimant_attrs: { address: { 'locality' => nil } }).with_result(nil) }
    end

    context 'with claimantType.claimant_addressUK.County' do
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.County').using(:claim, primary_claimant_attrs: { address: { 'county' => 'Example1 County' } }).with_result('Example1 County') }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.County').using(:claim, primary_claimant_attrs: { address: { 'county' => 'Example2 County' } }).with_result('Example2 County') }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.County').using(:claim, primary_claimant_attrs: { address: { 'county' => nil } }).with_result(nil) }
    end

    context 'with claimantType.claimant_addressUK.PostCode' do
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.PostCode').using(:claim, primary_claimant_attrs: { address: { 'post_code' => 'Example1 Postcode' } }).with_result('Example1 Postcode') }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.PostCode').using(:claim, primary_claimant_attrs: { address: { 'post_code' => 'Example2 Postcode' } }).with_result('Example2 Postcode') }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.PostCode').using(:claim, primary_claimant_attrs: { address: { 'post_code' => nil } }).with_result(nil) }
    end

    context 'with claimantType.claimant_addressUK.Country' do
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.Country').using(:claim, primary_claimant_attrs: { address: { 'country' => 'United Kingdom' } }).with_result('United Kingdom') }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.Country').using(:claim, primary_claimant_attrs: { address: { 'country' => 'Something Else' } }).with_result(nil) }
      it { is_expected.to present_ccd_field('claimantType.claimant_addressUK.Country').using(:claim, primary_claimant_attrs: { address: { 'country' => nil } }).with_result(nil) }
    end

    context 'with claimantType.claimant_phone_number' do
      it { is_expected.to present_ccd_field('claimantType.claimant_phone_number').using(:claim, primary_claimant_attrs: { address_telephone_number: 'Example number 1' }).with_result('Example number 1') }
      it { is_expected.to present_ccd_field('claimantType.claimant_phone_number').using(:claim, primary_claimant_attrs: { address_telephone_number: 'Example number 2' }).with_result('Example number 2') }
      it { is_expected.to present_ccd_field('claimantType.claimant_phone_number').using(:claim, primary_claimant_attrs: { address_telephone_number: nil }).with_result(nil) }
    end

    context 'with claimantType.claimant_mobile_number' do
      it { is_expected.to present_ccd_field('claimantType.claimant_mobile_number').using(:claim, primary_claimant_attrs: { mobile_number: 'Example number 1' }).with_result('Example number 1') }
      it { is_expected.to present_ccd_field('claimantType.claimant_mobile_number').using(:claim, primary_claimant_attrs: { mobile_number: 'Example number 2' }).with_result('Example number 2') }
      it { is_expected.to present_ccd_field('claimantType.claimant_mobile_number').using(:claim, primary_claimant_attrs: { mobile_number: nil }).with_result(nil) }
    end

    context 'with claimantType.claimant_email_address' do
      it { is_expected.to present_ccd_field('claimantType.claimant_email_address').using(:claim, primary_claimant_attrs: { email_address: 'test1@example.com' }).with_result('test1@example.com') }
      it { is_expected.to present_ccd_field('claimantType.claimant_email_address').using(:claim, primary_claimant_attrs: { email_address: 'test2@example.com' }).with_result('test2@example.com') }
      it { is_expected.to present_ccd_field('claimantType.claimant_email_address').using(:claim, primary_claimant_attrs: { email_address: nil }).with_result(nil) }
    end

    context 'with claimantType.claimant_contact_preference' do
      it { is_expected.to present_ccd_field('claimantType.claimant_contact_preference').using(:claim, primary_claimant_attrs: { contact_preference: 'email' }).with_result('Email') }
      it { is_expected.to present_ccd_field('claimantType.claimant_contact_preference').using(:claim, primary_claimant_attrs: { contact_preference: 'post' }).with_result('Post') }
      it { is_expected.to present_ccd_field('claimantType.claimant_contact_preference').using(:claim, primary_claimant_attrs: { contact_preference: nil }).with_result(nil) }
    end

    context 'with representativeClaimantType.representative_occupation' do
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_occupation').using(:claim, primary_representative_attrs: { representative_type: 'Solicitor' }).with_result('Solicitor') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_occupation').using(:claim, primary_representative_attrs: { representative_type: 'CAB' }).with_result('CAB') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_occupation').using(:claim, primary_representative_attrs: { representative_type: nil }).with_result(nil) }
    end

    context 'with claimantRepresentedQuestion' do
      it { is_expected.to present_ccd_field('claimantRepresentedQuestion').using(:claim).with_result('Yes') }
      it { is_expected.to present_ccd_field('claimantRepresentedQuestion').using(:claim, :no_representative).with_result('No') }
    end

    context 'with representativeClaimantType' do
      it { is_expected.not_to present_ccd_field('representativeClaimantType.name_of_organisation').using(:claim, :no_representative) }
    end

    context 'with representativeClaimantType.name_of_organisation' do
      it { is_expected.to present_ccd_field('representativeClaimantType.name_of_organisation').using(:claim, primary_representative_attrs: { organisation_name: 'Example org 1' }).with_result('Example org 1') }
      it { is_expected.to present_ccd_field('representativeClaimantType.name_of_organisation').using(:claim, primary_representative_attrs: { organisation_name: 'Example org 2' }).with_result('Example org 2') }
      it { is_expected.to present_ccd_field('representativeClaimantType.name_of_organisation').using(:claim, primary_representative_attrs: { organisation_name: nil }).with_result(nil) }
    end

    context 'with representativeClaimantType.name_of_representative' do
      it { is_expected.to present_ccd_field('representativeClaimantType.name_of_representative').using(:claim, primary_representative_attrs: { name: 'Name 1' }).with_result('Name 1') }
      it { is_expected.to present_ccd_field('representativeClaimantType.name_of_representative').using(:claim, primary_representative_attrs: { name: 'Name 2' }).with_result('Name 2') }
      it { is_expected.to present_ccd_field('representativeClaimantType.name_of_representative').using(:claim, primary_representative_attrs: { name: nil }).with_result(nil) }
    end

    context 'with representativeClaimantType.representative_address.AddressLine1' do
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.AddressLine1').using(:claim, primary_representative_attrs: { address: build(:address, building: 'Building 1') }).with_result('Building 1') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.AddressLine1').using(:claim, primary_representative_attrs: { address: build(:address, building: 'Building 2') }).with_result('Building 2') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.AddressLine1').using(:claim, primary_representative_attrs: { address: build(:address, building: nil) }).with_result(nil) }
    end

    context 'with representativeClaimantType.representative_address.AddressLine2' do
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.AddressLine2').using(:claim, primary_representative_attrs: { address: build(:address, street: 'Street 1') }).with_result('Street 1') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.AddressLine2').using(:claim, primary_representative_attrs: { address: build(:address, street: 'Street 2') }).with_result('Street 2') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.AddressLine2').using(:claim, primary_representative_attrs: { address: build(:address, street: nil) }).with_result(nil) }
    end

    context 'with representativeClaimantType.representative_address.PostTown' do
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.PostTown').using(:claim, primary_representative_attrs: { address: build(:address, locality: 'Town 1') }).with_result('Town 1') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.PostTown').using(:claim, primary_representative_attrs: { address: build(:address, locality: 'Town 2') }).with_result('Town 2') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.PostTown').using(:claim, primary_representative_attrs: { address: build(:address, locality: nil) }).with_result(nil) }
    end

    context 'with representativeClaimantType.representative_address.County' do
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.County').using(:claim, primary_representative_attrs: { address: build(:address, county: 'County 1') }).with_result('County 1') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.County').using(:claim, primary_representative_attrs: { address: build(:address, county: 'County 2') }).with_result('County 2') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.County').using(:claim, primary_representative_attrs: { address: build(:address, county: nil) }).with_result(nil) }
    end

    context 'with representativeClaimantType.representative_address.PostCode' do
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.PostCode').using(:claim, primary_representative_attrs: { address: build(:address, post_code: 'Post code 1') }).with_result('Post code 1') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.PostCode').using(:claim, primary_representative_attrs: { address: build(:address, post_code: 'Post code 2') }).with_result('Post code 2') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_address.PostCode').using(:claim, primary_representative_attrs: { address: build(:address, post_code: nil) }).with_result(nil) }
    end

    context 'with representativeClaimantType.representative_phone_number' do
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_phone_number').using(:claim, primary_representative_attrs: { address_telephone_number: 'Phone 1' }).with_result('Phone 1') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_phone_number').using(:claim, primary_representative_attrs: { address_telephone_number: 'Phone 2' }).with_result('Phone 2') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_phone_number').using(:claim, primary_representative_attrs: { address_telephone_number: nil }).with_result(nil) }
    end

    context 'with representativeClaimantType.representative_mobile_number' do
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_mobile_number').using(:claim, primary_representative_attrs: { mobile_number: 'Phone 1' }).with_result('Phone 1') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_mobile_number').using(:claim, primary_representative_attrs: { mobile_number: 'Phone 2' }).with_result('Phone 2') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_mobile_number').using(:claim, primary_representative_attrs: { mobile_number: nil }).with_result(nil) }
    end

    context 'with representativeClaimantType.representative_email_address' do
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_email_address').using(:claim, primary_representative_attrs: { email_address: 'rep@company1.com' }).with_result('rep@company1.com') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_email_address').using(:claim, primary_representative_attrs: { email_address: 'rep@company2.com' }).with_result('rep@company2.com') }
      it { is_expected.to present_ccd_field('representativeClaimantType.representative_email_address').using(:claim, primary_representative_attrs: { email_address: nil }).with_result(nil) }
    end

    context 'with claimantWorkAddress.claimant_work_address.AddressLine1' do
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine1').using(:claim, primary_respondent_attrs: { work_address: build(:address, building: 'Building 1') }).with_result('Building 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine1').using(:claim, primary_respondent_attrs: { work_address: build(:address, building: 'Building 2') }).with_result('Building 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine1').using(:claim, primary_respondent_attrs: { work_address: build(:address, building: nil) }).with_result(nil) }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine1').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, building: 'Building 1') }).with_result('Building 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine1').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, building: 'Building 2') }).with_result('Building 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine1').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, building: nil) }).with_result(nil) }
    end

    context 'with claimantWorkAddress.claimant_work_address.AddressLine2' do
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine2').using(:claim, primary_respondent_attrs: { work_address: build(:address, street: 'Street 1') }).with_result('Street 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine2').using(:claim, primary_respondent_attrs: { work_address: build(:address, street: 'Street 2') }).with_result('Street 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine2').using(:claim, primary_respondent_attrs: { work_address: build(:address, street: nil) }).with_result(nil) }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine2').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, street: 'Street 1') }).with_result('Street 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine2').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, street: 'Street 2') }).with_result('Street 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.AddressLine2').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, street: nil) }).with_result(nil) }
    end

    context 'with claimantWorkAddress.claimant_work_address.PostTown' do
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostTown').using(:claim, primary_respondent_attrs: { work_address: build(:address, locality: 'Town 1') }).with_result('Town 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostTown').using(:claim, primary_respondent_attrs: { work_address: build(:address, locality: 'Town 2') }).with_result('Town 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostTown').using(:claim, primary_respondent_attrs: { work_address: build(:address, locality: nil) }).with_result(nil) }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostTown').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, locality: 'Town 1') }).with_result('Town 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostTown').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, locality: 'Town 2') }).with_result('Town 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostTown').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, locality: nil) }).with_result(nil) }
    end

    context 'with claimantWorkAddress.claimant_work_address.County' do
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.County').using(:claim, primary_respondent_attrs: { work_address: build(:address, county: 'County 1') }).with_result('County 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.County').using(:claim, primary_respondent_attrs: { work_address: build(:address, county: 'County 2') }).with_result('County 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.County').using(:claim, primary_respondent_attrs: { work_address: build(:address, county: nil) }).with_result(nil) }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.County').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, county: 'County 1') }).with_result('County 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.County').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, county: 'County 2') }).with_result('County 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.County').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, county: nil) }).with_result(nil) }
    end

    context 'with claimantWorkAddress.claimant_work_address.PostCode' do
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostCode').using(:claim, primary_respondent_attrs: { work_address: build(:address, post_code: 'Postcode 1') }).with_result('Postcode 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostCode').using(:claim, primary_respondent_attrs: { work_address: build(:address, post_code: 'Postcode 2') }).with_result('Postcode 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostCode').using(:claim, primary_respondent_attrs: { work_address: build(:address, post_code: nil) }).with_result(nil) }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostCode').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, post_code: 'Postcode 1') }).with_result('Postcode 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostCode').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, post_code: 'Postcode 2') }).with_result('Postcode 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_address.PostCode').using(:claim, primary_respondent_attrs: { work_address: nil, address: build(:address, post_code: nil) }).with_result(nil) }
    end

    context 'with claimantWorkAddress.claimant_work_phone_number' do
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_phone_number').using(:claim, primary_respondent_attrs: { work_address_telephone_number: 'Number 1' }).with_result('Number 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_phone_number').using(:claim, primary_respondent_attrs: { work_address_telephone_number: 'Number 2' }).with_result('Number 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_phone_number').using(:claim, primary_respondent_attrs: { work_address_telephone_number: nil }).with_result(nil) }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_phone_number').using(:claim, primary_respondent_attrs: { work_address: nil, address_telephone_number: 'Number 1' }).with_result('Number 1') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_phone_number').using(:claim, primary_respondent_attrs: { work_address: nil, address_telephone_number: 'Number 2' }).with_result('Number 2') }
      it { is_expected.to present_ccd_field('claimantWorkAddress.claimant_work_phone_number').using(:claim, primary_respondent_attrs: { work_address: nil, address_telephone_number: nil }).with_result(nil) }
    end

    context 'with respondentCollection[0].value.respondent_name' do
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_name').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { name: 'Name 1' }).with_result('Name 1') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_name').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { name: 'Name 2' }).with_result('Name 2') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_name').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { name: nil }).with_result(nil) }
    end

    context 'with respondentCollection[0].value.respondent_address.AddressLine1' do
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.AddressLine1').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, building: 'Building 1') }).with_result('Building 1') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.AddressLine1').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, building: 'Building 2') }).with_result('Building 2') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.AddressLine1').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, building: nil) }).with_result(nil) }
    end

    context 'with respondentCollection[0].value.respondent_address.AddressLine2' do
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.AddressLine2').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, street: 'Street 1') }).with_result('Street 1') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.AddressLine2').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, street: 'Street 2') }).with_result('Street 2') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.AddressLine2').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, street: nil) }).with_result(nil) }
    end

    context 'with respondentCollection[0].value.respondent_address.PostTown' do
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.PostTown').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, locality: 'Town 1') }).with_result('Town 1') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.PostTown').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, locality: 'Town 2') }).with_result('Town 2') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.PostTown').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, locality: nil) }).with_result(nil) }
    end

    context 'with respondentCollection[0].value.respondent_address.County' do
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.County').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, county: 'County 1') }).with_result('County 1') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.County').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, county: 'County 2') }).with_result('County 2') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.County').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, county: nil) }).with_result(nil) }
    end

    context 'with respondentCollection[0].value.respondent_address.PostCode' do
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.PostCode').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, post_code: 'Postcode 1') }).with_result('Postcode 1') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.PostCode').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, post_code: 'Postcode 2') }).with_result('Postcode 2') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_address.PostCode').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address: build(:address, post_code: nil) }).with_result(nil) }
    end

    context 'with respondentCollection[0].value.respondent_phone1' do
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_phone1').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address_telephone_number: 'Number 1' }).with_result('Number 1') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_phone1').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address_telephone_number: 'Number 2' }).with_result('Number 2') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_phone1').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { address_telephone_number: nil }).with_result(nil) }
    end

    context 'with respondentCollection[0].value.respondent_ACAS' do
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_ACAS').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { acas_certificate_number: 'Cert 1' }).with_result('Cert 1') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_ACAS').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { acas_certificate_number: 'Cert 2' }).with_result('Cert 2') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_ACAS').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { acas_certificate_number: nil }).with_result(nil) }
    end

    context 'with respondentCollection[0].value.respondent_ACAS_question' do
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_ACAS_question').using(:claim, number_of_respondents: 2).with_result('Yes') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_ACAS_question').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { acas_certificate_number: '' }).with_result('No') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_ACAS_question').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { acas_certificate_number: nil }).with_result('No') }
    end

    context 'with respondentCollection[0].value.respondent_ACAS_no' do
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { acas_certificate_number: nil, acas_exemption_code: 'joint_claimant_has_acas_number' }).with_result('Another person') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { acas_certificate_number: nil, acas_exemption_code: 'acas_has_no_jurisdiction' }).with_result('No Power') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { acas_certificate_number: nil, acas_exemption_code: 'employer_contacted_acas' }).with_result('Employer already in touch') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { acas_certificate_number: nil, acas_exemption_code: 'interim_relief' }).with_result('Unfair Dismissal') }
      it { is_expected.to present_ccd_field('respondentCollection[0].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { acas_certificate_number: nil, acas_exemption_code: nil }).with_result(nil) }
      it { is_expected.not_to present_ccd_field('respondentCollection[0].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, primary_respondent_attrs: { acas_certificate_number: 'Some number' }) }
    end

    context 'with respondentCollection[1].value.respondent_name' do
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_name').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { name: 'Name 1' }).with_result('Name 1') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_name').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { name: 'Name 2' }).with_result('Name 2') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_name').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { name: nil }).with_result(nil) }
    end

    context 'with respondentCollection[1].value.respondent_address.AddressLine1' do
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.AddressLine1').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, building: 'Building 1') }).with_result('Building 1') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.AddressLine1').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, building: 'Building 2') }).with_result('Building 2') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.AddressLine1').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, building: nil) }).with_result(nil) }
    end

    context 'with respondentCollection[1].value.respondent_address.AddressLine2' do
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.AddressLine2').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, street: 'Street 1') }).with_result('Street 1') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.AddressLine2').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, street: 'Street 2') }).with_result('Street 2') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.AddressLine2').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, street: nil) }).with_result(nil) }
    end

    context 'with respondentCollection[1].value.respondent_address.PostTown' do
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.PostTown').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, locality: 'Town 1') }).with_result('Town 1') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.PostTown').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, locality: 'Town 2') }).with_result('Town 2') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.PostTown').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, locality: nil) }).with_result(nil) }
    end

    context 'with respondentCollection[1].value.respondent_address.County' do
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.County').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, county: 'County 1') }).with_result('County 1') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.County').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, county: 'County 2') }).with_result('County 2') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.County').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, county: nil) }).with_result(nil) }
    end

    context 'with respondentCollection[1].value.respondent_address.PostCode' do
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.PostCode').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, post_code: 'Postcode 1') }).with_result('Postcode 1') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.PostCode').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, post_code: 'Postcode 2') }).with_result('Postcode 2') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_address.PostCode').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address: build(:address, post_code: nil) }).with_result(nil) }
    end

    context 'with respondentCollection[1].value.respondent_phone1' do
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_phone1').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address_telephone_number: 'Number 1' }).with_result('Number 1') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_phone1').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address_telephone_number: 'Number 2' }).with_result('Number 2') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_phone1').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { address_telephone_number: nil }).with_result(nil) }
    end

    context 'with respondentCollection[1].value.respondent_ACAS' do
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_ACAS').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { acas_certificate_number: 'Cert 1' }).with_result('Cert 1') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_ACAS').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { acas_certificate_number: 'Cert 2' }).with_result('Cert 2') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_ACAS').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { acas_certificate_number: nil }).with_result(nil) }
    end

    context 'with respondentCollection[1].value.respondent_ACAS_question' do
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_ACAS_question').using(:claim, number_of_respondents: 2).with_result('Yes') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_ACAS_question').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { acas_certificate_number: '' }).with_result('No') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_ACAS_question').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { acas_certificate_number: nil }).with_result('No') }
    end

    context 'with respondentCollection[1].value.respondent_ACAS_no' do
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { acas_certificate_number: nil, acas_exemption_code: 'joint_claimant_has_acas_number' }).with_result('Another person') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { acas_certificate_number: nil, acas_exemption_code: 'acas_has_no_jurisdiction' }).with_result('No Power') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { acas_certificate_number: nil, acas_exemption_code: 'employer_contacted_acas' }).with_result('Employer already in touch') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { acas_certificate_number: nil, acas_exemption_code: 'interim_relief' }).with_result('Unfair Dismissal') }
      it { is_expected.to present_ccd_field('respondentCollection[1].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { acas_certificate_number: nil, acas_exemption_code: nil }).with_result(nil) }
      it { is_expected.not_to present_ccd_field('respondentCollection[1].value.respondent_ACAS_no').using(:claim, number_of_respondents: 2, secondary_respondent_attrs: { acas_certificate_number: 'Some number' }) }
    end

    context 'with claimantOtherType.claimant_employed_currently' do
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_currently').using(:claim).with_result('Yes') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_currently').using(:claim, employment_details_traits: [:no_longer_employed]).with_result('No') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_currently').using(:claim, employment_details_traits: [:working_notice_period]).with_result('Yes') }
      it { is_expected.not_to present_ccd_field('claimantOtherType.claimant_employed_currently').using(:claim, employment_details_traits: [:blank]) }
    end

    context 'with claimantOtherType.claimant_occupation' do
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_occupation').using(:claim, employment_details_attrs: { job_title: 'Bottle Washer' }).with_result('Bottle Washer') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_occupation').using(:claim, employment_details_attrs: { job_title: 'Project Manager' }).with_result('Project Manager') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_occupation').using(:claim, employment_details_attrs: { job_title: nil }).with_result(nil) }
      it { is_expected.not_to present_ccd_field('claimantOtherType.claimant_occupation').using(:claim, employment_details_traits: [:blank]) }
    end

    context 'with claimantOtherType.claimant_employed_from' do
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_from').using(:claim, employment_details_attrs: { start_date: '2012-11-21' }).with_result('2012-11-21') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_from').using(:claim, employment_details_attrs: { start_date: '2012-10-22' }).with_result('2012-10-22') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_from').using(:claim, employment_details_attrs: { start_date: nil }).with_result(nil) }
      it { is_expected.not_to present_ccd_field('claimantOtherType.claimant_employed_from').using(:claim, employment_details_traits: [:blank]) }
    end

    context 'with claimantOtherType.claimant_employed_notice_period' do
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_notice_period').using(:claim, employment_details_attrs: { notice_period_end_date: '2012-09-11' }).with_result('2012-09-11') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_notice_period').using(:claim, employment_details_attrs: { notice_period_end_date: '2012-09-12' }).with_result('2012-09-12') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_notice_period').using(:claim, employment_details_attrs: { notice_period_end_date: nil }).with_result(nil) }
      it { is_expected.not_to present_ccd_field('claimantOtherType.claimant_employed_notice_period').using(:claim, employment_details_traits: [:blank]) }
    end

    context 'with claimantOtherType.claimant_employed_to' do
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_to').using(:claim, employment_details_attrs: { end_date: '2015-08-05' }).with_result('2015-08-05') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_to').using(:claim, employment_details_attrs: { end_date: '2015-08-13' }).with_result('2015-08-13') }
      it { is_expected.to present_ccd_field('claimantOtherType.claimant_employed_to').using(:claim, employment_details_attrs: { end_date: nil }).with_result(nil) }
      it { is_expected.not_to present_ccd_field('claimantOtherType.claimant_employed_to').using(:claim, employment_details_traits: [:blank]) }
    end

    context 'with receiptDate presenting in London time zone' do
      it { is_expected.to present_ccd_field('receiptDate').using(:claim, date_of_receipt: '2019-06-12T07:28:58.000Z').with_result('2019-06-12') }
      it { is_expected.to present_ccd_field('receiptDate').using(:claim, date_of_receipt: '2019-07-13T07:28:58.000Z').with_result('2019-07-13') }
      it { is_expected.to present_ccd_field('receiptDate').using(:claim, date_of_receipt: '2019-03-31T23:00:00.000Z').with_result('2019-04-01') }
      it { is_expected.to present_ccd_field('receiptDate').using(:claim, date_of_receipt: '2019-03-31T22:59:59.999Z').with_result('2019-03-31') }
      it { is_expected.to present_ccd_field('receiptDate').using(:claim, date_of_receipt: '2019-10-26T23:00:00.000Z').with_result('2019-10-27') }
      it { is_expected.to present_ccd_field('receiptDate').using(:claim, date_of_receipt: '2019-10-27T23:00:00.000Z').with_result('2019-10-27') }
      it { is_expected.to present_ccd_field('receiptDate').using(:claim, date_of_receipt: '2019-07-14').with_result('2019-07-14') }
    end

    context 'with feeGroupReference' do
      it { is_expected.to present_ccd_field('feeGroupReference').using(:claim, reference: 'Reference 1').with_result('Reference 1') }
      it { is_expected.to present_ccd_field('feeGroupReference').using(:claim, reference: 'Reference 2').with_result('Reference 2') }
    end

    context 'with caseType' do
      it { is_expected.to present_ccd_field('caseType').using(:claim).with_result('Single') }
    end

    context 'with claimant_TypeOfClaimant' do
      it { is_expected.to present_ccd_field('claimant_TypeOfClaimant').using(:claim, :default).with_result('Individual') }
    end
  end
end
