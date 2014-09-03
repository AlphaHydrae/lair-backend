
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
        projectPath: asset.pathname.relative_path_from(Rails.root).to_s,
        mtime: asset.mtime.iso8601,
        digest: asset.digest
      }

      dumped_asset[:dependencies] = dependencies.collect do |dep|
        {
          logicalPath: dep.logical_path,
          projectPath: dep.pathname.relative_path_from(Rails.root).to_s,
          mtime: dep.mtime.iso8601,
          digest: dep.digest
        }
      end

      dump.push dumped_asset
    end

    dump_file = Rails.root.join 'spec', 'angular', 'assets.json'
    File.open(dump_file, 'w'){ |f| f.write JSON.pretty_generate(dump) }
    puts "Dumped manifest of application javascript assets to #{dump_file}"
  end
end
