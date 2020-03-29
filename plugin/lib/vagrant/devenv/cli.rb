require 'thor'

require Vagrant.source_root.join("plugins/commands/up/command")
require Vagrant.source_root.join("plugins/commands/destroy/command")


module Vagrant
    module Devenv
        module CLI
            class Main < Thor
                class_option :vagrant_home_path, :hide => true, :type => :string, :required => true
                class_option :vagrant_environment, :hide => true

                option :provision, :type => :boolean
                desc "up <name>", "Create a development environment"
                def up(name)
                    ENV["VAGRANT_DEVENV"] = "1"
                    ENV["VAGRANT_DEVENV_MACHINE_NAME"] = name

                    command = [name]
                    if options[:provision]
                        command.push "--provision"
                    end

                    env = self.vagrant_environment 

                    return VagrantPlugins::CommandUp::Command.new(command, env).execute
                end
                
                option :force, :type => :boolean
                desc "destroy <name>", "Destroy a devenv"
                def destroy(name)
                    ENV["VAGRANT_DEVENV"] = "1"
                    ENV["VAGRANT_DEVENV_MACHINE_NAME"] = name

                    command = [name]
                    if options[:force]
                        command.push "--force"
                    end

                    env = self.vagrant_environment 

                    return VagrantPlugins::CommandDestroy::Command.new(command, env).execute
                end

                desc "list", "List devenvs"
                def list

                end

                no_commands do
                    def vagrant_home_path
                        self.options["vagrant_home_path"]
                    end

                    def vagrant_environment
                        Vagrant::Environment.new({
                            home_path: self.vagrant_home_path,
                            ui_class: Vagrant::UI::Basic
                        })
                    end

                    def exit_on_failure?
                        true
                    end
                end
            end
        end
    end
end