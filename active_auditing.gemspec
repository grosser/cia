$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
name = "active_auditing"
require "#{name}/version"

Gem::Specification.new name, ActiveAuditing::VERSION do |s|
  s.summary = "Audit model events like update/create/delete via an observer + attribute changes + all events grouped by transaction"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.license = 'MIT'
end
