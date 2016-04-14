class CarIsHereController < Adhearsion::CallController

  def run
    answer
    order = metadata[:order]
    logger.info "словами заказ #{order.values}"
    order.words.each do |word|
      begin
        play word
      rescue
        next
      end
    end
  rescue Exception => ex
    return
  end

end
