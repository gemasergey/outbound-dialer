module Robo
  module ControllerMethods
    # The methods are defined in a normal method the user will then mix in their CallControllers
    # The following also contains an example of configuration usage
    #
    def greet(name)
      play "#{Adhearsion.config[:robo].greeting}, #{name}"
    end
  end
end
