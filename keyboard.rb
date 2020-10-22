# Handles beyboard input.
class Keyboard
  def initialize
    @pressed_key = {}
  end

  def button_down(id)
    case id
    when Gosu::KB_LEFT, Gosu::KB_A then @pressed_key[Gosu::KB_LEFT] = true
    when Gosu::KB_RIGHT, Gosu::KB_D then @pressed_key[Gosu::KB_RIGHT] = true
    end
  end

  def button_up(id)
    case id
    when Gosu::KB_LEFT, Gosu::KB_A then @pressed_key[Gosu::KB_LEFT] = nil
    when Gosu::KB_RIGHT, Gosu::KB_D then @pressed_key[Gosu::KB_RIGHT] = nil
    end
  end

  def pressed?(id)
    @pressed_key[id]
  end
end
