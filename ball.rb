class Ball
  SIZE = 50
  BUMP_FORCE = 1.0
  GRAVITY = 0.4

  attr_reader :pos

  def initialize(x_pos, y_pos)
    @pos = Vector2(x_pos, y_pos)
    @speed = Vector2(rand(-2.0..2), 0)
  end

  def move
    @pos += @speed
  end

  def handle_collisions(all_balls)
    all_balls.reject { |b| b.object_id == object_id }.each do |other_ball|
      bump_away_from(other_ball) if collides_with?(other_ball)
    end
  end

  def bounce_on_floor_if_colliding(floor)
    return if @pos.y + SIZE < floor

    @speed.y = -@speed.y.abs * 0.9 - 1
    @speed.x *= 0.99
  end

  def bounce_on_wall_if_colliding(width)
    return unless @pos.x + SIZE >= width || @pos.x - SIZE < 0

    @speed.x = -@speed.x
    @pos.x += (width/2 - @pos.x) / 200 # Avoid sticking to edge
  end

  def collides_with?(other_ball)
    distance_to(other_ball) < SIZE * 2
  end

  def bump_away_from(other_ball)
    @speed.x += @pos.x < other_ball.pos.x ? -BUMP_FORCE : BUMP_FORCE
    @speed.y += @pos.y < other_ball.pos.y ? -BUMP_FORCE : BUMP_FORCE
  end

  def fall
    @speed.y += GRAVITY
  end

  private

  def distance_to(other_ball)
    Math.sqrt((@pos.x - other_ball.pos.x).abs**2 +
              (@pos.y - other_ball.pos.y).abs**2)
  end
end
