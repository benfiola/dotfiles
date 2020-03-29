require 'thor'

require_relative './core.rb'



module Vagrant
    module Devenv
        module CLI
            class Main < Thor
                class_option :vagrant_home_path, :hide => true, :type => :string, :required => true

                option :provision, :type => :boolean
                desc "up <name>", "Create a development environment"
                def up(name)
                    Vagrant::Devenv::Core.new(self.vagrant_home_path).create(name, provision: options[:provision])
                end
                
                option :force, :type => :boolean
                desc "destroy <name>", "Destroy a devenv"
                def destroy(name)
                    Vagrant::Devenv::Core.new(self.vagrant_home_path).destroy(name, force: options[:force])
                end

                desc "list", "List devenvs"
                def list

                end

                no_commands do
                    def vagrant_home_path
                        self.options["vagrant_home_path"]
                    end
                end
            end
        end
    end
end