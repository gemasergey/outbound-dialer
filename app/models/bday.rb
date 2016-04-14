class Bday < Sequel::Model
  many_to_one :gsm_group

  def before_save
    self.updated_at = Time.now
    super
  end

    # Формируем массив id именниников today для
    # поздравления клиентов
  def self.today
    today = Array.new
    GsmGroup.idle_per_group.each do |group, count|
      bdays = Bday.select(:id).where(birthdate: Date.today, success: false, gsm_group_id: group).and("attempt < '5'").and("updated_at < ? or attempt = '0'", Time.now - 900).limit(count)
      next if bdays.empty?
      today.concat(bdays.map(:id))
    end
    today
  end

  def self.ready?
    bdays = Bday.where(birthdate: Date.today, success: false).and("attempt < 5")
    !bdays.empty?
  end

    # Осуществляем вызов по всем доступным
    # каналам
  def self.dial_out
    Bday.today.each do |id|
      bday = Bday[:id => id]
      next_try = bday[:attempt] + 1
      bday.set(attempt: next_try)
      bday.save
      outcall = Adhearsion::OutboundCall.new
      outcall.execute_controller_or_router_on_answer BirthDayController, {bday: bday}

        # Обрабатываем событие по ответу
      outcall.on_answer do
        outcall.tag 'answered'
        # Запись в БД параметра callsetup
        bday.update(success: true)
      end

      # Обрабатываем событие Hangup
      outcall.on_end do
        #
      end

      line = GsmGroup[:id => order[:gsm_group_id]].random_idle_line
      #line = GsmGroup[:id => 2].random_idle_line
      puts "BDAY: SIP/#{line.name}/#{bday[:callerid]}"

      #logger.info "BDAY: SIP/#{line.name}/#{bday[:callerid]}"
      #outcall.dial "SIP/#{line.name}/#{bday[:callerid]}", :from => "0573414405", :timeout => 30
      #outcall.dial "SIP/#{line.name}/0979008869", :from => "0573414405", :timeout => 30
    end # attempts.each

  end # of dial_out

end
