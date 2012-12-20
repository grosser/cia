require 'appraisal'
require 'bundler/gem_tasks'
require 'bump/tasks'

task :default do
  sh "bundle exec rake appraisal:install && bundle exec rake appraisal spec"
end

task :spec do
  sh "rspec spec/"
end
