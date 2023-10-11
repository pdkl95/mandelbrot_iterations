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

  linear_interp_to: (other, t) ->
    inv_t = 1 - t
    return
      x: (@x * inv_t) + (other.x * t)
      y: (@y * inv_t) + (other.y * t)

  ease_in_out_quart: (t) ->
    if t < 0.5
      8 * t * t * t * t
    else
      1 - Math.pow(-2 * t + 2, 4) / 2

  ease_to: (other, t) ->
    @linear_interp_to(other, @ease_in_out_quart(t))

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
