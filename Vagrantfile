# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  domain = 'vagrant.icinga.com'

  if Vagrant.has_plugin?('vagrant-vbguest') then
    config.vbguest.auto_update = false
  end

  config.vm.define 'aptly' do |host|
    host.vm.box = 'bento/debian-8'
    host.vm.hostname = "aptly.#{domain}"
    host.vm.network 'forwarded_port', guest: 8080, host: 8080

    config.vm.provider 'virtualbox' do |vb|
      vb.cpus = 2
      vb.memory = '2048'
      config.vm.synced_folder '.', '/vagrant', :type => 'virtualbox' # avoid rsync
    end

    config.vm.provision 'shell', path: 'vagrant/base-system.sh'
    config.vm.provision 'shell', path: 'vagrant/puppet-modules.sh'

    config.vm.provision 'puppet' do |puppet|
      # Note: only works with vboxsf
      puppet.manifests_path = ['vm', '/vagrant/vagrant']
      puppet.options = '--show_diff'
    end
  end
end
