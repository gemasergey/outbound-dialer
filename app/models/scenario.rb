class Scenario < Sequel::Model
  one_to_many :scenario_attempts
  many_to_one :sound
  one_to_many :time_ranges

    # Преверяем есть ли на данный момент
    # активный сценарий подходящий по времени
  def self.active?
    scenario = Scenario.where(paused: false, finished: false).first
    return false if scenario.nil?
    time_range = scenario.time_ranges_dataset.where(date: Date.today).first
    return false if time_range.nil?
    return false unless time_range.include?(Time.now)
    return false if scenario.finishing?
    true
  end

    # Возвращает массив состоящий из
    # попыток активного сценария
  def self.active_attempts
    return unless Scenario.active?
    scenario = Scenario.where(paused: false, finished: false).first
    GsmGroup.idle_per_group.each do |group, count|
      min_attempt = scenario.scenario_attempts_dataset.select(:attempt).where(gsm_group_id: group.to_i, success: false).group(:attempt).map(:attempt)
      next if min_attempt.empty?
      min = min_attempt.sort!.fetch(0)
      next if min == scenario.max_retry
      scenario.scenario_attempts_dataset.where(gsm_group_id: group, attempt: min, inprogress: false, success: false).and("updated_at < ? OR attempt='0'",
               Time.now - (scenario.retry_interval * 60)).limit(count).each do |attempt|
                 yield attempt
               end
    end
  end

    # Ставим сценарий на финиш
    # если достигли конца
  def finishing?
    if scenario_attempts_dataset.exclude(attempt: max_retry).and(success: false).limit(1).empty?
      self.finished = true
      save
      return true
    else
      return false
    end
  end

end
