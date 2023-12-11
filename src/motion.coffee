window.Motion or= {}

class Motion.Point
  constructor: (args...) ->
    switch args.length
      when 1
        @x = args[0].x
        @y = args[0].y

      when 2
        @x = args[0]
        @y = args[1]

      else
        APP.debug("new Highlight.Point() called with #{args.length} args: #{args.join(', ')}")

    @complex = APP.canvas_to_complex(@x, @y)
    @polar_radius = Math.sqrt((@complex.r * @complex.r) + (@complex.i * @complex.i))
    @polar_angle  = Math.atan2(@complex.i, @complex.r)
    @polar_angle += Math.TAU if @polar_angle < 0

  lerp: (a, b, t) ->
    (a * (1 - t)) + (b * t)

  lerp2: (a, b, t) ->
    return
      x: @lerp(a.x, b.x, t)
      y: @lerp(a.y, b.y, t)

  linear_interp_to: (other, t) ->
    @lerp2(this, other, t)

  polar_interp_to: (other, t) ->
    inv_t = 1 - t
    r     = (@polar_radius * inv_t) + (other.polar_radius * t)

    a = @polar_angle
    b = other.polar_angle
    b += Math.TAU if b < a

    dt = (b - a) %% Math.TAU
    theta = if dt < Math.PI
      @polar_angle + (dt * t)
    else
      dt = Math.TAU - dt
      @polar_angle - (dt * t)
      
    theta = theta %% Math.TAU
    
    APP.complex_to_canvas
      r: r * Math.cos(theta)
      i: r * Math.sin(theta)

  ease_in_out_quart: (t) ->
    if t < 0.5
      8 * t * t * t * t
    else
      1 - Math.pow(-2 * t + 2, 4) / 2

  ease_to: (other, t) ->
    polar = @polar_interp_to(other, @ease_in_out_quart(t))
    r = Math.min(@polar_radius, other.polar_radius)
    maxlinear = 0.85
    if r < maxlinear
      linear = @linear_interp_to(other, @ease_in_out_quart(t))
      @lerp2(linear, polar, r / maxlinear)
    else
      polar


class Motion.Anim
  constructor: (p_src, p_dst, @steps) ->
    @src = new Motion.Point(p_src)
    @dst = new Motion.Point(p_dst)

    @steps = parseInt(@steps)
    @step_size = 1.0 / @steps
    @current_step = 0
    @t = 0

  next: ->
    return @dst if @finished()

    @t += @step_size
    @current_step += 1
    @src.ease_to(@dst, @t)

  finished: ->
    @current_step >= @steps

  remaining: ->
    1.0 - (@current_step / @steps)

  highlight_color: ->
    channel = 255 * @remaining()

    "rgb(#{channel},#{channel},0)"

  finished_color: ->
    "rgb(0,0,0)"
