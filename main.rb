require 'gosu'
require './vector2'
require './circle'
require './ball'

class GosuExample < Gosu::Window
  include Circle

  NR_OF_BALLS = 16
  WALL_HEIGHT = 50
  FONT_SIZE = 40

  def initialize
    super(1500, 800, fullscreen: false)
    @balls = []
    @font = Gosu::Font.new(self, 'Arial', FONT_SIZE)
  end

  def update
    @balls << Ball.new(width / 2, 0) if (@balls.size < NR_OF_BALLS) && (rand < 0.01)
    threads = @balls.map do |ball|
      Thread.new do
        ball.handle_collisions(@balls)
        ball.bounce_on_floor_if_colliding(height - WALL_HEIGHT)
        ball.bounce_on_wall_if_colliding(width)
        ball.fall
        ball.move
      end
    end
    threads.each { |t| t.join }
  end

  def draw
    draw_rect(0, height - WALL_HEIGHT, width, WALL_HEIGHT, Gosu::Color::GREEN)
    @balls.each_with_index do |ball, _ix|
      draw_circle(Vector2(ball.pos.x, height - WALL_HEIGHT - Ball::SIZE / 2),
                  100 * Ball::SIZE / (height - ball.pos.y).abs,
                  Gosu::Color.from_hsv(120, 0.8, 0.5))
    end
    draw_rect(0, 0, width, height - WALL_HEIGHT, Gosu::Color::BLUE)
    @balls.each_with_index do |ball, ix|
      hue = ix * 25 % 360
      draw_circle_with_border(ball.pos, Ball::SIZE,
                              Gosu::Color.from_hsv(hue, ball.pos.y / height,
                                                   1),
                              2, Gosu::Color::BLACK)
      @font.draw_text(hue,
                      ball.pos.x - (hue.to_s.length * FONT_SIZE) / 3,
                      ball.pos.y - FONT_SIZE / 2,
                      0, 1, 1,
                      Gosu::Color::BLACK)
    end
  end
end

GosuExample.new.show
