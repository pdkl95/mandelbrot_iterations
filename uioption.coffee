window.UI or= {}
class UI.Option
  @create_input_element: (type = null, id = null) ->
    el = window.APP.context.createElement('input')
    el.id = id if id?
    el.type = type if type?
    el

  constructor: (@id, default_value = null, @on_change_callback = null) ->
    if @id instanceof Element
      @el = @id
      @id = @el.id
    else
      @el = window.APP.context.getElementById(@id)
      unless @el?
        console.log("ERROR - could not find element with id=\"#{@id}\"")

    if default_value?
      @default = default_value
    else
      @default = @detect_default_value()

    @set(@default)

    @el.addEventListener('change', @on_change)

  detect_default_value: ->
    @get()

  on_change: (event) =>
    @set(@get(event.target))
    @on_change_callback(@value) if @on_change_callback?

  enable: ->
    @el.disabled = false

  disable: ->
    @el.disabled = true

  destroy: ->
    @el.remove() if @el?
    @el = null

class UI.BoolOption extends UI.Option
  @create: (parent, @id, rest...) ->
    opt = new UI.BoolOption(UIOption.create_input_element('checkbox', @id), rest...)
    parent.appendChild(opt.el)
    opt

  get: (element = @el) ->
    element.checked

  set: (bool_value) ->
    @value = switch bool_value
      when 'true'  then true
      when 'false' then false
      else
        !!bool_value
    @el.checked = @value

class UI.IntOption extends UI.Option
  @create: (parent, @id, rest...) ->
    opt = new UI.IntOption(UIOption.create_input_element('number', @id), rest...)
    parent.appendChild(opt.el)
    opt

  get: (element = @el) ->
    parseInt(element.value)

  set: (number_value) ->
    @value = parseInt(number_value)
    @el.value = @value

class UI.FloatOption extends UI.Option
  @create: (parent, @id, rest...) ->
    opt = new UI.IntOption(UIOption.create_input_element(null, @id), rest...)
    parent.appendChild(opt.el)
    opt

  get: (element = @el) ->
    parseFloat(element.value)

  set: (number_value) ->
    @value = parseFloat(number_value)
    @el.value = @value

class UI.SelectOption extends UI.Option
  get: (element = @el) ->
    element.options[element.selectedIndex].value

  set: (option_name) ->
    opt = @option_with_name(option_name)
    if opt?
      @value = opt.value
      opt.selected = true

  values: ->
    @el.options.map( (x) -> x.name )

  option_with_name: (name) ->
    for opt in @el.options
      if opt.value is name
        return opt
    return null
