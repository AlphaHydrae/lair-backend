# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = 'ubuntu/trusty64'
  config.vm.network 'private_network', ip: '192.168.50.4'
  config.vm.network 'forwarded_port', guest: 80, host: 80
  config.vm.network 'forwarded_port', guest: 443, host: 443

  config.vm.provider 'virtualbox' do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.provision 'ansible' do |ansible|
    ansible.playbook = 'ansible/vagrant-playbook.yml'
    ansible.tags = ENV['ANSIBLE_TAGS'].split(',') if ENV.key? 'ANSIBLE_TAGS'
    ansible.skip_tags = ENV['ANSIBLE_SKIP_TAGS'].split(',') if ENV.key? 'ANSIBLE_SKIP_TAGS'
    ansible.extra_vars = {}
  end
end
