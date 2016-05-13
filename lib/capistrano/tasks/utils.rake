desc 'Stop the running application and erase all data'
task implode: 'compose:list_containers' do

  ask :confirmation, %/are you #{Paint["ABSOLUTELY 100% POSITIVE", :bold, :red]} you want to #{Paint["remove all containers and erase all data", :underline]}? You are in #{Paint[fetch(:stage).to_s.upcase, :magenta]} mode; type #{Paint["yes", :bold]} to proceed/
  raise 'Task aborted by user' unless fetch(:confirmation).match(/^yes$/i)

  unless fetch(:stage).to_s == 'vagrant'
    ask :double_confirmation, %/#{Paint["ARE YOU KIDDING?!", :bold, :red]}; this is the #{Paint[fetch(:stage).to_s.upcase, :magenta, :bold, :underline, :blink]} environment; type #{Paint["implode", :bold]} if you are not kidding/
    raise 'Task aborted by user' unless fetch(:double_confirmation).match(/^implode$/i)
  end

  on roles(:app) do |host|

    host_containers = fetch(:containers)[host]
    execute "docker rm -f #{host_containers.collect{ |c| c[:id] }.join(' ')}" unless host_containers.empty?
    fetch(:containers)[host].clear

    execute "sudo rm -fr #{fetch(:deploy_to)}"
  end
end

desc 'Remove any running application containers, erase all data, and perform a cold deploy'
task reset: %w(implode deploy)

desc 'Print the result of running the `uname` command on the server'
task :uname do
  on roles(:app) do |host|
    puts capture(:uname, '-a')
  end
end
