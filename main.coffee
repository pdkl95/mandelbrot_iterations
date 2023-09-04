window.APP = null

TAU = 2 * Math.PI

class MandelIter
  @deferred_background_render_callback = null

  constructor: (@context) ->

  init: () ->
    console.log('Starting init()...')

    @running = false

    @colorize_themes =
      linear_greyscale: [1, 1, 1]
      greyish_purple:   [2, 0.8, 2]

    @default_mandel_theme = 'linear_greyscale'
    @default_julia_theme  = 'greyish_purple'

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

    @content_el    = @context.getElementById('content')
    @status        = @context.getElementById('status')
    @status_current = 'loading'

    @show_tooltips = @context.getElementById('show_tooltips')
    @show_tooltips.addEventListener('change', @on_show_tooltips_change)
    @show_tooltips.checked = true

    @graph_wrapper       = @context.getElementById('graph_wrapper')
    @graph_mandel_canvas = @context.getElementById('graph_mandel')
    @graph_julia_canvas  = @context.getElementById('graph_julia')
    @graph_ui_canvas     = @context.getElementById('graph_ui')

    @graph_mandel_ctx = @graph_mandel_canvas.getContext('2d', alpha: false)
    @graph_julia_ctx  = @graph_julia_canvas.getContext( '2d', alpha: true)
    @graph_ui_ctx     = @graph_ui_canvas.getContext(    '2d', alpha: true)

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
      keyboard_step:            new UI.FloatOption('keyboard_step', 0.01)
      highlight_trace_path:     new UI.BoolOption('highlight_trace_path', false)
      highlight_internal_angle: new UI.BoolOption('highlight_internal_angle', false)
      trace_path_edge_distance: new UI.FloatOption('trace_path_edge_distance')
      trace_path:               new UI.SelectOption('trace_path')
      trace_speed:              new UI.FloatOption('trace_speed')
      orbit_draw_length:        new UI.IntOption('orbit_draw_length')
      orbit_draw_lines:         new UI.BoolOption('orbit_draw_lines', true)
      orbit_draw_points:        new UI.BoolOption('orbit_draw_points', true)
      orbit_point_size:         new UI.FloatOption('orbit_point_size', 2)
      julia_draw_local:         new UI.BoolOption('julia_draw_local', false)
      julia_more_when_paused:   new UI.BoolOption('julia_more_when_paused', true)
      julia_local_margin:       new UI.IntOption('julia_local_margin', 80)
      julia_local_max_size:     new UI.IntOption('julia_local_max_size', 750)
      julia_local_opacity:      new UI.PercentOption('julia_local_opacity', 0.6)
      julia_local_pixel_size:   new UI.IntOption('julia_local_pixel_size', 3)
      julia_max_iter_paused:    new UI.IntOption('julia_max_iter_paused', 250)
      julia_max_iterations:     new UI.IntOption('julia_max_iterations', 100)
      mandel_max_iterations:    new UI.IntOption('mandel_max_iterations', 120)
      mandel_color_scale_r:     new UI.FloatOption('mandel_color_scale_r', @colorize_themes[@default_mandel_theme][0])
      mandel_color_scale_g:     new UI.FloatOption('mandel_color_scale_g', @colorize_themes[@default_mandel_theme][1])
      mandel_color_scale_b:     new UI.FloatOption('mandel_color_scale_b', @colorize_themes[@default_mandel_theme][2])

    @option.julia_draw_local.register_callback
      on_true:  @on_julia_draw_local_true
      on_false: @on_julia_draw_local_false

    @option.julia_local_pixel_size.set_label_text_formater (value) -> "#{value}x"

    format_color_scale = (value) ->
      parseFloat(value).toFixed(2)
    @option.mandel_color_scale_r.set_label_text_formater(format_color_scale)
    @option.mandel_color_scale_g.set_label_text_formater(format_color_scale)
    @option.mandel_color_scale_b.set_label_text_formater(format_color_scale)
    @option.mandel_color_scale_r.register_callback on_change: @on_mandel_color_scale_change
    @option.mandel_color_scale_g.register_callback on_change: @on_mandel_color_scale_change
    @option.mandel_color_scale_b.register_callback on_change: @on_mandel_color_scale_change

    @pointer_angle = 0
    @pointer_angle_step = TAU/96

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
    @reset_renderbox()
    @draw_ui_scheduled = false

    @shift_step_accel = 0.333
    @ctrl_step_accel  = 0.1
    @alt_step_accel   = 0.01

    @defer_highres_frames = 0
    @deferred_render_passes = 3
    @deferred_render_pass_scale = 3
    @initial_render_pixel_size = @deferred_render_pass_scale ** @deferred_render_passes
    @render_lines_per_pass = 24

    @rendering_note          = @context.getElementById('rendering_note')
    @rendering_note_hdr      = @context.getElementById('rendering_note_hdr')
    @rendering_note_value    = @context.getElementById('rendering_note_value')
    @rendering_note_progress = @context.getElementById('rendering_note_progress')

    @main_bulb_center =
      r: -1
      i:  0
    @main_bulb_tangent_point =
      r: -3/4
      i:  0
    @main_bulb_radius = @main_bulb_tangent_point.r - @main_bulb_center.r

    @orbit_bb =
      min_x: 0
      max_x: 0
      min_y: 0
      max_y: 0

    @local_julia =
      width:  0
      height: 0
      x: 0
      y: 0

    document.addEventListener('keydown', @on_keydown)

    console.log('init() completed!')

    @draw_background()


  on_keydown: (event) =>
    accel = 1.0
    accel = @shift_step_accel if event.shiftKey
    accel =  @ctrl_step_accel if event.ctrlKey
    accel =   @alt_step_accel if event.altKey

    switch event.code
      when 'Space'
        @pause_mode_toggle()
        event.preventDefault()

      when 'ArrowUp'    then @mouse_step_up(accel)
      when 'ArrowDown'  then @mouse_step_down(accel)
      when 'ArrowLeft'  then @mouse_step_left(accel)
      when 'ArrowRight' then @mouse_step_right(accel)

      else
        # not our event
        return

    # it IS our event, so kill the event
    #event.stopPropagation()
    event.preventDefault()

  debug: (msg) ->
    unless @debugbox?
      @debugbox     = @context.getElementById('debugbox')
      @debugbox_hdr = @context.getElementById('debugbox_hdr')
      @debugbox_msg = @context.getElementById('debugbox_msg')
      @debugbox.classList.remove('hidden')

    timestamp = new Date()
    @debugbox_hdr.textContent = timestamp.toISOString()
    @debugbox_msg.textContent = '' + msg

  current_mandel_theme: ->
    if @option.mandel_color_scale_r? and @option.mandel_color_scale_g? and @option.mandel_color_scale_r?
      [ @option.mandel_color_scale_r.value, @option.mandel_color_scale_g.value, @option.mandel_color_scale_b.value ]
    else
      @colorize_themes[@default_mandel_theme]

  current_julia_theme: ->
    @colorize_themes[@default_julia_theme]

  on_mandel_color_scale_change: =>
    @repaint_mandelbrot()

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
    @canvas_num_pixels = w * h
    console.log("resize: #{w}x#{h}, #{@canvas_num_pixels} pixels")

    @graph_mandel_canvas.width  = w
    @graph_mandel_canvas.height = h
    @graph_width  = @graph_mandel_canvas.width
    @graph_height = @graph_mandel_canvas.height

    @graph_julia_canvas.width  = @graph_mandel_canvas.width
    @graph_julia_canvas.height = @graph_mandel_canvas.height
    @graph_ui_canvas.width  = @graph_mandel_canvas.width
    @graph_ui_canvas.height = @graph_mandel_canvas.height
    @graph_ui_width  = @graph_mandel_canvas.width
    @graph_ui_height = @graph_mandel_canvas.height

    @graph_aspect = @graph_width / @graph_height

    wpx = "#{w}px"
    hpx = "#{h}px"
    @graph_wrapper.style.width  = wpx
    @graph_wrapper.style.height = hpx
    @graph_ui_canvas.style.width  = wpx
    @graph_ui_canvas.style.height = hpx
    @graph_julia_canvas.style.width  = wpx
    @graph_julia_canvas.style.height = hpx
    @graph_mandel_canvas.style.width  = wpx
    @graph_mandel_canvas.style.height = hpx

    unless @mandel_values? and @mandel_values.length is @canvas_num_pixels
      @mandel_values = new Float64Array(@canvas_num_pixels)

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

  set_status: (klass) ->
    if @status_current?
      @status.classList.remove(@status_current)
    @status.classList.add(klass)
    @status_current = klass

  pause_mode_on: ->
    @pause_mode = true
    @set_status('paused')

  pause_mode_off: ->
    @pause_mode = false
    @schedule_ui_draw()
    @set_status('normal')

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
    @schedule_ui_draw()

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
      @option.julia_draw_local.set(false)
      @draw_background()
    else
      @pause_mode_toggle()

  on_mousemove: (event) =>
    @set_mouse_position(event.layerX, event.layerY)

  set_mouse_position: (newx, newy) ->
    oldx = @mouse.x
    oldy = @mouse.y
    @mouse.x = newx
    @mouse.y = newy

    @mouse.x = 0 if @mouse.x < 0
    @mouse.y = 0 if @mouse.y < 0
    @mouse.x = @graph_width  if @mouse.x > @graph_width
    @mouse.y = @graph_height if @mouse.y > @graph_height

    if (oldx != @mouse.x) or (oldy != @mouse.y)
      unless @pause_mode
        @orbit_mouse.x = @mouse.x
        @orbit_mouse.y = @mouse.y
      @mouse_active = true
      @schedule_ui_draw()

  move_mouse_position: (dx, dy, accel = 1.0) ->
    #accel = accel * 10
    oldx = @orbit_mouse.x
    oldy = @orbit_mouse.y
    @set_mouse_position(@orbit_mouse.x + (dx * accel), @orbit_mouse.y + (dy * accel))
    @orbit_mouse.x = @mouse.x
    @orbit_mouse.y = @mouse.y
    pos = @canvas_to_complex(@orbit_mouse.x, @orbit_mouse.y)
    @loc_c.innerText = @complex_to_string(pos)

    @defer_highres_frames = 1
    #console.log('old', oldx, oldy, 'dx', dx, 'dy', dy, 'accel', accel, 'new', @orbit_mouse.x, @orbit_mouse.y)

  mouse_step_up: (accel = 1.0) ->
    @move_mouse_position(0, -@option.keyboard_step.value, accel)

  mouse_step_down: (accel = 1.0) ->
    @move_mouse_position(0,  @option.keyboard_step.value, accel)

  mouse_step_left: (accel = 1.0) ->
    @move_mouse_position(-@option.keyboard_step.value, 0, accel)

  mouse_step_right: (accel = 1.0) ->
    @move_mouse_position( @option.keyboard_step.value, 0, accel)

  on_mouseenter: (event) =>
    @mouse_active = true
    @schedule_ui_draw()

  on_mouseout: (event) =>
    @mouse_active = false
    @schedule_ui_draw()

  on_julia_draw_local_true: =>
    @graph_julia_canvas.classList.remove('hidden')

  on_julia_draw_local_false: =>
    @graph_julia_canvas.classList.add('hidden')

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

    while (d <= 4) and (n < @mandel_maxiter)
      p =
        r: (z.r * z.r) - (z.i * z.i)
        i: 2 * z.r * z.i
      z =
        r: p.r + c.r
        i: p.i + c.i
      d = (z.r * z.r) + (z.i * z.i)
      n += 1

    [n, d <= 4]

  mandel_color_value: (x, y) ->
    c = @canvas_to_complex(x, y)
    [n, in_set] = @mandelbrot(c)
    if in_set
      0
    else
      n

  set_rendering_note: (text) ->
    if text?
      @rendering_note.classList.remove('hidden')
      @rendering_note_value.textContent = text
      @set_rendering_note_progress()
    else
      @rendering_note.classList.add('hidden')
      @rendering_note_value.textContent = ''

  hide_rendering_note: ->
    @set_rendering_note(null)

  set_rendering_note_progress: ->
    perc = parseInt(( @lines_finished / @graph_height) * 100)
    @rendering_note_progress.value = perc
    @rendering_note_progress.textContent = "#{perc}%"

  draw_background: ->
    @set_status('rendering')

    @graph_julia_ctx.clearRect(0, 0, @graph_width, @graph_height)

    @graph_mandel_ctx.fillStyle = 'rgb(0,0,0)'
    @graph_mandel_ctx.fillRect(0, 0, @graph_width, @graph_height)

    @render_pixel_size = @initial_render_pixel_size
    @lines_finished = 0
    @set_rendering_note("...")
    @schedule_background_render_pass()

  do_antialias: ->
    @antialias and @render_pixel_size <= 1

  schedule_background_render_pass: ->
    @render_mandel_img = @graph_mandel_ctx.getImageData(0, 0, @graph_width, @graph_height)

    render_msg = "#{@render_pixel_size}x"
    render_msg += " (antialias)" if @do_antialias()
    @set_rendering_note(render_msg)
    console.log(render_msg)

    setTimeout =>
      @deferred_background_render_callback()
    , 5

  schedule_background_render_more_lines: ->
    @set_rendering_note_progress()

    setTimeout =>
      @deferred_background_render_callback()
    , 0

  deferred_background_render_callback: ->
    elapsed = 0
    while (@lines_finished < @graph_height) and (elapsed < 1000)
      lastline = @render_mandelbrot(@render_pixel_size, @do_antialias())
      dirtyheight = lastline - @lines_finished
      @graph_mandel_ctx.putImageData(@render_mandel_img, 0, 0,  0, @lines_finished,   @graph_width, dirtyheight)
      @lines_finished = lastline
      elapsed = performance.now()

    if @lines_finished < @graph_height
      @schedule_background_render_more_lines()
    else if @render_pixel_size > 1
      @render_pixel_size /= @deferred_render_pass_scale
      @lines_finished = 0
      @schedule_background_render_pass()
    else
      console.log('finished rendering, @render_pixel_size = ' + @render_pixel_size)
      @hide_rendering_note()
      @set_status('normal')

  render_mandelbrot: (pixelsize, do_antialias) ->
    @mandel_maxiter = @option.mandel_max_iterations.value

    stopline = @lines_finished + @render_lines_per_pass
    if stopline >= @graph_height
      stopline = @graph_height

    @current_theme = @current_mandel_theme()
    @current_image = @render_mandel_img

    aamult = 2
    aastep = 1.0 / aamult

    for y in [@lines_finished..stopline] by pixelsize
      for x in [0..@graph_width] by pixelsize
        val = 0

        if do_antialias
          iter = 0
          for aay in [0..aamult] by aastep
            for aax in [0..aamult] by aastep
              val += @mandel_color_value(x + aax, y + aay)
              iter++

          val /= iter

        else
          val = @mandel_color_value(x, y)


        for py in [0..pixelsize]
          for px in [0..pixelsize]
            @render_pixel(x + px, y + py, val)

    return stopline

  render_pixel: (x, y, value) ->
    if x < @graph_width and y < @graph_height
      pos1x = x + (y * @graph_width)
      pos4x = 4 * pos1x

      value /= @mandel_maxiter
      @mandel_values[pos1x] = value
      @colorize_pixel(value, pos4x)

  colorize_pixel: (value, offset) ->
    value = Math.pow(value, 0.5) * 255
    @current_image.data[offset    ] = value * @current_theme[0]
    @current_image.data[offset + 1] = value * @current_theme[1]
    @current_image.data[offset + 2] = value * @current_theme[2]

  repaint_canvas: (ctx, values, theme) ->
    return unless ctx? and values?

    #@current_image = ctx.createImageData(@graph_width, @graph_height)
    @current_image = @graph_mandel_ctx.getImageData(0, 0, @graph_width, @graph_height)
    @current_theme = theme

    for y in [0..@graph_height]
      for x in [0..@graph_width]
        pos1x = x + (y * @graph_width)
        pos4x = 4 * pos1x
        @colorize_pixel(@mandel_values[pos1x], pos4x)
        @current_image.data[pos4x + 3] = 255

    ctx.putImageData(@current_image, 0, 0)

  repaint_mandelbrot: ->
    @repaint_canvas(@graph_mandel_ctx, @mandel_values, @current_mandel_theme())

  mandelbrot_orbit: (c, max_yield = @mandel_maxiter) ->
    n = 0
    d = 0
    z =
      r: 0
      i: 0

    yield z: z, n: n

    while (d <= 4) and (n < max_yield)
      p =
        r: (z.r * z.r) - (z.i * z.i)
        i: 2 * z.r * z.i
      z =
        r: p.r + c.r
        i: p.i + c.i
      d = (z.r * z.r) + (z.i * z.i)
      n += 1

      yield z: z, n: n

  draw_orbit: (c) ->
    mx = c.x
    my = c.y
    pos = @canvas_to_complex(mx, my)
    @loc_c.innerText = @complex_to_string(pos)

    draw_lines  = @option.orbit_draw_lines.value
    draw_points = @option.orbit_draw_points.value
    point_size  = @option.orbit_point_size.value
    julia_bb    = @option.julia_draw_local.value

    @graph_ui_ctx.save()

    @graph_ui_ctx.lineWidth = 2
    @graph_ui_ctx.strokeStyle = 'rgba(255,255,108,0.35)'
    @graph_ui_ctx.fillStyle   = 'rgba(255,249,187, 0.6)'

    if draw_lines
      @graph_ui_ctx.beginPath()
      @graph_ui_ctx.moveTo(mx, my)

    if draw_lines || draw_points
      if julia_bb
        @orbit_bb.min_x = @graph_width
        @orbit_bb.max_x = 0
        @orbit_bb.min_y = @graph_height
        @orbit_bb.max_y = 0

      for step from @mandelbrot_orbit(pos, @option.orbit_draw_length.value)
        if step.n > 0
          p = @complex_to_canvas(step.z)

          if draw_lines
            @graph_ui_ctx.lineTo(p.x, p.y)
            @graph_ui_ctx.stroke()

          if draw_points
            @graph_ui_ctx.beginPath()
            @graph_ui_ctx.arc(p.x, p.y, point_size, 0, TAU, false)
            @graph_ui_ctx.fill()

          if draw_lines
            @graph_ui_ctx.beginPath()
            @graph_ui_ctx.moveTo(p.x, p.y)

          if julia_bb
            @orbit_bb.min_x = Math.min(@orbit_bb.min_x, p.x)
            @orbit_bb.max_x = Math.max(@orbit_bb.max_x, p.x)
            @orbit_bb.min_y = Math.min(@orbit_bb.min_y, p.y)
            @orbit_bb.max_y = Math.max(@orbit_bb.max_y, p.y)

    isize = 3.2
    osize = isize * 3.4

    @graph_ui_ctx.beginPath()
    @graph_ui_ctx.save()

    @graph_ui_ctx.translate(mx, my)
    @graph_ui_ctx.rotate(@pointer_angle)
    @graph_ui_ctx.translate(-1 * mx, -1 * my)

    @graph_ui_ctx.moveTo(mx + isize, my + isize)  # BR
    @graph_ui_ctx.lineTo(mx + osize, my)          #    R
    @graph_ui_ctx.lineTo(mx + isize, my - isize)  # TR
    @graph_ui_ctx.lineTo(mx,         my - osize)  #    T
    @graph_ui_ctx.lineTo(mx - isize, my - isize)  # TL
    @graph_ui_ctx.lineTo(mx - osize, my        )  #    L
    @graph_ui_ctx.lineTo(mx - isize, my + isize)  # BL
    @graph_ui_ctx.lineTo(mx,         my + osize)  #    B
    @graph_ui_ctx.lineTo(mx + isize, my + isize)  # BR

    @graph_ui_ctx.fillStyle = 'rgba(255,249,187, 0.2)'
    @graph_ui_ctx.fill()

    @graph_ui_ctx.lineWidth = 1
    @graph_ui_ctx.strokeStyle = '#F09456'
    @graph_ui_ctx.stroke()

    @graph_ui_ctx.lineWidth = 1
    @graph_ui_ctx.strokeStyle = '#F2CE72'
    @graph_ui_ctx.stroke()

    @graph_ui_ctx.restore()

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

  julia: (c, z) ->
    n = 0
    d = 0
    zr = z.r
    zi = z.i

    while (d <= 4) and (n < @julia_maxiter)
      pr = (zr * zr) - (zi * zi)
      pi = 2 * zr * zi
      zr = pr + c.r
      zi = pi + c.i
      d = (zr * zr) + (zi * zi)
      n += 1

    [n, d <= 4]

  julia_color_value: (c, x, y) ->
    p = @canvas_to_complex(x, y)
    [n, in_set] = @julia(@canvas_to_complex(c.x, c.y), @canvas_to_complex(x, y))
    if in_set
      0
    else
      n

  draw_local_julia: (c) ->
    if (@local_julia.width > 0) and (@local_julia.height > 0)
      @graph_julia_ctx.clearRect(@local_julia.x, @local_julia.y, @local_julia.width, @local_julia.height)

    pixelsize = @option.julia_local_pixel_size.value
    @julia_maxiter = @option.julia_max_iterations.value
    opacity = Math.ceil(@option.julia_local_opacity.value * 256)

    highres = @pause_mode and @option.julia_more_when_paused.value
    if @defer_highres_frames > 0
      @defer_highres_frames = @defer_highres_frames - 1
      highres = false
      @schedule_ui_draw()

    if highres
      @local_julia.x = 0
      @local_julia.y = 0
      @local_julia.width  = @graph_width
      @local_julia.height = @graph_height
      pixelsize = 1
      @julia_maxiter = @option.julia_max_iter_paused.value

    else
      orbit_cx = Math.floor((@orbit_bb.max_x + @orbit_bb.min_x) / 2)
      orbit_cy = Math.floor((@orbit_bb.max_y + @orbit_bb.min_y) / 2)
      maxsize  = @option.julia_local_max_size.value
      margin2x = @option.julia_local_margin.value * 2
      @local_julia.width  = @orbit_bb.max_x - @orbit_bb.min_x + margin2x
      @local_julia.height = @orbit_bb.max_y - @orbit_bb.min_y + margin2x
      @local_julia.width  = Math.floor(@local_julia.width)
      @local_julia.height = Math.floor(@local_julia.height)
      @local_julia.width  = maxsize       if @local_julia.width  > maxsize
      @local_julia.height = maxsize       if @local_julia.height > maxsize
      @local_julia.width  = @graph_width  if @local_julia.width  > @graph_width
      @local_julia.height = @graph_height if @local_julia.height > @graph_height
      @local_julia.x = orbit_cx - Math.floor(@local_julia.width  / 2)
      @local_julia.y = orbit_cy - Math.floor(@local_julia.height / 2)
      @local_julia.x = 0 if @local_julia.x < 0
      @local_julia.y = 0 if @local_julia.y < 0
      maxx = Math.floor(@graph_width  - @local_julia.width)
      maxy = Math.floor(@graph_height - @local_julia.height)
      @local_julia.x = maxx if @local_julia.x > maxx
      @local_julia.y = maxy if @local_julia.y > maxy

    @current_image = @graph_julia_ctx.createImageData(@local_julia.width, @local_julia.height)
    @current_theme = @current_julia_theme()

    for y in [0..@local_julia.height] by pixelsize
      for x in [0..@local_julia.width] by pixelsize
        px = x + @local_julia.x
        py = y + @local_julia.y
        val = @julia_color_value(c, px, py)
        val /= 255

        for py in [0..pixelsize]
          for px in [0..pixelsize]
            pos1x = (x + px) + ((y + py) * @current_image.width)
            pos4x = 4 * pos1x
            @colorize_pixel(val, pos4x)
            @current_image.data[pos4x + 3] = opacity

    @graph_julia_ctx.putImageData(@current_image, @local_julia.x, @local_julia.y)

  draw_orbit_features: (c) ->
    @draw_orbit(c)
    if @option.julia_draw_local.value
      @draw_local_julia(c)

  draw_trace_animation: ->
    @draw_orbit_features(@current_trace_location)

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
    @draw_orbit(@orbit_mouse)

  draw_ui: ->
    @draw_ui_scheduled = false

    @graph_ui_ctx.clearRect(0, 0, @graph_width, @graph_height)

    @pointer_angle = @pointer_angle + @pointer_angle_step
    @pointer_angle = @pointer_angle - TAU if @pointer_angle >= TAU

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
        @draw_orbit_features(@orbit_mouse)
    else
      if @pause_mode
        @draw_orbit_features(@orbit_mouse)

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
