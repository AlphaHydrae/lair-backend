config = Rails.application.config_for :redis
host, port, db = config.split /:/

options = { host: host, port: port, db: db.to_i, driver: :hiredis }
options[:logger] = Rails.logger

$redis = Redis::Namespace.new 'lair', redis: Redis.new(options)
