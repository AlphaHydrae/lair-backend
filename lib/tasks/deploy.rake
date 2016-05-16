if Rails.env != 'production'
  require 'dotenv'
  require 'sshkit'
  require 'sshkit/dsl'
  include SSHKit::DSL
end

LAIR_HOSTS = %w(root@127.0.0.1:2222)
LAIR_ROOT = '/var/lib/lair'

SSHKit.config.output_verbosity = :debug if ENV['DEBUG']

task deploy: %i(deploy:config deploy:serf:run deploy:cache:run deploy:db:run deploy:app:run deploy:job:run deploy:scale)

namespace :deploy do
  task :scale do
    on LAIR_HOSTS do
      within LAIR_ROOT do
        docker_compose_scale services: { app: ENV['LAIR_DOCKER_APP_CONTAINERS'].try(:to_i) || 3, job: ENV['LAIR_DOCKER_JOB_CONTAINERS'].try(:to_i) || 3 }
      end
    end
  end

  namespace :app do
    task run: %(deploy:build:app) do
      on LAIR_HOSTS do
        within LAIR_ROOT do
          docker_compose_up :app, recreate: true
        end
      end
    end
  end

  namespace :job do
    task run: %(deploy:build:app) do
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
        # FIXME: vagrant
        current_dir = '/vagrant'
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

    task checkout: %i(deploy:repo:update) do
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
    task run: :prepare_env do
      on LAIR_HOSTS do
        within LAIR_ROOT do
          docker_compose_up :cache, recreate: false
        end
      end
    end
  end

  namespace :db do
    task run: :prepare_env do
      on LAIR_HOSTS do
        within LAIR_ROOT do

          env = ENV.select{ |k,v| !!k.match(/^LAIR_(?:DATABASE|POSTGRES)_/) }
          env['POSTGRES_PASSWORD'] = env.delete 'LAIR_POSTGRES_PASSWORD'

          docker_compose_up :db, recreate: false, env: env
        end
      end
    end
  end

  task config: :prepare_env do

    tmp = File.join File.dirname(__FILE__), '..', '..', 'tmp', 'deploy'
    FileUtils.mkdir_p tmp

    Dir.mktmpdir nil, tmp do |dir|

      env = ENV.select{ |k,v| k.index('LAIR_') == 0 || k == 'RAILS_ENV' }
      docker_compose_config = generate_config :docker_compose, env
      env_config = generate_config :env, env

      docker_compose_file = save_tmp_config :docker_compose, dir, docker_compose_config
      env_file = save_tmp_config :env, dir, env_config

      db_init_script = File.join File.dirname(__FILE__), '..', '..', 'docker', 'db-init-scripts', 'lair.sh'

      on LAIR_HOSTS do
        execute :mkdir, '-p', LAIR_ROOT, '/var/lib/lair/postgresql/init-scripts', '/var/lib/lair/redis'
        within LAIR_ROOT do
          upload! docker_compose_file, '/var/lib/lair/docker-compose.yml'
          upload! env_file, '/var/lib/lair/.env'
          upload! db_init_script, '/var/lib/lair/postgresql/init-scripts/lair.sh'
        end
      end
    end
  end

  task :prepare_env do
    ENV.reject!{ |k,v| k.index('LAIR_') == 0 || k == 'RAILS_ENV' }
    Dotenv.load! '.env.vagrant'
  end
end

def generate_config name, template_options = {}

  handlebars = Handlebars::Context.new
  templates_dir = File.join File.dirname(__FILE__), '..', '..', 'config', 'templates'

  template = handlebars.compile File.read(File.join(templates_dir, "#{name}.handlebars"))
  template.call template_options
end

def save_tmp_config name, tmp_dir, config
  tmp_file = File.join tmp_dir, name.to_s
  File.open(tmp_file, 'w'){ |f| f.write config }
  tmp_file
end

def docker_compose_up service, recreate: false, env: {}
  with env do

    args = [ :'docker-compose', '-p', 'lair', 'up', '--no-deps' ]
    args << '--no-recreate' unless recreate
    args << '-d' << service.to_s

    execute *args
  end
end

def docker_compose_scale services:

  args = [ :'docker-compose', '-p', 'lair', 'scale' ]
  services.each do |service,number|
    args << "#{service}=#{number}"
  end

  execute *args
end

def docker_build path:, name:
  within path.to_s do
    execute :docker, 'build', '-t', name.to_s, '.'
  end
end
