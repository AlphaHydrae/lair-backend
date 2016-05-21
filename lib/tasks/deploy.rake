require File.join(File.dirname(__FILE__), '..', 'deploy.rb')

# CONFIGURATION

set :envs, ->{ %i(vagrant production) }
set :env, ->{ ENV['LAIR_DEPLOY_ENV'] }

set :env_vars do
  ENV.select{ |k,v| k.index('LAIR_') == 0 || k == 'RAILS_ENV' }
end

set :local_root, ->{ File.join File.dirname(__FILE__), '..', '..' }
set :local_docker, ->{ File.join fetch(:local_root), 'docker' }

set :root, ->{ ENV['LAIR_DEPLOY_ROOT'] || '/var/lib/lair' }
set :repo, ->{ File.join fetch(:root), 'repo' }
set :checkout, ->{ File.join fetch(:root), 'checkout' }
set :tmp, ->{ File.join fetch(:root), 'tmp' }

set :repo_url, ->{ ENV['LAIR_REPO_URL'] }
set :branch, ->{ ENV['LAIR_REPO_BRANCH'] || 'master' }

set :host do
  if ENV['LAIR_DEPLOY_SSH_HOST']
    host = ENV['LAIR_DEPLOY_SSH_HOST']
    host = "#{ENV['LAIR_DEPLOY_SSH_USER']}@#{host}" if ENV['LAIR_DEPLOY_SSH_USER']
    host = "#{host}:#{ENV['LAIR_DEPLOY_SSH_PORT']}" if ENV['LAIR_DEPLOY_SSH_PORT']
    host
  else
    'root@127.0.0.1:2222'
  end
end

# TASKS

task deploy: %i(deploy:log:deploy_start deploy:app:build deploy:serf:run deploy:app:stop deploy:job:stop deploy:db:migrate deploy:assets:compile deploy:app:run deploy:job:run deploy:scale deploy:log:deploy_end)

fetch(:envs).each do |env|
  task env do
    ENV['LAIR_DEPLOY_ENV'] = env.to_s
  end
end

namespace :deploy do

  task hot: %i(deploy:app:ensure_running deploy:log:deploy_start deploy:app:build deploy:assets:compile deploy:app:run deploy:job:run deploy:scale deploy:log:deploy_end)

  task cold: %i(deploy:cold:ensure_not_run deploy:log:deploy_start deploy:app:build deploy:serf:run deploy:db:load_schema deploy:assets:compile deploy:app:run deploy:job:run deploy:scale deploy:log:deploy_end)

  namespace :cold do
    deploy_task ensure_not_run: %i(deploy:env) do
      raise "Containers have already been run" if docker_container_id
    end
  end

  deploy_task :scale do
    docker_compose_scale services: {
      app: ENV['LAIR_DOCKER_APP_CONTAINERS'].try(:to_i) || 3,
      job: ENV['LAIR_DOCKER_JOB_CONTAINERS'].try(:to_i) || 3
    }
  end

  namespace :app do
    deploy_task run: %i(deploy:app:ensure_build deploy:config) do
      docker_compose_up :app, recreate: true
    end

    deploy_task stop: %i(deploy:config) do
      docker_compose_stop :app
    end

    deploy_task build: %i(deploy:repo:checkout) do
      docker_build path: fetch(:checkout), name: 'alphahydrae/lair'
    end

    deploy_task ensure_build: %i(deploy:env) do
      ensure_docker_image_built 'alphahydrae/lair'
    end

    deploy_task :ensure_running do
      raise "No app containers are running" unless docker_container_id(compose_service: 'app', status: 'running')
    end
  end

  namespace :job do
    deploy_task run: %i(deploy:app:ensure_build deploy:config) do
      docker_compose_up :job, recreate: true
    end

    deploy_task stop: %i(deploy:config) do
      docker_compose_stop :job
    end
  end

  namespace :db do
    deploy_task run: %i(deploy:config deploy:cache:run) do

      env = ENV.select{ |k,v| !!k.match(/^LAIR_(?:DATABASE|POSTGRES)_/) }
      env['POSTGRES_PASSWORD'] = env.delete 'LAIR_POSTGRES_PASSWORD'

      with env do
        docker_compose_up :db
      end
    end

    deploy_task migrate: %i(deploy:app:ensure_build deploy:db:run deploy:wait) do
      docker_compose_run :task, 'db:migrate'
    end

    deploy_task load_schema: %i(deploy:app:ensure_build deploy:db:run deploy:wait) do
      docker_compose_run :task, 'db:schema:load', 'db:seed'
    end

    deploy_task load_dump: %i(deploy:repo:checkout deploy:db:run deploy:wait) do
      docker_run '--entrypoint', '/tmp/load-dump.sh', '--volume', '/var/lib/lair/checkout/docker/db/load-dump.sh:/tmp/load-dump.sh', '--volume /var/lib/lair/backup/dump.sql:/tmp/dump.sql', 'postgres:9.5', '/tmp/dump.sql'
    end
  end

  namespace :cache do
    deploy_task run: %i(deploy:config) do
      docker_compose_up :cache
    end
  end

  namespace :serf do
    deploy_task run: %i(deploy:app:ensure_build deploy:config) do
      docker_compose_up :serf
    end
  end

  namespace :assets do
    deploy_task compile: %i(deploy:app:ensure_build deploy:config) do
      docker_compose_run :task, 'assets:precompile', 'assets:clean'
      docker_compose_run :task, 'templates:precompile'
    end
  end

  deploy_task wait: %i(deploy:app:ensure_build deploy:config) do
    docker_compose_run :wait
  end

  namespace :backup do
    deploy_task run: %i(deploy:backup:ensure_build deploy:config) do
      execute :mkdir, '-p', File.join(fetch(:root), 'backup')
      docker_compose_run :backup
    end

    deploy_task build: %i(deploy:repo:checkout) do
      docker_build name: 'alphahydrae/lair-backup', path: File.join(fetch(:checkout), 'docker', 'backup')
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

    docker_compose_file = generate_handlebars_template path: local_docker_file('docker-compose.yml.hbs'), template_options: fetch(:env_vars)
    env_file = generate_handlebars_template path: local_docker_file('env.hbs'), template_options: fetch(:env_vars)
    nginx_conf_file = generate_handlebars_template path: local_docker_file('nginx', 'lair.serf.conf.hbs'), template_options: fetch(:env_vars)

    db_init_script_file = File.join fetch(:local_docker), 'db', 'init.sh'
    nginx_serf_conf_file = File.join fetch(:local_docker), 'nginx', 'config.yml'

    upload! docker_compose_file, remote_file('docker-compose.yml')
    upload! env_file, remote_file('.env')
    upload! db_init_script_file, remote_file('postgresql/init-scripts/00_lair.sh')
    upload! nginx_conf_file, '/etc/nginx-serf/sites/lair.conf.hbs'
    upload! nginx_serf_conf_file, '/etc/nginx-serf/config.yml' # TODO: move to ansible
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

    files_to_delete = %w(checkout docker-compose.yml .env postgresql public redis repo tmp).collect{ |dir| File.join fetch(:root), dir }
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
      execute :docker, 'stop', id
      execute :docker, 'rm', id
    end

    execute :rm, '-fr', *files_to_delete
  end

  deploy_task setup: %i(deploy:env) do

    dirs = %w(postgresql/init-scripts redis public tmp).collect{ |dir| File.join fetch(:root), dir }
    dirs << '/etc/nginx-serf/sites'

    execute :mkdir, '-p', dirs
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

def local_docker_file *args
  File.join *args.unshift(fetch(:local_docker))
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
    docker_compose_run :task, 'db:version'
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

def docker_compose_up service, recreate: false

  up_args = []
  up_args << '--no-recreate' unless recreate
  up_args << '-d' << service.to_s

  docker_compose 'up', '--no-deps', *up_args
end

def docker_compose_stop service
  docker_compose 'stop', service.to_s
end

def docker_compose_run *service_and_args
  docker_compose 'run', '--no-deps', '--rm', *service_and_args.collect(&:to_s)
end

def docker_compose_scale services:

  scale_args = services.inject([]) do |memo,(service,number)|
    memo << "#{service}=#{number}"
  end

  docker_compose 'scale', *scale_args
end

def docker_compose *args
  within fetch(:root) do
    capture *([ :'docker-compose', '-p', 'lair' ] + args)
  end
end

def docker_build path:, name:
  within path.to_s do
    execute :docker, 'build', '-t', name.to_s, '.'
  end
end

def docker_run *run_args
  within fetch(:root) do
    capture :docker, 'run', '--rm', '--env-file', '.env', '--net', 'lair_default', *run_args
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

def ensure_docker_image_built name
  image_id = capture :docker, 'images', '-q', name.to_s
  raise "Docker image #{name} not found" if image_id.strip.empty?
end
