require 'gosu'
require './vector2'
require './circle'

class GosuExample < Gosu::Window
  include Circle

  NR_OF_BALLS = 8
  BALL_SIZE = 50
  WALL_HEIGHT = 50
  WALL_Y_POS = -WALL_HEIGHT
  BUMP = 1.2

  def initialize
    super(1500, 800, fullscreen: false)
    @ball_pos = []
    @gravity = 0.4i
    @ball_speed = Array.new(NR_OF_BALLS) { Vector2(rand(-2.0..2), 0) }
  end

  def update
    if @ball_pos.size < NR_OF_BALLS and rand < 0.01
      @ball_pos << Vector2(width / 2, 0)
    end
    @ball_pos.each_with_index do |pos, ix|
      speed = @ball_speed[ix]
      if pos.y + BALL_SIZE >= height + WALL_Y_POS
        speed.y = -speed.y.abs * 0.9 - 1
        speed.x *= 0.99
      else
        speed.y += @gravity.imag
      end
      if pos.x + BALL_SIZE >= width || pos.x - BALL_SIZE < 0
        speed.x = -speed.x
        pos.x += (width/2 - pos.x) / 200 # Avoid sticking to edge
      end
      speed.x *= 0.999

      @ball_pos.each_with_index do |pos2, ix2|
        next if ix2 == ix
        distance = Math.sqrt((pos.x - pos2.x).abs**2 + (pos.y - pos2.y).abs**2)
        if distance < BALL_SIZE * 2
          # pos.x -= (pos2.x - pos.x) / 15
          # pos.y -= (pos2.y - pos.y) / 15
          speed2 = @ball_speed[ix2]
          delta = Vector2((speed.x + speed2.x) / 2, (speed.y + speed2.y) / 2)
          speed.x += pos.x < pos2.x ? -BUMP : BUMP
          speed.y += pos.y < pos2.y ? -BUMP : BUMP
        end
      end

      pos.x += speed.x
      pos.y += speed.y
    end
  end

  def draw
    draw_rect(0, 0, width, height, Gosu::Color::BLUE)
    @ball_pos.each_with_index do |pos, ix|
      draw_circle_with_border(pos, BALL_SIZE,
                              Gosu::Color.from_hsv(ix*40, pos.y / height, 1),
                              5, Gosu::Color::BLACK)
    end
    draw_rect(0, height + WALL_Y_POS, width,
              WALL_HEIGHT, Gosu::Color::GREEN)
  end
end

GosuExample.new.show
