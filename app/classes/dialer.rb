class Dialer

  attr_reader :idle_per_group

  def initialize
    Sequel::DATABASES.each do |d|
      d.sql_log_level = :debug
      d.loggers << logger
    end
  end

  def dial_out attempts
    attempts.each do |id|
      attempt = ScenarioAttempt[:id => id]
      next_try = attempt[:attempt] + 1
      attempt.update(attempt: next_try)

      dialer_call = DialerCall.create(scenario_attempt_id: attempt.id, callerid: attempt.lead[:callerid])
      attempt.add_dialer_call(dialer_call)
      attempt.update(inprogress: true)
      outcall = Adhearsion::OutboundCall.new
      create_time = Time.now
      outcall.execute_controller_or_router_on_answer DialerController, {scenario: attempt.scenario_id}

        # Обрабатываем событие по ответу
      outcall.on_answer do
        outcall.tag 'answered'
        # Запись в БД параметра callsetup
        dialer_call.update(setup: (Time.now - create_time))
        attempt.update(success: true)
      end

      # Обрабатываем событие Hangup
      outcall.on_end do
        # Звонок был отвечен?
        unless outcall.tagged_with? 'answered'
          dialer_call.update(setup: (Time.now - create_time))
        end
        # Запись в БД длидетльности звонка и кода завершения
        dialer_call.update(duration: outcall.duration, code: outcall.end_code)
        attempt.update(inprogress: false)
      end

      line = GsmGroup[:id => attempt[:gsm_group_id]].random_idle_line
      dialer_call.update(:gsm_line_id => line.id)
      logger.warn "SIP/#{line.name}/#{attempt.lead[:callerid]}"
      outcall.dial "SIP/#{line.name}/#{attempt.lead[:callerid]}", :from => "0573414405", :timeout => 30
    end # attempts.each
  end
end # of class Dialer
