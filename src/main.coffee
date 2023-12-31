window.APP = null

TAU = Math.TAU = 2 * Math.PI

class MandelIter
  @deferred_background_render_callback = null

  @storage_prefix = "mandel_iter"

  constructor: (@context) ->

  init: () ->
    console.log('Starting init()...')

    @running = false

    @content_el    = @context.getElementById('content')
    @status        = @context.getElementById('status')
    @status_current = 'loading'

    @msgbox = @context.getElementById('msgbox')
    @msg    = @context.getElementById('msg')
    @msg_visible = false

    for hdr in @context.querySelectorAll('.collapse_header')
      hdr.addEventListener('click', @on_collapse_header_click)

    @cursor_color =
      light_orange:
        selected: true
        name:   'Light Orange'
        stroke: '#F2CE72'
        fill:   'rgba(255,249,187, 0.2)'
      deep_sky_blue:
        name:   'Deep Sky Blue'
        stroke: '#00BFFF'
        fill:   'rgba(176,224,230, 0.2)'
      chartreuse:
        name:   'Chartreuse'
        stroke: '#7FFF00'
        fill:   'rgba(194,241,146, 0.2)'
      hot_pink:
        name:   'Hot Pink'
        stroke: '#FF69B4'
        fill:   'rgba(247,195,221, 0.2)'

    @theme = {}
    @theme.mandel = new Color.Theme('mandelbrot', 'mandel_external_color')
    @theme.mandel.set_colors
      internal:   '#000000'
      escape_min: '#000000'
      escape_max: '#FFFFFF'

    @theme.julia = new Color.Theme('julia')
    @theme.julia.set_colors
      internal:   '#000000'
      escape_min: '#000000'
      escape_max: '#FFFFFF'
    @theme.julia.add_stop 0.2, '#280A28'
    @theme.julia.add_stop 0.6, '#8D008D'
    @theme.julia.add_stop 0.8, '#AE64AE'

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

    window.addEventListener('resize', @on_content_wrapper_resize)

    for tabbutton in @context.querySelectorAll('.tabbutton')
      tabbutton.addEventListener('click', @on_tabbutton_click)

    @loc_c      = @context.getElementById('loc_c')
    @loc_radius = @context.getElementById('loc_radius')
    @loc_theta  = @context.getElementById('loc_theta')

    @button_reset   = @context.getElementById('button_reset')
    @button_zoom    = @context.getElementById('button_zoom')
    @zoom_amount    = @context.getElementById('zoom_amount')
    @btn_save_loc   = @context.getElementById('save_loc')
    @btn_save_c     = @context.getElementById('save_c')
    @button_set_c   = @context.getElementById('set_c')
    @loc_to_set_c   = @context.getElementById('copy_loc_to_set_c')
    @reset_storage  = @context.getElementById('reset_all_storage')
    @save_to_file   = @context.getElementById('save_to_file')
    @mandel_redraw  = @context.getElementById('mandel_redraw')
    @mandel_use_color_preset = @context.getElementById('mandel_use_color_preset')

    @button_reset.addEventListener(  'click',  @on_button_reset_click)
    @button_zoom.addEventListener(   'click',  @on_button_zoom_click)
    @zoom_amount.addEventListener(   'change', @on_zoom_amount_change)
    @btn_save_loc.addEventListener(  'click',  @on_btn_save_loc_click)
    @btn_save_c.addEventListener(    'click',  @on_btn_save_c_click)
    @button_set_c.addEventListener(  'click',  @on_button_set_c_click)
    @loc_to_set_c.addEventListener(  'click',  @on_copy_loc_to_set_c_click)
    @reset_storage.addEventListener( 'click',  @on_reset_storage_click)
    @save_to_file.addEventListener(  'click',  @on_save_to_file_click)
    @mandel_redraw.addEventListener( 'click',  @on_mandel_redraw_click)
    @mandel_use_color_preset.addEventListener('click', @on_mandel_use_color_preset_click)

    @keyhelp_dialog = new Dialog.Static('keyhelp', 'Keyboard Controls')
    @mandel_external_color_dialog = new Dialog.PopOut('mandel_external_color', 'Mandelbrot Color')

    @option =
      show_tooltips:            new UI.BoolOption('show_tooltips', true)
      confirm_remove_saved_loc: new UI.BoolOption('confirm_remove_saved_loc', true)
      set_c_real:               new UI.FloatOption('set_c_real')
      set_c_imag:               new UI.FloatOption('set_c_imag')
      keyboard_step:            new UI.FloatOption('keyboard_step', 0.01)
      highlight_trace_path:     new UI.BoolOption('highlight_trace_path', false)
      highlight_internal_angle: new UI.BoolOption('highlight_internal_angle', false)
      trace_path_edge_distance: new UI.FloatOption('trace_path_edge_distance')
      trace_speed:              new UI.FloatOption('trace_speed')
      orbit_draw_length:        new UI.IntOption('orbit_draw_length')
      orbit_draw_lines:         new UI.BoolOption('orbit_draw_lines', true)
      orbit_draw_points:        new UI.BoolOption('orbit_draw_points', true)
      orbit_point_size:         new UI.FloatOption('orbit_point_size', 2)
      orbit_skip_initial:       new UI.BoolOption('orbit_skip_initial_results', false)
      orbit_skip_num:           new UI.IntOption('orbit_skip_initial_num', 20)
      julia_draw_local:         new UI.BoolOption('julia_draw_local', false)
      julia_more_when_paused:   new UI.BoolOption('julia_more_when_paused', true)
      julia_local_margin:       new UI.IntOption('julia_local_margin', 80)
      julia_local_max_size:     new UI.IntOption('julia_local_max_size', 650)
      julia_local_opacity:      new UI.PercentOption('julia_local_opacity', 0.6)
      julia_local_pixel_size:   new UI.IntOption('julia_local_pixel_size', 3)
      julia_max_iter_paused:    new UI.IntOption('julia_max_iter_paused', 350)
      julia_max_iterations:     new UI.IntOption('julia_max_iterations', 80)
      julia_antialias:          new UI.SelectOption('julia_antialias');
      mandel_antialias:         new UI.SelectOption('mandel_antialias');
      mandel_max_iterations:    new UI.IntOption('mandel_max_iterations', 120)
      mandel_color_internal:    new UI.ColorOption('mandel_color_internal')
      mandel_color_preset:      new UI.SelectOption('mandel_color_preset');
      highlight_group:          new UI.SelectOption('highlight_group');
      cursor_color:             new UI.SelectOption('cursor_color');

    @option.orbit_skip_initial.register_callback on_change: @schedule_ui_draw
    @option.orbit_skip_num.register_callback     on_change: @schedule_ui_draw

    @option.julia_draw_local.persist = false

    @option.julia_draw_local.register_callback
      on_true:  @on_julia_draw_local_true
      on_false: @on_julia_draw_local_false

    @option.julia_more_when_paused.register_callback
      on_true:  @on_julia_more_when_paused_true
      on_false: @on_julia_more_when_paused_false

    @option.julia_local_margin.register_callback     on_change: @on_julia_changed
    @option.julia_local_max_size.register_callback   on_change: @on_julia_changed
    @option.julia_local_opacity.register_callback    on_change: @on_julia_changed
    @option.julia_local_pixel_size.register_callback on_change: @on_julia_changed
    @option.julia_max_iter_paused.register_callback  on_change: @on_julia_changed
    @option.julia_max_iterations.register_callback   on_change: @on_julia_changed
    @option.julia_antialias.register_callback        on_change: @on_julia_changed

    @option.julia_local_pixel_size.set_label_text_formater (value) -> "#{value}x"

    @option.highlight_group.register_callback       on_change: @on_highlight_group_changed
    @option.mandel_color_internal.register_callback on_change: @on_mandel_color_changed

    Color.Theme.prepare_presets(@option.mandel_color_preset)

    cursor_index = 1
    for cc_index, opt of @cursor_color
      @option.cursor_color.add_option(cc_index, opt.name, opt?.selected)
      cursor_index++

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

    @pause_anim = null
    @defer_resize = false
    @pause_mode = false
    @zoon_mode = false
    @antialias = true
    @reset_renderbox()
    @draw_ui_scheduled = false
    @rendering_mode = false

    @shift_step_accel = 0.333
    @ctrl_step_accel  = 0.1
    @alt_step_accel   = 0.01

    @defer_highres_frames = 0
    @deferred_render_passes = 3
    @deferred_render_pass_scale = 3
    @initial_render_pixel_size = @deferred_render_pass_scale ** @deferred_render_passes
    @render_lines_per_pass = 24
    @julia_max_rendertime = 200
    @defer_highres_timeout = 
    @defer_highres_timeout_length = 650
    @highlight_msg_fade_time = 3000

    @rendering_note          = @context.getElementById('rendering_note')
    @rendering_note_hdr      = @context.getElementById('rendering_note_hdr')
    @rendering_note_value    = @context.getElementById('rendering_note_value')
    @rendering_note_progress = @context.getElementById('rendering_note_progress')

    @highlight_prev = @context.getElementById('highlight_prev')
    @highlight_next = @context.getElementById('highlight_next')
    @highlight_list = @context.getElementById('highlight_list')

    for seq_id, seq of Highlight.sequences
      seq.add_to_groups(@option.highlight_group.el)

    @highlight_prev.addEventListener('click', @on_highlight_prev_click)
    @highlight_next.addEventListener('click', @on_highlight_next_click)
    @highlight_list.addEventListener('click', @on_highlight_list_click)

    @load_from_file_uploader = new FileIO.Uploader('load_from_file_input', 'load_from_file')
    @load_from_file_uploader.on_upload(@on_load_from_file_upload)

    @saved_locations = new Highlight.SavedLocations('saved_locations')
    @saved_locations_tab_button = @context.getElementById('saved_locations_tab_button')
    if @saved_locations.load_storage() > 0
      @show_saved_locations()

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
    document.addEventListener('keyup',   @on_keyup)

    @draw_local_julia_init()

    @on_highlight_group_changed()

    if @storage_get('pause_mode')
      stored_x = @storage_get_float('orbit_mouse_x')
      stored_y = @storage_get_float('orbit_mouse_y')
      if stored_x? and stored_y?
        @pause_mode_on(false)
        @set_mouse_position(stored_x, stored_y, true)
        @reset_julia_rendering()

    @theme.mandel.mark_default_and_load()
    @theme.julia.mark_default_and_load()
    @theme_mandel_update()
    
    console.log('init() completed!')

    @draw_background()


  on_keydown: (event) =>
    for type in ['INPUT', 'TD']
      return if event.target.nodeName is type

    accel = 1.0
    accel = @shift_step_accel if event.shiftKey
    accel =  @ctrl_step_accel if event.ctrlKey or event.metaKey
    accel =   @alt_step_accel if event.altKey

    switch event.code
      when 'ShiftLeft', 'ShiftRight'
        @shift_mode_on()

      when 'KeyP', 'Backspace'
        @highlight_prev_item()

      when 'KeyN', 'Enter'
        @highlight_next_item()

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

  on_keyup: (event) =>
    for type in ['INPUT', 'TD']
      return if event.target.nodeName is type

    switch event.code
      when 'ShiftLeft', 'ShiftRight'
        @shift_mode_off()

  debug: (msg) ->
    unless @debugbox?
      @debugbox     = @context.getElementById('debugbox')
      @debugbox_hdr = @context.getElementById('debugbox_hdr')
      @debugbox_msg = @context.getElementById('debugbox_msg')
      @debugbox.classList.remove('hidden')

    timestamp = new Date()
    @debugbox_hdr.textContent = timestamp.toISOString()
    @debugbox_msg.textContent = '' + msg

  warn: (msg) ->
    console.log("WARNING", msg)
    @set_highlight_msg("WARNING: #{msg}")

  on_collapse_header_click: (event) ->
    hdr = event.target
    hide_id = hdr.dataset.collapse_hide
    show_id = hdr.dataset.collapse_show
    hide = document.getElementById(hide_id)
    show = document.getElementById(show_id)

    if hdr.classList.contains('collapsed')
      hdr.classList.remove('collapsed')
      hide.classList.remove('hidden')
      show.classList.add('hidden')
    else
      hdr.classList.add('collapsed')
      hide.classList.add('hidden')
      show.classList.remove('hidden')

  on_tabbutton_click: (event) =>
    @tabbutton_activate(event.target)

  tabbutton_activate: (btn) ->
    panel = @context.getElementById(btn.id.replace(/_button$/, ''))
    for el in document.querySelectorAll('.tabbutton.active, .tabpanel.active')
      el.classList.remove('active')

    btn.classList.add('active')
    panel.classList.add('active')

  show_saved_locations: ->
    @tabbutton_activate(@saved_locations_tab_button)

  storage_key: (key) ->
    "#{@constructor.storage_prefix}-#{key}"

  storage_set: (key, value, default_value = null) ->
    if default_value? and (default_value is value)
      @storage_remove(key)
    else
      localStorage.setItem(@storage_key(key), value)

  storage_get: (key) ->
    localStorage.getItem(@storage_key(key))

  storage_get_int: (key) ->
    parseInt(@storage_get(key))

  storage_get_float: (key) ->
    parseFloat(@storage_get(key))

  storage_remove: (key) ->
    localStorage.removeItem(@storage_key(key))

  on_reset_storage_click: =>
    return unless window.confirm("Remove ALL persistent storage and reset ALL values back to defaults?")
    @storage_remove('pause_mode')
    @storage_remove('orbit_mouse_x')
    @storage_remove('orbit_mouse_y')

    for name, opt of @option
      opt.reset()

    @theme.mandel.reset()
    @theme.julia.reset()

    @on_mandel_color_changed()

  saved_locations_serialize: =>
    JSON.stringify({ saved_locations: @saved_locations.to_json_obj() })

  on_save_to_file_click: (event) =>
    date = new Date(Date.now())
    filename = "mandel_iter-saved_locations-#{date.toJSON()}.json"
    filedata = @saved_locations_serialize()
    FileIO.download(filename, filedata, 'application/json')

  on_load_from_file_upload: (filedata) =>
    objs = JSON.parse(filedata)?.saved_locations
    if objs?
      @saved_locations.load_json_objs(objs)

  use_fractal_colors: (opt = {}) ->
    if opt.internal?
      @fract_color_internal = opt.internal
    if opt.escape_min?
      @fract_color_escape_min = opt.escape_min
    if opt.escape_max?
      @fract_color_escape_max = opt.escape_max

  use_mandel_colors: ->
    @use_fractal_colors(@default_mandel_colors)

  use_julia_colors: ->
    @use_fractal_colors(@default_julia_colors)

  on_mandel_color_change: =>
    @repaint_mandelbrot()

  on_mandel_use_color_preset_click: =>
    @theme.mandel.load_preset_by_index(@option.mandel_color_preset.value)
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

  hide_highlight_msg: =>
    if @msg_visible
      @msg.textContent = ''
      @msgbox.classList.add('hidden')
      @msg_visible = false

  set_highlight_msg: (text) =>
    @msg.textContent = text
    @msgbox.classList.remove('hidden')
    @msg_visible = true

  current_highlight_group: ->
    return null if @option.highlight_group.value is 0
    Highlight.sequences[@option.highlight_group.value]

  on_highlight_group_changed: =>
    g = @current_highlight_group()
    if g?
      @show_highlight_buttons()
      g.select(@highlight_list)
    else
      @hide_highlight_buttons()
      @highlight_list.replaceChildren()
      @hide_highlight_msg()

  select_highlight_item: (item) ->
    if item?
      item.select()
      @animate_to(@complex_to_canvas(item))
      @set_highlight_msg(item.name)

  highlight_prev_item: ->
    g = @current_highlight_group()
    @select_highlight_item(g.prev()) if g?

  highlight_next_item: ->
    g = @current_highlight_group()
    @select_highlight_item(g.next()) if g?

  on_highlight_prev_click: =>
    @highlight_prev_item()

  on_highlight_next_click: =>
    @highlight_next_item()

  on_highlight_list_click: (event) =>
    t = event.target
    if (t.tagName is "LI") and t.classList.contains('highlight_item')
      @select_highlight_item(Highlight.items[t.id])

  hide_highlight_buttons: ->
    @highlight_prev.classList.add('invis')
    @highlight_next.classList.add('invis')
    @highlight_list.classList.add('invis')

  show_highlight_buttons: ->
    @highlight_prev.classList.remove('invis')
    @highlight_next.classList.remove('invis')
    @highlight_list.classList.remove('invis')

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
    if performance.now() < @deferred_fit_time
      console.log('waiting for deferrewd fit timeout...')
      return

    console.log('deferred - REDRAWING MANDELBROT')
    @fit_canvas_to_width()
    @draw_background()
    @defer_resize = false

  on_content_wrapper_resize: (event) =>
    if @defer_resize
      console.log("already deferred, resetting timeout")
      @deferred_fit_time = performance.now() + 200
    else
      console.log('setting deferred fit timeout')
      @defer_resise = true
      @deferred_fit_time = performance.now() + 500
      setTimeout(@deferred_fit_canvas_to_width, 510)

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

  restore_normal_status: ->
    if @pause_mode
      @set_status('paused')
    else
      @set_status('normal')

  shift_mode_on: ->
    @shift_mode = true
    @content_el.classList.add('shift_mode')

  shift_mode_off: ->
    @shift_mode = false
    @content_el.classList.remove('shift_mode')

  pause_mode_on: (persist = true) ->
    @pause_mode = true
    @ljopt.changed = true
    @set_status('paused')
    if persist
      @storage_set('pause_mode', @pause_mode)
      @storage_set('orbit_mouse_x', @orbit_mouse.x)
      @storage_set('orbit_mouse_y', @orbit_mouse.y)

  pause_mode_off: ->
    @pause_mode = false
    @ljopt.busy = false
    @ljopt.changed = true
    @schedule_ui_draw()
    @set_status('normal')
    @hide_highlight_msg()
    @storage_remove('pause_mode')
    @storage_remove('orbit_mouse_x')
    @storage_remove('orbit_mouse_y')

  pause_mode_toggle: ->
    if @pause_mode
      @pause_mode_off()
    else
      @pause_mode_on()

  zoom_mode_on: ->
    @zoom_mode = true
    if @pause_mode
      @zoom_save_pause_position = @canvas_to_complex(@orbit_mouse.x, @orbit_mouse.y)

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
    @hide_highlight_msg()

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

  on_mandel_redraw_click: () =>
    @draw_background()

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

  zoom_to_window: ->
    w = @get_zoom_window()
    newstart = @canvas_to_complex(w.x, w.y)
    newend   = @canvas_to_complex(w.x + w.w, w.y + w.h)
    @renderbox.start = newstart
    @renderbox.end   = newend

    zpos = @zoom_save_pause_position
    @zoom_mode_off()
    @zoom_save_pause_position = zpos

    @zoom_save_julia_draw_local = @option.julia_draw_local.value
    @option.julia_draw_local.set(false)
    @draw_background()

  on_graph_click: (event) =>
    if @zoom_mode
      @zoom_to_window()
    else
      @pause_mode_toggle()

  on_mousemove: (event) =>
    unless @rendering_mode
      @set_mouse_position(event.layerX, event.layerY)

  set_mouse_position: (newx, newy, force = false) ->
    oldx = @mouse.x
    oldy = @mouse.y
    @mouse.x = newx
    @mouse.y = newy

    @mouse.x = 0 if @mouse.x < 0
    @mouse.y = 0 if @mouse.y < 0
    @mouse.x = @graph_width  if @mouse.x > @graph_width
    @mouse.y = @graph_height if @mouse.y > @graph_height

    if (oldx != @mouse.x) or (oldy != @mouse.y)
      if !@pause_mode or force
        @orbit_mouse.x = @mouse.x
        @orbit_mouse.y = @mouse.y
        @ljopt.changed = true
      @mouse_active = true
      @schedule_ui_draw()

  move_mouse_position: (dx, dy, accel = 1.0, force = false) ->
    oldx = @orbit_mouse.x
    oldy = @orbit_mouse.y
    @set_mouse_position(@orbit_mouse.x + (dx * accel), @orbit_mouse.y + (dy * accel), force)
    @orbit_mouse.x = @mouse.x
    @orbit_mouse.y = @mouse.y
    pos = @canvas_to_complex(@orbit_mouse.x, @orbit_mouse.y)
    @loc_c.innerText = @complex_to_string(pos)

    @reset_julia_rendering()
    @defer_highres_frames = 1
    @defer_highres_timeout = performance.now() + @defer_highres_timeout_length

  mouse_step_up: (accel = 1.0) ->
    @move_mouse_position(0, -@option.keyboard_step.value, accel, true)

  mouse_step_down: (accel = 1.0) ->
    @move_mouse_position(0,  @option.keyboard_step.value, accel, true)

  mouse_step_left: (accel = 1.0) ->
    @move_mouse_position(-@option.keyboard_step.value, 0, accel, true)

  mouse_step_right: (accel = 1.0) ->
    @move_mouse_position( @option.keyboard_step.value, 0, accel, true)

  on_button_set_c_click: (event) =>
    z =
      r: parseFloat(@option.set_c_real.value)
      i: parseFloat(@option.set_c_imag.value)

    unless isNaN(z.r) or isNaN(z.i)
      @animate_to(@complex_to_canvas(z))

  on_btn_save_c_click: (event) =>
    @show_saved_locations()
    z =
      r: parseFloat(@option.set_c_real.value)
      i: parseFloat(@option.set_c_imag.value)
    @saved_locations.add(z)
    @show_saved_locations()

  on_copy_loc_to_set_c_click: (event) =>
    @update_current_trace_location()
    loc = @current_trace_location
    pos = @canvas_to_complex(loc.x, loc.y)
    @option.set_c_real.set(pos.r)
    @option.set_c_imag.set(pos.i)

  on_btn_save_loc_click: (event) =>
    @update_current_trace_location()
    loc = @current_trace_location
    pos = @canvas_to_complex(loc.x, loc.y)
    @saved_locations.add(pos)
    @show_saved_locations()

  on_mouseenter: (event) =>
    @mouse_active = true
    @schedule_ui_draw()

  on_mouseout: (event) =>
    @mouse_active = false
    @schedule_ui_draw()

  on_julia_draw_local_true: =>
    @graph_julia_canvas.classList.remove('hidden')
    @reset_julia_rendering()

  on_julia_draw_local_false: =>
    @graph_julia_canvas.classList.add('hidden')
    @reset_julia_rendering()

  on_julia_more_when_paused_true: =>
    @reset_julia_rendering()

  on_julia_more_when_paused_false: =>
    @reset_julia_rendering()

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
    cr = c.r
    ci = c.i

    # cardioid quick test  (buggy?)
    #cr4 = cr - 0.25
    #q = cr4 + (ci * ci)
    #if (q * (q + cr4)) <= (0.25 * ci * ci)
    #  return [@mandel_maxiter, true]

    # period 2 buln quick test
    zr1 = zr + 1
    if ((zr1 * zr1) + (zi * zi)) <= 0.0625
      return [@mandel_maxiter, true]

    n = 0
    d = 0
    zr = 0
    zi = 0

    while (d <= 4) and (n < @mandel_maxiter)
      pr = (zr * zr) - (zi * zi)
      pi = 2 * zr * zi
      zr = pr + cr
      zi = pi + ci
      d  = (zr * zr) + (zi * zi)
      n += 1

    [n, d <= 4]

  mandelbrot_orbit: (c, max_yield = @mandel_maxiter, skip = 0) ->
    cr = c.r
    ci = c.i
    n = 0
    d = 0
    zr = 0
    zi = 0

    if skip is 0
      yield z: {r: zr, i: zi}, n: n
    else
      max_yield += skip

    while (d <= 4) and (n < max_yield)
      pr = (zr * zr) - (zi * zi)
      pi = 2 * zr * zi
      zr = pr + cr
      zi = pi + ci
      d  = (zr * zr) + (zi * zi)
      n += 1

      if skip > 0
        skip -= 1
      else
        yield z: {r: zr, i: zi}, n: n

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
    else
      @rendering_note.classList.add('hidden')
      @rendering_note_value.textContent = ''

  hide_rendering_note: ->
    @set_rendering_note(null)

  set_rendering_note_progress: (perc = null) ->
    perc ?= @lines_finished / @graph_height
    perc = parseInt(perc * 100)
    @rendering_note_progress.value = perc
    @rendering_note_progress.textContent = "#{perc}%"

  draw_background: ->
    @set_status('rendering')
    @rendering_mode = true

    @graph_julia_ctx.clearRect(0, 0, @graph_width, @graph_height)

    @graph_mandel_ctx.fillStyle = 'rgb(0,0,0)'
    @graph_mandel_ctx.fillRect(0, 0, @graph_width, @graph_height)

    @render_pixel_size = @initial_render_pixel_size
    @lines_finished = 0
    @set_rendering_note("...")
    @set_rendering_note_progress()
    @schedule_background_render_pass()

  do_antialias: ->
    @option.mandel_antialias.value > 1 and @render_pixel_size <= 1

  schedule_background_render_pass: ->
    @render_mandel_img = @graph_mandel_ctx.getImageData(0, 0, @graph_width, @graph_height)

    render_msg = "#{@render_pixel_size}x"
    render_msg += " (antialias)" if @do_antialias()
    @set_rendering_note(render_msg)
    @set_rendering_note_progress()

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
      @rendering_mode = false
      @hide_rendering_note()
      @restore_normal_status()
      if @zoom_save_pause_position?
        pos = @complex_to_canvas(@zoom_save_pause_position)
        console.log('zoom restore', @zoom_save_pause_position, pos)
        @zoom_save_pause_position = null
        @pause_mode_on()
        @option.julia_draw_local.set(@zoom_save_julia_draw_local)
        @animate_to(pos)

  render_mandelbrot: (pixelsize, do_antialias) ->
    @mandel_maxiter = @option.mandel_max_iterations.value

    stopline = @lines_finished + @render_lines_per_pass
    if stopline >= @graph_height
      stopline = @graph_height

    @current_theme = @theme.mandel
    @current_image = @render_mandel_img
    @current_internal_color = @current_theme.named_color.internal

    aamult = @option.mandel_antialias.value
    aastep = 1.0 / aamult

    if aamult is 1
      do_antialias = false

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
      @mandel_values[pos1x] = value
      @colorize_pixel(value, pos4x)

  colorize_pixel: (value, offset) ->
    if value is 0
      @current_image.data[offset    ] = @current_internal_color.r
      @current_image.data[offset + 1] = @current_internal_color.g
      @current_image.data[offset + 2] = @current_internal_color.b
    else
      value = Math.pow(value, 0.5) * 25
      rgb = @current_theme.lookup(value)
      @current_image.data[offset    ] = rgb[0]
      @current_image.data[offset + 1] = rgb[1]
      @current_image.data[offset + 2] = rgb[2]

  repaint_canvas: (ctx, values, theme) ->
    return unless ctx? and values?

    @current_image = @graph_mandel_ctx.getImageData(0, 0, @graph_width, @graph_height)
    @current_theme = theme
    @current_internal_color = @current_theme.named_color.internal

    for y in [0..@graph_height]
      for x in [0..@graph_width]
        pos1x = x + (y * @graph_width)
        pos4x = 4 * pos1x
        @colorize_pixel(@mandel_values[pos1x], pos4x)
        @current_image.data[pos4x + 3] = 255

    ctx.putImageData(@current_image, 0, 0)

  repaint_mandelbrot: ->
    @repaint_canvas(@graph_mandel_ctx, @mandel_values, @theme.mandel)

  theme_mandel_update: ->
    @theme.mandel.set_colors
      internal:   @option.mandel_color_internal.value
    @theme.mandel.rebuild()

  on_mandel_color_changed: =>
    @theme_mandel_update()
    @repaint_mandelbrot()

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

    do_skip = @option.orbit_skip_initial.value
    skip = 0
    skip_first_line = false
    if do_skip
      skip = @option.orbit_skip_num.value
      skip_first_line = true

    if draw_lines and not do_skip
      @graph_ui_ctx.beginPath()
      @graph_ui_ctx.moveTo(mx, my)

    if draw_lines || draw_points
      if julia_bb
        @orbit_bb.min_x = @graph_width
        @orbit_bb.max_x = 0
        @orbit_bb.min_y = @graph_height
        @orbit_bb.max_y = 0

      for step from @mandelbrot_orbit(pos, @option.orbit_draw_length.value, skip)
        if step.n > 0
          p = @complex_to_canvas(step.z)

          if draw_lines
            if skip_first_line
              skip_first_line = false
            else
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

    cc_index = @option.cursor_color.value

    @graph_ui_ctx.fillStyle = @cursor_color[cc_index].fill
    @graph_ui_ctx.fill()

    @graph_ui_ctx.lineWidth = 1
    @graph_ui_ctx.strokeStyle = @cursor_color[cc_index].stroke
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

  draw_local_julia_init: ->
    @ljopt =
      busy:         false
      ystart:       0
      c:            null
      pixelsize:    @option.julia_local_pixel_size.value
      opacity:      Math.ceil(@option.julia_local_opacity.value * 256)
      do_antialias:  false
      do_early_stop: false
      aamult:        1
      aastep:        1.0
      highres:       @pause_mode and @option.julia_more_when_paused.value
      meeds_clear:   false

    @old_local_julia =
      x: 0
      y: 0
      width:  @graph_width
      height: @graph_height

  draw_local_julia_setup: (c) ->
    return false unless @ljopt.changed

    @old_local_julia.x      = @local_julia.x
    @old_local_julia.y      = @local_julia.y
    @old_local_julia.width  = @local_julia.height
    @old_local_julia.height = @local_julia.height

    @ljopt.c             = c
    @ljopt.pixelsize     = @option.julia_local_pixel_size.value
    @ljopt.opacity       = Math.ceil(@option.julia_local_opacity.value * 256)
    @ljopt.do_antialias  = false
    @ljopt.aamult        = 1
    @ljopt.aastep        = 1.0
    @ljopt.highres       = @pause_mode and @option.julia_more_when_paused.value
    @ljopt.do_early_stop = @ljopt.highres
    @ljopt.needs_clear   = true

    @julia_maxiter = @option.julia_max_iterations.value

    if @defer_highres_frames > 0
      @defer_highres_frames = @defer_highres_frames - 1
      @ljopt.highres = false
      @schedule_ui_draw()
      return false

    if @defer_highres_timeout > 0
      delta = @defer_highres_timeout - performance.now()
      if delta > 0
        barmargin = 2
        barheight = 3
        backheight = barheight + barmargin + barmargin
        barperc = (@defer_highres_timeout_length - delta) / @defer_highres_timeout_length
        @graph_ui_ctx.save()
        @graph_ui_ctx.fillStyle = 'rgba(30,30,30,0.55)'
        @graph_ui_ctx.fillRect(0, @graph_height - backheight - 1, @graph_width, backheight)
        @graph_ui_ctx.fillStyle = 'rgba(240,60,60,0.72)'
        @graph_ui_ctx.fillRect(1, @graph_height - barheight - barmargin - 1, (@graph_width * barperc) - 1, barheight)
        @graph_ui_ctx.restore()

        @ljopt.highres = false
        @schedule_ui_draw()
        return false
      else
        @defer_highres_timeout = 0

    @ljopt.busy   = true
    @ljopt.ystart = 0

    if @pause_anim?
      @ljopt.highres = false

    if @ljopt.highres
      @local_julia.x = 0
      @local_julia.y = 0
      @local_julia.width  = @graph_width
      @local_julia.height = @graph_height
      @ljopt.pixelsize = 1
      @julia_maxiter = @option.julia_max_iter_paused.value
      @ljopt.aamult = @option.julia_antialias.value
      if @ljopt.aamult > 0
        @ljopt.aastep = 1.0 / @ljopt.aamult
        @ljopt.do_antialias = true

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
    @current_theme = @theme.julia
    @current_internal_color = @current_theme.named_color.internal

    return true

  clear_julia: ->
    if @ljopt.needs_clear
      @ljopt.needs_clear = false
      @graph_julia_ctx.clearRect(0, 0, @graph_width, @graph_height)

  draw_local_julia: (lj) ->
    start_time = performance.now()
    rowcount = 0
    for y in [@ljopt.ystart..@local_julia.height] by @ljopt.pixelsize
      for x in [0..@local_julia.width] by @ljopt.pixelsize
        xx = x + @local_julia.x
        yy = y + @local_julia.y

        val = 0

        if @ljopt.do_antialias
          iter = 0
          for aay in [0..@ljopt.aamult] by @ljopt.aastep
            for aax in [0..@ljopt.aamult] by @ljopt.aastep
              val += @julia_color_value(@ljopt.c, xx + aax, yy + aay)
              iter++
          val /= iter

        else
          val = @julia_color_value(@ljopt.c, xx, yy)

        for py in [0..@ljopt.pixelsize]
          rowcount++
          for px in [0..@ljopt.pixelsize]
            pos1x = (x + px) + ((y + py) * @current_image.width)
            pos4x = 4 * pos1x
            @colorize_pixel(val, pos4x)
            @current_image.data[pos4x + 3] = @ljopt.opacity

      if @ljopt.do_early_stop
        if (y % 10) == 0
          if (performance.now() - start_time) > @julia_max_rendertime
            @clear_julia()
            @graph_julia_ctx.putImageData(@current_image, @local_julia.x, @local_julia.y, 0, @ljopt.ystart, @local_julia.width, @local_julia.height - @ljopt.ystart)
            @ljopt.ystart = y + @ljopt.pixelsize
            @schedule_ui_draw()
            @set_status('rendering')
            @set_rendering_note("#{y} / #{@local_julia.height} Julia lines")
            @set_rendering_note_progress(y/@local_julia.height)
            return

    @clear_julia()
    @graph_julia_ctx.putImageData(@current_image, @local_julia.x, @local_julia.y, 0, @ljopt.ystart, @local_julia.width, @local_julia.height - @ljopt.ystart)
    @reset_julia_rendering(@ljopt.highres and @pause_mode)

  reset_julia_rendering: (stoprender = false) ->
    @ljopt.changed = !stoprender
    @ljopt.busy = false

    @hide_rendering_note()
    @restore_normal_status()

    @schedule_ui_draw()

  on_julia_changed: =>
    @ljopt.changed = true
    @schedule_ui_draw()

  draw_orbit_features: (c) ->
    @draw_orbit(c)
    if @option.julia_draw_local.value
      if @ljopt.busy
        @draw_local_julia()
      else
        if @draw_local_julia_setup(c)
          @draw_local_julia()

  draw_trace_animation: ->
    @draw_orbit_features(@current_trace_location)

    unless @pause_mode
      @trace_angle = @trace_angle + @option.trace_speed.value
      @trace_angle = @trace_angle - TAU if @trace_angle >= TAU
      @trace_slider.value = @trace_angle

  animate_to: (pos) ->
    @pause_mode_on()
    @reset_julia_rendering()
    @pause_anim = new Motion.Anim(@orbit_mouse, pos, 32)
    @pause_anim.saved_color = @msg.style.color
    @update_pause_anim()

  update_pause_anim: ->
    return unless @pause_anim?
 
    pos = @pause_anim.next()
    @set_mouse_position(pos.x, pos.y, true)
    if @pause_anim.finished()
      @msg.style.color = @pause_anim.finished_color()
      @pause_anim = null
    else
      @msg.style.color = @pause_anim.highlight_color()
      @schedule_ui_draw()

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

  update_current_trace_location: ->
    if @trace_animation_enabled
      @current_trace_location = @cardioid(@trace_angle)
    else
      @current_trace_location = @orbit_mouse

  draw_ui: ->
    @draw_ui_scheduled = false

    @graph_ui_ctx.clearRect(0, 0, @graph_width, @graph_height)

    @pointer_angle = @pointer_angle + @pointer_angle_step
    @pointer_angle = @pointer_angle - TAU if @pointer_angle >= TAU

    @update_current_trace_location()

    if @option.highlight_trace_path.value
      @draw_cardioid_trace_path()

    if @option.highlight_internal_angle.value
      @draw_cardioid_internal_angle()

    # exclusive modes

    if @trace_animation_enabled
      @draw_trace_animation()

    else
      @update_pause_anim()

      if @mouse_active
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
