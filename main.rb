require 'gosu'
require './vector2'
require './circle'
require './ball'

# The main class.
class BouncingBalls < Gosu::Window
  include Circle

  WHITE = Gosu::Color::WHITE
  WALL_HEIGHT = 50
  FONT_SIZE = 40
  CROSSHAIR_LENGTH = 20

  def initialize
    super(1500, 800, fullscreen: false)
    @nr_of_balls = 3
    @balls = [new_ball]
    @font = Gosu::Font.new(self, 'Arial', FONT_SIZE)
  end

  def update
    if @pause
      @pause -= 1
      if @pause == 0
        @pause = nil
        @nr_of_balls = @nr_of_balls * 4 / 3
        @balls = [new_ball]
      end
    elsif @balls.compact.empty?
      @pause = 100
    else
      update_balls
      @crosshair = Vector2(mouse_x, mouse_y)
      @hit_radius -= 1 if @hit_radius && @hit_radius > 0
    end
  end

  def button_down(id)
    return unless id == Gosu::MS_LEFT

    @crosshair = Vector2(mouse_x, mouse_y)
    @hit = Vector2(mouse_x, mouse_y)
    (0...@nr_of_balls).each do |ix|
      next unless @balls[ix]
      next unless @balls[ix].distance_to(@crosshair) < Ball::SIZE

      @balls[ix] = nil
      @hit_radius = 15
    end
  end

  def draw
    draw_rect(0, height - WALL_HEIGHT, width, WALL_HEIGHT, Gosu::Color::GREEN)

    @balls.compact.each { |ball| draw_shadow(ball) }

    draw_rect(0, 0, width, height - WALL_HEIGHT, Gosu::Color::BLUE)

    unless @pause
      @font.draw_text("#{@balls.compact.size}/#{@nr_of_balls} balls", 30, 30, 0, 1, 1, WHITE)
    end

    @balls.each_with_index.select { |ball, _| ball }.each { |ball, ix| draw_ball(ball, ix) }

    if @pause
      draw_message
    else
      draw_circle(@hit, @hit_radius, WHITE) if @hit
      draw_crosshair_with_shadow(@crosshair.x, @crosshair.y) if @crosshair
    end
  end

  private

  def update_balls
    @balls << new_ball if (@balls.size < @nr_of_balls) && (rand < 0.01)

    threads = @balls.compact.map do |ball|
      Thread.new do
        ball.handle_collisions(@balls)
        ball.bounce_on_floor_if_colliding(height - WALL_HEIGHT)
        ball.bounce_on_wall_if_colliding(width)
        ball.fall
        ball.move
      end
    end
    threads.each(&:join)
  end

  def new_ball
    Ball.new(width / 2, 0)
  end

  def draw_shadow(ball)
    draw_circle(Vector2(ball.pos.x, height - WALL_HEIGHT - Ball::SIZE / 2),
                500 * Ball::SIZE / (1.5 * height - ball.pos.y),
                Gosu::Color.from_hsv(120, 0.8, 0.5))
  end

  def draw_ball(ball, index)
    hue = index * 33 % 360
    draw_circle_with_border(ball.pos, Ball::SIZE,
                            Gosu::Color.from_hsv(hue, ball.pos.y / height, 1), 3,
                            Gosu::Color::BLACK)
  end

  def draw_message
    text = 'Level cleared'
    @font.draw_text(text,
                    width / 2 - text.length * FONT_SIZE / 4,
                    height / 2 - FONT_SIZE / 2,
                    0, 1, 1, WHITE)
  end

  def draw_crosshair_with_shadow(x, y)
    draw_crosshair(x + offset, y + offset, Gosu::Color::BLACK)
    draw_crosshair(x, @crosshair.y, WHITE)
  end

  def draw_crosshair(x, y, color)
    draw_line(x, y - CROSSHAIR_LENGTH, color, x, y + CROSSHAIR_LENGTH, color)
    draw_line(x - CROSSHAIR_LENGTH, y, color, x + CROSSHAIR_LENGTH, y, color)
  end
end

BouncingBalls.new.show
