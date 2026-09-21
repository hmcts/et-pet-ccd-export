# Temporary to enable all features
class FeatureFlag
  def self.value_for(*)
    true
  end
end
