module GenerateEthosCaseReference
  # This code is temporary and has a ticket to remove it once CCD is sorted (RST-2139)
  # @TODO Review this code to see if is still relevant
  def ethos_case_reference(office_code)
    return nil unless generate_ethos_case_reference?
    seconds_into_year = (Time.now.utc - Time.now.utc.beginning_of_year)
    reference = (seconds_into_year * 10).to_i.to_s.rjust(9, '0')
    "#{office_code}#{reference[0..4]}/#{reference[5..8]}"
  end

  private

  def generate_ethos_case_reference?
    Rails.application.config.generate_ethos_case_reference
  end
end
