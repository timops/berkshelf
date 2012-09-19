require 'vagrant'
require 'berkshelf'

module Berkshelf
  # @author Jamie Winsor <jamie@vialstudios.com>
  # @author Andrew Garson <andrew.garson@gmail.com>
  module Vagrant
    module Action
      autoload :Install, 'berkshelf/vagrant/action/install'
      autoload :Upload, 'berkshelf/vagrant/action/upload'
      autoload :Clean, 'berkshelf/vagrant/action/clean'
      autoload :SetUI, 'berkshelf/vagrant/action/set_ui'
    end

    autoload :Config, 'berkshelf/vagrant/config'
    autoload :Middleware, 'berkshelf/vagrant/middleware'

    class << self
      # @param [Vagrant::Action::Environment] env
      def shelf_for(env)
        File.join(Berkshelf.berkshelf_path, "vagrant", env[:global_config].vm.host_name)
      end

      # @param [Symbol] shortcut
      # @param [Vagrant::Config::Top] config
      #
      # @return [Array]
      def provisioners(shortcut, config)
        config.vm.provisioners.select { |prov| prov.shortcut == shortcut }
      end

      # Determine if the given instance of Vagrant::Config::Top contains a
      # chef_solo provisioner
      #
      # @param [Vagrant::Config::Top] config
      #
      # @return [Boolean]
      def chef_solo?(config)
        !provisioners(:chef_solo, config).empty?
      end

      # Determine if the given instance of Vagrant::Config::Top contains a
      # chef_client provisioner
      #
      # @param [Vagrant::Config::Top] config
      #
      # @return [Boolean]
      def chef_client?(config)
        !provisioners(:chef_client, config).empty?
      end

      # Initialize the Berkshelf Vagrant middleware stack
      def init!
        ::Vagrant.config_keys.register(:berkshelf) { Berkshelf::Vagrant::Config }
        ::Vagrant.actions[:provision].insert(::Vagrant::Action::VM::Provision, Berkshelf::Vagrant::Middleware.install)
        ::Vagrant.actions[:provision].insert(::Vagrant::Action::VM::Provision, Berkshelf::Vagrant::Middleware.upload)
        ::Vagrant.actions[:start].insert(::Vagrant::Action::VM::Provision, Berkshelf::Vagrant::Middleware.install)
        ::Vagrant.actions[:start].insert(::Vagrant::Action::VM::Provision, Berkshelf::Vagrant::Middleware.upload)
        ::Vagrant.actions[:destroy].insert(::Vagrant::Action::VM::CleanMachineFolder, Berkshelf::Vagrant::Middleware.clean)
      end
    end
  end
end

Berkshelf::Vagrant.init!
