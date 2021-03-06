config = Rails.application.config_for :redis

host, port, db = config.split /:/
port ||= 6379
db ||= 0

options = { host: host, port: port.to_i, db: db.to_i, driver: :hiredis }
#options[:logger] = Rails.logger

$redis_db = Redis.new options
$redis = Redis::Namespace.new 'lair', redis: $redis_db
