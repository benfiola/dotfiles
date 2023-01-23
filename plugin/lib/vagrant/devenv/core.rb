require Vagrant.source_root.join("plugins/commands/up/command")
require Vagrant.source_root.join("plugins/commands/destroy/command")


module Vagrant
    module Devenv
        class Core
            def initialize(home_path)
                @env = Vagrant::Environment.new({
                    home_path: home_path,
                    ui_class: Vagrant::UI::Basic
                })
            end

            def create(name, provision: false)
                ENV["VAGRANT_DEVENV"] = "1"
                ENV["VAGRANT_DEVENV_MACHINE_NAME"] = name

                command = [name]
                if provision
                    command.push "--provision"
                end

                return VagrantPlugins::CommandUp::Command.new(command, @env).execute
            end

            def destroy(name, force: false)
                ENV["VAGRANT_DEVENV"] = "1"
                ENV["VAGRANT_DEVENV_MACHINE_NAME"] = name

                command = [name]
                if force
                    command.push "--force"
                end

                return VagrantPlugins::CommandDestroy::Command.new(command, @env).execute
            end
        end
    end
end
