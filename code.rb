# frozen_string_literal: true

def solution(s)
  photos = PhotoList.new(s).parse
  album = Album.new(photos).organize
  AlbumDisplay.new(album).present
end

# For simplicity in the correction all the ruby classes were created into this same file

class PhotoList
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
    return date_time(value) if date_time?(index)
    return file_name(value) if file_name?(index)

    value
  end

  def type(index)
    @format_list[index][:type]
  end

  def date_time?(index)
    type(index) == :date_time
  end

  def date_time(value)
    DateTime.parse(value)
  end

  def file_name?(index)
    type(index) == :file_name
  end

  def file_name(value)
    name, extension = value.split('.')
    { name: name, extension: extension }
  end
end

class Album
  def initialize(photos)
    @photos = photos
    @city_groups = {}
  end

  def organize
    group_photos_by_city
    sort_photos_by_date_within_group
  end

  protected

  def group_photos_by_city
    @photos.each_with_index do |photo, input_index|
      add_to_city_group(photo, input_index)
    end
  end

  def add_to_city_group(photo, input_index)
    @city_groups[photo[:city]] ||= []
    @city_groups[photo[:city]] << photo.merge(input_index: input_index)
  end

  def sort_photos_by_date_within_group
    @city_groups.map { |city, photos| { city => organize_group(photos) } }.reduce(:merge)
  end

  def organize_group(photos)
    sort_photos_by_date(photos).map do |photo, group_index|
      photo.merge(group_index: group_index)
    end
  end

  def sort_photos_by_date(photos)
    photos.sort_by { |photo| photo[:date] }.each_with_index
  end
end

class AlbumDisplay
  def initialize(album)
    @album = album
  end

  def present
    photos.sort_by { |photo| photo[:input_index] }.map { |photo| show(photo) }
  end

  def photos
    @album.values.flatten
  end

  protected

  def show(photo)
    "#{photo[:city]}#{photo_index(photo)}.#{photo[:image_file][:extension]}"
  end

  def photo_index(photo)
    length = maximum_index_length(photo)
    index = current_index(photo)
    index.rjust(length, '0')
  end

  def current_index(photo)
    (photo[:group_index] + 1).to_s
  end

  def maximum_index_length(photo)
    @album[photo[:city]].size.to_s.length
  end
end
