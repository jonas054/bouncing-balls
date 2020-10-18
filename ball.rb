# Represents one of the balls and handles its movement.
class Ball
  SIZE = 50
  BUMP_FORCE = 2.6
  GRAVITY = 0.8i
  BOUNCINESS = 0.9
  FRICTION_FACTOR = 0.99

  attr_reader :pos, :speed, :points

  def initialize(x_pos, y_pos)
    @pos = Vector2(x_pos, y_pos)
    until @speed && @speed.size > BouncingBalls::MOVEMENT_THRESHOLD
      @speed = Vector2(rand(-2.0..2), rand(0..1))
    end
    @points = rand(-50..50) until @points&.nonzero?
  end

  def bottom_y
    @pos.y + Ball::SIZE
  end

  def move
    @pos += @speed
  end

  def handle_collisions(all_balls)
    all_balls.compact.reject { |b| b.object_id == object_id }.each do |other_ball|
      bump_away_from(other_ball) if collides_with?(other_ball)
    end
  end

  def bounce_on_floor_if_colliding(floor)
    relative_height = @pos.y + SIZE - floor
    return if relative_height < 0

    @speed.y = -@speed.y.abs * BOUNCINESS - relative_height / 10
    @speed.x *= FRICTION_FACTOR
  end

  def bounce_on_wall_if_colliding(width)
    return unless @pos.x + SIZE >= width || @pos.x - SIZE < 0

    @speed.x = -@speed.x * BOUNCINESS
    @pos.x += (width / 2 - @pos.x) / 200 # Avoid sticking to edge
  end

  def collides_with?(other_ball)
    distance_to(other_ball.pos) < SIZE * 2
  end

  def bump_away_from(other_ball)
    @speed += Vector2(@pos.x < other_ball.pos.x ? -BUMP_FORCE : BUMP_FORCE,
                      @pos.y < other_ball.pos.y ? -BUMP_FORCE : BUMP_FORCE)
  end

  def fall
    @speed += GRAVITY
  end

  def distance_to(other_pos)
    Math.sqrt((@pos.x - other_pos.x).abs**2 +
              (@pos.y - other_pos.y).abs**2)
  end
end
