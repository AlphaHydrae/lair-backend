source 'https://rubygems.org'

gem 'rails', '4.2.0'
gem 'dotenv-rails', groups: %i(development test)

# Database
gem 'pg'
gem 'strip_attributes'

# Memory Database
gem 'redis'
gem 'hiredis'
gem 'redis-namespace'

# Background Jobs
gem 'resque'
gem 'resque-scheduler'

# Templates & Assets
gem 'slim-rails'
gem 'less-rails'
gem 'stylus'
gem 'therubyracer'
gem 'uglifier', '>= 1.3.0'

# Standards
gem 'iso'
gem 'isbn'

# API & Services
gem 'jwt'
gem 'grape'
gem 'jbuilder'
gem 'httparty'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use Rails Html Sanitizer for HTML sanitization
gem 'rails-html-sanitizer', '~> 1.0'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do

  gem 'thin'

  # Call 'debugger' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exceptions page and /console in development
  gem 'web-console', '~> 2.0.0.beta2'

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
end
