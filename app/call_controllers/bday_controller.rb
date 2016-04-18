class BirthDayController < Adhearsion::CallController

  def run
    answer
    play "/opt/rbox/sounds/bday"
  rescue Exception => ex
    logger.error "BdayController" + ex.backtrace
    return
  end

end
