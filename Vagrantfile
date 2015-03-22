# -*- mode: ruby -*-
# vi: set ft=ruby :

NUM_INSTANCES = 3
BASE_IP_ADDR  = "192.168.65"

Vagrant.configure(2) do |config|
  config.vm.box = "rancheros"
  config.vm.box_url = "https://github.com/ailispaw/rancheros-iso-box/releases/download/v0.6.1/rancheros-virtualbox.box"

  config.vm.network :forwarded_port, guest: 2375, host: 2375, auto_correct: true

  if Vagrant.has_plugin?("vagrant-triggers") then
    config.trigger.after [:up, :resume] do
      info "Adjusting datetime after suspend and resume."
      run_remote <<-EOT.prepend("\n")
        sudo system-docker stop ntp
        sudo ntpd -n -q -g -I eth0 > /dev/null
        date
        sudo system-docker start ntp
      EOT
    end
  end

  # Adjusting datetime before provisioning.
  config.vm.provision :shell, run: "always" do |sh|
    sh.inline = <<-EOT
      system-docker stop ntp
      ntpd -n -q -g -I eth0 > /dev/null
      date
      system-docker start ntp
    EOT
  end

  (1..NUM_INSTANCES).each do |i|
    config.vm.define vm_name = "node-%02d" % i do |node|
      node.vm.hostname = vm_name

      node.vm.network :private_network, ip: "#{BASE_IP_ADDR}.#{i+100}"

      node.vm.synced_folder ".", "/vagrant", type: "nfs", mount_options: ["nolock", "vers=3", "udp"]
    end
  end
end
