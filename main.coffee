window.APP = null

TAU = 2 * Math.PI

class MandelIter
  constructor: (@context) ->

  init: () ->
    console.log('Starting init()...')

    @running = false

    fmtfloatopts =
      notation:    'standard'
      style:       'decimal'
      useGrouping: false
      minimumIntegerDigits: 1
      maximumFractionDigits: 3
      signDisplay: 'always'

    @fmtfloat = new Intl.NumberFormat undefined, fmtfloatopts
    fmtfloatopts['signDisplay'] = 'never'
    @fmtfloatnosign = new Intl.NumberFormat undefined, fmtfloatopts

    @content_el       = @context.getElementById('content')

    @show_tooltips   = @context.getElementById('show_tooltips')
    @show_tooltips.addEventListener('change', @on_show_tooltips_change)
    @show_tooltips.checked = true

    @graph_wrapper   = @context.getElementById('graph_wrapper')
    @graph_canvas    = @context.getElementById('graph')
    @graph_ui_canvas = @context.getElementById('graph_ui')

    @graph_ctx    = @graph_canvas.getContext('2d', alpha: false)
    @graph_ui_ctx = @graph_ui_canvas.getContext('2d', alpha: true)

    @resize_canvas(900, 600)
    @fit_canvas_to_width()

    #window.addEventListener('resize', @on_content_wrapper_resize)

    @loc_c      = @context.getElementById('loc_c')
    @loc_radius = @context.getElementById('loc_radius')
    @loc_theta  = @context.getElementById('loc_theta')

    @button_reset = @context.getElementById('button_reset')
    @button_zoom  = @context.getElementById('button_zoom')
    @zoom_amount  = @context.getElementById('zoom_amount')

    @button_reset.addEventListener('click', @on_button_reset_click)
    @button_zoom.addEventListener( 'click', @on_button_zoom_click)
    @zoom_amount.addEventListener('change', @on_zoom_amount_change)

    @option =
      highlight_trace_path:     new UI.BoolOption('highlight_trace_path', false)
      highlight_internal_angle: new UI.BoolOption('highlight_internal_angle', false)
      trace_path_edge_distance: new UI.FloatOption('trace_path_edge_distance')
      trace_path:               new UI.SelectOption('trace_path')
      trace_speed:              new UI.FloatOption('trace_speed')
      orbit_draw_length:        new UI.IntOption('orbit_draw_length')

    @trace_angle = 0
    @trace_steps = 60 * 64
    @trace_angle_step = TAU / @trace_steps

    @trace_slider = @context.getElementById('trace_slider')
    @trace_slider.addEventListener('input', @on_trace_slider_input)
    @trace_slider.value = @trace_angle

    @trace_animation_enabled = false
    @button_trace_cardioid = @context.getElementById('button_trace_cardioid')
    @button_trace_cardioid.addEventListener('click', @on_button_trace_cardioid_click)
    @trace_cardioid_off()

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

    @defer_resize = false
    @pause_mode = false
    @zoon_mode = false
    @antialias = true
    @maxiter = 100
    @reset_renderbox()
    @draw_ui_scheduled = false

    @main_bulb_center =
      r: -1
      i:  0
    @main_bulb_tangent_point =
      r: -3/4
      i:  0
    @main_bulb_radius = @main_bulb_tangent_point.r - @main_bulb_center.r

    console.log('init() completed!')

    @draw_background()


  debug: (msg) ->
    unless @debugbox?
      @debugbox = $('#debugbox')
      @debugbox_hdr = @debugbox.find('.hdr')
      @debugbox_msg = @debugbox.find('.msg')
      @debugbox.removeClass('hidden')

    timestamp = new Date()
    @debugbox_hdr.text(timestamp.toISOString())
    @debugbox_msg.text('' + msg)

  complex_to_string: (z) ->
    rstr = @fmtfloat.format(z.r)
    istr = @fmtfloatnosign.format(z.i)

    if z.i is 0
      # pure real
      rstr
    else if z.r is 0
      # pure imaginary
      if z.i is 1
        'i'
      else if z.i is -1
        '-i'
      else
        'i'
    else
      # complex value
      if z.i < 0
        if z.i is -1
          rstr + ' - i'
        else
          rstr + ' - ' + istr + 'i'
      else
        if z.i is 1
          rstr + ' + i'
        else
          rstr + ' + ' + istr + 'i'

  on_show_tooltips_change: (event) =>
    if @show_tooltips.checked
      @content_el.classList.add('show_tt')
    else
      @content_el.classList.remove('show_tt')

  resize_canvas: (w, h) ->
    console.log('resize', w, h)
    @graph_canvas.width  = w
    @graph_canvas.height = h
    @graph_width  = @graph_canvas.width
    @graph_height = @graph_canvas.height

    @graph_ui_canvas.width  = @graph_canvas.width
    @graph_ui_canvas.height = @graph_canvas.height
    @graph_ui_width  = @graph_canvas.width
    @graph_ui_height = @graph_canvas.height

    @graph_aspect = @graph_width / @graph_height

    wpx = "#{w}px"
    hpx = "#{h}px"
    @graph_wrapper.style.width  = wpx
    @graph_wrapper.style.height = hpx
    @graph_ui_canvas.style.width  = wpx
    @graph_ui_canvas.style.height = hpx
    @graph_canvas.style.width  = wpx
    @graph_canvas.style.height = hpx

    if (@graph_width != @graph_ui_width) or (@graph_height != @graph_ui_height)
      @debug('Canvas #graph is not the same size as canvas #graph_ui')

  fit_canvas_to_width: ->
    w = @content_el.clientWidth
    w -= 9
    h = Math.floor(w / @graph_aspect)
    @resize_canvas(w, h)

  deferred_fit_canvas_to_width: =>
    console.log('deferred')
    @fit_canvas_to_width()
    @draw_background()
    @defer_resize = false

  on_content_wrapper_resize: (event) =>
    if @defer_resize
      console.log("already deferred")
    else
      console.log('setting defferred fit timeout')
      @defer_resise = true
      setTimeout(@deferred_fit_canvas_to_width, 5000)

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
    @schedule_ui_draw()

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

  trace_cardioid_on: ->
    @button_trace_cardioid.textContent = 'Stop'
    @button_trace_cardioid.classList.remove('inactive')
    @button_trace_cardioid.classList.add('enabled')
    @trace_slider.disabled = false
    @trace_slider.value = @trace_angle
    @trace_animation_enabled = true

  trace_cardioid_off: ->
    @button_trace_cardioid.textContent = 'Start'
    @button_trace_cardioid.classList.remove('enabled')
    @button_trace_cardioid.classList.add('inactive')
    @trace_slider.disabled = true
    @trace_animation_enabled = false

  trace_cardioid_toggle: ->
    if @trace_animation_enabled
      @trace_cardioid_off()
    else
      @trace_cardioid_on()

  on_button_trace_cardioid_click: (event) =>
    @trace_cardioid_toggle()

  on_trace_slider_input: (event) =>
    @trace_angle = parseFloat(@trace_slider.value)

  on_button_reset_click: (event) =>
    @reset_renderbox()
    @zoom_mode_off()
    @trace_cardioid_off()
    @draw_background()

  on_button_zoom_click: (event) =>
    @trace_cardioid_off() unless @zoom_mode
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
      w = @get_zoom_window()
      newstart = @canvas_to_complex(w.x, w.y)
      newend   = @canvas_to_complex(w.x + w.w, w.y + w.h)
      @renderbox.start = newstart
      @renderbox.end   = newend
      @zoom_mode = false
      @draw_background()
    else
      @pause_mode_toggle()

  on_mousemove: (event) =>
    oldx = @mouse.x
    oldy = @mouse.y
    @mouse.x = event.layerX
    @mouse.y = event.layerY
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

  rectangular_to_polar_angle: (r, i) ->
    return Math.atan2(i, r)

  polar_to_rectangular: (radius, angle) ->
    return
      r: radius * Math.cos(angle)
      i: radius * Math.sin(angle)

  canvas_to_complex: (x, y) =>
    return
      r: @renderbox.start.r + (x / @graph_width)  * (@renderbox.end.r - @renderbox.start.r)
      i: @renderbox.start.i + (y / @graph_height) * (@renderbox.end.i - @renderbox.start.i)

  complex_to_canvas: (z) ->
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
    c = @canvas_to_complex(x, y)
    [n, in_set] = @mandelbrot(c)
    if in_set
      0
    else
      n

  draw_background: ->
    @graph_ctx.fillStyle = 'rgb(0,0,0)'
    @graph_ctx.fillRect(0, 0, @graph_width, @graph_height)

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

  draw_orbit: (c) ->
    mx = c.x
    my = c.y
    pos = @canvas_to_complex(mx, my)
    @loc_c.innerText = @complex_to_string(pos)

    @graph_ui_ctx.save()

    @graph_ui_ctx.beginPath()
    @graph_ui_ctx.lineWidth = 2
    @graph_ui_ctx.strokeStyle = 'rgba(255,255,108,0.5)'

    @graph_ui_ctx.moveTo(mx, my)

    for step from @mandelbrot_orbit(pos, @option.orbit_draw_length.value)
      if step.n > 0
        p = @complex_to_canvas(step.z)
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

    @graph_ui_ctx.lineWidth = 2
    @graph_ui_ctx.strokeStyle = '#d5c312'
    @graph_ui_ctx.stroke()

    @graph_ui_ctx.restore()

  main_bulb: (theta) ->
    theta = theta % TAU

    shrink = @option.trace_path_edge_distance.value
    rec = @polar_to_rectangular(@main_bulb_radius - shrink, theta)
    rec.r += @main_bulb_center.r

    @complex_to_canvas(rec)

  cardioid: (theta) ->
    theta = theta % TAU

    #shrink = 0.015
    shrink = @option.trace_path_edge_distance.value

    ct = Math.cos(theta)
    mcos = 1 - ct

    mcos = mcos * (1 - shrink)

    a =
      r: ct
      i: Math.sin(theta)

    a.r = ((a.r * 0.5) * mcos) + 0.25 - (shrink * 0.5)
    a.i = ((a.i * 0.5) * mcos)

    @complex_to_canvas(a)

  draw_cardioid_trace_path: ->
    @graph_ui_ctx.save()

    steps = 100
    step_size = TAU / steps
    theta = 0
    p = @cardioid(theta)
    first = p

    @graph_ui_ctx.save()

    @graph_ui_ctx.beginPath()
    @graph_ui_ctx.moveTo(p.x, p.y)

    while theta < TAU
      theta = theta + step_size
      p = @cardioid(theta)
      @graph_ui_ctx.lineTo(p.x, p.y)

    @graph_ui_ctx.lineTo(first.x, first.y)

    @graph_ui_ctx.lineWidth = 2
    @graph_ui_ctx.strokeStyle = '#61E0F6'
    @graph_ui_ctx.stroke()

    @graph_ui_ctx.restore()

  draw_cardioid_internal_angle: ->
    angle = null

    if @trace_animation_enabled
      angle = @trace_angle
    else if @mouse_active
      if @zoom_mode
        # disabled while zooming
      else
        # show the internal angle of the mouse pointer
        m = @canvas_to_complex(@orbit_mouse.x, @orbit_mouse.y)
        angle = @rectangular_to_polar_angle(m.r, m.i)
    else
      # skip other/unknown modes

    return null unless angle?

    zorigin =
      r: 0
      i: 0

    zorigin_tangent_point =
      r: 0.5
      i: 0

    origin = @complex_to_canvas(zorigin)
    origin_tangent_point  = @complex_to_canvas(zorigin_tangent_point)

    radius = (origin_tangent_point.x - origin.x) / 2

    # r = 0.5 = (inner circle radius 0.25)
    #         + (outer circle radius 0.25)
    circle = @polar_to_rectangular(0.5, angle)

    @loc_radius.innerText = @fmtfloat.format(radius)
    @loc_theta.innerText  = @fmtfloat.format(angle)

    @graph_ui_ctx.save()
    @graph_ui_ctx.lineWidth = 2

    outer = @complex_to_canvas(circle)

    @graph_ui_ctx.beginPath()
    @graph_ui_ctx.moveTo(origin.x, origin.y)
    @graph_ui_ctx.lineTo(outer.x, outer.y)
    @graph_ui_ctx.lineTo(@current_trace_location.x, @current_trace_location.y)
    @graph_ui_ctx.strokeStyle = '#F67325'
    @graph_ui_ctx.stroke()

    @graph_ui_ctx.beginPath()
    @graph_ui_ctx.arc(origin.x, origin.y, radius, 0, TAU, false)
    @graph_ui_ctx.strokeStyle = '#00FF47'
    @graph_ui_ctx.stroke()

    @graph_ui_ctx.beginPath()
    @graph_ui_ctx.arc(outer.x, outer.y, radius, 0, TAU, false)
    @graph_ui_ctx.strokeStyle = '#21CC50'
    @graph_ui_ctx.stroke()

    @graph_ui_ctx.restore()

  draw_main_bulb_trace_path: ->
    center  = @complex_to_canvas(@main_bulb_center)
    ztangent =
      r: @main_bulb_tangent_point.r - @option.trace_path_edge_distance.value
      i: @main_bulb_tangent_point.i
    tangent = @complex_to_canvas(ztangent)
    radius = tangent.x - center.x

    @graph_ui_ctx.beginPath()
    @graph_ui_ctx.arc(center.x, center.y, radius, 0, TAU, false)
    @graph_ui_ctx.strokeStyle = '#00FF47'
    @graph_ui_ctx.stroke()

  draw_trace_animation: ->
    @draw_orbit(@current_trace_location)

    unless @pause_mode
      @trace_angle = @trace_angle + @option.trace_speed.value
      @trace_angle = @trace_angle - TAU if @trace_angle >= TAU
      @trace_slider.value = @trace_angle

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

    @orbit_mouse = @cardioid(@trace_angle)
    @draw_orbit()

  draw_ui: ->
    @draw_ui_scheduled = false

    @graph_ui_ctx.clearRect(0, 0, @graph_width, @graph_height)

    if @trace_animation_enabled
      @current_trace_location =
        switch @option.trace_path.value
          when 'main_cardioid' then @cardioid(@trace_angle)
          when 'main_bulb'     then @main_bulb(@trace_angle)
    else
      @current_trace_location = @orbit_mouse

    if @option.highlight_trace_path.value
      switch @option.trace_path.value
        when 'main_cardioid' then @draw_cardioid_trace_path()
        when 'main_bulb'     then @draw_main_bulb_trace_path()

    if @option.highlight_internal_angle.value
      switch @option.trace_path.value
        when 'main_cardioid' then @draw_cardioid_internal_angle()

    # exclusive modes

    if @trace_animation_enabled
      @draw_trace_animation()

    else if @mouse_active
      if @zoom_mode
        @draw_zoom()
      else
        @draw_orbit(@orbit_mouse)

  draw_ui_callback: =>
    APP.draw_ui()
    @schedule_ui_draw() unless @pause_mode

  schedule_ui_draw: =>
    unless @draw_ui_scheduled
      window.requestAnimationFrame(@draw_ui_callback)
      @draw_ui_scheduled = true

document.addEventListener 'DOMContentLoaded', =>
  window.APP = new MandelIter(document)
  window.APP.init()
  window.APP.schedule_ui_draw()
