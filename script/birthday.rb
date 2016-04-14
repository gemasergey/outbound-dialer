require 'rubygems'
require 'sequel'
require 'mysql2'
require 'date'

  # скрит предназначен для выгрузки именниников из базы Такси Диспетчер
  # в таблицу bday проекта ROBO
  # далее каждому из именниников направляется голосовой файл с поздравлением
begin
  taxi_db_conf = {
                  adapter: 'mysql2',
                  host: '192.168.0.101',
                  database: 'taxi_kharkov',
                  user: 'rbox',
                  password: 'rbox',
                  encoding: 'latin1'
                  }

  robo_db_conf = {
                  adapter: 'mysql2',
                  host: '127.0.0.1',
                  database: 'robo',
                  user: 'root',
                  password: '1221vthrehbq'
  }
  DBT = Sequel.connect(taxi_db_conf)
  DB = Sequel.connect(robo_db_conf)

  puts DBT[:refclients].exclude(birthdate: nil).first
  puts DB[:orders].first

  DBT.fetch("SELECT phone, birthdate FROM refclients WHERE MONTH(birthdate) = MONTH(NOW()) AND DAY(birthdate) = DAY(NOW())").each do |client|
    callerid = client[:phone].gsub(/\D/, '')
    #puts "#{callerid}-#{client[:birthdate]}"
    prefix = DB[:prefixes].where(name: callerid[0..2]).first
    next if prefix.nil?
    gsm_group_id = prefix[:gsm_group_id]
    DB[:bdays].insert(birthdate: Date.today, callerid: callerid, gsm_group_id: gsm_group_id,
                     attempt: 0, success: false, created_at: Time.now, updated_at: Time.now)
  end
end
