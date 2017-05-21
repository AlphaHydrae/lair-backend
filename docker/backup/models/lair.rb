REQUIRED_ENV = Hash.new do |hash,key|
  var_name = key.to_s.upcase
  raise "$#{var_name} must be set" if !ENV[var_name] || ENV[var_name].strip.empty?
  ENV[var_name]
end

Model.new(:lair, 'Lair database backup') do

  database PostgreSQL do |db|
    db.name = REQUIRED_ENV[:LAIR_DATABASE_NAME]
    db.username = REQUIRED_ENV[:LAIR_DATABASE_USERNAME]
    db.password = REQUIRED_ENV[:LAIR_DATABASE_PASSWORD]
    db.host = REQUIRED_ENV[:LAIR_DATABASE_HOST]
    db.port = 5432
  end

  compress_with Gzip

  encrypt_with GPG do |encryption|
    encryption.keys = {}
    encryption.keys[REQUIRED_ENV[:LAIR_BACKUP_GPG_KEY_NAME]] = File.read(REQUIRED_ENV[:LAIR_BACKUP_GPG_KEY_PATH])
    encryption.recipients = REQUIRED_ENV[:LAIR_BACKUP_GPG_KEY_NAME]
  end

  store_with S3 do |s3|
    s3.access_key_id = REQUIRED_ENV[:LAIR_BACKUP_S3_ACCESS_KEY_ID]
    s3.secret_access_key = REQUIRED_ENV[:LAIR_BACKUP_S3_SECRET_ACCESS_KEY]
    s3.region = REQUIRED_ENV[:LAIR_BACKUP_S3_REGION]
    s3.bucket = REQUIRED_ENV[:LAIR_BACKUP_S3_BUCKET]
    s3.path = REQUIRED_ENV[:LAIR_BACKUP_S3_PATH]
    s3.chunk_size = 5
  end

  store_with Local do |local|
    local.path = '/var/lib/backup/local'
    local.keep = 12
  end

  notify_by Slack do |slack|
    slack.on_success = true
    slack.on_warning = true
    slack.on_failure = true
    slack.webhook_url = REQUIRED_ENV[:LAIR_SLACK_WEBHOOK_URL]
    slack.username = 'Lair'
    slack.icon_emoji = ':floppy_disk:'
  end
end
