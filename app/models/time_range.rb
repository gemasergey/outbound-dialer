class TimeRange < Sequel::Model
  many_to_one :scenario

  def include? time
    range = to_sec(start)..to_sec(stop)
    range === to_sec(time)
  end

  private

  def to_sec time
    (time.hour * 3600) + (time.min * 60)
  end
end
