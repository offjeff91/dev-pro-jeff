# frozen_string_literal: true

# To facilitate the execution of the code all classes on which the solution depends were created in this same file
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
      photos: built_items.reject(&method(:invalid?)),
      errors: built_items.select(&method(:invalid?))
    }
  end

  protected

  def built_items
    @built_items ||= items.map { |item, input_index| @photo_item.build(item, input_index) }
  end

  def items
    @input.split("\n").slice(0, 99).each_with_index
  end

  def invalid?(item)
    item[:invalid?]
  end
end

# For validations and formatting, active_model could have been used
# But it was not used, so this code test doesn't need external libs to be executed
class PhotoList::Format
  FORMAT_LIST = [
    {
      name: :image_file,
      type: :file_name,
      validations: [:only_letter_in_file_name],
      formats: [],
      extensions: %w[jpg png jpeg]
    },
    {
      name: :city,
      type: :default,
      validations: [:only_letter],
      formats: %i[capitalize slice],
      length: { min: 1, max: 20 }
    },
    {
      name: :date,
      type: :date_time,
      validations: [:year_range],
      year: { from: 2000, to: 2020 },
      formats: []
    }
  ].freeze

  def type(index)
    FORMAT_LIST[index][:type]
  end

  def name(index)
    FORMAT_LIST[index][:name]
  end

  def get(index)
    FORMAT_LIST[index]
  end

  def size
    FORMAT_LIST.size
  end
end

class PhotoList::PhotoItem
  def initialize(format = nil, property = nil)
    @format = format || PhotoList::Format.new
    @property = property || PhotoList::Property.new(@format)
  end

  def build(item, input_index)
    build_item(item).merge(input_index: input_index)
  end

  protected

  def build_item(item)
    build_object(item)
  rescue PhotoList::ValidationError => e
    invalid_response(e)
  end

  def build_object(item)
    validate_structure(item)
    item_values(item).map(&method(:build_property)).reduce(:merge)
  end

  def invalid_response(validation_error)
    { invalid?: true, validation_message: validation_error.message }
  end

  def item_values(item)
    item.split(',').slice(0, @format.size).each_with_index
  end

  def build_property(value, index)
    @property.build(value.strip, index)
  end

  def validate_structure(item)
    raise PhotoList::ValidationError::FormatError if item_values(item).size < @format.size
  end
end

class PhotoList::Property
  def initialize(format, factory = nil)
    @format = format
    @factory = factory || PhotoList::Property::Factory.new
  end

  def build(value, index)
    { @format.name(index) => build_value(value, index) }
  end

  protected

  def build_value(value, index)
    type = @format.type(index)
    property = @factory.send(type)
    item_format = @format.get(index)
    property.build(value, item_format)
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

class PhotoList::Property::Base
  def initialize(validation = nil, formatter = nil)
    @validation = validation || PhotoList::Validation.new
    @formatter = formatter || PhotoList::Formatter.new
  end

  def build(value, item_format)
    validate(value, item_format)
    item = create(value)
    format(item, item_format)
  end

  private

  def validate(value, item_format)
    validations.concat(item_format[:validations]).each do |validation_key|
      run_validation(validation_key, value, item_format)
    end
  end

  def run_validation(validation_key, value, item_format)
    validation_rule = @validation.send(validation_key)
    raise validation_rule[:error], item_format unless validation_rule[:rule].call(value, item_format)
  end

  def format(item, item_format)
    value = item
    item_format[:formats].each do |format_key|
      format_action = @formatter.send(format_key)
      value = format_action[:action].call(value, item_format)
    end
    value
  end
end

class PhotoList::Property::DateTime < PhotoList::Property::Base
  require 'date'

  protected

  def create(value)
    DateTime.parse(value)
  end

  def validations
    [:date_time_format]
  end
end

class PhotoList::Property::FileName < PhotoList::Property::Base
  protected

  def create(value)
    name, extension = value.split('.')
    { name: name, extension: extension }
  end

  def validations
    %i[file_name_format extension]
  end
end

class PhotoList::Property::Default < PhotoList::Property::Base
  protected

  def create(value)
    value
  end

  def validations
    []
  end
end

class PhotoList::Validation
  def file_name_format
    {
      rule: ->(value, _item_format) { value.split('.').size == 2 },
      error: PhotoList::ValidationError::FileNameFormatError
    }
  end

  def only_letter
    {
      rule: ->(value, _item_format) { /^[A-z]+$/.match?(value) },
      error: PhotoList::ValidationError::OnlyLetterError
    }
  end

  def extension
    {
      rule: ->(value, item_format) { item_format[:extensions].include?(value.split('.').last) },
      error: PhotoList::ValidationError::ImageExtensionError
    }
  end

  def only_letter_in_file_name
    {
      rule: ->(value, _item_format) { /^[A-z]+$/.match?(value.split('.').first) },
      error: PhotoList::ValidationError::OnlyLetterError
    }
  end

  def date_time_format
    {
      rule: lambda do |value, _item_format|
        regex = /[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1]) (2[0-3]|[01][0-9]):[0-5][0-9]:[0-5][0-9]/
        regex.match?(value)
      end,
      error: PhotoList::ValidationError::DateTimeFormatError
    }
  end

  def year_range
    {
      rule: lambda do |value, item_format|
        from, to = item_format[:year].values
        Date.parse(value).year.between?(from, to)
      end,
      error: PhotoList::ValidationError::YearRangeError
    }
  end
end

class PhotoList::Formatter
  def capitalize
    {
      action: ->(value, _item_format) { value.capitalize }
    }
  end

  def slice
    {
      action: lambda do |value, item_format|
        min, max = item_format[:length].values
        value.slice(min - 1, max)
      end
    }
  end
end

class PhotoList::ValidationError < StandardError; end

class PhotoList::ValidationError::FormatError < PhotoList::ValidationError
  def message
    'line has no basic well-formed structure'
  end
end

class PhotoList::ValidationError::OnlyLetterError < PhotoList::ValidationError
  def initialize(item_format)
    super
    @item_format = item_format
  end

  def message
    "#{@item_format[:name]} should contain only letters"
  end
end

class PhotoList::ValidationError::ImageExtensionError < PhotoList::ValidationError
  def initialize(item_format)
    super
    @item_format = item_format
  end

  def message
    "allowed extensions: #{@item_format[:extensions]}"
  end
end

class PhotoList::ValidationError::FileNameFormatError < PhotoList::ValidationError
  def initialize(item_format)
    super
    @item_format = item_format
  end

  def message
    "#{@item_format[:name]} expects <name>.<extension> format"
  end
end

class PhotoList::ValidationError::DateTimeFormatError < PhotoList::ValidationError
  def message
    'date time expects the format yyyy-mm-dd hh:mm:ss'
  end
end

class PhotoList::ValidationError::YearRangeError < PhotoList::ValidationError
  def initialize(item_format)
    super
    @item_format = item_format
  end

  def message
    from, to = @item_format[:year].values

    "date time expects year from #{from} to #{to}"
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
    @photos.each(&method(:add_to_city_group))
  end

  def add_to_city_group(photo)
    @city_groups[photo[:city]] ||= []
    @city_groups[photo[:city]] << photo
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
    all_photos.sort_by(&method(:input_index)).map(&method(:show)).join("\n")
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
