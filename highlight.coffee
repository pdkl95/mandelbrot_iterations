window.Highlight or= {}

Highlight.items = {}
Highlight.sequences = {}

class Highlight.Item
  @next_serialnum: ->
    @_serialnum ||= 0
    @_serialnum++

  constructor: (@r, @i, @name) ->
    @serial = Highlight.Item.next_serialnum()
    @id = "hl-item-#{@serial}"
    Highlight.items[@id] = this

  li_title: ->
    "#{@r} + #{@i}i"

  create_li: ->
    el = document.createElement('li')
    el.id = @id
    el.classList.add('highlight_item')
    el.classList.add('tt')
    el.classList.add('ttleft')
    el.setAttribute('data-title', @li_title())
    el.textContent = @name
    el

  li: ->
    @li_el ||= @create_li()

  select: ->
    for el in document.querySelectorAll('#highlight_list .highlight_item.selected')
      el.classList.remove('selected')
    @li_el.classList.add('selected')

class Highlight.Sequence
  @next_serialnum: ->
    @_serialnum ||= 0
    @_serialnum++

  constructor: (@group_name, @name) ->
    @serial = Highlight.Sequence.next_serialnum()
    @id = "hl-seq-#{@serial}"
    Highlight.sequences[@id] = this
    @items = []

  description: ->
    "#{@group_name} - #{@name}"

  add: (item_args...) ->
    item = new Highlight.Item(item_args...)
    @items.push(item)

  add_to_groups: (parent) ->
    @option_el = document.createElement('option')
    @option_el.id = @id
    @option_el.value = @id
    @option_el.textContent = @description()
    parent.appendChild(@option_el)

  li_items: ->
    @items.map (i) ->
      i.li()

  select: (list_el) ->
    @current_idx = 0
    list_el.replaceChildren()
    for li_el in @li_items()
      list_el.appendChild(li_el)

  current: ->
    @current_idx ?= 0
    @items[@current_idx]

  prev: ->
    @current_idx--
    if @current_idx < 0
      @current_idx = @items.length - 1
    @current()

  next: ->
    @current_idx++
    if @current_idx >= @items.length
      @current_idx = 0
    @current()


##########################################################################

natb = new Highlight.Sequence("Natural Numbers", "Bulbs")
natb.add   0.0,                  0.0,                  "Period 1 Cardioid"
natb.add  -1.0,                  0.0,                  "Period 2 Bulb"
natb.add  -0.13080895008605875,  0.7441860465116279,   "Period 3 Bulb"
natb.add   0.27710843373493965,  0.5322997416020672,   "Period 4 Bulb"
natb.add   0.37890705679862435,  0.3357622739018089,   "Period 5 Bulb"
natb.add   0.39013769363166784,  0.2164857881136979,   "Period 6 Bulb"
natb.add   0.37823580034423365,  0.1444961240310032,   "Period 7 Bulb"

natt = new Highlight.Sequence("Natural Numbers", "Tangent Point")
natt.add  -1.0,                  0.0,                  "Period 2 Tangent Point"
natt.add  -0.12534581653163057,  0.6494540047116335,   "Period 3 Tangent Point"
natt.add   0.25014244320041534,  0.4997574456139653,   "Period 4 Tangent Point"
natt.add   0.3565970347803682,   0.3288718747652626,   "Period 5 Tangent Point"
natt.add   0.3749373532678093,   0.21617198000410243,  "Period 6 Tangent Point"
natt.add   0.3673160480625435,   0.1471806613953346,   "Period 7 Tangent Point"

step7 = new Highlight.Sequence("Step Size", "Period 7")
step7.add  0.37823580034423365,  0.1444961240310032,   "Period 7 Step 1 Bulb (1/7)"
step7.add  0.12380378657487201,  0.613514211886304,    "Period 7 Step 2 Bulb (2/7)"
step7.add -0.6248795180722884,   0.42529715762273756,  "Period 7 Step 3 Bulb (3/7)"
step7.add -0.6248795180722884,  -0.42529715762273756,  "Period 7 Step 4 Bulb (4/7)"
step7.add  0.12380378657487201, -0.613514211886304,    "Period 7 Step 5 Bulb (5/7)"
step7.add  0.37823580034423365, -0.1444961240310032,   "Period 7 Step 6 Bulb (6/7)"

