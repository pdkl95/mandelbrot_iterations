(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  window.Dialog || (window.Dialog = {});

  Dialog.Base = (function() {
    function Base() {
      this.on_header_mousemove = bind(this.on_header_mousemove, this);
      this.on_header_mouseup = bind(this.on_header_mouseup, this);
      this.on_header_mousedown = bind(this.on_header_mousedown, this);
      this.on_close_click = bind(this.on_close_click, this);
      this.on_show_dialog_click = bind(this.on_show_dialog_click, this);
      this.mousewrap_margin = 40;
      this.content_el = document.getElementById(this.content_id);
      if (this.content_el == null) {
        APP.warn("Cannot find Dialog.Wrap target #" + this.content_id);
      }
      this.show_dialog_el = document.getElementById(this.show_dialog_id);
      if (this.show_dialog_el == null) {
        APP.warn("Cannot find Dialog.Wrap show_dialog button #" + this.show_dialogid);
      }
      this.show_dialog_el.addEventListener('click', this.on_show_dialog_click);
    }

    Base.prototype.on_show_dialog_click = function(event) {
      if (this.wrap_el != null) {
        return this.hide();
      } else {
        return this.show();
      }
    };

    Base.prototype.show = function() {
      if (this.wrap_el != null) {
        return;
      }
      if (this.before_show != null) {
        this.before_show();
      }
      this.x || (this.x = 0);
      this.y || (this.y = 0);
      this.original_parent = this.content_el.parentNode;
      this.mousewrap_el = document.createElement('div');
      this.mousewrap_el.classList.add('dialog_mousewrap');
      this.wrap_el = document.createElement('div');
      this.wrap_el.classList.add('dialog_box');
      this.wrap_el.classList.add('dialog_wrap');
      this.close_el = document.createElement('button');
      this.close_el.classList.add('dialog_close');
      this.close_el.innerHTML = '&times;';
      this.title_el = document.createElement('h4');
      this.title_el.classList.add('dialog_title');
      this.title_el.innerText = this.title;
      this.header_el = document.createElement('div');
      this.header_el.classList.add('dialog_header');
      this.header_el.appendChild(this.title_el);
      this.header_el.appendChild(this.close_el);
      this.body_el = document.createElement('div');
      this.body_el.classList.add('dialog_body');
      this.original_parent.insertBefore(this.mousewrap_el, this.content_el);
      this.mousewrap_el.appendChild(this.wrap_el);
      this.wrap_el.appendChild(this.header_el);
      this.body_el.appendChild(this.content_el);
      this.wrap_el.appendChild(this.body_el);
      this.close_el.addEventListener('click', this.on_close_click);
      this.header_el.addEventListener('mousedown', this.on_header_mousedown);
      this.mousewrap_el.addEventListener('mouseup', this.on_header_mouseup);
      this.mousewrap_el.addEventListener('mousemove', this.on_header_mousemove);
      this.mousewrap_el.addEventListener("mouseleave", this.on_header_mouseleave);
      this.set_position();
      if (this.after_show != null) {
        return this.after_show();
      }
    };

    Base.prototype.hide = function() {
      if (this.wrap_el == null) {
        return;
      }
      if (this.before_hide != null) {
        this.before_hide();
      }
      if ((this.mousewrap_el != null) && (this.original_parent != null) && (this.content_el != null)) {
        this.original_parent.insertBefore(this.content_el, this.mousewrap_el);
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
      if (this.mousewrap_el != null) {
        this.mousewrap_el.remove();
        this.mousewrap_el = null;
      }
      if (this.after_hide != null) {
        return this.after_hide();
      }
    };

    Base.prototype.on_close_click = function(event) {
      return this.hide();
    };

    Base.prototype.on_header_mousedown = function(event) {
      this.drag = true;
      this.drag_x = event.pageX;
      return this.drag_y = event.pageY;
    };

    Base.prototype.update_drag_position = function(event) {
      var delta_x, delta_y, ox, oy;
      delta_x = event.pageX - this.drag_x;
      delta_y = event.pageY - this.drag_y;
      ox = this.x;
      oy = this.y;
      this.x += delta_x;
      this.y += delta_y;
      this.set_position();
      this.drag_x = event.pageX;
      return this.drag_y = event.pageY;
    };

    Base.prototype.on_header_mouseup = function(event) {
      if (this.drag) {
        this.update_drag_position(event);
        return this.drag = false;
      }
    };

    Base.prototype.on_header_mousemove = function(event) {
      if (this.drag) {
        return this.update_drag_position(event);
      }
    };

    Base.prototype.on_header_mouseleave = function(event) {
      return this.drag = false;
    };

    Base.prototype.set_position = function() {
      var maxheight, maxwidth, x, y;
      maxwidth = document.body.clientWidth - this.wrap_el.clientWidth + this.mousewrap_margin;
      maxheight = document.body.clientHeight - this.wrap_el.clientHeight + this.mousewrap_margin;
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
      x = parseInt(this.x - this.mousewrap_margin, 10);
      y = parseInt(this.y - this.mousewrap_margin, 10);
      this.mousewrap_el.style.left = x + "px";
      return this.mousewrap_el.style.top = y + "px";
    };

    return Base;

  })();

  Dialog.Static = (function(superClass) {
    extend(Static, superClass);

    function Static(content_id, title) {
      this.content_id = content_id;
      this.title = title;
      this.show_dialog_id = "show_" + this.content_id;
      Static.__super__.constructor.call(this, this.content_id, this.title);
    }

    Static.prototype.after_show = function() {
      return this.content_el.classList.remove('hidden');
    };

    Static.prototype.before_hide = function() {
      return this.content_el.classList.add('hidden');
    };

    return Static;

  })(Dialog.Base);

  Dialog.PopOut = (function(superClass) {
    extend(PopOut, superClass);

    function PopOut(content_id, title) {
      this.content_id = content_id;
      this.title = title;
      this.show_dialog_id = this.content_id + "_move_to_dialog";
      PopOut.__super__.constructor.call(this, this.content_id, this.title);
    }

    PopOut.prototype.before_show = function() {
      return this.show_dialog_el.classList.add('hidden');
    };

    PopOut.prototype.after_hide = function() {
      return this.show_dialog_el.classList.remove('hidden');
    };

    return PopOut;

  })(Dialog.Base);

}).call(this);
