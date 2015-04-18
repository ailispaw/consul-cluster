# -*- mode: ruby -*-
# vi: set ft=ruby :

module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") do
        Cap::ChangeHostName
      end

      guest_capability("linux", "configure_networks") do
        Cap::ConfigureNetworks
      end
    end
  end
end

NUM_INSTANCES = 3
BASE_IP_ADDR  = "192.168.65"

Vagrant.configure(2) do |config|
  config.vm.box = "ailispaw/rancheros-lite"

  config.vm.network :forwarded_port, guest: 2375, host: 2375, auto_correct: true, disabled: true

  if Vagrant.has_plugin?("vagrant-triggers") then
    config.trigger.after [:up, :resume] do
      info "Adjusting datetime after suspend and resume."
      run_remote "sudo sntp -4sSc pool.ntp.org"
    end
  end

  # Adjusting datetime before provisioning.
  config.vm.provision :shell, run: "always" do |sh|
    sh.inline = "sntp -4sSc pool.ntp.org"
  end

  (1..NUM_INSTANCES).each do |i|
    config.vm.define vm_name = "node-%02d" % i do |node|
      node.vm.hostname = vm_name

      node.vm.network :private_network, ip: "#{BASE_IP_ADDR}.#{i+100}"

      node.vm.synced_folder ".", "/vagrant"
    end
  end
end
