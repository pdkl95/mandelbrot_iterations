window.UI or= {}
class UI.Option
  @create_input_element: (type = null, id = null) ->
    el = window.APP.context.createElement('input')
    el.id = id if id?
    el.type = type if type?
    el

  constructor: (@id, @default, @on_change_callback = null) ->
    if @id instanceof Element
      @el = @id
      @id = @el.id
    else
      @el = window.APP.context.getElementById(@id)

    @set(@default)
    @el.addEventListener('change', @on_change)

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
