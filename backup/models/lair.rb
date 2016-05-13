# encoding: utf-8

##
# Backup Generated: lair
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t lair [-c <path_to_configuration_file>]
#
# For more information about Backup's components, see the documentation at:
# http://backup.github.io/backup
#
Model.new(:lair, 'Lair database backup') do

  database PostgreSQL do |db|
    db.name               = ENV['LAIR_DATABASE_NAME']
    db.username           = ENV['LAIR_DATABASE_USERNAME']
    db.password           = ENV['LAIR_DATABASE_PASSWORD']
    db.host               = ENV['LAIR_DATABASE_HOST']
    db.port               = 5432
  end

  compress_with Gzip

  encrypt_with GPG do |encryption|
    encryption.keys = {}
    encryption.keys[ENV['LAIR_BACKUP_GPG_KEY_NAME']] = File.read(ENV['LAIR_BACKUP_GPG_KEY_PATH'])
    encryption.recipients = ENV['LAIR_BACKUP_GPG_KEY_NAME']
  end

  store_with S3 do |s3|
    s3.access_key_id = ENV['LAIR_BACKUP_S3_ACCESS_KEY_ID']
    s3.secret_access_key = ENV['LAIR_BACKUP_S3_SECRET_ACCESS_KEY']
    s3.region = ENV['LAIR_BACKUP_S3_REGION']
    s3.bucket = ENV['LAIR_BACKUP_S3_BUCKET']
    s3.path = 'backup'
    s3.chunk_size = 5
  end

  store_with Local do |local|
    local.path = '/var/lib/lair/backup/local'
    local.keep = 12
  end
end
