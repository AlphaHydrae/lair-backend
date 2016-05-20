if Rails.env != 'production'
  require 'dotenv'
  require 'sshkit'
  require 'sshkit/dsl'
  include SSHKit::DSL
end

LAIR_HOSTS = []
LAIR_ROOT = '/var/lib/lair'

SSHKit.config.output_verbosity = :debug if ENV['DEBUG']

task deploy: %i(deploy:config deploy:serf:run deploy:cache:run deploy:db:run deploy:assets:compile deploy:app:run deploy:job:run deploy:scale)

%i(vagrant production).each do |env|
  task env do
    ENV['DEPLOY_ENV'] = env.to_s
  end
end

namespace :deploy do
  task :scale do
    on LAIR_HOSTS do
      within LAIR_ROOT do
        docker_compose_scale services: { app: ENV['LAIR_DOCKER_APP_CONTAINERS'].try(:to_i) || 3, job: ENV['LAIR_DOCKER_JOB_CONTAINERS'].try(:to_i) || 3 }
      end
    end
  end

  namespace :app do
    task run: %i(deploy:env deploy:build:app) do
      on LAIR_HOSTS do
        within LAIR_ROOT do
          docker_compose_up :app, recreate: true
        end
      end
    end
  end

  namespace :assets do
    task compile: %i(deploy:env deploy:build:app) do
      on LAIR_HOSTS do
        within LAIR_ROOT do
          docker_compose_run :task, 'assets:precompile', 'assets:clean'
          docker_compose_run :task, 'templates:precompile'
        end
      end
    end
  end

  namespace :job do
    task run: %i(deploy:env deploy:build:app) do
      on LAIR_HOSTS do
        within LAIR_ROOT do
          docker_compose_up :job, recreate: true
        end
      end
    end
  end

  namespace :build do
    task app: %i(deploy:repo:checkout) do
      on LAIR_HOSTS do
        current_dir = File.join LAIR_ROOT, 'current'
        docker_build path: current_dir, name: 'alphahydrae/lair'
      end
    end
  end

  namespace :serf do
    task run: %i(deploy:config deploy:build:app) do
      on LAIR_HOSTS do
        within LAIR_ROOT do
          docker_compose_up :serf
        end
      end
    end
  end

  namespace :repo do
    task :update do
      on LAIR_HOSTS do
        repo_dir = File.join LAIR_ROOT, 'repo'
        if test "[ ! -d #{repo_dir} ]"
          within LAIR_ROOT do
            execute :git, 'clone', '--bare', ENV['LAIR_REPO_URL'], 'repo'
          end
        else
          within File.join(LAIR_ROOT, 'repo') do
            execute :git, 'fetch', '--all'
          end
        end
      end
    end

    task checkout: %i(deploy:env deploy:repo:update) do
      on LAIR_HOSTS do

        repo_dir = File.join LAIR_ROOT, 'repo'
        current_dir = File.join LAIR_ROOT, 'current'
        tmp_dir = File.join LAIR_ROOT, 'tmp'
        archive_file = File.join tmp_dir, 'checkout.tar'

        execute :rm, '-fr', current_dir
        execute :mkdir, '-p', current_dir, tmp_dir

        within repo_dir do
          branch = ENV['LAIR_REPO_BRANCH'] || 'master'
          execute :git, 'archive', '--output', archive_file, branch
        end

        within tmp_dir do
          execute :tar, '-C', current_dir, '-x', '--file', archive_file
        end
      end
    end
  end

  namespace :cache do
    task run: %i(deploy:env) do
      on LAIR_HOSTS do
        within LAIR_ROOT do
          docker_compose_up :cache
        end
      end
    end
  end

  namespace :db do
    task run: %i(deploy:env) do
      on LAIR_HOSTS do
        within LAIR_ROOT do

          env = ENV.select{ |k,v| !!k.match(/^LAIR_(?:DATABASE|POSTGRES)_/) }
          env['POSTGRES_PASSWORD'] = env.delete 'LAIR_POSTGRES_PASSWORD'

          docker_compose_up :db, env: env
        end
      end
    end

    task migrate: %i(deploy:env deploy:build:app) do
      on LAIR_HOSTS do
        within LAIR_ROOT do
          docker_compose_run :task, 'db:migrate'
        end
      end
    end
  end

  namespace :backup do
    task run: %i(deploy:env) do

    end

    task build: %i(deploy:env) do
      on LAIR_HOSTS do
        docker_build name: 'alphahydrae/lair-backup', path: File.join(current_version_dir, 'docker', 'backup')
      end
    end
  end

  task config: %i(deploy:env) do

    tmp = File.join File.dirname(__FILE__), '..', '..', 'tmp', 'deploy'
    FileUtils.mkdir_p tmp

    Dir.mktmpdir nil, tmp do |dir|

      project_root = File.join File.dirname(__FILE__), '..', '..'
      env = ENV.select{ |k,v| k.index('LAIR_') == 0 || k == 'RAILS_ENV' }

      docker_compose_config = generate_config path: File.join(project_root, 'docker', 'docker-compose.yml'), template_options: env
      docker_compose_file = save_tmp_config :docker_compose, dir, docker_compose_config

      env_config = generate_config path: File.join(project_root, 'docker', 'env.hbs'), template_options: env
      env_file = save_tmp_config :env, dir, env_config

      db_init_script = File.join project_root, 'docker', 'db', 'init-scripts', 'lair.sh'

      nginx_serf_conf = File.join project_root, 'docker', 'nginx', 'config.yml'
      nginx_conf = generate_config path: File.join(project_root, 'docker', 'nginx', 'lair.serf.conf.hbs'), template_options: env
      nginx_file = save_tmp_config :nginx, dir, nginx_conf

      on LAIR_HOSTS do
        execute :mkdir, '-p', '/etc/nginx-serf/sites' # TODO: move to ansible
        execute :mkdir, '-p', LAIR_ROOT, '/var/lib/lair/postgresql/init-scripts', '/var/lib/lair/redis', '/var/lib/lair/public'
        within LAIR_ROOT do
          upload! docker_compose_file, '/var/lib/lair/docker-compose.yml'
          upload! env_file, '/var/lib/lair/.env'
          upload! db_init_script, '/var/lib/lair/postgresql/init-scripts/lair.sh'
          upload! nginx_file, '/etc/nginx-serf/sites/lair.conf.hbs'
          upload! nginx_serf_conf, '/etc/nginx-serf/config.yml' # TODO: move to ansible
        end
      end
    end
  end

  task :env do
    ENV.reject!{ |k,v| k.index('LAIR_') == 0 || k == 'RAILS_ENV' }

    deploy_env = ENV['DEPLOY_ENV']
    raise "$DEPLOY_ENV must be set" unless deploy_env

    Dotenv.load! ".env.#{deploy_env}"

    if ENV['LAIR_SSH_HOST']
      host = ENV['LAIR_SSH_HOST']
      host = "#{ENV['LAIR_SSH_USER']}@#{host}" if ENV['LAIR_SSH_USER']
      host = "#{host}:#{ENV['LAIR_SSH_PORT']}" if ENV['LAIR_SSH_PORT']
      LAIR_HOSTS << host
    else
      LAIR_HOSTS << 'root@127.0.0.1:2222'
    end
  end
end

def current_version_dir
  ENV['LAIR_DEPLOY_CURRENT_VERSION_DIR'] || File.join(LAIR_ROOT, 'current')
end

def generate_config path:, template_options: {}
  handlebars = Handlebars::Context.new
  template = handlebars.compile File.read(path)
  template.call template_options
end

def save_tmp_config name, tmp_dir, config
  tmp_file = File.join tmp_dir, name.to_s
  File.open(tmp_file, 'w'){ |f| f.write config }
  tmp_file
end

def docker_compose_up service, recreate: false, env: {}
  deploy_env = ENV.select{ |k,v| k.index('LAIR_DEPLOY_') == 0 }
  with deploy_env.merge(env) do

    args = [ :'docker-compose', '-p', 'lair', 'up', '--no-deps' ]
    args << '--no-recreate' unless recreate
    args << '-d' << service.to_s

    execute *args
  end
end

def docker_compose_run *service_and_args, env: {}
  deploy_env = ENV.select{ |k,v| k.index('LAIR_DEPLOY_') == 0 }
  with deploy_env.merge(env) do

    args = [ :'docker-compose', '-p', 'lair', 'run', '--no-deps', '--rm' ]
    args += service_and_args.collect(&:to_s)

    execute *args
  end
end

def docker_compose_scale services:, env: {}

  args = [ :'docker-compose', '-p', 'lair', 'scale' ]
  services.each do |service,number|
    args << "#{service}=#{number}"
  end

  deploy_env = ENV.select{ |k,v| k.index('LAIR_DEPLOY_') == 0 }
  with deploy_env.merge(env) do
    execute *args
  end
end

def docker_build path:, name:
  within path.to_s do
    execute :docker, 'build', '-t', name.to_s, '.'
  end
end
