class Dialer

  def initialize
    @idle_per_group = Hash.new
    @attempts = Array.new
    Sequel::DATABASES.each do |d|
      d.sql_log_level = :debug
      d.loggers << logger
    end
  end

  def active_scenario?
    scenario = Scenario.where(paused: false, finished: false).first
    return false if scenario.nil?
    time_range = scenario.time_ranges_dataset.where(date: Date.today).first
    logger.warn "Active_scenario?: #{time_range.to_s}"
    return false if time_range.nil?
    time_range.include? Time.now
  end

    # Формируем хэш, где ключ это id GSM группы,
    # а значение количество свободных карт
  def find_idle
    @idle_per_group.clear
    GsmGroup.all.each do |gsm_group|
      idle_lines = gsm_group.gsm_lines_dataset.where(:busy => false)
      next if idle_lines.count < 3
      @idle_per_group[gsm_group.id] = idle_lines.count - 2
    end
    logger.warn "find_idle: #{@idle_per_group.to_s}"
  end

    # Формируем массив состоящий из
    # попыток сценария
  def find_leads
    @attempts.clear
    scenario = Scenario.where(paused: false, finished: false).first
    return if scenario.nil?
    @idle_per_group.each do |group, count|
      min_attempt = scenario.scenario_attempts_dataset.where(gsm_group_id: group.to_i, success: false).group(:attempt).map(:attempt)#
      next if min_attempt.empty?
      min = min_attempt.sort!.fetch(0)
      next if min == scenario.max_retry
      attempts = if min == 0
                scenario.scenario_attempts_dataset.where(gsm_group_id: group, attempt: 0, inprogress: false, success: false).limit(count)
              else
                scenario.scenario_attempts_dataset.where(gsm_group_id: group, attempt: min, inprogress: false, success: false).and("updated_at < ?", Time.now - (scenario.retry_interval * 60)).limit(count)
              end
      @attempts.concat(attempts.map(:id))
    end
      # Ставим сценарий на паузу
      # в случае если массив пустой
    if scenario.scenario_attempts_dataset.exclude(attempt: scenario.max_retry).and(success: false).empty?
      logger.warn 'Finish him'
      scenario.update(finished: true)
    end
    logger.warn "find_leads: #{@attempts.to_s}"
  end

  def dial_out
    @attempts.each do |id|
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

      lines = GsmGroup[:id => attempt[:gsm_group_id]].gsm_lines_dataset.where(busy: false).map(:id)
      line = GsmLine[:id => lines.sample]
      dialer_call.update(:gsm_line_id => line.id)
      logger.warn "SIP/#{line.name}/#{attempt.lead[:callerid]}"
      outcall.dial "SIP/#{line.name}/#{attempt.lead[:callerid]}", :from => "0573414405", :timeout => 30
    end # attempts.each
  end
end # of class Dialer
