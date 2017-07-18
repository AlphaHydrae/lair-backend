require 'paint'

namespace :users do

  desc "Generates an authentication token for the user with the given name"
  task :token, %i(name) => :environment do |t,args|
    user = User.where(normalized_name: args[:name].downcase).first!
    puts AccessToken.new(user, :all).encode
  end

  desc "Makes the user with the given name an administrator"
  task :admin, %i(name) => :environment do |t,args|

    u = User.where(normalized_name: args[:name].downcase).first!

    if u.admin?
      puts Paint["User #{u.name} is already an administrator", :yellow]
    else
      u.update_attribute :roles_mask, u.roles_mask | User.mask_for(:admin)
      puts Paint["User #{u.name} is now an administrator", :green]
    end
  end

  desc "Activates the user with the given name"
  task :activate, %i(name) => :environment do |t,args|

    u = User.where(normalized_name: args[:name].downcase).first!

    if u.active
      puts Paint["User #{u.name} is already active", :yellow]
    else
      u.update_attribute :active, true
      puts Paint["User #{u.name} has been activated", :green]
    end
  end

  desc "Deactivates the user with the given name"
  task :deactivate, %i(name) => :environment do |t,args|

    u = User.where(normalized_name: args[:name].downcase).first!

    if !u.active
      puts Paint["User #{u.name} is already deactivated", :yellow]
    else
      u.update_attribute :active, false
      puts Paint["User #{u.name} has been deactivated", :green]
    end
  end
end
