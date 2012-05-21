$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
name = "cia"
require "#{name}/version"

Gem::Specification.new name, CIA::VERSION do |s|
  s.summary = "Audit model events like update/create/delete + attribute changes + group them by transaction, in normalized table layout for easy query access."
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.license = 'MIT'
end
