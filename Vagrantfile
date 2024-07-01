Vagrant.configure("2") do |config|
    config.vm.box = "generic/rhel8"

    # Provision the VM using the shell script
    config.vm.provision "shell", path: "provision.sh"
  end
