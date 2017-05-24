require File.join(File.dirname(__FILE__), '..', 'deploy.rb')

# CONFIGURATION

set :envs, ->{ %i(vagrant production) }
set :env, ->{ ENV['LAIR_DEPLOY_ENV'] }

set :env_vars do
  ENV.select{ |k,v| k.index('LAIR_') == 0 || k == 'RAILS_ENV' }
end

set :local_root, ->{ File.join File.dirname(__FILE__), '..', '..' }

set :root, ->{ ENV['LAIR_DEPLOY_ROOT'] || '/var/lib/lair/backend' }
set :repo, ->{ File.join fetch(:root), 'repo' }
set :checkout, ->{ File.join fetch(:root), 'checkout' }
set :build, ->{ ENV['LAIR_DEPLOY_BUILD'] || fetch(:checkout) }
set :tmp, ->{ File.join fetch(:root), 'tmp' }
set :network, ->{ ENV['LAIR_DEPLOY_NETWORK'] }

set :app_containers, ->{ ENV['LAIR_DOCKER_APP_CONTAINERS'].try(:to_i) || 1 }
set :job_containers, ->{ ENV['LAIR_DOCKER_JOB_CONTAINERS'].try(:to_i) || 1 }

set :repo_url, ->{ ENV['LAIR_REPO_URL'] }
set :branch, ->{ ENV['LAIR_REPO_BRANCH'] || 'master' }

set :host do
  host = ENV['LAIR_DEPLOY_SSH_HOST']
  host = "#{ENV['LAIR_DEPLOY_SSH_USER']}@#{host}" if ENV['LAIR_DEPLOY_SSH_USER']
  host = "#{host}:#{ENV['LAIR_DEPLOY_SSH_PORT']}" if ENV['LAIR_DEPLOY_SSH_PORT']
  host
end

# TASKS

task deploy: %i(deploy:log:deploy_start deploy:app:build deploy:app:stop deploy:job:stop deploy:db:migrate deploy:app:run deploy:job:run deploy:scale deploy:log:deploy_end)

fetch(:envs).each do |env|
  task env do
    ENV['LAIR_DEPLOY_ENV'] = env.to_s
  end
end

namespace :deploy do

  task hot: %i(deploy:app:ensure_running deploy:log:deploy_start deploy:app:build deploy:app:run deploy:job:run deploy:scale deploy:log:deploy_end)

  task cold: %i(deploy:cold:ensure_not_run deploy:log:deploy_start deploy:app:build deploy:db:load_schema deploy:app:run deploy:job:run deploy:scale deploy:log:deploy_end)

  task dump: %i(deploy:cold:ensure_not_run deploy:log:deploy_start deploy:app:build deploy:db:load_dump deploy:app:run deploy:job:run deploy:scale deploy:log:deploy_end)

  namespace :cold do
    deploy_task ensure_not_run: %i(deploy:env) do
      raise "Containers have already been run" if docker_container_id
    end
  end

  deploy_task :scale, %i(apps jobs) => %i(deploy:app:ensure_running) do |t,args|
    docker_compose_scale services: {
      app: args[:apps] || fetch(:app_containers),
      job: args[:jobs] || fetch(:job_containers)
    }
  end

  namespace :app do
    deploy_task run: %i(deploy:app:ensure_build deploy:config) do
      docker_compose_up :app, build: true, recreate: true
    end

    deploy_task stop: %i(deploy:config) do
      docker_compose_stop :app
    end

    deploy_task rm: %i(deploy:app:stop) do
      docker_compose_rm :app
    end

    deploy_task build: %i(deploy:repo:checkout) do
      docker_build path: fetch(:build), name: 'alphahydrae/lair'
    end

    deploy_task ensure_build: %i(deploy:env) do
      ensure_docker_image_built 'alphahydrae/lair'
    end

    deploy_task ensure_running: %i(deploy:env) do
      raise "No app containers are running" unless docker_container_id(compose_service: 'app', status: 'running')
    end
  end

  namespace :job do
    deploy_task run: %i(deploy:app:ensure_build deploy:config) do
      docker_compose_up :job, build: true, recreate: true
    end

    deploy_task stop: %i(deploy:config) do
      docker_compose_stop :job
    end

    deploy_task rm: %i(deploy:job:stop) do
      docker_compose_rm :job
    end
  end

  namespace :db do
    deploy_task run: %i(deploy:config deploy:cache:run) do

      env = ENV.select{ |k,v| !!k.match(/^LAIR_(?:DATABASE|POSTGRES)_/) }
      env['POSTGRES_PASSWORD'] = env.delete 'LAIR_POSTGRES_PASSWORD'

      with env do
        docker_compose_up :db, build: true
      end
    end

    deploy_task migrate: %i(deploy:app:ensure_build deploy:db:run) do
      docker_compose_run service: :task, command: 'db:migrate'
    end

    deploy_task load_schema: %i(deploy:app:ensure_build deploy:db:run) do
      docker_compose_run service: :task, command: [ 'db:schema:load', 'db:seed' ]
    end

    deploy_task load_dump: %i(deploy:repo:checkout deploy:db:run) do

      volumes = {
        "#{fetch(:checkout)}/docker/db/load-dump" => '/usr/local/bin/load-dump',
        "#{fetch(:root)}/dump.sql" => '/tmp/dump.sql'
      }

      docker_run image: 'postgres:9.6', entrypoint: '/usr/local/bin/load-dump', command: '/tmp/dump.sql', volumes: volumes
    end
  end

  namespace :cache do
    deploy_task run: %i(deploy:config) do
      docker_compose_up :cache
    end
  end

  deploy_task backup: %i(deploy:backup:build deploy:config) do
    docker_compose_run service: 'backup', entrypoint: '/usr/local/bin/backup', env: { LOG_TO_STDOUT: '1' }
  end

  namespace :backup do
    deploy_task build: %i(deploy:config deploy:repo:checkout) do
      docker_compose_build service: :backup
    end

    deploy_task start: %i(deploy:config deploy:repo:checkout) do
      docker_compose_up :backup, build: true, recreate: true
    end

    deploy_task stop: %i(deploy:config) do
      docker_compose_stop :backup
      docker_compose_rm :backup
    end

    deploy_task ensure_build: %i(deploy:env) do
      ensure_docker_image_built 'alphahydrae/lair-backup'
    end
  end

  deploy_task ps: %i(deploy:env) do

    containers = docker_ps.split /\n+/

    puts

    if containers.length <= 1
      puts "No containers are running"
    else
      containers.each do |container|
        puts container
      end
    end

    puts
  end

  namespace :repo do
    deploy_task update: %i(deploy:env) do
      repo_dir = fetch :repo
      if test "[ ! -d #{repo_dir} ]"
        within fetch(:root) do
          execute :git, 'clone', '--mirror', fetch(:repo_url), 'repo'
        end
      else
        within repo_dir do
          execute :git, 'fetch', '--all'
          execute :git, 'fetch', 'origin', "'+refs/heads/*:refs/heads/*'"
        end
      end
    end

    deploy_task checkout: %i(deploy:repo:update) do

      archive_file = File.join fetch(:tmp), 'checkout.tar'

      execute :rm, '-fr', fetch(:checkout)
      execute :mkdir, '-p', fetch(:checkout), fetch(:tmp)

      within fetch(:repo) do
        execute :git, 'archive', '--output', archive_file, fetch(:branch)
      end

      within fetch(:tmp) do
        execute :tar, '-C', fetch(:checkout), '-x', '--file', archive_file
      end
    end

    deploy_task ensure_checkout: %i(deploy:env) do
      raise "Repository has not been checked out" unless test "[ -d #{fetch(:checkout)} ]"
    end
  end

  deploy_task config: %i(deploy:setup) do

    backup_key_file = local_file('backup.key')
    docker_compose_file = generate_handlebars_template path: local_file('docker', 'docker-compose.yml'), template_options: fetch(:env_vars)
    env_file = generate_handlebars_template path: local_file('docker', 'env.hbs'), template_options: fetch(:env_vars)
    nginx_conf_file = generate_handlebars_template path: local_file('docker', 'nginx', 'lair.serf.conf.hbs'), template_options: fetch(:env_vars)

    upload! backup_key_file, remote_file('backup.key')
    upload! docker_compose_file, remote_file('docker-compose.yml')
    upload! env_file, remote_file('.env')
    upload! nginx_conf_file, '/etc/nginx-serf/sites/lair.conf.hbs'
  end

  deploy_task implode: %i(deploy:env) do

    env = fetch :env
    cli = HighLine.new

    puts
    answer = cli.ask %/Are you #{Paint["ABSOLUTELY 100% POSITIVE", :bold, :red]} you want to #{Paint["remove all containers and erase all data", :underline]}? You are in the #{Paint[env.to_s.upcase, :magenta]} environment; type #{Paint["yes", :bold]} to proceed: /
    raise 'Task aborted by user' unless answer.to_s.match(/^yes$/i)
    puts

    containers = docker_ps

    puts
    puts "The following containers will be stopped and removed:"
    puts

    containers.split(/\n+/).each do |container|
      puts container
    end

    volume_names = docker_volume_ls

    puts
    puts "The following volumes will be removed permanently:"

    volume_names.each do |name|
      puts "- #{name}"
    end

    files_to_delete = %w(checkout docker-compose.yml .env repo tmp).collect{ |dir| File.join fetch(:root), dir }
    files_to_delete << '/etc/nginx-serf/sites/lair.conf.hbs'

    puts
    puts "The following files will be deleted:"
    files_to_delete.each{ |f| puts "- #{f}" }

    unless env == 'vagrant'
      puts
      puts %/#{Paint["ARE YOU KIDDING?!", :bold, :white, :red, :blink]}; this is the #{Paint[env.to_s.upcase, :magenta, :bold, :underline, :blink]} environment!/
    end

    puts

    answer = cli.ask %/Type #{Paint["implode", :bold]} to proceed: /
    raise 'Task aborted by user' unless answer.match(/^implode$/i)
    puts

    container_ids = containers.split(/\n+/).drop(1).collect{ |c| c.strip.sub(/ .*/, '') }
    container_ids.each do |id|
      execute :docker, 'rm', '-f', id
    end

    volume_names.each do |name|
      docker_volume_rm name
    end

    execute :rm, '-fr', *files_to_delete
  end

  deploy_task setup: %i(deploy:env) do
    execute :mkdir, '-p', File.join(fetch(:root), 'tmp')
  end

  deploy_task versions: %i(deploy:env) do
    puts(JSON.pretty_generate(all_versions))
  end

  namespace :log do
    deploy_task deploy_start: %i(deploy:setup) do
      set :deploy_start, Time.now
      execute :echo, Shellwords.shellescape("\n[#{Time.now}] Starting deployment"), '>>', remote_file('deploy.log')
    end

    deploy_task deploy_end: %i(deploy:setup) do
      duration = Time.now.to_f - fetch(:deploy_start).to_f
      execute :echo, Shellwords.shellescape("[#{Time.now}] Versions: " + JSON.dump(all_versions)), '>>', remote_file('deploy.log')
      execute :echo, Shellwords.shellescape("[#{Time.now}] Deployment finished in #{duration.round(3)}s"), '>>', remote_file('deploy.log')
    end
  end

  task :env do
    envs = fetch(:envs).collect &:to_s
    deploy_env = ENV['LAIR_DEPLOY_ENV']
    raise "$LAIR_DEPLOY_ENV must be set; use `rake <env> <task>` with env being one of #{envs.join(', ')}" unless deploy_env
    raise "Unsupported deployment environment #{deploy_env}; supported environments are #{envs.join(', ')}" unless envs.include? deploy_env

    ENV.reject!{ |k,v| k.index('LAIR_') == 0 || k == 'RAILS_ENV' }

    Dotenv.load! ".env.#{deploy_env}"
    ENV['LAIR_DEPLOY_ENV'] = deploy_env
  end

  deploy_task uname: %i(deploy:env) do
    puts capture(:uname, '-a')
  end
end

def local_file *args
  file = File.join *args.unshift(fetch(:local_root))
  raise "File #{file} is required" unless File.exist? file
  file
end

def remote_file *args
  File.join *args.unshift(fetch(:root))
end

def all_versions

  app_container_id = docker_container_id compose_service: :app
  app_image_id = app_container_id ? docker_inspect(app_container_id, format: '{{.Image}}') : nil

  db_container_id = docker_container_id compose_service: :db
  db_image_id = db_container_id ? docker_inspect(db_container_id, format: '{{.Image}}') : nil

  cache_container_id = docker_container_id compose_service: :cache
  cache_image_id = cache_container_id ? docker_inspect(cache_container_id, format: '{{.Image}}') : nil

  docker_version = capture :docker, '--version'
  docker_compose_version = capture :'docker-compose', '--version'

  # TODO: add git version

  commit = if test "[ -d #{fetch(:repo)} ]"
    within fetch(:repo) do
      capture :git, 'rev-parse', '--verify', 'HEAD'
    end
  end

  db_version = if db_container_id && test("[ -f #{remote_file('docker-compose.yml')} ]")
    output = docker_compose_run service: :task, command: 'db:version'
    output.strip.split(/\n+/).last.sub(/^Current version: /, '')
  end

  {
    appImage: app_image_id,
    cacheImage: cache_image_id,
    commit: commit,
    db: db_version,
    dbImage: db_image_id,
    docker: docker_version.strip,
    dockerCompose: docker_compose_version.strip
  }
end

def docker_compose_build service:, build_args: {}

  args = []
  args << service.to_s

  build_args.each do |key,value|
    args << '--build-arg' << "#{key}=#{value}"
  end

  docker_compose :build, *args
end

def docker_compose_up service, build: false, recreate: false

  up_args = []
  up_args << '--build' if build
  up_args << '--no-recreate' unless recreate
  up_args << '-d' << service.to_s

  docker_compose :up, '--no-deps', *up_args
end

def docker_compose_stop service
  docker_compose :stop, service.to_s
end

def docker_compose_rm service
  docker_compose :rm, '-f', service.to_s
end

def docker_compose_run service:, entrypoint: nil, command: [], env: {}, no_deps: true, rm: true

  args = []
  args << '--no-deps' if no_deps
  args << '--rm' if rm
  args << '--entrypoint' << entrypoint if entrypoint

  env.each do |key,value|
    args << '-e' << "#{key}=#{value}"
  end

  args << service.to_s

  command = [ command ] if command && !command.kind_of?(Array)
  args += command

  docker_compose :run, *args
end

def docker_compose_scale services:

  scale_args = services.inject([]) do |memo,(service,number)|
    memo << "#{service}=#{number}"
  end

  docker_compose :scale, *scale_args
end

def docker_compose *args
  within fetch(:root) do
    capture *([ :'docker-compose', '-p', 'lair' ] + args).collect(&:to_s)
  end
end

def docker_build path:, name:
  within path.to_s do
    execute :docker, 'build', '-t', name.to_s, '.'
  end
end

def docker_run image:, entrypoint: nil, command: [], env: {}, env_file: true, network: true, rm: true, volumes: {}

  args = []
  args << '--rm' if rm
  args << '--env-file' << '.env' if env_file
  args << '--entrypoint' << entrypoint if entrypoint

  env.each do |key,value|
    args << '--env' << "#{key}=#{value}"
  end

  if network == true
    args << '--net' << fetch(:network)
  elsif network
    args << '--net' << network.to_s
  end

  volumes.each do |key,value|
    args << '--volume' << "#{key}:#{value}"
  end

  args << image.to_s

  command = [ command ] if command && !command.kind_of?(Array)
  args += command

  within fetch(:root) do
    capture :docker, 'run', *args
  end
end

def docker_ps compose_project: 'lair', compose_service: nil, quiet: false, latest: false, status: nil

  ps_args = []
  ps_args << '--quiet' if quiet
  ps_args << '--latest' if latest
  ps_args << '--filter' << "label=com.docker.compose.project=#{compose_project}" if compose_project
  ps_args << '--filter' << "label=com.docker.compose.service=#{compose_service}" if compose_service
  ps_args << '--filter' << "status=#{status}" if status

  output = capture :docker, 'ps', *ps_args
  output.strip
end

def docker_container_id compose_project: 'lair', compose_service: nil, status: nil
  id = docker_ps compose_project: compose_project, compose_service: compose_service, quiet: true, latest: true, status: status
  id.empty? ? nil : id
end

def docker_inspect id, format: nil

  inspect_args = []
  inspect_args << '--format' << format.to_s if format
  inspect_args << id.to_s

  output = capture :docker, 'inspect', *inspect_args
  output.strip
end

def docker_volume_ls compose_project: 'lair'

  ls_args = []
  ls_args << '--quiet'
  ls_args << '--filter' << "label=com.docker.compose.project=#{compose_project}" if compose_project

  output = capture :docker, 'volume', 'ls', *ls_args
  lines = output.strip.split /\n+/
  lines.empty? ? lines : lines.slice(1, lines.length - 1)
end

def docker_volume_rm name
  execute :docker, 'volume', 'rm', name.to_s
end

def ensure_docker_image_built name
  image_id = capture :docker, 'images', '-q', name.to_s
  raise "Docker image #{name} not found" if image_id.strip.empty?
end
