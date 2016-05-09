source 'https://rubygems.org'

gem 'rails', '4.2.1'

# Database
gem 'pg'
gem 'activerecord-import'
gem 'ar_after_transaction'

# Memory Database
gem 'redis'
gem 'hiredis'
gem 'redis-namespace'

# Models
gem 'strip_attributes'
gem 'simple_states'
gem 'role_model'
gem 'wisper'

# Background Jobs
gem 'resque'
gem 'resque-scheduler'
gem 'resque-workers-lock'
gem 'resque-waiting-room'

# Templates & Assets
gem 'slim-rails'
gem 'less-rails'
gem 'stylus'
gem 'therubyracer'
gem 'uglifier', '>= 1.3.0'
gem 'ngannotate-rails'
gem 'autoprefixer-rails'
gem 'redcarpet'

# Standards
gem 'iso'
gem 'library_stdnums'

# API & Services
gem 'jwt'
gem 'grape'
gem 'jbuilder'
gem 'httparty'
gem 'google-api-client'
gem 'pundit'
gem 'aws-sdk', '~> 2'
gem 'dragonfly'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use Rails Html Sanitizer for HTML sanitization
gem 'rails-html-sanitizer', '~> 1.0'

gem 'paint'

group :production do
  gem 'unicorn-rails'
end

group :development, :test do

  # Solve http://mislav.net/2013/07/ruby-openssl/
  gem 'certified'

  gem 'capistrano'
  gem 'handlebars'
  gem 'dotenv-rails'

  gem 'thin'

  # Call 'debugger' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exceptions page and /console in development
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'rspec-rails', '~> 3.0'
  gem 'rspec-collection_matchers'
  gem 'shoulda-matchers'
  gem 'factory_girl_rails'
  gem 'deep_merge', require: 'deep_merge/rails_compat'

  gem 'quiet_assets'

  gem 'capybara'
  gem 'selenium-webdriver'

  gem 'rake-version'

  gem 'guard'
  gem 'guard-rake'
  gem 'guard-process'

  gem 'resque-pool'
end
