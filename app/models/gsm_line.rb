class GsmLine < Sequel::Model
  many_to_one :gsm_group
end
