class TimeRange < Sequel::Model
  many_to_one :scenario

    # Проверяем входит ли заданное время
    # в интервал между start - stop
  def include? time
    range = to_sec(start)..to_sec(stop)
    range === to_sec(time)
  end

  private

    # Преобразование часов и минут
    # в секунды
  def to_sec time
    (time.hour * 3600) + (time.min * 60)
  end
end
