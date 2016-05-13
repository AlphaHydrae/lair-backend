# This initializer MUST run after the redis initializer.
Resque.redis = $redis_db
Resque.redis.namespace = 'lair:resque'

if ENV['LAIR_LOG_TO_STDOUT']
  Resque.logger = Logger.new STDOUT
else
  Resque.logger = Logger.new Rails.root.join('log', "resque.#{Rails.env}.log")
end

Resque.logger.level = Rails.env == 'production' ? Logger::WARN : Logger::INFO
