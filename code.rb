def solution(s)
  photos = List.new(s).parse
  Album.new(photos).organize
end

class List
  FORMAT = [
    { name: :image_file, type: :file_name },
    { name: :city, type: :default },
    { name: :date, type: :date_time }
  ]

  def initialize(input, key_value = KeyValue.new(FORMAT))
    @input = input
    @key_value = key_value
  end

  def parse
    lines.map { |line| parse_line(line) }
  end

  protected

  def lines
    @input.split("\n")
  end

  def parse_line(line)
    values(line).map { |value, index| build_key_value(value, index) }.reduce(:merge)
  end

  def values(line)
    line.split(', ').each_with_index
  end

  def build_key_value(value, index)
    @key_value.build(value, index)
  end
end

class KeyValue
  def initialize(format)
    @format = format
  end
  def build(value, index)
    { @format[index][:name] => value }
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