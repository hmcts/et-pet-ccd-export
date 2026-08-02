
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "et_ccd_export/version"

Gem::Specification.new do |spec|
  spec.name          = "et_ccd_export"
  spec.version       = EtCcdExport::Version
  spec.authors       = ["Gary Taylor"]
  spec.email         = ["gary.taylor@hmcts.net"]

  spec.summary       = %q{Interim gem for ccd exports for employment tribunals}
  spec.description   = %q{Interim gem for ccd exports for employment tribunals}
  spec.homepage      = "https://github.com/hmcts/et_ccd_export"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]
end
