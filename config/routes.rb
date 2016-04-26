# encoding: utf-8

require 'call_controllers/bday_controller'
require 'call_controllers/carishere_controller'
require 'call_controllers/dialer_controller'

Adhearsion.router do

  # Specify your call routes, directing calls with particular attributes to a controller

  route 'default', CarIsHereController
end
