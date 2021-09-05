# Represents an (x, y) coordinate.
class Vector2
  def initialize(x, y)
    @complex = Complex(x, y)
  end

  def size
    @complex.abs
  end

  def x
    @complex.real
  end

  def y
    @complex.imag
  end

  def x=(new_x)
    @complex = Complex(new_x, @complex.imag)
  end

  def y=(new_y)
    @complex = Complex(@complex.real, new_y)
  end

  def -(other)
    self + -1 * other
  end

  def +(other)
    case other
    when Complex
      other = Vector2.new(other.real, other.imag)
    when Numeric
      other = Vector2.new(other, 0)
    end
    Vector2.new(@complex.real + other.x, @complex.imag + other.y)
  end

  def distance_to(other_pos)
    Math.sqrt((x - other_pos.x).abs**2 + (y - other_pos.y).abs**2)
  end
end

def Vector2(x, y) # rubocop:disable Naming/MethodName
  Vector2.new(x, y)
end
