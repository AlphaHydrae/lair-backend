
namespace :assets do

  desc "Dump a JSON manifest of application javascript assets for testing"
  task dump: :environment do

    main_assets = %w(application.js)

    environment = Sprockets::Environment.new Rails.root
    environment.append_path 'app/assets/javascripts'
    environment.append_path 'vendor/assets/javascripts'

    dump = []

    %w(application.js).each do |main_asset|

      asset = environment.find_asset main_asset
      raise "Unknown asset #{main_asset}" unless asset

      dependencies = asset.to_a

      dumped_asset = {
        logicalPath: main_asset,
        projectPath: asset.pathname.relative_path_from(Rails.root).to_s
      }

      dumped_asset[:dependencies] = dependencies.collect do |dep|
        {
          logicalPath: dep.logical_path,
          projectPath: dep.pathname.relative_path_from(Rails.root).to_s
        }
      end

      dump.push dumped_asset
    end

    dump_contents = JSON.pretty_generate dump
    dump_file = Rails.root.join 'spec', 'angular', 'assets.json'

    if File.exist?(dump_file) && Digest::SHA512.hexdigest(File.read(dump_file)) == Digest::SHA512.hexdigest(dump_contents)
      puts "Manifest of application javascript assets has not changed"
    else
      File.open(dump_file, 'w'){ |f| f.write dump_contents }
      puts "Dumped manifest of application javascript assets to #{dump_file}"
    end
  end
end
