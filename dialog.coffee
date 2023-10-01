window.Dialog or= {}

#class Dialog.Base
#  constructor: ->

class Dialog.PopOut #extends Dialog.Base
  constructor: (@content_id, @title) ->
    @move_to_dialog_id = "#{@content_id}_move_to_dialog"

    @mousewrap_margin = 40

    @content_el = document.getElementById(@content_id)
    unless @content_el?
      APP.warn("Cannot find Dialog.Wrap target ##{@content_id}")

    @move_to_dialog_el = document.getElementById(@move_to_dialog_id)
    unless @move_to_dialog_el?
      APP.warn("Cannot find Dialog.Wrap move_to_dialog button ##{@content_id}")

    @move_to_dialog_el.addEventListener('click', @on_move_to_dialog_click)

  on_move_to_dialog_click: (event) =>
    @popout()

  popout: ->
    @move_to_dialog_el.classList.add('hidden')

    @x = 0
    @y = 0

    @original_parent = @content_el.parentNode

    @mousewrap_el = document.createElement('div')
    @mousewrap_el.classList.add('dialog_mousewrap')

    @wrap_el = document.createElement('div')
    @wrap_el.classList.add('dialog_box')
    @wrap_el.classList.add('dialog_wrap')

    @close_el = document.createElement('button')
    @close_el.classList.add('dialog_close')
    @close_el.innerHTML = '&times;'

    @title_el = document.createElement('h4')
    @title_el.classList.add('dialog_title')
    @title_el.innerText = @title

    @header_el = document.createElement('div')
    @header_el.classList.add('dialog_header')
    @header_el.appendChild(@title_el)
    @header_el.appendChild(@close_el)

    @body_el = document.createElement('div')
    @body_el.classList.add('dialog_body')

    @original_parent.insertBefore(@mousewrap_el, @content_el)
    @mousewrap_el.appendChild(@wrap_el)
    @wrap_el.appendChild(@header_el)
    @body_el.appendChild(@content_el)
    @wrap_el.appendChild(@body_el)

    @close_el.addEventListener('click', @on_close_click)

    @header_el.addEventListener('mousedown',  @on_header_mousedown)
    @mousewrap_el.addEventListener('mouseup',    @on_header_mouseup)
    @mousewrap_el.addEventListener('mousemove',  @on_header_mousemove)
    @mousewrap_el.addEventListener("mouseleave", @on_header_mouseleave)

    @set_position()

  unpopout: ->
    if @mousewrap_el? and @original_parent? and @content_el?
      @original_parent.insertBefore(@content_el, @mousewrap_el)

    if @title_el?
      @title_el.remove()
      @title_el = null

    if @close_el?
      @close_el.remove()
      @close_el = null

    if @header_el?
      @header_el.remove()
      @header_el = null

    if @body_el?
      @body_el.remove()
      @body_el = null

    if @wrap_el?
      @wrap_el.remove()
      @wrap_el = null

    if @mousewrap_el?
      @mousewrap_el.remove()
      @mousewrap_el = null

    @move_to_dialog_el.classList.remove('hidden')

  on_close_click: (event) =>
    @unpopout()

  on_header_mousedown: (event) =>
    @drag = true
    @drag_x = event.pageX
    @drag_y = event.pageY

  update_drag_position: (event) ->
    delta_x = event.pageX - @drag_x
    delta_y = event.pageY - @drag_y
    ox = @x
    oy = @y
    @x += delta_x
    @y += delta_y
    #console.log("delta: (#{delta_x},#{delta_y}), pos: (#{ox},#{oy})->(#{@x},#{@y})")
    @set_position()

    @drag_x = event.pageX
    @drag_y = event.pageY

  on_header_mouseup: (event) =>
    @update_drag_position(event)
    @drag = false

  on_header_mousemove: (event) =>
    if @drag
      @update_drag_position(event)

  on_header_mouseleave: (event) ->
    @drag = false

  set_position: ->
    maxwidth  = document.body.clientWidth  - @wrap_el.clientWidth  + @mousewrap_margin
    maxheight = document.body.clientHeight - @wrap_el.clientHeight + @mousewrap_margin

    @x = maxwidth  if @x > maxwidth
    @x = maxheight if @x > maxheight
    @x = 0         if @x < 0
    @y = 0         if @y < 0

    x = parseInt(@x - @mousewrap_margin, 10)
    y = parseInt(@y - @mousewrap_margin, 10)

    @mousewrap_el.style.left = "#{x}px"
    @mousewrap_el.style.top  = "#{y}px"
