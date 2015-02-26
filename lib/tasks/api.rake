namespace :api do

  desc "Print out all API routes"
  task routes: :environment do
    puts " Verb     URI Pattern"
    Lair::API.routes.each do |api|
      puts " #{api.route_method.ljust(8)} #{api.route_path}"
    end
  end
end
