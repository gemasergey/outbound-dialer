module Robo
  class Plugin < Adhearsion::Plugin
    # Actions to perform when the plugin is loaded
    #
    init :robo do
      logger.warn "Robo has been loaded"
    end

    # Basic configuration for the plugin
    #
    config :robo do
      greeting "Hello", :desc => "What to use to greet users"
    end

    # Defining a Rake task is easy
    # The following can be invoked with:
    #   rake plugin_demo:info
    #
    tasks do
      namespace :robo do
        desc "Prints the PluginTemplate information"
        task :info do
          STDOUT.puts "Robo plugin v. #{VERSION}"
        end
      end
    end

  end
end
