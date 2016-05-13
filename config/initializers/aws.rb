Aws.config.update({
  region: ENV['LAIR_AWS_REGION'],
  credentials: Aws::Credentials.new(ENV['LAIR_AWS_ACCESS_KEY_ID'], ENV['LAIR_AWS_SECRET_ACCESS_KEY']),
})
