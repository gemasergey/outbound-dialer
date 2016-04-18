class Bday < Sequel::Model
  many_to_one :gsm_group

  def before_save
    self.updated_at = Time.now
    super
  end

    # Формируем массив id именниников today для
    # поздравления клиентов
  def self.today
    return unless Bday.ready?
    GsmGroup.idle_per_group.each do |group, count|
      Bday.where(birthdate: Date.today, success: false, gsm_group_id: group).and("attempt < '5'").and("updated_at < ? or attempt = '0'", Time.now - 900).limit(count).each do |bday|
        yield bday
      end
    end
  end

  def self.ready?
    bdays = Bday.where(birthdate: Date.today, success: false).and("attempt < '5'").and("updated_at < ? or attempt = '0'", Time.now - 900).first
    !bdays.nil?
  end

    # Осуществляем вызов по всем доступным
    # каналам
  def dial_out
    next_try = self.attempt + 1
    set(attempt: next_try)
    save
    outcall = Adhearsion::OutboundCall.new
    outcall.execute_controller_or_router_on_answer BirthDayController, {bday: self}

      # Обрабатываем событие по ответу
    outcall.on_answer do
      outcall.tag 'answered'
      # Запись в БД параметра callsetup
      update(success: true)
    end

    # Обрабатываем событие Hangup
    outcall.on_end do
      #
    end

    line = GsmGroup[:id => gsm_group_id].random_idle_line
    outcall.dial "SIP/#{line.name}/#{callerid}", :from => "0573414405", :timeout => 30

  end # of dial_out

end
