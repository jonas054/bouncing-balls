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
  BLUE = Gosu::Color::BLUE
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
    @gravity = 0.8
    @font = Gosu::Font.new(self, 'Arial', FONT_SIZE)
    @hole_pos = 50
    @score = 0
    @total = 0
    @keyboard = Keyboard.new(self)
  end

  def key_down(str)
    case str
    when 'g' then @gravity *= 1.1
    when 'G' then @gravity *= 0.9
    end
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
    else
      active_balls = @balls.compact
      if active_balls.empty? || @score != 0 && active_balls.all? { _1.points < 0 }
        @pause = Time.now
      elsif active_balls.all? { _1.bottom_y >= floor } &&
            active_balls.map { _1.speed.size }.sum < MOVEMENT_THRESHOLD
        @pause = Time.now
        @too_slow = true
      else
        update_balls
      end
    end
    update_hole
  end

  def draw
    draw_rect(0, floor, width, WALL_HEIGHT, Gosu::Color::GREEN)

    each_active_ball { draw_shadow(_1) } unless @pause

    draw_rect(0, 0, width, floor, BLUE)
    draw_hole
    draw_score_texts

    if @too_slow
      draw_message('Level skipped')
    elsif @pause
      draw_message('Level cleared')
    else
      each_active_ball { draw_ball(_1) }
    end
  end

  private

  def each_active_ball
    @balls.compact.each { yield _1 }
  end

  def restart
    @ball_size = rand(35..100)
    @pause = false
    @too_slow = false
    @nr_of_balls = rand(3..10)
    @balls = [new_ball]
  end

  def update_balls
    if @balls.size < @nr_of_balls && @balls.compact.size < MAX_BALLS_IN_PLAY &&
       rand < 0.01
      @balls << new_ball
    end

    @balls.compact.map do |ball|
      ball.handle_collisions(@balls)
      unless in_hole?(ball.pos.x)
        ball.bounce_on_floor_if_colliding(floor) do |volume, playback_speed|
          SOUNDS[:good].play(volume, playback_speed)
        end
      end
      ball.bounce_on_wall_if_colliding(width)
      ball.fall(@gravity)
      ball.move
    end

    @balls.each_with_index do |ball, ix|
      next unless ball && ball.pos.y > height

      @score += ball.points
      SOUNDS[ball.points < 0 ? :bad : :good].play
      @balls[ix] = nil
    end
  end

  def in_hole?(ball_x)
    ball_x - @ball_size / 2 >= @hole_pos &&
      ball_x + @ball_size / 2 <= @hole_pos + HOLE_WIDTH
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
    draw_circle(Vector2(ball.pos.x, floor - @ball_size / 2),
                500 * @ball_size / (1.5 * height - ball.pos.y),
                Gosu::Color.from_hsv(120, 0.8, 0.5))
  end

  def draw_ball(ball)
    color = ball.points > 0 ? Gosu::Color::GREEN : Gosu::Color::RED
    draw_circle_with_border(ball.pos, @ball_size, color, 3, BLACK)
    draw_centered_text(ball.points.to_s, ball.pos.x, ball.pos.y,
                       ball.points < 0 ? WHITE : BLACK)
  end

  # (x1, y1)------(x2, y1)------(x3, y1)  BLUE
  #        \      /      \     /
  #        (x4, y2)-----(x5, y2)         BLACK
  def draw_hole
    slope_width = 50
    x1 = @hole_pos
    x2 = x1 + HOLE_WIDTH / 2
    x3 = x1 + HOLE_WIDTH
    x4 = x1 + slope_width
    x5 = x1 + HOLE_WIDTH - slope_width
    y1 = floor
    y2 = y1 + WALL_HEIGHT
    draw_triangle(x1, y1, BLUE, x2, y1, BLUE, x4, y2, BLACK) # left
    draw_triangle(x2, y1, BLUE, x3, y1, BLUE, x5, y2, BLACK) # right
    draw_triangle(x2, y1, BLUE, x4, y2, BLACK, x5, y2, BLACK) # middle
  end

  def draw_score_texts
    reset_text_pos
    waiting = @nr_of_balls - @balls.size
    text = "Balls: #{@balls.size - @balls.compact.size} caught"
    text += ", #{waiting} waiting" if waiting > 0
    draw_text(text, 30)
    draw_text("Score #{@score}", 30)
    draw_text("Total #{@total}", 30)
    reset_text_pos
    draw_text("Gravity #{(@gravity * 12.25).round(2)}", width - 23 * FONT_SIZE / 4)
  end

  def reset_text_pos
    @text_pos = 30
  end

  def draw_text(text, x)
    @font.draw_text(text, x, @text_pos, 0, 1, 1, WHITE)
    @text_pos += FONT_SIZE
  end

  def draw_message(text)
    draw_centered_text(text, width / 2, height / 2, WHITE)
  end

  def draw_centered_text(text, x, y, color)
    @font.draw_text(text, x - text.length * FONT_SIZE / 4, y - FONT_SIZE / 2, 0, 1, 1,
                    color)
  end

  def floor
    height - WALL_HEIGHT
  end
end

BouncingBalls.new.show
