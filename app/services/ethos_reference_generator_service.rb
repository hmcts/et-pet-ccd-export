# Generates a new reference number from a previous reference number
module EthosReferenceGeneratorService
  MAX_REF = 99999
  # @param [String] previous_reference A reference number in the format oo00000/yyyy where oo is the office number, yyyy is the year and 00000 is the sequence number
  # @return [String] The new reference number.  Note that wrap around can happen only once and to signify that it has happened, the century is set to 00 in the year
  def self.call(previous_reference)
    match_data = previous_reference.match(/\A(\d\d)(\d{5})\/(\d{4})\z/)
    next_ref = match_data[2].to_i + 1
    year = match_data[3].to_i
    raise 'All reference numbers used up' if next_ref > MAX_REF && wrapped_around(year)

    if next_ref > MAX_REF
      next_ref = 1
      year = wrap_around(year)
    end
    "#{match_data[1]}#{next_ref.to_s.rjust(5, '0')}/#{year.to_s.rjust(4, '0')}"
  end

  def self.wrapped_around(year)
    year < 100
  end

  def self.wrap_around(year)
    year % 100
  end

  private_class_method :wrapped_around, :wrap_around
end