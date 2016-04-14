class CarIsHere

  attr_accessor :dbtaxi

  def initialize
    @dbtaxi = Sequel.connect("mysql2://rbox:rbox@192.168.0.101/taxi_kharkov",
                             :max_connections => 10, :logger => logger, encoding: 'latin1')
    @dbtaxi.sql_log_level = :debug
    @zero_aftercall = Hash.new # пост обработка водителя 00
    @queue = Hash.new
    @hot_orders = Array.new
  end

    # Копируем заказы для сообщения в 
    # свою таблицу
  def copy_orders
    logger.info "check_orders"
    td_orders = @dbtaxi[:orders].where(:orderstate => 2, :mess => '', :ordervendorexecute => '7171')
    td_orders.each do |td_order|
      if td_order[:msgid3] == 1
        logger.info "ВЫЗОВ ОСУЩЕСТВЛЯЕТСЯ ДЛЯ ЗАКАЗА #{td_order[:num]}"
      elsif td_order[:msgid3] == 2
        logger.info "УЖЕ СООБЩИЛИ ЗАКАЗ #{td_order[:num]}"
      else
        num = td_order[:num]
        callerid = td_order[:phone].gsub(/\D/, '')
        driver = td_order[:orderwasdrivers].split(',').fetch(-1)
        car = @dbtaxi[:refcars].where(defsign: driver).first
        if car.nil?
          logger.info "Позывной не найден в справочнике"
          car = {carnumber: '', model: '', color: ''}
        else
          car[:carnumber] = Translit::convert(car[:carnumber].encode("UTF-8", "CP1251"), :english).gsub(/\D/, '')
          car[:model] = Translit::convert(car[:model].encode("UTF-8", "CP1251"), :english).downcase.gsub(' ', '')
          car[:color] = Translit::convert(car[:color].encode!("UTF-8", "CP1251")).downcase
        end
        gsm_group_id = Prefix.where(name: callerid[0..2]).first.gsm_group[:id]

        Order.create(order: num, attempt: 0, callerid: callerid, gsm_group_id: gsm_group_id,
                     finished: false, inprogress: false, driver: driver, color: car[:color],
                     model: car[:model], carnum: car[:carnumber],
                     created_at: Time.now, updated_at: Time.now)
        logger.info "ОБНАРУЖЕН НОВЫЙ НОМЕР ЗАКАЗА #{num}"
        @dbtaxi[:orders].where(num: num).update(msgid3: 1)
      end
    end #each order

  end # of copy_orders


    # Формируем звонок по всем id в
    # hot_orders
  def dial_out hot_orders
    logger.info "CarIsHere#dial_out #{hot_orders.to_s}"
    hot_orders.each do |id|
      order = Order[:id => id]
      next_try = order[:attempt] + 1
      order.set(attempt: next_try, inprogress: true)
      order.save
      outcall = Adhearsion::OutboundCall.new
      outcall.execute_controller_or_router_on_answer CarIsHereController, {order: order}

        # Обрабатываем событие по ответу
      outcall.on_answer do
        outcall.tag 'answered'
        # Запись в БД параметра callsetup
        order.update(finished: true)
        td_answer = order.answer
        logger.info "CAR IS HERE: #{td_answer}"
      end

      # Обрабатываем событие Hangup
      outcall.on_end do
        # Все попытки закончились?
        if order.attempt == 5
          order.update(finished: true)
          td_answer = order.wo_answer
          logger.info "CAR IS HERE: #{td_answer}"
        end
        order.update(inprogress: false)
      end

      line = GsmGroup[:id => order[:gsm_group_id]].random_idle_line
      #line = GsmGroup[:id => 2].random_idle_line
      logger.info "CAR IS HERE: SIP/#{line.name}/#{order[:callerid]}"
      outcall.dial "SIP/#{line.name}/#{order[:callerid]}", :from => "0573414405", :timeout => 30
      #outcall.dial "SIP/#{line.name}/0979008869", :from => "0573414405", :timeout => 30
    end # attempts.each

  end # of dial_out

end
