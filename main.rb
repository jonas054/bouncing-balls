require 'gosu'
require './vector2'
require './circle'
require './ball'

class GosuExample < Gosu::Window
  include Circle

  WALL_HEIGHT = 50
  FONT_SIZE = 40
  CROSSHAIR_LENGTH = 20

  def initialize
    super(1500, 800, fullscreen: false)
    @nr_of_balls = 3
    @balls = [Ball.new(width / 2, 0)]
    @font = Gosu::Font.new(self, 'Arial', FONT_SIZE)
  end

  def update
    if @pause
      @pause -= 1
      if @pause == 0
        @pause = nil
        @balls << Ball.new(width / 2, 0)
      end
      return
    elsif @balls.compact.empty?
      @balls = []
      @nr_of_balls = @nr_of_balls * 4 / 3
      @pause = 100
      return
    end
    @balls << Ball.new(width / 2, 0) if (@balls.size < @nr_of_balls) && (rand < 0.01)
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
    @crosshair = Vector2(mouse_x, mouse_y)
    @hit_radius -= 1 if @hit_radius && @hit_radius > 0
  end

  def button_down(id)
    if id == Gosu::MS_LEFT
      @crosshair = Vector2(mouse_x, mouse_y)
      @hit = Vector2(mouse_x, mouse_y)
      @hit_radius = 15
      hit_ball_ix = (0..@nr_of_balls).find do |ix|
        @balls[ix] && @balls[ix].distance_to(@crosshair) < Ball::SIZE
      end
      @balls[hit_ball_ix] = nil if hit_ball_ix
    end
  end

  def draw
    draw_rect(0, height - WALL_HEIGHT, width, WALL_HEIGHT, Gosu::Color::GREEN)
    @balls.compact.each do |ball|
      draw_circle(Vector2(ball.pos.x, height - WALL_HEIGHT - Ball::SIZE / 2),
                  500 * Ball::SIZE / (1.5 * height - ball.pos.y),
                  Gosu::Color.from_hsv(120, 0.8, 0.5))
    end
    draw_rect(0, 0, width, height - WALL_HEIGHT, Gosu::Color::BLUE)
    unless @pause
      @font.draw_text("#{@balls.compact.size}/#{@nr_of_balls} balls", 30, 30,
                      0, 1, 1, Gosu::Color::WHITE)
    end
    @balls.each_with_index do |ball, ix|
      next unless ball

      hue = ix * 33 % 360
      draw_circle_with_border(ball.pos, Ball::SIZE,
                              Gosu::Color.from_hsv(hue, ball.pos.y / height,
                                                   1),
                              3, Gosu::Color::BLACK)
    end
    if @pause
      text = 'Level cleared'
      @font.draw_text(text,
                      width / 2 - text.length * FONT_SIZE / 4,
                      height / 2 - FONT_SIZE / 2,
                      0, 1, 1,
                      Gosu::Color::WHITE)
      return
    end
    draw_circle(@hit, @hit_radius, Gosu::Color::WHITE) if @hit
    if @crosshair
      (1..2).each do |offset|
        draw_cross(@crosshair.x + offset, @crosshair.y + offset,
                   Gosu::Color::BLACK)
      end
      draw_cross(@crosshair.x, @crosshair.y, Gosu::Color::WHITE)
    end
  end

  def draw_cross(x, y, color)
    draw_line(x, y - CROSSHAIR_LENGTH, color, x, y + CROSSHAIR_LENGTH, color)
    draw_line(x - CROSSHAIR_LENGTH, y, color, x + CROSSHAIR_LENGTH, y, color)
  end
end

GosuExample.new.show
