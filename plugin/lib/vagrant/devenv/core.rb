require "pathname"
require "pstore"

require Vagrant.source_root.join("plugins/commands/up/command")
require Vagrant.source_root.join("plugins/commands/destroy/command")

require_relative './version'

module Vagrant
    module Devenv
        class Error < Vagrant::Errors::VagrantError
            def initialize(message)
                super({:error_message => message})
            end

            def error_message
                @extra_data[:error_message]
            end
        end

        class Core
            def initialize(home_path)
                @home_path = home_path
                @env = Vagrant::Environment.new({
                    home_path: @home_path,
                    ui_class: Vagrant::UI::Basic
                })

                # create a metadata store for the plugin
                @store = PStore.new(
                    Pathname.new(@home_path).join("vagrant-devenv.store").to_s,
                    thread_safe: true
                )
                self.store_initialize
                self.store_maintenance
            end

            # public APIs
            def create(name, provision: false)
                ENV["VAGRANT_DEVENV"] = "1"
                ENV["VAGRANT_DEVENV_MACHINE_NAME"] = name

                if self.store_has_environment? @env.cwd, name
                    unless provision
                        raise Error.new "Development environment '#{name}' exists - force previsioning with --prevision"
                    end
                end

                self.vagrant_up(name, provision: provision)
                self.store_add_environment(@env.cwd, name)
            end

            def destroy(name, force: false)
                ENV["VAGRANT_DEVENV"] = "1"
                ENV["VAGRANT_DEVENV_MACHINE_NAME"] = name

                unless self.store_has_environment? @env.cwd, name
                    raise Error.new "Development environment '#{name}' does not exist"
                end

                self.vagrant_destroy(name, force: force)
                self.store_remove_environment(@env.cwd, name)
            end

            def list
                store_environments = self.store_environments
                store_environments.values.each do |environments|
                    environments.values.each do |environment|
                        @env.ui.info("#{environment[:directory]}:#{environment[:name]} (#{environment[:version]})")
                    end
                end
            end

            # internal helpers
            def store_add_environment(directory, environment)
                # if directory is a Pathname, convert to a string
                directory = directory.to_s

                @store.transaction do
                    environment = environment.to_sym
                    @store[:environments][directory.to_sym] ||= {}
                    @store[:environments][directory.to_sym][environment.to_sym] = {
                        :name => environment.to_s,
                        :directory => directory.to_s,
                        :version => Vagrant::Devenv::VERSION
                    }
                end
            end

            def store_environments
                @store.transaction(read_only: true) do
                    return @store[:environments]
                end
            end

            def store_has_environment?(directory, name)
                directory = directory.to_s.to_sym
                name = name.to_sym

                @store.transaction do
                    @store.fetch(:environments, {}).fetch(directory, {}).include? name
                end
            end

            def store_initialize
                @store.transaction do
                    @store[:version] ||= Vagrant::Devenv::VERSION
                    @store[:environments] ||= {}
                end
            end

            def store_maintenance
                # collect all vagrant machines
                vagrant_machines = {}
                @env.machine_index.to_a.each do |machine|
                    directory = machine.vagrantfile_path.to_s.to_sym
                    vagrant_machines[directory] ||= {}
                    vagrant_machines[directory][machine.name.to_sym] = machine
                end

                # find stale development environments
                to_remove = []
                self.store_environments.keys.each do |directory|
                    self.store_environments[directory].keys.each do |environment|
                        unless vagrant_machines.fetch(directory, {}).include? environment
                            to_remove.push([directory, environment])
                        end
                    end
                end

                # remove stale development environments
                to_remove.each do |directory, environment|
                    self.store_remove_environment(directory, environment)
                end
            end

            def store_remove_environment(directory, environment)
                # if directory is a Pathname, convert to a string
                directory = directory.to_s.to_sym
                environment = environment.to_sym

                @store.transaction do
                    unless @store[:environments].include? directory
                        return
                    end
                    @store[:environments][directory].delete(environment)
                    if @store[:environments][directory].keys.length == 0
                        @store[:environments].delete(directory)
                    end
                end
            end

            # vagrant command wrappers
            def command_env
                Vagrant::Environment.new({home_path: @home_path, ui_class: Vagrant::UI::Basic})
            end

            def vagrant_destroy(name, force: false)
                command = [name]
                if force
                    command.push "--force"
                end
                VagrantPlugins::CommandDestroy::Command.new(command, self.command_env).execute
            end

            def vagrant_up(name, provision: false)
                command = [name]
                if provision
                    command.push "--provision"
                end
                VagrantPlugins::CommandUp::Command.new(command, self.command_env).execute
            end
        end
    end
end
