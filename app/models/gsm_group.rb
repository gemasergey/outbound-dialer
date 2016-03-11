class GsmGroup < Sequel::Model
  one_to_many :gsm_lines
  one_to_many :prefixes
end
