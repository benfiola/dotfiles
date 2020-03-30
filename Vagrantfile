def devenv_machine_name
    ENV.fetch("VAGRANT_DEVENV_MACHINE_NAME", :default)
end

Vagrant.configure("2") do |config|
    config.vm.define devenv_machine_name do |subconfig|
        subconfig.vm.box = "pristine/ubuntu-budgie-19.10"
        subconfig.vm.box_version = "1.0.0"

        config.vm.provision "ansible_local" do |ansible|
            ansible.compatibility_mode = "2.0"
            ansible.extra_vars = {
                ansible_python_interpreter:"auto_silent" 
            }
            ansible.playbook = "provisioning/playbook_main.yml"
            ansible.install_mode = "pip"
            # ansible.verbose = "-vvvv"
            ansible.version = "2.9.6"
            ansible.groups = {
                "development_environment" => [devenv_machine_name]
            }
        end

        config.vm.provider :virtualbox do |vb|
            vb.memory = 8192
            vb.cpus = 4

            # host/guest vb features
            vb.customize ['modifyvm', :id, '--clipboard-mode', 'bidirectional']
            vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
            
            # gfx
            vb.customize ["modifyvm", :id, "--vram", "256"]
            vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
            vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
            
            # audio
            vb.customize ["modifyvm", :id, "--audio", "dsound"]
            vb.customize ["modifyvm", :id, "--audioout", "on"]
            
            # usb
            vb.customize ["modifyvm", :id, "--usbxhci", "on"]

            # nested vm support
            vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
        end
    end
end