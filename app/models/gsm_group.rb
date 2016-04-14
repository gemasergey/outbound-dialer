class GsmGroup < Sequel::Model
  one_to_many :gsm_lines
  one_to_many :prefixes

    # Возвращает хэш, где ключ это id GSM группы,
    # а значение количество свободных карт
  def self.idle_per_group
    idle_per_group = Hash.new
    GsmGroup.all.each do |gsm_group|
      lines = gsm_group.gsm_lines_dataset.where(:busy => false).count
      next if lines < 3
      idle_per_group[gsm_group.id] = lines - 2
    end
    return idle_per_group
  end

    # Возвращает случайную
    # свободную линию
  def random_idle_line
    lines = self.gsm_lines_dataset.where(busy: false).map(:id)
    return GsmLine[:id => lines.sample]
  end
end
