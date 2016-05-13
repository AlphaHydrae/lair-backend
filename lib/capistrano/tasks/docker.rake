namespace :docker do

  desc 'Build an up-to-date docker image from the checked out release'
  task :build do
    on roles(:app) do
      within fetch(:docker_build_path) do
        execute :docker_build, '-t', fetch(:docker_image), '.'
      end
    end
  end

  desc 'Build the base docker image from the checked out release'
  task :build_base do
    on roles(:app) do
      within "#{fetch(:docker_build_path)}/docker/base" do
        execute :docker_build, '-t', "#{fetch(:docker_image)}-docker-base", '.'
      end
    end
  end
end
