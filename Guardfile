
ignore /bower_components/, /node_modules/

guard 'rake', task: 'assets:dump', run_on_start: false do
  watch %r{^app\/assets\/javascripts\/.*\.js$}
end

guard 'rake', task: 'spec:angular:prepare', run_on_start: false do
  watch %r{^app\/assets\/javascripts\/lair\.js\.erb$}
end
