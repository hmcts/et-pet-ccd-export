module OptionalAcasExemptionHelper
  def optional_acas_exemption(exemption)
    case exemption
    when 'joint_claimant_has_acas_number'
      'Another person'
    when 'acas_has_no_jurisdiction'
      'No Power'
    when 'employer_contacted_acas'
      'Employer already in touch'
    when 'interim_relief'
      'Unfair Dismissal'
    end
  end
end
