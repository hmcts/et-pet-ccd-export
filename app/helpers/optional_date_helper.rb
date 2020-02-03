module OptionalDateHelper
  def optional_date(date, config: Rails.application.config)
    return nil if date.nil?
    
    Time.zone.parse(date).in_time_zone(config.ccd_time_zone).strftime('%Y-%m-%d')
  end
end
