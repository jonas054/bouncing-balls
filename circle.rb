module Circle
  def draw_circle_with_border(center, radius, color, border_thickness,
                              border_color)
    draw_circle(center, radius, border_color)
    draw_circle(center, radius - border_thickness, color)
  end

  def draw_circle(center, radius, color)
    step = 40 / Math.log(radius)
    x1 = center.x
    y1 = center.y
    half_side = Math.sin(step * Math::PI / 360) * radius + 2
    (0...360).step(step) do |degrees|
      rotate(degrees, x1, y1) do
        x2 = x1 + radius
        draw_triangle(x1, y1, color,
                      x2, y1 - half_side, color,
                      x2, y1 + half_side, color)
      end
    end
  end
end
