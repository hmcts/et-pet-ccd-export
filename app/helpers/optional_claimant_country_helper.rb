module OptionalClaimantCountryHelper
  def optional_claimant_country(country)
    return country if [nil, 'United Kingdom'].include?(country)

    nil
  end
end
