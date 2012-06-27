require 'appraisal'
require 'bundler/gem_tasks'

task :fast_force_install_appraisals => "appraisal:gemfiles" do
  Appraisal::File.each do |appraisal|
    gemfile = appraisal.gemfile_path
    options = "--gemfile='#{gemfile}'"
    sh "bundle check #{options} || bundle install #{options} || (rm #{gemfile}.lock && bundle install #{options})"
  end
end

task :default => :fast_force_install_appraisals do
  exec "#{$0} appraisal spec"
end

task :spec do
  sh "rspec spec/"
end

# extracted from https://github.com/grosser/project_template
rule /^version:bump:.*/ do |t|
  sh "git status | grep 'nothing to commit'" # ensure we are not dirty
  index = ['major', 'minor','patch'].index(t.name.split(':').last)
  file = 'lib/cia/version.rb'

  version_file = File.read(file)
  old_version, *version_parts = version_file.match(/(\d+)\.(\d+)\.(\d+)/).to_a
  version_parts[index] = version_parts[index].to_i + 1
  version_parts[2] = 0 if index < 2 # remove patch for minor
  version_parts[1] = 0 if index < 1 # remove minor for major
  new_version = version_parts * '.'
  File.open(file,'w'){|f| f.write(version_file.sub(old_version, new_version)) }

  sh "bundle && git add #{file} Gemfile.lock && git commit -m 'bump version to #{new_version}'"
end
