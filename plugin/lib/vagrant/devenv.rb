require 'vagrant'


module Vagrant
    module Devenv
        class Plugin < Vagrant.plugin('2')
            name "vagrant-devenv"

            description <<-DESC
                
            DESC

            command('devenv') do
                require_relative "./devenv/command"
                Command
            end
        end
    end
end
