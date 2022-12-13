# frozen_string_literal: true

# For simplicity in the correction all the ruby classes were created into this same file
def solution(s)
  photo_list = PhotoList.new(s).parse
  photos, errors = photo_list.values
  album = Album.new(photos).organize
  AlbumDisplay.new(album, errors).present
end

class PhotoList
  def initialize(input, photo_item = nil)
    @input = input
    @photo_item = photo_item || PhotoList::PhotoItem.new
  end

  def parse
    {
      photos: built_items.reject { |item| item[:invalid?] },
      errors: built_items.select { |item| item[:invalid?] }
    }
  end

  protected

  def built_items
    @built_items ||= items.map { |item, input_index| @photo_item.build(item, input_index) }
  end

  def items
    @input.split("\n").slice(0, 99).each_with_index
  end
end

class PhotoList::PhotoItem
  def initialize(property = nil)
    @property = property || PhotoList::Property.new
  end

  def build(item, input_index)
    build_item(item).merge(input_index: input_index)
  end

  protected

  def build_item(item)
    build_object(item)
  rescue PhotoList::ValidationError => validation_error
    invalid_response(validation_error)
  end

  def build_object(item)
    item_values(item).map(&method(:build_property)).reduce(:merge)
  end

  def invalid_response(validation_error)
    { invalid?: true, validation_message: validation_error.message }
  end

  def item_values(item)
    item.split(',').each_with_index
  end

  def build_property(value, index)
    @property.build(value.strip, index)
  end
end

class PhotoList::Property
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
    property = @factory.send(type)
    property.build(value)
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
  require 'date'
  def build(value)
    DateTime.parse(value)
  end
end

class PhotoList::Property::FileName
  def build(value)
    name, extension = value.split('.')
    raise PhotoList::ValidationError::OnlyLetterOnFileNameError unless /^[A-z]+$/.match?(name)
    { name: name, extension: extension }
  end
end

class PhotoList::Property::Default
  def build(value)
    raise PhotoList::ValidationError::TOOLONG  if value.length > 7
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

  def name(index)
    FORMAT_LIST[index][:name]
  end
end

class PhotoList::ValidationError < StandardError; end

class PhotoList::ValidationError::TOOLONG < PhotoList::ValidationError
  def message
    'TOOLONG'
  end
end

class PhotoList::ValidationError::OnlyLetterOnFileNameError < PhotoList::ValidationError
  def message
    'file name should contain only letters'
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
    @city_groups[photo[:city]] << photo.merge(input_index: input_index) #remove
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
  def initialize(album, errors, photo_display = nil)
    @album = album
    @errors = errors
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
    photos.concat(@errors)
  end

  def photos
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
    return "Error: #{photo[:validation_message]}" if photo[:invalid?]
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
