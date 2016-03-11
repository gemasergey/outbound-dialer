class Scenario < Sequel::Model
  one_to_many :scenario_attempts
  many_to_one :sound
  one_to_many :time_ranges
end
