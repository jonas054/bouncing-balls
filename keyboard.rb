# Handles beyboard input.
class Keyboard
  def initialize(client)
    @client = client
    @pressed_key = {}
  end

  def button_down(id)
    @pressed_key[aliased(id)] = true

    return unless id == Gosu::KB_G

    shifted = pressed?(Gosu::KB_LEFT_SHIFT) || pressed?(Gosu::KB_RIGHT_SHIFT)
    @client.key_down(shifted ? 'G' : 'g')
  end

  def button_up(id)
    @pressed_key[aliased(id)] = nil
  end

  def pressed?(id)
    @pressed_key[aliased(id)]
  end

  def aliased(id)
    case id
    when Gosu::KB_A then Gosu::KB_LEFT
    when Gosu::KB_D then Gosu::KB_RIGHT
    else id
    end
  end
end
