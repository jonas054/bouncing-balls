require 'gosu'
require './vector2'
require './circle'
require './ball'

class GosuExample < Gosu::Window
  include Circle

  NR_OF_BALLS = 8
  WALL_HEIGHT = 50

  def initialize
    super(1500, 800, fullscreen: false)
    @balls = []
  end

  def update
    if @balls.size < NR_OF_BALLS and rand < 0.01
      @balls << Ball.new(width / 2, 0)
    end
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
    draw_rect(0, 0, width, height, Gosu::Color::BLUE)
    @balls.each_with_index do |ball, ix|
      draw_circle_with_border(ball.pos, Ball::SIZE,
                              Gosu::Color.from_hsv(ix * 40, ball.pos.y / height,
                                                   1),
                              5, Gosu::Color::BLACK)
    end
    draw_rect(0, height - WALL_HEIGHT, width, WALL_HEIGHT, Gosu::Color::GREEN)
  end
end

GosuExample.new.show
