source 'https://rubygems.org'

gem 'rails', '4.2.0.beta1'
gem 'dotenv-rails', groups: [:development, :test]

gem 'pg'

gem 'haml-rails'
gem 'less-rails'
gem 'therubyracer'
gem 'uglifier', '>= 1.3.0'

#gem 'devise'
# https://github.com/plataformatec/devise/pull/3153
gem 'devise', git: 'https://github.com/plataformatec/devise.git', branch: 'lm-rails-4-2'
gem 'omniauth-google-oauth2'
gem 'jwt'

gem 'grape'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use Rails Html Sanitizer for HTML sanitization
gem 'rails-html-sanitizer', '~> 1.0'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do

  # Call 'debugger' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exceptions page and /console in development
  gem 'web-console', '~> 2.0.0.beta2'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'rspec-rails', '~> 3.0.0'
  gem 'shoulda-matchers'
  gem 'factory_girl_rails'

  gem 'quiet_assets'

  gem 'capybara'
  gem 'selenium-webdriver'

  gem 'rake-version'
end
