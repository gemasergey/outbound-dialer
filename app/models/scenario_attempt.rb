class ScenarioAttempt < Sequel::Model
  many_to_one :scenario
  many_to_one :lead
  one_to_many :dialer_calls

  def before_save
    self.updated_at = Time.now
    super
  end

  def dial_out
    next_try = attempt + 1
    set(attempt: next_try)
    set(inprogress: true)
    save

    dialer_call = DialerCall.create(scenario_attempt_id: id, callerid: self.lead[:callerid])
    self.add_dialer_call(dialer_call)
    outcall = Adhearsion::OutboundCall.new
    create_time = Time.now
    outcall.execute_controller_or_router_on_answer DialerController, {scenario: scenario_id}

      # Обрабатываем событие по ответу
    outcall.on_answer do
      outcall.tag 'answered'
      # Запись в БД параметра callsetup
      dialer_call.update(setup: (Time.now - create_time))
      update(success: true)
    end

    # Обрабатываем событие Hangup
    outcall.on_end do
      # Звонок был отвечен?
      unless outcall.tagged_with? 'answered'
        dialer_call.update(setup: (Time.now - create_time))
      end
      # Запись в БД длидетльности звонка и кода завершения
      dialer_call.update(duration: outcall.duration, code: outcall.end_code)
      update(inprogress: false)
    end

    line = GsmGroup[:id => gsm_group_id].random_idle_line
    dialer_call.update(:gsm_line_id => line.id)
    outcall.dial "SIP/#{line.name}/#{lead[:callerid]}", :from => "0573414405", :timeout => 30
  end
end
