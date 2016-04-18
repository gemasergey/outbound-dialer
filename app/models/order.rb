class Order < Sequel::Model
  many_to_one :gsm_group

  def before_save
    self.updated_at = Time.now
    super
  end

    # Формируем массив id заказов hot_orders для
    # авто сообщения клиентам
  def self.hot_orders
    return unless Order.ready?
    GsmGroup.idle_per_group.each do |group, count|
      Order.where(finished: false, inprogress: false, gsm_group_id: group).and("updated_at < ? or attempt = '0'", Time.now - 40).limit(count).each do |order|
        yield order
      end
    end
  end

  def self.ready?
    orders = Order.where(finished: false, inprogress: false).first
    !orders.nil?
  end

  # Закрываем отказы
  # устанавливая водителя 000
  def self.ooo
    orders = Order.where("driver = '00' AND updated_at < ?", Time.now - 1500 )
    orders.each do |order|
      yield order
    end
  end

    # Формируем звонок по всем id в
    # hot_orders
  def dial_out
    next_try = self.attempt + 1
    self.set(attempt: next_try, inprogress: true)
    self.save
    outcall = Adhearsion::OutboundCall.new
    outcall.execute_controller_or_router_on_answer CarIsHereController, {order: self}

      # Обрабатываем событие по ответу
    outcall.on_answer do
      outcall.tag 'answered'
      # Запись в БД параметра callsetup
      update(finished: true)
      answer
    end

    # Обрабатываем событие Hangup
    outcall.on_end do
      # Все попытки закончились?
      if attempt == 5
        update(finished: true)
        wo_answer
      end
      update(inprogress: false)
    end

    line = GsmGroup[:id => self.gsm_group_id].random_idle_line
    outcall.dial "SIP/#{line.name}/#{self.callerid}", :from => "0573414405", :timeout => 30
  end # of dial_out

    # Преобразуем цифры номера в слова
    #
  def words
    @dir = '/opt/rbox/sounds/'
    @dirdigits = '/opt/rbox/sounds/digits/'
    @words = Array.new

      # отказ
      # водитель 00
    if driver == '00'
      return [@dir + 'otkaz']
    end

    @words.push(@dir + 'bi_bi')
    model_tsvet_carnum
    @words.push(@dir + 'repeat')
    model_tsvet_carnum
    @words.push(@dir + 'goodbye')

    return @words
  end #of words

    # Сообщили клиенту параметры машины
    # обратная связь с Такси Диспетчер
  def answer
    socket = TCPSocket.open('192.168.0.101', 333)
    socket.puts "OSD<br>#{self.order}<br>3<br>1"
    response = socket.gets
    socket.close if socket
    return response.to_s
  rescue Exception => ex
    return "Error in Order#answer: #{ex.message}"
  end

    # Не удалось дозвониться клиенту
    # отправляем номер водителю
  def wo_answer
    res = HTTP.get("http://192.168.0.101:8084/callphone/nedozwon.php?ordernum=#{self.order}&phone=#{self.callerid}")
    return res.to_s
  rescue Exception => ex
    return "Error in Order#wo_answer: #{ex.message}"
  end

    # Заказ отказан, через
    # 25 минут закрываем в Такси Диспетчер
  def close
    socket = TCPSocket.open('192.168.0.101', 333)
    socket.puts "NIS<br>closebyordernum<br>#{self.order}<br><br>2<br>"
    response = socket.gets
    socket.close if socket
    self.update(driver: '000')
    return response.to_s
  rescue Exception => ex
    return "Error in Order#close: #{ex.message}"
  end


  private

    # Добавляем в словарь модель
    # цвет, номер
  def model_tsvet_carnum
    @words.push(@dir + self[:model]) unless self[:model].empty?
    @words.push(@dir + 'tsvet', @dir + self.color.gsub(/\s+/, "")) unless self.color.empty?
    return if self.carnum.empty?
    @words.push(@dir +'nomer')
    case self[:carnum].length
      when 4
        two_digits self.carnum[0..1]
        two_digits self.carnum[2..3]
      when 5
        two_digits self.carnum[0..1]
        three_digits self.carnum[2..4]
    end # case
  end

    # Представляем номер из 2
    # цифр в виде слов
  def two_digits number
    f = {'0'=> '0', '1'=> number, '2'=> '20', '3'=> '30', '4'=> '40', '5'=> '50', '6'=> '60', '7'=> '70', '8'=> '80', '9'=> '90'}
    @words.push(@dirdigits + f.fetch(number[0]))
    @words.push(@dirdigits + number[1]) unless number[0] == '1' || number[1] == '0'
  end

    # Представляем номер из 3
    # цифр в виде слов
  def three_digits number
    f = {'0'=> '0', '1'=> '100', '2'=> '200', '3'=> '300', '4'=> '400', '5'=> '500', '6'=> '600', '7'=> '700', '8'=> '800', '9'=> '900'}
    @words.push(@dirdigits + f[number[0]])
    two_digits number[1..2]
  end

end
