APP = null

TAU = 2 * Math.PI

class MandelIter
  constructor: (@context) ->

  init: () ->
    console.log('Starting init()...')

    @running = false

    @content_el       = @context.getElementById('content')

    @graph_wrapper   = @context.getElementById('graph_wrapper')
    @graph_canvas    = @context.getElementById('graph')
    @graph_ui_canvas = @context.getElementById('graph_ui')

    @graph_ctx    = @graph_canvas.getContext('2d', alpha: true)
    @graph_ui_ctx = @graph_ui_canvas.getContext('2d', alpha: true)

    @graph_width  = @graph_canvas.width
    @graph_height = @graph_canvas.height

    @graph_ui_width  = @graph_canvas.width
    @graph_ui_height = @graph_canvas.height

    if (@graph_width != @graph_ui_width) or (@graph_height != @graph_ui_height)
      @debug('Canvas #graph is not the same size as canvas #graph_ui')

    @mouse_active = false
    @mouse =
      x: 0
      y: 0

    @context.addEventListener('mousemove',  @on_mousemove)
    @context.addEventListener('mouseenter', @on_mouseenter)
    @context.addEventListener('mouseout',   @on_mouseout)

    @maxiter = 100

    @renderbox =
      start:
        r: -2
        i: -1
      end:
        r: 1
        i: 1

    @draw_ui_scheduled = false

    console.log('init() completed!')


    @draw_background()

    #@update()

  debug: (msg) ->
    unless @debugbox?
      @debugbox = $('#debugbox')
      @debugbox_hdr = @debugbox.find('.hdr')
      @debugbox_msg = @debugbox.find('.msg')
      @debugbox.removeClass('hidden')

    timestamp = new Date()
    @debugbox_hdr.text(timestamp.toISOString())
    @debugbox_msg.text('' + msg)

  on_mousemove: (event) =>
    [ oldx, oldy ] = @mouse
    cc = @graph_canvas.getBoundingClientRect()
    @mouse.x = event.pageX - cc.left
    @mouse.y = event.pageY - cc.top
    if (oldx != @mouse.x) or (oldy != @mouse.y)
      @schedule_ui_draw()

  on_mouseenter: (event) =>
    @mouse_active = true
    @schedule_ui_draw()

  on_mouseout: (event) =>
    @mouse_active = false
    @schedule_ui_draw()

  canvas_to_render_coord: (x, y) ->
    return
      r: @renderbox.start.r + (x / @graph_width)  * (@renderbox.end.r - @renderbox.start.r)
      i: @renderbox.start.i + (y / @graph_height) * (@renderbox.end.i - @renderbox.start.i)

  mandelbrot: (c) ->
    n = 0
    d = 0
    z =
      r: 0
      i: 0

    while (d <= 2) and (n < @maxiter)
      p =
        r: Math.pow(z.r, 2) - Math.pow(z.i, 2)
        i: 2 * z.r * z.i
      z =
        r: p.r + c.r
        i: p.i + c.i
      d = Math.pow(z.r, 2) + Math.pow(z.i, 2)
      n += 1

    [n, d <= 2]

  draw_background: ->
    @graph_ctx.fillStyle = 'rgb(0,0,0)'
    @graph_ctx.fillRect(0, 0, @graph_width, @graph_height)

    console.log('createImageData()')

    img = @graph_ctx.getImageData(0, 0, @graph_width, @graph_height)
    data = img.data

    console.log('Iterating over pixels;..')

    for y in [0..@graph_height]
      for x in [0..@graph_width]
        c = @canvas_to_render_coord(x, y)
        [n, in_set] = @mandelbrot(c)
        unless in_set
          pos = 4 * (x + (y * @graph_width))
          val = Math.pow((n / @maxiter), 0.5) * 255
          data[pos    ] = val
          data[pos + 1] = Math.floor(val - (n/1))
          data[pos + 2] = Math.floor(val - (n/2))

    console.log('putImageData()')

    @graph_ctx.putImageData(img, 0, 0)

  mandelbrot_orbit: (c, max_yield = @maxiter) ->
    n = 0
    d = 0
    z =
      r: 0
      i: 0

    yield z: z, n: n

    while (d <= 2) and (n < max_yield)
      p =
        r: Math.pow(z.r, 2) - Math.pow(z.i, 2)
        i: 2 * z.r * z.i
      z =
        r: p.r + c.r
        i: p.i + c.i
      d = Math.pow(z.r, 2) + Math.pow(z.i, 2)
      n += 1

      yield z: z, n: n

  draw_ui: ->
    @draw_ui_scheduled = false

    @graph_ui_ctx.fillStyle = 'rgba(0,0,0,0.0)'
    @graph_ui_ctx.fillRect(0, 0, @graph_width, @graph_height)

    if true #@mouse_active
      pos = @canvas_to_render_coord(@mouse.x, @mouse.y)
      console.log('draw', @mouse, pos)
      for step from @mandelbrot_orbit(pos, 10)
        console.log(step)

      msize = 10

      @graph_ui_ctx.beginPath()

      @graph_ui_ctx.moveTo(@mouse.x + msize, @mouse.y)

      @graph_ui_ctx.arc(@mouse.x + msize, @mouse.y - msize, msize, 0, TAU/4)

      @graph_ui_ctx.fillStyle = 'rgba(255,249,187, 0.33)'
      @graph_ui_ctx.fill()

      @graph_ui_ctx.lineWidth = 3
      @graph_ui_ctx.strokeStyle = '#bb7e24'
      @graph_ui_ctx.stroke()

      @graph_ui_ctx.lineWidth = 2
      @graph_ui_ctx.strokeStyle = '#d5c312'
      @graph_ui_ctx.stroke()

  draw_ui_callback: =>
    APP.draw_ui()

  schedule_ui_draw: =>
    unless @draw_ui_scheduled
      window.requestAnimationFrame(@draw_ui_callback)
      @draw_ui_scheduled = true

$(document).ready =>
  APP = new MandelIter(document)
  APP.init()
  #APP.draw()
