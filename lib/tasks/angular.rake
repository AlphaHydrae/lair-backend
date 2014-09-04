require 'fileutils'

namespace :spec do

  namespace :angular do

    desc "Pre-compile the main javascript application file and save it to the spec/angular directory"
    task prepare: :environment do

      # pre-compile test application
      abort 'Could not pre-compile test assets' unless system 'RAILS_ENV=test bundle exec rake assets:precompile'

      assets_dir = Rails.root.join 'public', 'assets'
      files = Dir.entries(assets_dir).select{ |e| e.match /^test-[a-z0-9]+\.js$/ }
      abort "Could not find application file in public/assets" if files.empty?
      abort "Found multiple application files (#{files.join(', ')})" if files.length > 1

      src = File.join assets_dir, files.first
      dest = Rails.root.join 'spec', 'angular', 'lair.js'
      FileUtils.cp src, dest
      puts "Copied #{src} to #{dest}"

      FileUtils.remove_entry_secure assets_dir
      puts "Cleaned #{assets_dir}"
    end
  end
end
