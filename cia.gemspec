name = "cia"
require "./lib/#{name}/version"

Gem::Specification.new name, CIA::VERSION do |s|
  s.summary = "Audit model events like update/create/delete + attribute changes + group them by transaction, in normalized table layout for easy query access."
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib Readme.md`.split("\n")
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.7.0'

  s.add_dependency 'activerecord', '>= 4.2'
  s.add_dependency 'activesupport', '>= 4.2'
  s.add_development_dependency 'bump'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 3.4'
  s.add_development_dependency 'sqlite3', '~> 1.6.0' # 1.7 breaks ruby 2.7
end
