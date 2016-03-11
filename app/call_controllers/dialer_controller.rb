class DialerController < Adhearsion::CallController

  attr_accessor :number, :attempt

  def run
    answer
    logger.warn "Controller: #{metadata.to_s}"
    sound = Scenario[:id => metadata[:scenario]].sound
    wav = sound.wav_file_name
    play "/opt/robo/public/sounds/#{sound.id}/#{wav}"
  end

end
