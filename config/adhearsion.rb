# encoding: utf-8

root_path = File.expand_path File.dirname('../')

require 'socket'

Adhearsion.config do |config|

  # Centralized way to specify any Adhearsion platform or plugin configuration
  # - Execute rake config:show to view the active configuration values
  #
  # To update a plugin configuration you can write either:
  #
  #    * Option 1
  #        Adhearsion.config.<plugin-name> do |config|
  #          config.<key> = <value>
  #        end
  #
  #    * Option 2
  #        Adhearsion.config do |config|
  #          config.<plugin-name>.<key> = <value>
  #        end

  config.development do |dev|
    dev.platform.logging.level = :debug
  end

  config.production do |pro|
    pro.platform.logging.level = :debug
  end

  ##
  # Use with Rayo (eg Voxeo PRISM or FreeSWITCH mod_rayo)
  #
  # config.punchblock.username = "usera@freeswitch.local-dev.mojolingo.com" # Your XMPP JID for use with Rayo
  # config.punchblock.password = "1" # Your XMPP password

  ##
  # Use with Asterisk
  #
   config.punchblock.platform = :asterisk # Use Asterisk
   config.punchblock.username = "ahn" # Your AMI username
   config.punchblock.password = "dtxyjcnm" # Your AMI password
   config.punchblock.host = "127.0.0.1" # Your AMI host

   # Active Record
  config.adhearsion_activerecord do |ar|
    ar.username = "root"
    ar.password = "1221vthrehbq"
    ar.database = "robo"
    ar.adapter  = "mysql2" # i.e. mysql, sqlite3
    ar.host     = "localhost"    # i.e. localhost
    ar.port     = "3306".to_i # i.e. 3306
  end

end
