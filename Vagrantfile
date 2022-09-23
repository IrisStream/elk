Vagrant.configure("2") do |config|

  config.vm.define "elk-server" do |es1|
    # Provider Settings
    es1.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 2
    end
    # es1.vm.box = "irisstream/elk-server"
    # es1.vm.box_version = "2.0"
    es1.vm.box = "ubuntu/focal64"

    es1.vm.hostname = "elk-server"

    # Network Settings
    es1.vm.network "private_network", ip: "192.168.56.5"

    # Provisioning Settings
    # es1.vm.provision "shell", path: "scripts/elk_bootstrap.sh"
    es1.vm.provision :hosts, :sync_hosts => true
  end

  config.vm.define "client-logstash" do |client|
    # Provider Settings
    client.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 2
    end
    client.vm.box = "ubuntu/focal64"

    client.vm.hostname = "client-logstash"

    # Network Settings
    client.vm.network "private_network", ip: "192.168.56.6"

    # File Sync Settings
    client.vm.synced_folder "./files/client-logstash/", "/var/www/html", :mount_options => ["dmode=777", "fmode=666"]

    # Provisioning Settings
    client.vm.provision "shell", path: "scripts/client_logstash_bootstrap.sh"
    client.vm.provision :hosts, :sync_hosts => true
  end

  config.vm.define "client-elasticsearch" do |client|
    # Provider Settings
    client.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 2
    end
    client.vm.box = "ubuntu/focal64"

    client.vm.hostname = "client-elasticsearch"

    # Network Settings
    client.vm.network "private_network", ip: "192.168.56.7"

    # File Sync Settings
    client.vm.synced_folder "./files/client-elasticsearch", "/var/www/html", :mount_options => ["dmode=777", "fmode=666"]

    # Provisioning Settings
    client.vm.provision "shell", path: "scripts/client_elasticsearch_bootstrap.sh"
    client.vm.provision :hosts, :sync_hosts => true
  end
  
end