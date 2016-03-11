class Lead < Sequel::Model
  one_to_many :scenario_attempts

end
