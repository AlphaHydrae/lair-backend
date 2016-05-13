require 'paint'

namespace :templates do

  desc 'Compile all templates in client to public/templates'
  task precompile: :environment do
    templates_dir = Rails.root.join 'client'

    Dir.chdir templates_dir
    templates = Dir.glob('**/*.slim').reject{ |t| t.match /^(?:\.|_)/ }

    target_dir = Rails.root.join 'public', 'templates'
    FileUtils.mkdir_p target_dir

    templates.each do |template|
      source = File.join templates_dir, template
      target = File.join target_dir, template.sub(/\.slim$/, '')

      scope = Object.new
      options = {}
      rendered = Slim::Template.new(source, options).render(scope)

      FileUtils.mkdir_p File.dirname(target)
      File.open(target, 'w'){ |f| f.write rendered }

      puts Paint["#{Pathname.new(source).relative_path_from Rails.root} -> #{Pathname.new(target).relative_path_from Rails.root}", :green]
    end
  end
end
