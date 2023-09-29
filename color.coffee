window.Color or= {}

class Color.RGB
  constructor: (value = '#000000', gvalue = null, bvalue = null) ->
    if gvalue? and bvalue?
      @r =  value
      @g = gvalue
      @b = bvalue
    else
      @r = 0
      @g = 0
      @b = 0
      @set(value)

  set: (value) ->
    switch typeof value
      when "string"
        @set_string(value)
      when 'object'
        if value.r? and value.g? and value.b?
          @set_rgb(value.r, value.g, value.b)
        else
          APP.warn('Object is not Color.RGB-like', value)
      else
        console.log('cannot interpret as a color', value)

  _parse_byte: (x) ->
    value = switch typeof x
      when 'number'
        parseInt(x, 10)

      when 'string'
        if x.length is 1
          x = "#{x}#{x}"
        parseInt(x, 16)

      else
        APP.warn('Not a byte value', x)
        0

    if value < 0
      0
    else
      if value > 255
        255
      else
        value

  set_rgb: (r,g,b) ->
    @r = @_parse_byte(r)
    @g = @_parse_byte(g)
    @b = @_parse_byte(b)

  set_string: (str) ->
    md = str.match /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i
    if md?
      return @set_rgb(md[1], md[2], md[3]) 

    md = str.match /^#([0-9a-f])([0-9a-f])([0-9a-f])$/i
    if md?
      return @set_rgb(md[1], md[2], md[3])

    APP.warn("Invalid color string", str)
    this

  hexbyte: (byte) ->
    byte = 0   if byte < 0
    byte = 255 if byte > 255
    str = byte.toString(16)
    str = "0#{str}" if str.length < 2
    str

  linear_blend_rgb: (other, t) ->
    r = parseInt(((1 - t) * @r) + (t * other.r))
    g = parseInt(((1 - t) * @g) + (t * other.g))
    b = parseInt(((1 - t) * @b) + (t * other.b))
    return [r, g, b]

  rgb: ->
    [@r, @g, @b]

  to_hex: ->
    [ "#", @hexbyte(@r), @hexbyte(@g), @hexbyte(@b) ].join('')

  to_rgb: ->
    "rgb(#{@r},#{@g},#{@b})"

  to_rgba: (a) ->
    "rgbs(#{@r},#{@g},#{@b},#{a})"
    
class Color.Stop extends Color.RGB
  @compare: (a, b) ->
    a.position - b.position

  constructor: (@theme, position, rest...) ->
    super(rest...)
    @set_position(position)

  set_position: (value) ->
    @position = parseFloat(value)
    @position = 0 if @position < 0
    @position = 1 if @position > 1
    @update_editor_position() if @editor_el?
    @position

  prepare_editor: ->
    @editor_el = document.createElement('div')
    @editor_el.classList.add('color_stop')

    @editor_input = document.createElement('input')
    @editor_input.classList.add('hidden')
    @editor_input.setAttribute('type', 'color')
    @editor_input.setAttribute('tabindex', -1)
    @update_editor_input()

    @editor_el.appendChild(@editor_input)
    @theme.editor_stop_container.appendChild(@editor_el)

    @update_editor_bg(false)
    @update_editor_position()
    @editor_input.addEventListener('change', @on_editor_input_change)
    @editor_el.addEventListener('dblclick', @on_editor_dblclick)
    @editor_el.addEventListener('mousedown', @on_editor_mousedown)

  on_editor_input_change: (event) =>
    @set_string(@editor_input.value)
    @update_editor_bg()
    APP.repaint_mandelbrot()

  on_editor_dblclick: (event) =>
    @editor_input.click()

  update_editor_input: ->
    if @editor_input?
      @editor_input.value = @to_hex()

  on_editor_mousedown: (event) =>
    @theme.start_drag(this, event)

  position_percent: ->
    "#{@position * 100}%"

  update_editor_position: (update_theme = true) ->
    @editor_el.style.left = @position_percent()
    @theme.update_editor_gradient() if update_theme

  update_editor_bg: (update_theme = true) ->
    @editor_el.style.backgroundColor = @to_rgb()
    @theme.update_editor_gradient() if update_theme

  set_rgb: (r,g,b) ->
    super(r,g,b)
    if @editor_bg_el?
      @update_editor_bg()

  remove_editor: ->
    if @editor_el?
      @editor_el.remove()

  remove: ->
    @remove_editor()
    index = @theme.stops.indexOf(this)
    @theme.stops.splice(index, 1) if index?

    @theme.rebuild()

class Color.Theme
  constructor: (@name, @editor_id = null) ->
    @default_table_size = 256
    @named_color = {}
    @stops = []
    @table_size = 0

    @construct_editor() if @editor_id?

  find_stop_index: (pos) ->
    i = 0
    while i < @stops.length
      stop = @stops[i]
      if stop.position is pos
        return i
      i++
    return null

  add_stop: (position, value) ->
    if (position < 0) or (position > 1)
      APP.warn("Color positions in a Theme must satisfy 0 <= position <= 1")

    if @editor?
      for stop in @stops
        stop.remove_editor()
      @editor_stop_container.replaceChildren()

    color = new Color.Stop(this, position, value)
    #console.log("add stop pos=#{color.position}", color)
    index = @find_stop_index(position)
    if index?
      @stops[index] = color
    else
      @stops.push(color)
      @sort_stops()

    #console.log('new stops', @stops) 
    if @editor?
      for stop in @stops
        stop.prepare_editor()

    @rebuild()
    color

  sort_stops: ->
    @stops.sort(Color.Stop.compare)
    for i in [1..@stops.length]
      prev = @stops[i - 1]
      next = @stops[i]
      prev.next = next
      next.prev = prev if next

  set_color: (name, value) ->
    color = new Color.RGB(value)
    @named_color[name] = color

    switch name
      when 'escape_min'
        @add_stop(0, color)
      when 'escape_max'
        @add_stop(1, color)
    
  set_colors: (opt) ->
    for name, value of opt
      @set_color(name, value)

  rgb_at: (pos) ->
    pos = 0 if pos < 0
    pos = 1 if pos > 1

    stop_index = 0
    prev = @stops[stop_index++]
    next = @stops[stop_index++]

    while pos < prev.position
      prev = next
      next = @stops[stop_index++]

    delta = next.position - prev.position
    t = (pos - prev.position) / delta
    prev.linear_blend_rgb(next, t)

  rgb_hex_at: (pos) ->
    rgb = @rgb_at(pos)
    color = new Color.RGB(rgb...)
    color.to_hex()

  reset_lookup_table: (size = @default_table_size) ->
    @table = @build_lookup_table(size)

  build_lookup_table: (size = @default_table_size) ->
    if size > @table_size or !@table?
      bytes = size * 3
      console.log("building lookup table (size=#{size}, #{bytes} bytes)")
      console.log('stops', @stops)
      console.log('positions', @stops.map (x) -> x.position)
      @table = new Uint8ClampedArray(bytes)
      @table_size = size

    stop_index = 0
    prev = @stops[stop_index++]
    next = @stops[stop_index++]
    step = 1.0 / size
    pos = 0
    offset = 0
    delta = next.position

    while pos < 1.0
      if next? and pos >= next.position
        prev = next
        next = @stops[stop_index++]
        if next?
          delta = next.position - prev.position
        else
          delta = 0

      rgb = if next? and delta > 0
        t =(pos - prev.position) / delta
        prev.linear_blend_rgb(next, t)
      else
        prev.rgb()

      @table[offset    ] = rgb[0]
      @table[offset + 1] = rgb[1]
      @table[offset + 2] = rgb[2]

      offset += 3
      pos += step

  lookup: (value) ->
    @build_lookup_table() unless @table?
    value = Math.floor(value)
    value = value % @table_size
    value *= 3
    return [@table[value], @table[value + 1], @table[value + 2]]

  rebuild: (size = @default_table_size) ->
    return if @stops.length < 2
    #@reset_lookup_table(size)
    @table = null

  construct_editor: ->
    @editor = document.getElementById(@editor_id)
    @editor_bg_container = document.createElement('div')
    @editor_bg_container.classList.add('editor_bg_container')
    @editor_bg = document.createElement('div')
    @editor_bg.classList.add('editor_bg')
    @editor_bg.classList.add('noselect')
    @editor_bg.classList.add('clear_both')
    @editor_bg_container.appendChild(@editor_bg)
    @editor.appendChild(@editor_bg_container)

    @editor_stop_container = document.createElement('div')
    @editor_stop_container.classList.add('stop_container')
    @editor_stop_container.classList.add('noselect')
    @editor_stop_container.setAttribute('title', 'Click to add a color marker')
    @editor.appendChild(@editor_stop_container)

    @editor_footer = document.createElement('div')
    @editor_footer.classList.add('clear_both')
    @editor.appendChild(@editor_footer)

    @editor_bg.addEventListener('click', @on_editor_bg_click)

    @drag = null
    @editor.addEventListener('mouseup',   @on_editor_mouseup)
    @editor.addEventListener('mousemove', @on_editor_mousemove)

  editor_gradient_stops_css: ->
    stops = @stops.map (stop) ->
      "#{stop.to_rgb()} #{stop.position_percent()}"

    stops.join(', ')

  editor_linear_gradient_css: ->
    "linear-gradient(to right, #{@editor_gradient_stops_css()})"

  editor_background_css: ->
    "rgba(0,0,0,0) #{@editor_linear_gradient_css()} repeat scroll 0% 0%"

  update_editor_gradient: ->
    @editor_bg.style.background = @editor_background_css()
    @rebuild()

  start_drag: (stop, event) ->
    rect = event.target.getBoundingClientRect()
    @drag = stop
    @drag.editor_el.classList.add('drag')
    @drag_start_x = event.clientX - event.currentTarget.offsetLeft
    @drag_start_y = event.clientY - event.currentTarget.offsetTop
    @drag_x = @drag_start_x
    @drag_y = @drag_start_y

  update_drag_position: (event) ->
    rect = @editor_stop_container.getBoundingClientRect()
    width = rect.width
    start_offset = @drag.position * width
    new_offset = start_offset + event.movementX
    new_pos = new_offset / width
    @drag.set_position(new_pos)

  on_editor_mouseup: (event) =>
    if @drag?
      @update_drag_position(event)
      for el in document.querySelectorAll("##{@editor_id} .color_stop.drag")
        el.classList.remove('drag')
      @drag = null
      APP.repaint_mandelbrot()

  on_editor_mousemove: (event) =>
    if @drag?
      @update_drag_position(event)

  on_editor_bg_click: (event) =>
    rect = @editor_bg.getBoundingClientRect()
    start = rect.x
    width = rect.width
    x = event.clientX
    pos = (x - start) / width
    color = @rgb_hex_at(pos)
    @add_stop(pos, color)
