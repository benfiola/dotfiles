require "pathname"
require "pstore"

require Vagrant.source_root.join("plugins/commands/up/command")
require Vagrant.source_root.join("plugins/commands/destroy/command")

require_relative './version';

module Vagrant
    module Devenv
        class Core
            def initialize(home_path)
                @env = Vagrant::Environment.new({
                    home_path: home_path,
                    ui_class: Vagrant::UI::Basic
                })
                @store = PStore.new(
                    Pathname.new(home_path).join("vagrant-devenv.store").to_s,
                    thread_safe: true
                )
                @store.transaction do
                    @store[:version] ||= Vagrant::Devenv::VERSION
                    @store[:machines] ||= {}
                end
            end

            def stored_environments
                @store.transaction(read_only: true) do
                    return @store[:machines]
                end
            end

            def add_to_store(environment)
                @store.transaction do
                    @store[:machines][:"#{environment}"] = {
                        :name => environment,
                        :version => Vagrant::Devenv::VERSION
                    }
                end
            end

            def remove_from_store(environment)
                @store.transaction do
                    @store[:machines].delete(:"#{environment}")
                end
            end
            
            def create(name, provision: false)
                ENV["VAGRANT_DEVENV"] = "1"
                ENV["VAGRANT_DEVENV_MACHINE_NAME"] = name

                command = [name]
                if provision
                    command.push "--provision"
                end

                VagrantPlugins::CommandUp::Command.new(command, @env).execute
                self.add_to_store(name)
            end

            def destroy(name, force: false)
                ENV["VAGRANT_DEVENV"] = "1"
                ENV["VAGRANT_DEVENV_MACHINE_NAME"] = name

                command = [name]
                if force
                    command.push "--force"
                end

                VagrantPlugins::CommandDestroy::Command.new(command, @env).execute
                self.remove_from_store(name)
            end

            def list
                self.stored_environments.values.each do |value|
                    @env.ui.info("#{value[:name]} (#{value[:version]})")
                end
            end
        end
    end
end
