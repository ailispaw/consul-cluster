# -*- mode: ruby -*-
# vi: set ft=ruby :

# A dummy plugin for Barge to set hostname and network correctly at the very first `vagrant up`
module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") { Cap::ChangeHostName }
      guest_capability("linux", "configure_networks") { Cap::ConfigureNetworks }
    end
  end
end

NUM_INSTANCES = 3
BASE_IP_ADDR  = "192.168.65"

Vagrant.configure(2) do |config|
  config.vm.box = "ailispaw/barge"

  config.vm.network :forwarded_port, guest: 2375, host: 2375, auto_correct: true, disabled: true

  (1..NUM_INSTANCES).each do |i|
    config.vm.define vm_name = "node-%02d" % i do |node|
      node.vm.hostname = vm_name

      node.vm.network :private_network, ip: "#{BASE_IP_ADDR}.#{i+100}"

      node.vm.synced_folder ".", "/vagrant"
    end
  end
end
