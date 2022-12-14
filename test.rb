require './solution'

TEST_SIZE = 20

class Test
  def load(size)
    (1..size).map(&method(:build)).join("\n")
  end
  protected
  def build(_n)
    [ file, city, date ].join(',')
  end

  def file
    "photo.#{extension}"
  end

  def extension
    rand(5) > 0 ? valid_extensions.sample : invalid_extensions.sample
  end

  def valid_extensions
    %w[ jpg png jpeg ]
  end

  def invalid_extensions
    %w[ mp3 doc x ]
  end

  def city
    rand(5) > 0 ? valid_cities.sample : invalid_cities.sample
  end

  def valid_cities
    [ 'Rio', 'SaoPaulo', 'Cordoba', 'BuenosAires', 'Montevideu' ]
  end

  def invalid_cities
    [ 'Rio de Janeiro', 'NY 2020', '??' ]
  end

  def date from = 0.0, to = Time.now
    result = Time.at(from + rand * (to.to_f - from.to_f))
    result.strftime("%F %T")
  end
end


def run
  input = Test.new.load(TEST_SIZE)
  puts "INPUT:"
  puts input
  puts "SOLUTION:"
  puts solution(input)
end


run