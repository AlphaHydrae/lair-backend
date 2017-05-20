if Rails.env != 'production'
  require 'dotenv'
  require 'fileutils'
  require 'highline'
  require 'shellwords'
  require 'sshkit'
  require 'sshkit/dsl'
  require 'tmpdir'

  include SSHKit::DSL
  SSHKit.config.output_verbosity = :debug if ENV['DEBUG']
end

LAIR_DEPLOY_DATA = {}

def set key, value = nil, &block
  LAIR_DEPLOY_DATA[key] = value.nil? && block ? block : value
end

def fetch key
  if !LAIR_DEPLOY_DATA.key?(key)
    raise "Unknown deploy data key #{key.inspect}"
  elsif LAIR_DEPLOY_DATA[key].respond_to?(:call)
    LAIR_DEPLOY_DATA[key] = LAIR_DEPLOY_DATA[key].call
  else
    LAIR_DEPLOY_DATA[key]
  end
end

set :local_tmp, ->{ Dir.mktmpdir }

def deploy_task *args, &block
  task *args do |*task_args|
    on fetch(:host) do
      begin
        instance_exec *task_args, &block
      ensure
        tmp_dir = LAIR_DEPLOY_DATA[:local_tmp]
        if !tmp_dir.respond_to?(:call)
          puts "Removing temporary directory #{tmp_dir}" if ENV['DEBUG']
          FileUtils.remove_entry_secure tmp_dir
          set :local_tmp, ->{ Dir.mktmpdir }
        end
      end
    end
  end
end

LAIR_DEPLOY_UUIDS = []

def generate_uuid
  next while LAIR_DEPLOY_UUIDS.include?(uuid = SecureRandom.uuid)
  LAIR_DEPLOY_UUIDS << uuid
  uuid
end

def generate_handlebars_template path:, template_options: {}

  handlebars = Handlebars::Context.new
  template = handlebars.compile File.read(path)
  compiled = template.call template_options

  tmp_file = File.join fetch(:local_tmp), generate_uuid.to_s
  File.open(tmp_file, 'w'){ |f| f.write compiled }
  tmp_file
end

def vagrant_ssh_config
  FileUtils.mkdir_p 'tmp'

  config_file = File.join 'tmp', "vagrant-ssh-config-#{Time.now.strftime('%Y-%m-%d')}"
  unless File.exist? config_file
    File.open(config_file, 'w'){ |f| f.write `vagrant ssh-config`.strip }
  end

  Dir.glob(File.join('tmp', 'vagrant-ssh-config-*')).reject{ |f| f == config_file }.each do |file|
    FileUtils.remove_entry_secure file
  end

  File.read(config_file).split(/\n+/).reject(&:empty?).inject({}) do |memo,line|
    key, value = line.strip.split(/\s+/, 2)
    memo[key] = value
    memo
  end
end
