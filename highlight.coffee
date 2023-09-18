window.Highlight or= {}

Highlight.items = {}
Highlight.sequences = {}
Highlight.saved_locations = {}

class Highlight.Item
  @next_serialnum: ->
    @_serialnum ||= 0
    @_serialnum++

  constructor: (@r, @i, @name = null) ->
    @serial = Highlight.Item.next_serialnum()
    @id = "hl-item-#{@serial}"
    Highlight.items[@id] = this

class Highlight.SavedItem extends Highlight.Item
  @storage_id: (idx) ->
    "saved_loc[#{idx}]"

  constructor: (@parent_collection, args...) ->
    super(args...)
    @serial = Highlight.Sequence.next_serialnum()
    @name ||= "Save ##{@serial}"
    @row_id = "saved_item-row-#{@serial}"
    Highlight.saved_locations[@row_id] = this

  create_set_c_button: (value) ->
    text = APP.fmtfloat.format(value)
    el = document.createElement('a')
    el.innerText = text
    el.classList.add('set_c_button')
    el.addEventListener('xlixk', @on_set_c_button_click)
    el

  create_tr: (parent) ->
    return @tr_el if @tr_el?
    @tr_el = parent.insertRow(-1)
    @tr_el.id = @row_id

    @name_cell = @tr_el.insertCell(0)
    @real_cell = @tr_el.insertCell(1)
    @imag_cell = @tr_el.insertCell(2)
    @btn_cell  = @tr_el.insertCell(3)

    #@name_cell.contentEditable = 'plaintext-only'
    @name_cell.innerText = @name
    @real_cell.appendChild = @create_set_c_button(@r)
    @imag_cell.appendChild = @create_set_c_button(@i)

    @delete_button = document.createElement('button')
    @delete_button.classList.add('delete')
    @delete_button.innerHTML = '&times;'
    @delete_button.addEventListener('click', @on_delete_button_click)
    @btn_cell.appendChild(@delete_button)

    @tr_el

  serialize: ->
    if @name?
      "#{@r}|#{@i}|#{@name}"
    else
      "#{@r}|#{@i}"

  save: (idx) ->
    @save_idx = idx
    APP.storage_set(Highlight.SavedItem.storage_id(idx), @serialize())

  remove_storage: ->
    if @save_idx?
      APP.storage_remove(Highlight.SavedItem.storage_id(@save_idx))

  remove: ->
    @remove_storage()
    @tr_el.remove()
    idx = @parent_collection.items.indexOf(this)
    @parent_collection.items.splice(idx, 1)
    delete Highlight.saved_locations[@row_id]

  on_delete_button_click: (event) =>
    row = event.target.parentElement.parentElement
    if row?
      loc = Highlight.saved_locations[row.id]
      if loc?
        loc.remove()

  on_set_c_button_click: (event) =>
    row = event.target.parent
    loc = Highlight.saved_locations[row.id]
    console.log('set_c_button_click', 'row', row, 'loc', loc)
    loc.set_c() if loc?

  set_c: ->
    APP.animate_to(@complex_to_canvas(item))

class Highlight.SequenceItem
  li_title: ->
    "#{@r} + #{@i}i"

  create_li: ->
    el = document.createElement('li')
    el.id = @id
    el.classList.add('highlight_item')
    #el.classList.add('tt')
    #el.classList.add('ttleft')
    #el.setAttribute('data-title', @li_title())
    el.textContent = @name
    el

  li: ->
    @li_el ||= @create_li()

  select: ->
    for el in document.querySelectorAll('#highlight_list .highlight_item.selected')
      el.classList.remove('selected')
    @li_el.classList.add('selected')

class Highlight.ItemCollection
  constructor: ->
    @items = []

class Highlight.SavedLocations extends Highlight.ItemCollection
  @next_serialnum: ->
    @_serialnum ||= 0
    @_serialnum++

  constructor: (@id) ->
    super()

    @tbody_id = "#{@id}_body"
    @el       = document.getElementById(@id)
    @tbody_el = document.getElementById(@tbody_id)

  create_new_saved_item: (args...) ->
    new Highlight.SavedItem(this, args...)

  append: (item) ->
    item.create_tr(@tbody_el)
    @items.push(item)

  add: (z) ->
    @append(@create_new_saved_item(z.r, z.i))
    @save()

  save: ->
    for item, idx in @items
      item.save(idx)
    APP.storage_set('num_saved_locations', @items.length)

  deserialize: (str) ->
    new Highlight.SavedItem(this, str.split('|')...)

  load_item_from_storage: (idx) ->
    str = APP.storage_get(Highlight.SavedItem.storage_id(idx))
    if str?
      item = @deserialize(str)
      item.save_idx = idx
      item
    else
      null

  load_storage: ->
    n = APP.storage_get_int('num_saved_locations')
    for idx in [0..n]
      item = @load_item_from_storage(idx)
      @append(item) if item?

class Highlight.Sequence extends Highlight.ItemCollection
  @next_serialnum: ->
    @_serialnum ||= 0
    @_serialnum++

  constructor: (@group_name, @name) ->
    super()
    @serial = Highlight.Sequence.next_serialnum()
    @id = "hl-seq-#{@serial}" 
    Highlight.sequences[@id] = this

  description: ->
    "#{@group_name} - #{@name}"

  add: (item_args...) ->
    item = new Highlight.SequenceItem(item_args...)
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

