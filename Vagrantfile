# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Provider Settings
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end

  config.vm.define "elk-server" do |es1|
    es1.vm.box = "ubuntu/focal64"

    es1.vm.hostname = "elk-server"

    # Network Settings
    # es1.vm.network "forwarded_port", guest: 80, host: 8080
    # es1.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"
    es1.vm.network "private_network", ip: "192.168.56.5"
    # es1.vm.network "public_network"

    # File Sync Settings
    # es1.vm.synced_folder "./files/elk-server", "/tmp/setup", :mount_options => ["dmode=777", "fmode=666"]

    # Provisioning Settings
    es1.vm.provision "shell", path: "scripts/elk_bootstrap.sh"
    es1.vm.provision :hosts, :sync_hosts => true
  end

  config.vm.define "client" do |client|
    client.vm.box = "ubuntu/focal64"

    client.vm.hostname = "client"

    # Network Settings
    # client.vm.network "forwarded_port", guest: 80, host: 8080
    client.vm.network "private_network", ip: "192.168.56.6"
    # client.vm.network "public_network"

    # File Sync Settings
    client.vm.synced_folder "./files/client", "/var/www/html", :mount_options => ["dmode=777", "fmode=666"]

    # Provisioning Settings
    client.vm.provision "shell", path: "scripts/client_bootstrap.sh"
    client.vm.provision :hosts, :sync_hosts => true
  end
end