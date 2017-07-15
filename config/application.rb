require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lair
  class Application < Rails::Application
    VERSION = File.read Rails.root.join('VERSION')
    API_VERSION = 1

    attr_reader :destroy_user

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

    def current_event
      @current_event
    end

    def with_current_event event
      previous_current_event = @current_event
      @current_event = event
      begin
        yield if block_given?
      ensure
        @current_event = previous_current_event
      end
    end

    def destroy record, current_user, options = {}
      hard = options.fetch :hard, false

      record.class.transaction do
        @destroy_user = current_user

        observer = DeletionObserver.new
        Wisper.subscribe observer do
          yield if block_given?

          if hard
            record.class.where(id: record.id).delete_all
          else
            record.cache_previous_version
            record.deleter = current_user
            record.destroy
          end
        end

        @destroy_user = nil

        if hard
          raise "#{observer.events.length} events were stored" if observer.events.any?
        else
          event = Event.where(trackable_type: record.class.name, trackable_id: record.id, event_type: 'delete').first
          side_effects = observer.events.select{ |e| e.id != event.id }
          Event.where(id: side_effects.collect(&:id)).update_all cause_id: event.id if side_effects.any?
        end
      end
    end

    class DeletionObserver
      attr_reader :events

      def initialize
        @events = []
      end

      def event_created event
        @events << event
      end
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

    config.assets.paths << Rails.root.join('client')
    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
    config.assets.paths << Rails.root.join('vendor', 'assets', 'fonts')
    config.assets.precompile << /\.(?:svg|eot|woff|woff2|ttf|otf|png|gif)\z/

    %w(api jobs scrapers search serializers).each do |dir|
      config.paths.add File.join('app', dir), glob: File.join('**', '*.rb')
      config.autoload_paths += Dir[Rails.root.join('app', dir, '*')]
    end
  end
end
