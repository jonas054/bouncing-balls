require 'gosu'
require 'forwardable'
require './vector2'
require './circle'
require './ball'
require './keyboard'

# The main class.
class BouncingBalls < Gosu::Window
  include Circle
  extend Forwardable

  def_delegators :@keyboard, :button_up, :button_down

  WHITE = Gosu::Color::WHITE
  BLACK = Gosu::Color::BLACK
  WALL_HEIGHT = 50
  FONT_SIZE = 40
  HOLE_WIDTH = 200
  MOVEMENT_THRESHOLD = 0.5
  MAX_BALLS_IN_PLAY = 6
  SOUNDS = {
    good: Gosu::Sample.new('message.ogg'),
    bad: Gosu::Sample.new('bell.ogg'),
    score: Gosu::Sample.new('dialog-information.ogg')
  }.freeze

  def initialize
    super(1500, 800, fullscreen: false)
    restart
    @font = Gosu::Font.new(self, 'Arial', FONT_SIZE)
    @hole_pos = 50
    @score = 0
    @total = 0
    @keyboard = Keyboard.new
  end

  def update
    if @pause
      if @score != 0
        delta = @score / @score.abs
        @total += delta
        @score -= delta
        SOUNDS[:score].play if @total % 5 == 0
      end
      restart if @score == 0 && Time.now - @pause > 2
    elsif @balls.compact.empty? ||
          @score != 0 && @balls.compact.map(&:points).all?(&:negative?)
      @pause = Time.now
    elsif @balls.compact.all? { |ball| ball.bottom_y >= height - WALL_HEIGHT } &&
          @balls.compact.inject(0) { |acc, ball| acc + ball.speed.size } < MOVEMENT_THRESHOLD
      @pause = Time.now
      @too_slow = true
    else
      update_balls
    end
    update_hole
  end

  def draw
    draw_rect(0, height - WALL_HEIGHT, width, WALL_HEIGHT, Gosu::Color::GREEN)

    @balls.compact.each { |ball| draw_shadow(ball) } unless @pause

    draw_rect(0, 0, width, height - WALL_HEIGHT, Gosu::Color::BLUE)
    draw_hole
    draw_score_texts

    if @too_slow
      draw_message('Level skipped')
    elsif @pause
      draw_message('Level cleared')
    else
      @balls.compact.each { |ball| draw_ball(ball) }
    end
  end

  private

  def restart
    @ball_size = rand(35..100)
    @pause = false
    @too_slow = false
    @nr_of_balls = rand(3..10)
    @balls = [new_ball]
  end

  def update_balls
    if @balls.size < @nr_of_balls && @balls.compact.size < MAX_BALLS_IN_PLAY && rand < 0.01
      @balls << new_ball
    end

    threads = @balls.compact.map do |ball|
      Thread.new do
        ball.handle_collisions(@balls)
        ball.bounce_on_floor_if_colliding(height - WALL_HEIGHT) unless in_hole?(ball.pos.x)
        ball.bounce_on_wall_if_colliding(width)
        ball.fall
        ball.move
      end
    end
    threads.each(&:join)

    @balls.each_index do |ix|
      ball = @balls[ix]
      next unless ball && ball.pos.y > height

      @score += ball.points
      SOUNDS[ball.points < 0 ? :bad : :good].play
      @balls[ix] = nil
    end
  end

  def in_hole?(ball_x)
    ball_x - @ball_size / 2 >= @hole_pos && ball_x + @ball_size / 2 <= @hole_pos + HOLE_WIDTH
  end

  def new_ball
    Ball.new(width / 2, 0, @ball_size)
  end

  def update_hole
    hole_speed = 0
    hole_speed = -1 if @keyboard.pressed?(Gosu::KB_LEFT)
    hole_speed = 1 if @keyboard.pressed?(Gosu::KB_RIGHT)
    if hole_speed > 0 && @hole_pos <= width - @ball_size ||
       hole_speed < 0 && @hole_pos + HOLE_WIDTH >= @ball_size
      @hole_pos += hole_speed * 10
    end
  end

  def draw_shadow(ball)
    draw_circle(Vector2(ball.pos.x, height - WALL_HEIGHT - @ball_size / 2),
                500 * @ball_size / (1.5 * height - ball.pos.y),
                Gosu::Color.from_hsv(120, 0.8, 0.5))
  end

  def draw_ball(ball)
    color = ball.points > 0 ? Gosu::Color::GREEN : Gosu::Color::RED
    draw_circle_with_border(ball.pos, @ball_size, color, 3, BLACK)
    draw_centered_text(ball.points.to_s, ball.pos.x, ball.pos.y,
                       ball.points < 0 ? WHITE : BLACK)
  end

  def draw_hole
    x1 = @hole_pos
    y1 = height - WALL_HEIGHT
    draw_triangle(x1, y1, BLACK, x1 + HOLE_WIDTH, y1, BLACK, x1 + HOLE_WIDTH / 2, y1 + 400, BLACK)
  end

  def draw_score_texts
    text = "Balls: #{@balls.size - @balls.compact.size} caught"
    waiting = @nr_of_balls - @balls.size
    text += ", #{waiting} waiting" if waiting > 0
    @font.draw_text(text, 30, 30, 0, 1, 1, WHITE)
    @font.draw_text("Score #{@score}", 30, 70, 0, 1, 1, WHITE)
    @font.draw_text("Total #{@total}", 30, 110, 0, 1, 1, WHITE)
  end

  def draw_message(text)
    draw_centered_text(text, width / 2, height / 2, WHITE)
  end

  def draw_centered_text(text, x, y, color)
    @font.draw_text(text, x - text.length * FONT_SIZE / 4, y - FONT_SIZE / 2, 0, 1, 1, color)
  end
end

BouncingBalls.new.show
