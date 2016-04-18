# encoding: utf-8

Adhearsion::Events.draw do

  # Register global handlers for events
  #
  # eg. Handling Punchblock events
  # punchblock do |event|
  #   ...
  # end
  #
  # eg Handling PeerStatus AMI events
  # ami :name => 'PeerStatus' do |event|
  #   ...
  # end
  #

  after_initialized do |event|
    logger.info "Application initialized.!!!!!!!!!!!!"
    Sequel::DATABASES.each do |d|
      d.sql_log_level = :debug
      d.loggers << logger
    end
  end

  ami :name => 'Newchannel' do |event|
    dirty_chan = event.attributes.fetch('Channel','')
    if dirty_chan[4..6]  ==  'gsm'
      logger.info "New GSM channel #{dirty_chan}"
      ChannelsStatus.first.update("#{dirty_chan[4..8]}" => 'blocked')
      GsmLine.where(name: dirty_chan[4..8]).first.update(busy: true)
    end
  end

  ami :name => 'Hangup' do |event|
    dirty_chan=event.attributes['Channel']
    if dirty_chan[4..6]  ==  'gsm'
      logger.info "Hangup GSM channel #{dirty_chan}"
      ChannelsStatus.first.update("#{dirty_chan[4..8]}" => 'work')
      GsmLine.where(name: dirty_chan[4..8]).first.update(busy: false)
    end
  end
end
