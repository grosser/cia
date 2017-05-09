name = "cia"
require "./lib/#{name}/version"

Gem::Specification.new name, CIA::VERSION do |s|
  s.summary = "Audit model events like update/create/delete + attribute changes + group them by transaction, in normalized table layout for easy query access."
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib Readme.md`.split("\n")
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.2.0'
  s.add_runtime_dependency "json"
  s.add_development_dependency 'bump'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 3.4'
  s.add_development_dependency 'wwtd'
  s.add_development_dependency 'activerecord'
  s.add_development_dependency 'sqlite3'
end
