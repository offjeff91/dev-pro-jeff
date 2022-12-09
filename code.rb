def solution(s)
  # format = [ :image_file, :city, :date]
  # data = s.split("\n").map { |line| line.split(', ').each_with_index.map { |value, index| { format[index] => value } }.reduce(:merge) }
  data = ListParser.new(s).parse
  # write response for data
end

class ListParser
  FORMAT = [ :image_file, :city, :date]
  def initialize input
    @input = input
  end
  def parse
    lines.map { |line| parse_line(line) }
  end
  protected
  def lines
    @input.split("\n")
  end
  def parse_line(line)
    values(line).map { |value, index| build_hash(value, index) }.reduce(:merge)
  end
  def values(line)
    line.split(', ').each_with_index
  end
  def build_hash(value, index)
    { ListParser::FORMAT[index] => value }
  end
end