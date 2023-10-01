(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.Dialog || (window.Dialog = {});

  Dialog.PopOut = (function() {
    function PopOut(content_id, title) {
      this.content_id = content_id;
      this.title = title;
      this.on_header_mousemove = bind(this.on_header_mousemove, this);
      this.on_header_mouseup = bind(this.on_header_mouseup, this);
      this.on_header_mousedown = bind(this.on_header_mousedown, this);
      this.on_close_click = bind(this.on_close_click, this);
      this.on_move_to_dialog_click = bind(this.on_move_to_dialog_click, this);
      this.move_to_dialog_id = this.content_id + "_move_to_dialog";
      this.content_el = document.getElementById(this.content_id);
      if (this.content_el == null) {
        APP.warn("Cannot find Dialog.Wrap target #" + this.content_id);
      }
      this.move_to_dialog_el = document.getElementById(this.move_to_dialog_id);
      if (this.move_to_dialog_el == null) {
        APP.warn("Cannot find Dialog.Wrap move_to_dialog button #" + this.content_id);
      }
      this.move_to_dialog_el.addEventListener('click', this.on_move_to_dialog_click);
    }

    PopOut.prototype.on_move_to_dialog_click = function(event) {
      return this.popout();
    };

    PopOut.prototype.popout = function() {
      var rect;
      this.move_to_dialog_el.classList.add('hidden');
      rect = this.content_el.getBoundingClientRect();
      this.x = 0;
      this.y = 0;
      this.original_parent = this.content_el.parentNode;
      this.wrap_el = document.createElement('div');
      this.wrap_el.classList.add('dialog_box');
      this.wrap_el.classList.add('dialog_wrap');
      this.close_el = document.createElement('button');
      this.close_el.classList.add('dialog_close');
      this.title_el = document.createElement('h3');
      this.title_el.classList.add('dialog_title');
      this.title_el.innerText = this.title;
      this.header_el = document.createElement('div');
      this.header_el.classList.add('dialog_header');
      this.header_el.appendChild(this.title_el);
      this.header_el.appendChild(this.close_el);
      this.body_el = document.createElement('div');
      this.body_el.classList.add('dialog_body');
      this.original_parent.insertBefore(this.wrap_el, this.content_el);
      this.wrap_el.appendChild(this.header_el);
      this.wrap_el.appendChild(this.content_el);
      this.close_el.addEventListener('click', this.on_close_click);
      this.header_el.addEventListener('mousedown', this.on_header_mousedown);
      this.header_el.addEventListener('mouseup', this.on_header_mouseup);
      this.header_el.addEventListener('mousemove', this.on_header_mousemove);
      return this.set_position();
    };

    PopOut.prototype.unpopout = function() {
      if ((this.wrap_el != null) && (this.original_parent != null) && (this.content_el != null)) {
        this.original_parent.insertBefore(this.content_el, this.wrap_el);
      }
      if (this.title_el != null) {
        this.title_el.remove();
        this.title_el = null;
      }
      if (this.close_el != null) {
        this.close_el.remove();
        this.close_el = null;
      }
      if (this.header_el != null) {
        this.header_el.remove();
        this.header_el = null;
      }
      if (this.body_el != null) {
        this.body_el.remove();
        this.body_el = null;
      }
      if (this.wrap_el != null) {
        this.wrap_el.remove();
        this.wrap_el = null;
      }
      return this.move_to_dialog_el.classList.remove('hidden');
    };

    PopOut.prototype.on_close_click = function(event) {
      return this.unpopout();
    };

    PopOut.prototype.on_header_mousedown = function(event) {
      this.drag = true;
      this.drag_start_x = event.pageX;
      return this.drag_start_y = event.pageY;
    };

    PopOut.prototype.update_drag_position = function(event) {
      var delta_x, delta_y;
      delta_x = event.pageX - this.drag_start_x;
      delta_y = event.pageY - this.drag_start_y;
      this.x += delta_x;
      return this.y += delta_y;
    };

    PopOut.prototype.on_header_mouseup = function(event) {
      this.update_drag_position(event);
      return this.drag = false;
    };

    PopOut.prototype.on_header_mousemove = function(event) {
      return this.update_drag_position(event);
    };

    PopOut.prototype.set_position = function() {
      var maxheight, maxwidth;
      maxwidth = document.body.clientWidth - this.wrap_el.clientWidth;
      maxheight = document.body.clientHeight - this.wrap_el.clientHeigh;
      if (this.x > maxwidth) {
        this.x = maxwidth;
      }
      if (this.x > maxheight) {
        this.x = maxheight;
      }
      if (this.x < 0) {
        this.x = 0;
      }
      if (this.y < 0) {
        this.y = 0;
      }
      this.wrap_el.style.left = (parseInt(this.x, 10)) + "px";
      return this.wrap_el.style.top = (parseInt(this.y, 10)) + "px";
    };

    return PopOut;

  })();

}).call(this);
