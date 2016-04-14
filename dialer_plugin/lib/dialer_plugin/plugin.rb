module DialerPlugin
  class Plugin < Adhearsion::Plugin

    run :greet_plugin do
      logger.info "Start CALL generator"
      Thread.new do
        catching_standard_errors do
          dialer = Dialer.new
          carishere = CarIsHere.new
          loop do
            sleep 10
            carishere.copy_orders
            carishere.dial_out(Order.hot_orders) if Order.ready?
              # Закрываем отказы
            Order.ooo {|order| logger.info "Закрываем отказы: #{order.close}"}
              # Телемаркетинг
            next unless Scenario.active
            dialer.dial_out Scenario.active_attempts
          end #loop
        end # catching_standard_errors
      end # Thread
    end # plugin run

    # Actions to perform when the plugin is loaded
    #
    init :dialer_plugin do
      logger.warn "DialerPlugin has been loaded"
    end

    # Basic configuration for the plugin
    #
    config :dialer_plugin do
      greeting "Hello", :desc => "What to use to greet users"
    end

    # Defining a Rake task is easy
    # The following can be invoked with:
    #   rake plugin_demo:info
    #
    tasks do
      namespace :dialer_plugin do
        desc "Prints the PluginTemplate information"
        task :info do
          STDOUT.puts "DialerPlugin plugin v. #{VERSION}"
        end
      end
    end

  end
end
