module OptionalAcasExemptionHelper
  LOOKUP = {
    'joint_claimant_has_acas_number' => 'Another person',
    'acas_has_no_jurisdiction' => 'No Power',
    'employer_contacted_acas' => 'Employer already in touch',
    'interim_relief' => 'Unfair Dismissal'
  }.freeze
  def optional_acas_exemption(exemption)
    LOOKUP[exemption]
  end
end
