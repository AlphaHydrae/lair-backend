require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lair
  class Application < Rails::Application
    VERSION = File.read Rails.root.join('VERSION')
    API_VERSION = 1

    def version
      VERSION
    end

    def api_version
      API_VERSION
    end

    def service_config service
      # TODO: cache
      config = config_for :services
      raise "Missing configuration for service #{service}" unless config[service.to_s]
      config[service.to_s].with_indifferent_access
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # For not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
    config.assets.paths << Rails.root.join('vendor', 'assets', 'fonts')
    config.assets.precompile << /\.(?:svg|eot|woff|woff2|ttf|otf|png|gif)\z/

    %w(api jobs search serializers).each do |dir|
      config.paths.add File.join('app', dir), glob: File.join('**', '*.rb')
      config.autoload_paths += Dir[Rails.root.join('app', dir, '*')]
    end
  end
end
