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

    @graph_ctx    = @graph_canvas.getContext('2d', alpha: false)
    @graph_ui_ctx = @graph_ui_canvas.getContext('2d', alpha: true)

    @graph_width  = @graph_canvas.width
    @graph_height = @graph_canvas.height

    @graph_ui_width  = @graph_canvas.width
    @graph_ui_height = @graph_canvas.height

    @graph_aspect = @graph_width / @graph_height

    if (@graph_width != @graph_ui_width) or (@graph_height != @graph_ui_height)
      @debug('Canvas #graph is not the same size as canvas #graph_ui')

    @button_reset = @context.getElementById('button_reset')
    @button_zoom  = @context.getElementById('button_zoom')
    @zoom_amount  = @context.getElementById('zoom_amount')

    @button_reset.addEventListener('click', @on_button_reset_click)
    @button_zoom.addEventListener( 'click', @on_button_zoom_click)
    @zoom_amount.addEventListener('change', @on_zoom_amount_change)

    @mouse_active = false
    @mouse =
      x: 0
      y: 0
    @orbit_mouse =
      x: 0
      y: 0

    @graph_wrapper.addEventListener('mousemove',  @on_mousemove)
    @graph_wrapper.addEventListener('mouseenter', @on_mouseenter)
    @graph_wrapper.addEventListener('mouseout',   @on_mouseout)
    @graph_wrapper.addEventListener('click',      @on_graph_click)

    @pause_mode = false
    @zoon_mode = false
    @antialias = true
    @maxiter = 100
    @reset_renderbox()
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

  reset_renderbox: ->
    @renderbox =
      start:
        r: -2
        i: -1
      end:
        r: 1
        i: 1

  pause_mode_on: ->
    @pause_mode = true

  pause_mode_off: ->
    @pause_mode = false

  pause_mode_toggle: ->
    if @pause_mode
      @pause_mode_off()
    else
      @pause_mode_on()

  zoom_mode_on: ->
    @zoom_mode = true

  zoom_mode_off: ->
    @zoom_mode = false

  zoom_mode_toggle: ->
    if @zoom_mode
      @zoom_mode_off()
    else
      @zoom_mode_on()

  on_button_reset_click: (event) =>
    @reset_renderbox()
    @zoom_mode_off()
    @draw_background()

  on_button_zoom_click: (event) =>
    @zoom_mode_toggle()

  on_zoom_amount_change: (event) =>
    if @zoom_mode
      @schedule_ui_draw()

  get_zoom_window: ->
    zoom = @zoom_amount.options[@zoom_amount.selectedIndex].value
    w =
      w: @graph_width  * zoom
      h: @graph_height * zoom

    w.x = if @mouse.x < w.w then 0 else @mouse.x - w.w
    w.y = if @mouse.y < w.h then 0 else @mouse.y - w.h

    return w

  on_graph_click: (event) =>
    if @zoom_mode
      console.log('zoom click')
      w = @get_zoom_window()
      newstart = @canvas_to_render_coord(w.x, w.y)
      newend   = @canvas_to_render_coord(w.x + w.w, w.y + w.h)
      @renderbox.start = newstart
      @renderbox.end   = newend
      @zoom_mode = false
      @draw_background()
    else
      @pause_mode_toggle()
      console.log('pause mode:', @pause_mode)

  on_mousemove: (event) =>
    [ oldx, oldy ] = @mouse
    cc = @graph_canvas.getBoundingClientRect()
    @mouse.x = event.pageX - cc.left
    @mouse.y = event.pageY - cc.top
    if (oldx != @mouse.x) or (oldy != @mouse.y)
      unless @pause_mode
        @orbit_mouse.x = @mouse.x
        @orbit_mouse.y = @mouse.y
      @mouse_active = true
      @schedule_ui_draw()

  on_mouseenter: (event) =>
    @mouse_active = true
    @schedule_ui_draw()

  on_mouseout: (event) =>
    @mouse_active = false
    @schedule_ui_draw()

  canvas_to_render_coord: (x, y) =>
    return
      r: @renderbox.start.r + (x / @graph_width)  * (@renderbox.end.r - @renderbox.start.r)
      i: @renderbox.start.i + (y / @graph_height) * (@renderbox.end.i - @renderbox.start.i)

  render_coord_to_canvas: (z) ->
    return
      x: ((z.r - @renderbox.start.r) / (@renderbox.end.r - @renderbox.start.r)) * @graph_width
      y: ((z.i - @renderbox.start.i) / (@renderbox.end.i - @renderbox.start.i)) * @graph_height

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

  mandel_color_value: (x, y) ->
    c = @canvas_to_render_coord(x, y)
    [n, in_set] = @mandelbrot(c)
    if in_set
      0
    else
      n

  draw_background: ->
    @graph_ctx.fillStyle = 'rgb(0,0,0)'
    @graph_ctx.fillRect(0, 0, @graph_width, @graph_height)

    console.log('createImageData()')

    img = @graph_ctx.getImageData(0, 0, @graph_width, @graph_height)
    data = img.data

    for y in [0..@graph_height]
      for x in [0..@graph_width]
        val = @mandel_color_value(x, y)
        if @antialias
          val += @mandel_color_value(x + 0.5, y      )
          val += @mandel_color_value(x      , y + 0.5)
          val += @mandel_color_value(x + 0.5, y + 0.5)
          val /= 4

        pos = 4 * (x + (y * @graph_width))
        val = Math.pow((val / @maxiter), 0.5) * 255
        data[pos    ] = val
        data[pos + 1] = val
        data[pos + 2] = val

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

  draw_orbit: ->
    mx = @orbit_mouse.x
    my = @orbit_mouse.y
    pos = @canvas_to_render_coord(mx, my)

    @graph_ui_ctx.beginPath()
    @graph_ui_ctx.lineWidth = 2
    @graph_ui_ctx.strokeStyle = 'rgba(255,255,108,0.5)'

    @graph_ui_ctx.moveTo(mx, my)

    for step from @mandelbrot_orbit(pos, 50)
      if step.n > 0
        p = @render_coord_to_canvas(step.z)
        @graph_ui_ctx.lineTo(p.x, p.y)
        @graph_ui_ctx.stroke()
        @graph_ui_ctx.beginPath()
        @graph_ui_ctx.moveTo(p.x, p.y)

    isize = 3
    osize = isize * 3

    @graph_ui_ctx.beginPath()

    @graph_ui_ctx.moveTo(mx + isize, my + isize)  # BR
    @graph_ui_ctx.lineTo(mx + osize, my)          #    R
    @graph_ui_ctx.lineTo(mx + isize, my - isize)  # TR
    @graph_ui_ctx.lineTo(mx,         my - osize)  #    T
    @graph_ui_ctx.lineTo(mx - isize, my - isize)  # TL
    @graph_ui_ctx.lineTo(mx - osize, my        )  #    L
    @graph_ui_ctx.lineTo(mx - isize, my + isize)  # BL
    @graph_ui_ctx.lineTo(mx,         my + osize)  #    B
    @graph_ui_ctx.lineTo(mx + isize, my + isize)  # BR


    @graph_ui_ctx.fillStyle = 'rgba(255,249,187, 0.1)'
    @graph_ui_ctx.fill()

    @graph_ui_ctx.lineWidth = 2
    @graph_ui_ctx.strokeStyle = '#bb7e24'
    @graph_ui_ctx.stroke()

    @graph_ui_ctx.lineWidth = 1
    @graph_ui_ctx.strokeStyle = '#d5c312'
    @graph_ui_ctx.stroke()

  draw_zoom: ->
    @graph_ui_ctx.save()

    w = @get_zoom_window()
    region = new Path2D()
    region.rect(0, 0, @graph_width, @graph_height)
    region.rect(w.x, w.y, w.w, w.h)
    @graph_ui_ctx.clip(region, "evenodd")

    @graph_ui_ctx.fillStyle = 'rgba(255,232,232,0.333)'
    @graph_ui_ctx.fillRect(0, 0, @graph_width, @graph_height)

    @graph_ui_ctx.restore()

  draw_ui: ->
    @draw_ui_scheduled = false

    @graph_ui_ctx.clearRect(0, 0, @graph_width, @graph_height)

    if @mouse_active
      if @zoom_mode
        @draw_zoom()
      else
        @draw_orbit()

  draw_ui_callback: =>
    APP.draw_ui()

  schedule_ui_draw: =>
    unless @draw_ui_scheduled
      window.requestAnimationFrame(@draw_ui_callback)
      @draw_ui_scheduled = true

document.addEventListener 'DOMContentLoaded', =>
  APP = new MandelIter(document)
  APP.init()
