# frozen_string_literal: true

Vagrant.configure("2") do |config|
  config.vm.box = "generic/rocky9"
  config.ssh.insert_key = false

  # Interfaz física del host Fedora utilizada para Bridge.
  bridge_adapter = "wlo1"

  nodes = {
    "k8s-master" => {
      cpus: 2,
      memory: 2048,
      mac: "080027560010"
    },
    "k8s-worker" => {
      cpus: 1,
      memory: 2048,
      mac: "080027560020"
    }
  }

  nodes.each do |name, settings|
    config.vm.define name do |node|
      node.vm.hostname = "#{name}.lab.local"

      # Adaptador 1: NAT, creado por VirtualBox. Vagrant usa esta NIC para SSH.
      # Adaptador 2: Bridge, acceso desde la red física.
      node.vm.network "public_network",
                      bridge: bridge_adapter,
                      auto_config: false

      # Adaptador 3: Host-Only, administración privada desde Fedora.
      node.vm.network "private_network",
                      type: "dhcp",
                      virtualbox__intnet: false,
                      auto_config: false

      # Adaptador 4: red privada DHCP compartida con dns-dhcp01.
      # La MAC estable permite que DHCP entregue la dirección reservada.
      node.vm.network "private_network",
                      type: "dhcp",
                      mac: settings[:mac],
                      auto_config: false

      node.vm.provider "virtualbox" do |vb|
        vb.name = name
        vb.cpus = settings[:cpus]
        vb.memory = settings[:memory]
        vb.customize ["modifyvm", :id, "--ioapic", "on"]
      end

      node.vm.synced_folder ".", "/vagrant",disabled: true
    end
  end
end
