# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

if Rails.env != 'production'
  require 'rake-version'
  RakeVersion::Tasks.new do |v|
    v.copy 'bower.json'
    v.copy 'package.json'
    v.copy 'spec/angular/unit/version.spec.js'
  end
end
