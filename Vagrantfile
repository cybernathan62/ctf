Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  config.vm.boot_timeout = 2800

  # =========================
  # Clés SSH
  # =========================
  KEY_DEBIAN  = File.expand_path("./keys/ssh/debian/debian_admin", __dir__)
  KEY_PFSENSE = File.expand_path("./keys/ssh/pfsense/pfsense_admin", __dir__)
  KEY_WIN     = File.expand_path("./keys/ssh/windows/vagrant_2290", __dir__)

  # =========================
  # Réglages globaux SSH
  # =========================
  config.ssh.insert_key = false
  config.ssh.keys_only  = true

  # Pas de partage /vagrant auto
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # =====================================================================
  # 1. PFSENSE-1
  # WAN + Bastion + Transit PF1-PF2 + DMZ
  # =====================================================================
  config.vm.define "pfsense-1" do |p|
    p.vm.box = "cyberctf/pfsense"
    p.ssh.shell = "freebsd"
    p.vm.communicator = "ssh"


    p.ssh.username = "admin"
    p.ssh.private_key_path = KEY_PFSENSE
    p.ssh.insert_key = false
    p.ssh.keys_only = true
    p.ssh.shell = "/bin/sh"

    p.vm.network "forwarded_port", guest: 22, host: 2321, id: "ssh", auto_correct: true

    p.vm.network "forwarded_port", guest: 2401, host: 2401, auto_correct: true
    p.vm.network "forwarded_port", guest: 8081, host: 8081, auto_correct: true
    p.vm.network "forwarded_port", guest: 8441, host: 8441, auto_correct: true
    p.vm.network "forwarded_port", guest: 8442, host: 8442, auto_correct: true
    p.vm.network "forwarded_port", guest: 8443, host: 8443, auto_correct: true
    p.vm.network "forwarded_port", guest: 8445, host: 8445, auto_correct: true
    p.vm.network "forwarded_port", guest: 2402, host: 2402, auto_correct: true
    p.vm.network "forwarded_port", guest: 2403, host: 2403, auto_correct: true
    p.vm.network "forwarded_port", guest: 2404, host: 2404, auto_correct: true
    p.vm.network "forwarded_port", guest: 2405, host: 2405, auto_correct: true
    p.vm.network "forwarded_port", guest: 2406, host: 2406, auto_correct: true
    p.vm.network "forwarded_port", guest: 2407, host: 2407, auto_correct: true
    p.vm.network "forwarded_port", guest: 2408, host: 2408, auto_correct: true

    p.vm.network "private_network",
      virtualbox__intnet: "zone1-bastion-net",
      auto_config: false

    p.vm.network "private_network",
      virtualbox__intnet: "transit-pf1-pf2",
      auto_config: false

    p.vm.network "private_network",
      virtualbox__intnet: "zone1-dmz-net",
      auto_config: false

    p.vm.provider "virtualbox" do |v|
      v.name = "final-pfsense-1"
      v.memory = 2048
      v.cpus = 2
      v.gui = false

      v.customize ["modifyvm", :id, "--nic1", "nat"]
      v.customize ["modifyvm", :id, "--cableconnected1", "on"]
      v.customize ["modifyvm", :id, "--cableconnected2", "on"]
      v.customize ["modifyvm", :id, "--cableconnected3", "on"]
      v.customize ["modifyvm", :id, "--cableconnected4", "on"]
    end

    p.vm.provision "file",
      source: "./backup/pfsense/pfsense-1-config.xml",
      destination: "/root/pfsense-1-config.xml"
  end

  # =====================================================================
  # 2. PFSENSE-2
  # Supervision + Transit PF1-PF2 + Transit PF2-PF3
  # =====================================================================
  config.vm.define "pfsense-2" do |p|
    p.vm.box = "cyberctf/pfsense"
    p.ssh.shell = "freebsd"
    p.vm.communicator = "ssh"
    

    p.ssh.username = "admin"
    p.ssh.private_key_path = KEY_PFSENSE
    p.ssh.insert_key = false
    p.ssh.keys_only = true
    p.ssh.shell = "/bin/sh"

    

    p.vm.network "forwarded_port", guest: 22, host: 2322, id: "ssh", auto_correct: true

    p.vm.network "private_network",
      virtualbox__intnet: "zone2-supervision-net",
      auto_config: false

    p.vm.network "private_network",
      virtualbox__intnet: "transit-pf1-pf2",
      auto_config: false

    p.vm.network "private_network",
      virtualbox__intnet: "transit-pf2-pf3",
      auto_config: false

    p.vm.provider "virtualbox" do |v|
      v.name = "final-pfsense-2"
      v.memory = 2048
      v.cpus = 2
      v.gui = false

      v.customize ["modifyvm", :id, "--nic1", "nat"]
      v.customize ["modifyvm", :id, "--cableconnected1", "on"]
      v.customize ["modifyvm", :id, "--cableconnected2", "on"]
      v.customize ["modifyvm", :id, "--cableconnected3", "on"]
      v.customize ["modifyvm", :id, "--cableconnected4", "on"]
    end

    p.vm.provision "file",
      source: "./backup/pfsense/pfsense-2-config.xml",
      destination: "/root/pfsense-2-config.xml"
  end

  # =====================================================================
  # 3. PFSENSE-3
  # DB + Transit PF2-PF3 + Future zone
  # =====================================================================
  config.vm.define "pfsense-3" do |p|
    p.vm.box = "cyberctf/pfsense"
    p.ssh.shell = "freebsd"
    p.vm.communicator = "ssh"


    p.ssh.username = "admin"
    p.ssh.private_key_path = KEY_PFSENSE
    p.ssh.insert_key = false
    p.ssh.keys_only = true
    p.ssh.shell = "/bin/sh"
    

    p.vm.network "forwarded_port", guest: 22, host: 2323, id: "ssh", auto_correct: true

    p.vm.network "private_network",
      virtualbox__intnet: "zone3-db-net",
      auto_config: false

    p.vm.network "private_network",
      virtualbox__intnet: "transit-pf2-pf3",
      auto_config: false

    p.vm.network "private_network",
      virtualbox__intnet: "zone3-future-net",
      auto_config: false

    p.vm.provider "virtualbox" do |v|
      v.name = "final-pfsense-3"
      v.memory = 2048
      v.cpus = 2
      v.gui = false

      v.customize ["modifyvm", :id, "--nic1", "nat"]
      v.customize ["modifyvm", :id, "--cableconnected1", "on"]
      v.customize ["modifyvm", :id, "--cableconnected2", "on"]
      v.customize ["modifyvm", :id, "--cableconnected3", "on"]
      v.customize ["modifyvm", :id, "--cableconnected4", "on"]
    end

    p.vm.provision "file",
      source: "./backup/pfsense/pfsense-3-config.xml",
      destination: "/root/pfsense-3-config.xml"
  end

  # =====================================================================
  # 4. DEBIAN
  # =====================================================================

  config.vm.define "bastion" do |d|
    d.vm.box = "cyberctf/Debian_bastion"

    d.ssh.username = "vagrant"
    d.ssh.private_key_path = KEY_DEBIAN
    

    d.vm.network "forwarded_port", guest: 22, host: 2301, id: "ssh", auto_correct: true
    d.vm.network "private_network",
      virtualbox__intnet: "zone1-bastion-net",
      auto_config: false

    d.vm.provider "virtualbox" do |v|
      v.name = "final-bastion"
      v.memory = 2048
      v.cpus = 2
      v.gui = true

      v.customize ["modifyvm", :id, "--nic1", "nat"]
      v.customize ["modifyvm", :id, "--cableconnected1", "on"]
      v.customize ["modifyvm", :id, "--cableconnected2", "on"]
    end
  end

  config.vm.define "dmz" do |d|
    d.vm.box = "cyberctf/Debian_bastion"
    d.vm.hostname = "final-dmz"

    d.ssh.username = "vagrant"
    d.ssh.private_key_path = KEY_DEBIAN
    

    d.vm.network "forwarded_port", guest: 22, host: 2302, id: "ssh", auto_correct: true
    d.vm.network "private_network",
      virtualbox__intnet: "zone1-dmz-net",
      auto_config: false

    d.vm.provider "virtualbox" do |v|
      v.name = "final-dmz"
      v.memory = 2048
      v.cpus = 2
      v.gui = true

      v.customize ["modifyvm", :id, "--nic1", "nat"]
      v.customize ["modifyvm", :id, "--cableconnected1", "on"]
      v.customize ["modifyvm", :id, "--cableconnected2", "on"]
    end
  end

  config.vm.define "wazuh" do |d|
    d.vm.box = "cyberctf/debian_wazuh"
    d.vm.hostname = "final-wazuh"
    

    d.ssh.username = "vagrant"
    

    d.vm.network "forwarded_port", guest: 22, host: 2303, id: "ssh", auto_correct: true
    d.vm.network "private_network",
      virtualbox__intnet: "zone2-supervision-net",
      auto_config: false

    d.vm.provider "virtualbox" do |v|
      v.name = "final-wazuh"
      v.gui = false

      v.customize ["modifyvm", :id, "--nic1", "nat"]
      v.customize ["modifyvm", :id, "--cableconnected1", "on"]
      v.customize ["modifyvm", :id, "--cableconnected2", "on"]
    end
  end

  config.vm.define "zabbix" do |d|
    d.vm.box = "cyberctf/Debian_bastion"
    d.vm.hostname = "final-zabbix"
    

    d.ssh.username = "debian"
    d.ssh.private_key_path = KEY_DEBIAN
    

    d.vm.network "forwarded_port", guest: 22, host: 2304, id: "ssh", auto_correct: true
    d.vm.network "private_network",
      virtualbox__intnet: "zone2-supervision-net",
      auto_config: false

    d.vm.provider "virtualbox" do |v|
      v.name = "final-zabbix"
      v.memory = 2048
      v.cpus = 2
      v.gui = false

      v.customize ["modifyvm", :id, "--nic1", "nat"]
      v.customize ["modifyvm", :id, "--cableconnected1", "on"]
      v.customize ["modifyvm", :id, "--cableconnected2", "on"]
    end
  end

  config.vm.define "db-server" do |d|
    d.vm.box = "cyberctf/Debian_bastion"
    d.vm.hostname = "final-db-server"

    d.ssh.username = "debian"
    d.ssh.private_key_path = KEY_DEBIAN
    

    d.vm.network "forwarded_port", guest: 22, host: 2305, id: "ssh", auto_correct: true
    d.vm.network "private_network",
      virtualbox__intnet: "zone3-db-net",
      auto_config: false

    d.vm.provider "virtualbox" do |v|
      v.name = "final-db-server"
      v.memory = 2048
      v.cpus = 2
      v.gui = false

      v.customize ["modifyvm", :id, "--nic1", "nat"]
      v.customize ["modifyvm", :id, "--cableconnected1", "on"]
      v.customize ["modifyvm", :id, "--cableconnected2", "on"]
    end
  end
end
  