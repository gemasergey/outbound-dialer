class DialerCall < Sequel::Model
  many_to_one :scenario_attempt

  def before_create
    self.created_at ||= Time.now
    super
  end

  def before_save
    self.updated_at ||= Time.now
    super
  end

end
