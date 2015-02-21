# This initializer MUST run after the redis initializer.
Resque.redis = $redis

if Rails.env == 'development'
  Resque.logger = Logger.new STDOUT
  Resque.logger.level = Logger::DEBUG
end
