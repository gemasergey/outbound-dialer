module DialerPlugin
  class Plugin < Adhearsion::Plugin

    run :greet_plugin do
      logger.info "Start CALL generator"
      Thread.new do
        catching_standard_errors do
          loop do
            sleep 10

              # Сообщаем автомобили по выполненным заказам
            Order.hot_orders do |order|
              logger.info "Doing dial for order: #{order.order}, callerid: #{order.callerid}"
              order.dial_out
            end

              # Закрываем отказанные заказы
            Order.ooo do |order|
              logger.info "Закрываем отказы: #{order.close}"
            end

              # Поздравляем с днем рождения именниников
            Bday.today do |bday|
              logger.info "Happy birthday dear #{bday.callerid}"
              bday.dial_out
            end

              # Телемаркетинг
            Scenario.active_attempts do |attempt|
              attempt.dial_out
            end

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
