RSpec::Matchers.define :present_ccd_field do |ccd_field_path|
  undefined = Object.new
  expected_result = undefined
  @ccd_field_path = ccd_field_path
  match do |presenter|
    result = presenter.present(build(*@from_args).as_json, event_token: 'event token')
    nodes = JsonPath.new("$..data.#{ccd_field_path}").on(result)
    @result = nodes.first
    @key_present = nodes.present?
    if expected_result == undefined
      @key_present
    else
      @key_present && @result == expected_result
    end
  end

  failure_message do
    if @key_present
      "expected the presenter to present \"#{expected_result}\" in \"data.#{ccd_field_path}\" but \"#{@result}\" was presented"
    else
      "expected the presenter to present \"data.#{ccd_field_path}\" but that key was not present in the data"
    end
  end

  failure_message_when_negated do
    if expected_result != undefined
      "expected the presenter not to present \"#{expected_result}\" in \"data.#{ccd_field_path}\" but it did"
    else
      "expected the presenter not to present \"data.#{ccd_field_path}\" but it did"
    end
  end

  chain :using do |*args|
    @from_args = args
  end
  chain :with_result do |new_expected_result|
    expected_result = new_expected_result
  end
end
