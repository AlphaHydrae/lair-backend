require 'paint'

namespace :static do

  desc 'Copy all static assets in static to public'
  task :copy do

    target = Rails.root.join 'public'

    Dir.chdir Rails.root.join('static')

    Dir.glob('**/*').reject{ |f| f.match /^\./ }.each do |file|
      source = Rails.root.join 'static', file
      FileUtils.cp_r source, target
      puts Paint["#{Pathname.new(source).relative_path_from Rails.root} -> #{File.join 'public', file}", :green]
    end
  end
end
