# frozen_string_literal: true

# For simplicity in the correction all the ruby classes were created into this same file
def solution(s)
  photos = PhotoList.new(s).parse
  album = Album.new(photos).organize
  AlbumDisplay.new(album).present
end

class PhotoList
  def initialize(input, photo_item = nil)
    @input = input
    @photo_item = photo_item || PhotoList::PhotoItem.new
  end

  def parse
    items.map { |item| @photo_item.build(item) }
  end

  protected

  def items
    @input.split("\n").slice(0, 99)
  end
end

class PhotoList::PhotoItem
  def initialize(property = nil)
    @property = property || PhotoList::Property.new
  end

  def build(item)
    item_values(item).map(&method(:build_property)).reduce(:merge)
  end

  protected

  def item_values(item)
    item.split(', ').each_with_index
  end

  def build_property(value, index)
    @property.build(value, index)
  end
end

class PhotoList::Property
  require 'date'
  def initialize(format = nil, factory = nil)
    @format = format || PhotoList::Format.new
    @factory = factory || PhotoList::Property::Factory.new
  end

  def build(value, index)
    { @format.name(index) => build_value(value, index) }
  end

  protected

  def build_value(value, index)
    type = @format.type(index)
    @factory.send(type).build(value)
  end
end

class PhotoList::Property::Factory
  def date_time
    PhotoList::Property::DateTime.new
  end

  def file_name
    PhotoList::Property::FileName.new
  end

  def default
    PhotoList::Property::Default.new
  end
end

class PhotoList::Property::DateTime
  def build(value)
    DateTime.parse(value)
  end
end

class PhotoList::Property::FileName
  def build(value)
    name, extension = value.split('.')
    { name: name, extension: extension }
  end
end

class PhotoList::Property::Default
  def build(value)
    value
  end
end

class PhotoList::Format
  FORMAT_LIST = [
    { name: :image_file, type: :file_name },
    { name: :city, type: :default },
    { name: :date, type: :date_time }
  ].freeze

  def type(index)
    FORMAT_LIST[index][:type]
  end

  def date_time?(index)
    type(index) == :date_time
  end

  def file_name?(index)
    type(index) == :file_name
  end

  def name(index)
    FORMAT_LIST[index][:name]
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
    @photos.each_with_index(&method(:add_to_city_group))
  end

  def add_to_city_group(photo, input_index)
    @city_groups[photo[:city]] ||= []
    @city_groups[photo[:city]] << photo.merge(input_index: input_index)
  end

  def sort_photos_by_date_within_group
    @city_groups.map(&method(:fit_group)).reduce(:merge)
  end

  def fit_group(city, photos)
    { city => photos.uniq(&method(:date)).sort_by(&method(:date)) }
  end

  def date(photo)
    photo[:date]
  end
end

class AlbumDisplay
  def initialize(album, photo_display = nil)
    @album = album
    @photo_display = photo_display || AlbumDisplay::PhotoDisplay.new
  end

  def present
    all_photos.sort_by(&method(:input_index)).map(&method(:show))
  end

  def input_index(photo)
    photo[:input_index]
  end

  protected

  def all_photos
    photo_groups.map(&method(:photos_with_group_data)).flatten
  end

  def photo_groups
    @album.values
  end

  def photos_with_group_data(photos)
    photos.each_with_index.map do |photo, group_index|
      photo.merge(group_index: group_index).merge(group_size: photos.length)
    end
  end

  def show(photo)
    @photo_display.present(photo)
  end
end

class AlbumDisplay::PhotoDisplay
  def initialize(index_display = nil)
    @index_display = index_display || AlbumDisplay::PhotoIndexDisplay.new
  end

  def present(photo)
    @photo = photo
    "#{city}#{photo_index}.#{file_extension}"
  end

  protected

  def city
    @photo[:city]
  end

  def photo_index
    @index_display.present(@photo)
  end

  def file_extension
    @photo[:image_file][:extension]
  end
end

class AlbumDisplay::PhotoIndexDisplay
  def present(photo)
    length = maximum_index_length(photo)
    index = current_index(photo)
    index.rjust(length, '0')
  end

  protected

  def current_index(photo)
    (photo[:group_index] + 1).to_s
  end

  def maximum_index_length(photo)
    photo[:group_size].to_s.length
  end
end
