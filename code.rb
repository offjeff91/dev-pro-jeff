def solution(s)
  # format = [ :image_file, :city, :date]
  # data = s.split("\n").map { |line| line.split(', ').each_with_index.map { |value, index| { format[index] => value } }.reduce(:merge) }
  photos = List.new(s).parse
  x = Album.new(photos).organize
  # write response for data
end

class List
  FORMAT = [:image_file, :city, :date]

  def initialize(input)
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
    { List::FORMAT[index] => value }
  end
end

class Album
  def initialize(photos)
    @photos = photos
    @city_collection = {}
  end

  def organize
    @photos.each { |photo| add_to_city_collection(photo) }
    @city_collection
  end

  protected
  def add_to_city_collection(photo)
    @city_collection[photo[:city]] ||= []
    @city_collection[photo[:city]] << photo.except(:city)
  end
end