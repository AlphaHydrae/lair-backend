namespace :users do

  desc "Generates an authentication token for the user with the supplied e-mail"
  task :token, [ :email ] => :environment do |t,args|
    puts User.where(email: args[:email]).first!.generate_auth_token
  end
end
