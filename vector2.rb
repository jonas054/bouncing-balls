class Vector2
  def initialize(x, y) # rubocop:disable Naming/MethodParameterName
    @complex = Complex(x, y)
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
end

def Vector2(x, y) # rubocop:disable Naming/MethodName, Naming/MethodParameterName
  Vector2.new(x, y)
end
