module GenerateEthosCaseReference
  def ethos_case_reference
    return nil unless generate_ethos_case_reference?

    "#{Time.now.strftime('%Y%m%d%H%M%S.%6N')}"
  end

  private

  def generate_ethos_case_reference?
    Rails.application.config.generate_ethos_case_reference
  end
end
