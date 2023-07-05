APP = null

TAU = 2 * Math.PI

class Point
  constructor: (x, y, @color) ->
    @hover = false
    @selected = false

    @order = 0
    @radius = 5
    @color ?= '#000'

    @position =
      x: x
      y: y

    @move x, y

  move: (x, y) ->
    @x = x
    @y = y

    @ix = Math.floor(@x)
    @iy = Math.floor(@y)

  contains: (x, y) ->
    dx = @x - x
    dy = @y - y
    dist = Math.sqrt((dx * dx) + (dy * dy))
    return dist <= @radius

  update: (t) ->
    @position.x = @x
    @position.y = @y

  draw: ->
    #console.log('draw point', @x, @y, @color)
    ctx = APP.graph_ctx

    if @hover
      ctx.beginPath()
      ctx.fillStyle = '#ff0'
      ctx.strokeStyle = '#000'
      ctx.lineWidth = 1
      ctx.arc(@x, @y, @radius * 3, 0, TAU)
      ctx.fill()
      ctx.stroke()

    ctx.beginPath()
    ctx.fillStyle = @color
    ctx.arc(@x, @y, @radius, 0, TAU)
    ctx.fill()


class MandelIter
  constructor: (@context) ->

  init: () ->
    console.log('Starting init()...')

    @running = false

    @content_el       = @context.getElementById('content')

    @graph_wrapper   = @context.getElementById('graph_wrapper')
    @graph_canvas    = @context.getElementById('graph')
    #@graph_ui_canvas = @context.getElementById('graph_ui')

    @graph_ctx    = @graph_canvas.getContext('2d', alpha: true)
    #graph_ui_ctx = @graph_ui_canvas.getContext('2d', alpha: true)

    @graph_width  = @graph_canvas.width
    @graph_height = @graph_canvas.height

    #@context.addEventListener('mousemove', @on_mousemove)
    #@context.addEventListener('mousedown', @on_mousedown)
    #@context.addEventListener('mouseup',   @on_mouseup)

    @maxiter = 100

    @renderbox =
      start:
        r: -2
        i: -1
      end:
        r: 1
        i: 1

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

  get_mouse_coord: (event) ->
    cc = @graph_canvas.getBoundingClientRect()
    return
      x: event.pageX - cc.left
      y: event.pageY - cc.top

  on_mousemove: (event) =>
    mouse = @get_mouse_coord(event)
    for order in @points
      for p in order
        oldx = p.x
        oldy = p.y
        if p.selected
          p.x = mouse.x
          p.y = mouse.y

        oldhover = p.hover
        if p.contains(mouse.x, mouse.y)
          p.hover = true
        else
          p.hover = false

        if (p.hover != oldhover) or (p.x != oldx) or (p.y != oldy)
          @update_and_draw()

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
      #console.log(p, z)
      d = Math.pow(z.r, 2) + Math.pow(z.i, 2)
      n += 1

    #console.log('mandel[' + c.r + ', ' + c.i + '] d = ' + d + ', n = ' + n, d <= 2)
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
        c =
          r: @renderbox.start.r + (x / @graph_width)  * (@renderbox.end.r - @renderbox.start.r)
          i: @renderbox.start.i + (y / @graph_height) * (@renderbox.end.i - @renderbox.start.i)

        [n, in_set] = @mandelbrot(c)
        unless in_set
          pos = 4 * (x + (y * @graph_width))
          val = Math.pow((n / @maxiter), 0.5) * 255
          data[pos    ] = val
          data[pos + 1] = Math.floor(val - (n/1))
          data[pos + 2] = Math.floor(val - (n/2))

    console.log('putImageData()')

    @graph_ctx.putImageData(img, 0, 0)

  update: =>

  draw: ->
    @graph_ctx.clearRect(0, 0, @graph_canvas.width, @graph_canvas.height)
    @draw_bezier()
    for order in @points
      for p in order
        p.draw()

  update_and_draw: ->
    @update()
    @draw()

  update_callback: (timestamp) =>
    @frame_is_scheduled = false
    elapsed = timestamp - @prev_anim_timestamp
    if elapsed > 0
      @prev_anim_timestamp = @anim_timestamp
      @update()
      @draw()

    @schedule_next_frame() if @running
    return null
 
  schedule_next_frame: =>
    unless @frame_is_scheduled
      @frame_is_scheduled = true
      window.requestAnimationFrame(@update_callback)
    return null

  first_update_callback: (timestamp) =>
    @anim_timestamp      = timestamp
    @prev_anim_timestamp = timestamp
    @frame_is_scheduled = false
    @schedule_next_frame()
   
  schedule_first_frame: =>
    @frame_is_scheduled = true
    window.requestAnimationFrame(@first_update_callback)
    return null

$(document).ready =>
  APP = new MandelIter(document)
  APP.init()
  #APP.draw()
