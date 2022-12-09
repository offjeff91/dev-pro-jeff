def solution(s)
  format = [ :image_file, :city, :date]
  data = s.split("\n").map { |line| line.split(', ').each_with_index.map { |value, index| { format[index] => value } }.reduce(:merge) }
end