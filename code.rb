def solution(s)
  photos = List.new(s).parse
  Album.new(photos).organize
end

# For simplicity in the correction all the ruby classes were created in this file

class List
  FORMAT_LIST = [
    { name: :image_file, type: :file_name },
    { name: :city, type: :default },
    { name: :date, type: :date_time }
  ].freeze

  def initialize(input, key_value = KeyValue.new(FORMAT_LIST))
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
  require 'date'
  def initialize(format_list)
    @format_list = format_list
  end

  def build(value, index)
    { key(index) => build_value(value, index) }
  end

  protected

  def key(index)
    @format_list[index][:name]
  end

  def build_value(value, index)
    return date_time_value(value) if date_time?(index)
    return file_name_value(value) if file_name?(index)

    value
  end

  def type(index)
    @format_list[index][:type]
  end

  def date_time?(index)
    type(index) == :date_time
  end

  def date_time_value(value)
    DateTime.parse(value)
  end

  def file_name?(index)
    type(index) == :file_name
  end

  def file_name_value(value)
    name, extension = value.split('.')
    { name: name, extension: extension }
  end
end

class Album
  def initialize(photos)
    @photos = photos
    @city_collection = {}
  end

  def organize
    @photos.each_with_index { |photo, index| add_to_city_collection(photo, index) }
    @city_collection.map { |city, photos | { city => sort_photos_by_date(photos) } }.reduce(:merge)
  end

  protected

  def add_to_city_collection(photo, index)
    @city_collection[photo[:city]] ||= []
    @city_collection[photo[:city]] << photo.except(:city).merge(index: index)
  end

  def sort_photos_by_date(photos)
    photos.sort_by { |photo| photo[:date] }
  end
end
