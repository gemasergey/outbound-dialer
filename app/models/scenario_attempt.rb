class ScenarioAttempt < Sequel::Model
  many_to_one :scenario
  many_to_one :lead
  one_to_many :dialer_calls

  def before_save
    self.updated_at ||= Time.now
    super
  end

end
