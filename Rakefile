require 'bundler/setup'
require 'appraisal'
require 'bundler/gem_tasks'
require 'bump/tasks'
require 'wwtd/tasks'

task :default => ["appraisal:gemfiles", :wwtd]

task :spec do
  sh "rspec spec/"
end
