# -*- mode: ruby -*-
# vi: set ft=ruby :
# some excerpts from deomorxsy/talvlab
#
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provision "shell", inline: "echo hello"

  config.vm.define "staging1" do |staging1|
    staging1.vm.box = "deomorxsy/kjx-headless"
    memory = 1024
    cpus = 1
    staging1.vm.provider :qemu do |v|
      v.memory = memory
      v.cpus = cpus
      v.linked_clone = true
  end

  # vm ips
  boxes = [
    { :name => "agent1", ip => "192.168.42.91"},
    { :name => "agent2", ip => "192.168.42.92"},
    { :name => "agent3", ip => "192.168.42.93"}
  ]

  # Provision each of the VMs
  boxes.each do |opts|
    config.vm.define opts[:name] do |config|
      config.vm.hostname = opts[:name]
      config.vm.network :private_network, ip: opts[:ip]

      # provision all vms in parallel with ansible when the last VM is up
      if opts[:name] == "agent3"
        config.vm.provision "ansible" do |ansible|
          ansible.compatibility_mode = "2.0"
          ansible.playbook = "./playbooks/main.yaml"
          ansible.limit = "all"
          ansible.become = "true"
          # agents are workers.
          ansible.groups = {
              "kubernetes" => ["agent1", "agent2", "agent3"],
              "kubernetes_master" => ["agent1"],
              "kubernetes_master:vars" => {
                  kubernetes_role: "master",
                  # check this
                  swapfile_path: "/dev/mapper/vagrant--vg-swap_1",
                  kubernetes_apiserver_advertise_address: "192.168.56.71"
              },
              "kubernetes_node" => ["agent2", "agent3"],
              "kubernetes_node:vars" => {
                kubernetes_role: "node",
                swapfile_path: "/dev/mapper/vagrant--vg-swap_1"
              }
          }
        end
      end
    end
  end
end


