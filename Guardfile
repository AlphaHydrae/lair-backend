# Guardfile
# More info at https://github.com/guard/guard#readme
ignore /bower_components/, /node_modules/

group 'resque' do
  resque_worker_command = 'bundle exec rake resque:work'
  guard :process, name: 'Resque Worker', env: { 'QUEUE' => '*', 'INTERVAL' => '2', 'TERM_CHILD' => '1' }, command: resque_worker_command do
    watch %r{^app/(.+)\.rb$}
    watch %r{^lib/(.+)\.rb$}
  end
end

group 'resque-pool' do
  resque_pool_command = 'bundle exec resque-pool --environment development'
  guard :process, name: 'Resque Pool', command: resque_pool_command, env: { 'RESQUE' => '1', 'TERM_CHILD' => '1' } do
    watch %r{^app/(.+)\.rb$}
    watch %r{^lib/(.+)\.rb$}
    watch %r{^config/resque-pool\.yml$}
  end
end

guard 'rake', task: 'assets:dump', run_on_start: false do
  watch %r{^app\/assets\/javascripts\/.*\.js$}
end

guard 'rake', task: 'spec:angular:prepare', run_on_start: false do
  watch %r{^app\/assets\/javascripts\/lair\.js\.erb$}
end
