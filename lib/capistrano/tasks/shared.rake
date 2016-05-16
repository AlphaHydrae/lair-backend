namespace :shared do
  task :setup do
    on roles(:app) do
      within shared_path do
        execute :mkdir, '-p', 'public/assets', 'tmp/cache'
      end
    end
  end
end
