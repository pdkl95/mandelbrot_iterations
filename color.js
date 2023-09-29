(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  window.Color || (window.Color = {});

  Color.RGB = (function() {
    function RGB(value, gvalue, bvalue) {
      if (value == null) {
        value = '#000000';
      }
      if (gvalue == null) {
        gvalue = null;
      }
      if (bvalue == null) {
        bvalue = null;
      }
      if ((gvalue != null) && (bvalue != null)) {
        this.r = value;
        this.g = gvalue;
        this.b = bvalue;
      } else {
        this.r = 0;
        this.g = 0;
        this.b = 0;
        this.set(value);
      }
    }

    RGB.prototype.set = function(value) {
      switch (typeof value) {
        case "string":
          return this.set_string(value);
        case 'object':
          if ((value.r != null) && (value.g != null) && (value.b != null)) {
            return this.set_rgb(value.r, value.g, value.b);
          } else {
            return APP.warn('Object is not Color.RGB-like', value);
          }
          break;
        default:
          return console.log('cannot interpret as a color', value);
      }
    };

    RGB.prototype._parse_byte = function(x) {
      var value;
      value = (function() {
        switch (typeof x) {
          case 'number':
            return parseInt(x, 10);
          case 'string':
            if (x.length === 1) {
              x = "" + x + x;
            }
            return parseInt(x, 16);
          default:
            APP.warn('Not a byte value', x);
            return 0;
        }
      })();
      if (value < 0) {
        return 0;
      } else {
        if (value > 255) {
          return 255;
        } else {
          return value;
        }
      }
    };

    RGB.prototype.set_rgb = function(r, g, b) {
      this.r = this._parse_byte(r);
      this.g = this._parse_byte(g);
      return this.b = this._parse_byte(b);
    };

    RGB.prototype.set_string = function(str) {
      var md;
      md = str.match(/^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i);
      if (md != null) {
        return this.set_rgb(md[1], md[2], md[3]);
      }
      md = str.match(/^#([0-9a-f])([0-9a-f])([0-9a-f])$/i);
      if (md != null) {
        return this.set_rgb(md[1], md[2], md[3]);
      }
      APP.warn("Invalid color string", str);
      return this;
    };

    RGB.prototype.hexbyte = function(byte) {
      var str;
      if (byte < 0) {
        byte = 0;
      }
      if (byte > 255) {
        byte = 255;
      }
      str = byte.toString(16);
      if (str.length < 2) {
        str = "0" + str;
      }
      return str;
    };

    RGB.prototype.linear_blend_rgb = function(other, t) {
      var b, g, r;
      r = parseInt(((1 - t) * this.r) + (t * other.r));
      g = parseInt(((1 - t) * this.g) + (t * other.g));
      b = parseInt(((1 - t) * this.b) + (t * other.b));
      return [r, g, b];
    };

    RGB.prototype.rgb = function() {
      return [this.r, this.g, this.b];
    };

    RGB.prototype.to_hex = function() {
      return ["#", this.hexbyte(this.r), this.hexbyte(this.g), this.hexbyte(this.b)].join('');
    };

    RGB.prototype.to_rgb = function() {
      return "rgb(" + this.r + "," + this.g + "," + this.b + ")";
    };

    RGB.prototype.to_rgba = function(a) {
      return "rgbs(" + this.r + "," + this.g + "," + this.b + "," + a + ")";
    };

    return RGB;

  })();

  Color.Stop = (function(superClass) {
    extend(Stop, superClass);

    Stop.compare = function(a, b) {
      return a.position - b.position;
    };

    function Stop() {
      var position, rest, theme;
      theme = arguments[0], position = arguments[1], rest = 3 <= arguments.length ? slice.call(arguments, 2) : [];
      this.theme = theme;
      this.on_editor_mousedown = bind(this.on_editor_mousedown, this);
      this.on_editor_dblclick = bind(this.on_editor_dblclick, this);
      this.on_editor_input_change = bind(this.on_editor_input_change, this);
      Stop.__super__.constructor.apply(this, rest);
      this.set_position(position);
    }

    Stop.prototype.set_position = function(value) {
      this.position = parseFloat(value);
      if (this.position < 0) {
        this.position = 0;
      }
      if (this.position > 1) {
        this.position = 1;
      }
      if (this.editor_el != null) {
        this.update_editor_position();
      }
      return this.position;
    };

    Stop.prototype.prepare_editor = function() {
      this.editor_el = document.createElement('div');
      this.editor_el.classList.add('color_stop');
      this.editor_input = document.createElement('input');
      this.editor_input.classList.add('hidden');
      this.editor_input.setAttribute('type', 'color');
      this.editor_input.setAttribute('tabindex', -1);
      this.update_editor_input();
      this.editor_el.appendChild(this.editor_input);
      this.theme.editor_stop_container.appendChild(this.editor_el);
      this.update_editor_bg(false);
      this.update_editor_position();
      this.editor_input.addEventListener('change', this.on_editor_input_change);
      this.editor_el.addEventListener('dblclick', this.on_editor_dblclick);
      return this.editor_el.addEventListener('mousedown', this.on_editor_mousedown);
    };

    Stop.prototype.on_editor_input_change = function(event) {
      this.set_string(this.editor_input.value);
      this.theme.save();
      this.update_editor_bg();
      return APP.repaint_mandelbrot();
    };

    Stop.prototype.on_editor_dblclick = function(event) {
      return this.editor_input.click();
    };

    Stop.prototype.update_editor_input = function() {
      if (this.editor_input != null) {
        return this.editor_input.value = this.to_hex();
      }
    };

    Stop.prototype.on_editor_mousedown = function(event) {
      return this.theme.start_drag(this, event);
    };

    Stop.prototype.position_percent = function() {
      return (this.position * 100) + "%";
    };

    Stop.prototype.update_editor_position = function(update_theme) {
      if (update_theme == null) {
        update_theme = true;
      }
      this.editor_el.style.left = this.position_percent();
      if (update_theme) {
        return this.theme.update_editor_gradient();
      }
    };

    Stop.prototype.update_editor_bg = function(update_theme) {
      if (update_theme == null) {
        update_theme = true;
      }
      this.editor_el.style.backgroundColor = this.to_rgb();
      if (update_theme) {
        return this.theme.update_editor_gradient();
      }
    };

    Stop.prototype.set_rgb = function(r, g, b) {
      Stop.__super__.set_rgb.call(this, r, g, b);
      if (this.editor_bg_el != null) {
        return this.update_editor_bg();
      }
    };

    Stop.prototype.remove_editor = function() {
      if (this.editor_el != null) {
        return this.editor_el.remove();
      }
    };

    Stop.prototype.remove = function() {
      var index;
      this.remove_editor();
      index = this.theme.stops.indexOf(this);
      if (index != null) {
        this.theme.stops.splice(index, 1);
      }
      return this.theme.rebuild();
    };

    Stop.prototype.serialize = function() {
      return {
        position: this.position,
        color: this.to_hex()
      };
    };

    return Stop;

  })(Color.RGB);

  Color.Theme = (function() {
    Theme.storage_id = function(name) {
      return "color_theme[" + name + "]";
    };

    function Theme(name1, editor_id) {
      this.name = name1;
      this.editor_id = editor_id != null ? editor_id : null;
      this.on_editor_bg_click = bind(this.on_editor_bg_click, this);
      this.on_editor_mousemove = bind(this.on_editor_mousemove, this);
      this.on_editor_mouseup = bind(this.on_editor_mouseup, this);
      this.default_table_size = 256;
      this.named_color = {};
      this.stops = [];
      this.table_size = 0;
      if (this.editor_id != null) {
        this.construct_editor();
      }
    }

    Theme.prototype.mark_default_and_load = function() {
      this.default_state = this.serialize();
      return this.load();
    };

    Theme.prototype.reset = function() {
      this.remove_storage();
      this.deserialize(this.default_state);
      return this.rebuild();
    };

    Theme.prototype.serialize = function() {
      var color, name, named, obj, ref;
      named = {};
      ref = this.named_color;
      for (name in ref) {
        color = ref[name];
        named[name] = color.to_hex();
      }
      obj = {
        table_size: this.table_size,
        named_color: named,
        stops: this.stops.map(function(s) {
          return s.serialize();
        })
      };
      return JSON.stringify(obj);
    };

    Theme.prototype.deserialize = function(str) {
      var hex, j, len, name, obj, ref, ref1, results, s;
      obj = JSON.parse(str);
      if (obj.named_color != null) {
        this.named_color = {};
        ref = obj.named_color;
        for (name in ref) {
          hex = ref[name];
          this.named_color[name] = new Color.RGB(hex);
        }
      }
      if (obj.stops != null) {
        while (this.stops.length > 0) {
          this.stops[0].remove();
        }
        this.stops = [];
        ref1 = obj.stops;
        results = [];
        for (j = 0, len = ref1.length; j < len; j++) {
          s = ref1[j];
          results.push(this.add_stop(s.position, s.color));
        }
        return results;
      }
    };

    Theme.prototype.save = function() {
      var state;
      if (this.default_state != null) {
        state = this.serialize();
        if (state === this.default_state) {
          return this.remove_storage();
        } else {
          return APP.storage_set(Color.Theme.storage_id(this.name), state);
        }
      }
    };

    Theme.prototype.load = function() {
      var str;
      str = APP.storage_get(Color.Theme.storage_id(this.name));
      if (str != null) {
        return this.deserialize(str);
      }
    };

    Theme.prototype.remove_storage = function() {
      return APP.storage_remove(Color.Theme.storage_id(this.name));
    };

    Theme.prototype.find_stop_index = function(pos) {
      var i, stop;
      i = 0;
      while (i < this.stops.length) {
        stop = this.stops[i];
        if (stop.position === pos) {
          return i;
        }
        i++;
      }
      return null;
    };

    Theme.prototype.add_stop = function(position, value) {
      var color, index, j, k, len, len1, ref, ref1, stop;
      if ((position < 0) || (position > 1)) {
        APP.warn("Color positions in a Theme must satisfy 0 <= position <= 1");
      }
      if (this.editor != null) {
        ref = this.stops;
        for (j = 0, len = ref.length; j < len; j++) {
          stop = ref[j];
          stop.remove_editor();
        }
        this.editor_stop_container.replaceChildren();
      }
      color = new Color.Stop(this, position, value);
      index = this.find_stop_index(position);
      if (index != null) {
        this.stops[index] = color;
      } else {
        this.stops.push(color);
        this.sort_stops();
      }
      if (this.editor != null) {
        ref1 = this.stops;
        for (k = 0, len1 = ref1.length; k < len1; k++) {
          stop = ref1[k];
          stop.prepare_editor();
        }
      }
      this.save();
      this.rebuild();
      return color;
    };

    Theme.prototype.sort_stops = function() {
      var i, j, next, prev, ref, results;
      this.stops.sort(Color.Stop.compare);
      results = [];
      for (i = j = 1, ref = this.stops.length; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
        prev = this.stops[i - 1];
        next = this.stops[i];
        prev.next = next;
        if (next) {
          results.push(next.prev = prev);
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Theme.prototype.set_color = function(name, value) {
      var color;
      color = new Color.RGB(value);
      this.named_color[name] = color;
      switch (name) {
        case 'escape_min':
          return this.add_stop(0, color);
        case 'escape_max':
          return this.add_stop(1, color);
      }
    };

    Theme.prototype.set_colors = function(opt) {
      var name, results, value;
      results = [];
      for (name in opt) {
        value = opt[name];
        results.push(this.set_color(name, value));
      }
      return results;
    };

    Theme.prototype.rgb_at = function(pos) {
      var delta, next, prev, stop_index, t;
      if (pos < 0) {
        pos = 0;
      }
      if (pos > 1) {
        pos = 1;
      }
      stop_index = 0;
      prev = this.stops[stop_index++];
      next = this.stops[stop_index++];
      while (pos < prev.position) {
        prev = next;
        next = this.stops[stop_index++];
      }
      delta = next.position - prev.position;
      t = (pos - prev.position) / delta;
      return prev.linear_blend_rgb(next, t);
    };

    Theme.prototype.rgb_hex_at = function(pos) {
      var color, rgb;
      rgb = this.rgb_at(pos);
      color = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Color.RGB, rgb, function(){});
      return color.to_hex();
    };

    Theme.prototype.reset_lookup_table = function(size) {
      if (size == null) {
        size = this.default_table_size;
      }
      return this.table = this.build_lookup_table(size);
    };

    Theme.prototype.build_lookup_table = function(size) {
      var bytes, delta, next, offset, pos, prev, results, rgb, step, stop_index, t;
      if (size == null) {
        size = this.default_table_size;
      }
      if (size > this.table_size || (this.table == null)) {
        bytes = size * 3;
        this.table = new Uint8ClampedArray(bytes);
        this.table_size = size;
      }
      stop_index = 0;
      prev = this.stops[stop_index++];
      next = this.stops[stop_index++];
      step = 1.0 / size;
      pos = 0;
      offset = 0;
      delta = next.position;
      results = [];
      while (pos < 1.0) {
        if ((next != null) && pos >= next.position) {
          prev = next;
          next = this.stops[stop_index++];
          if (next != null) {
            delta = next.position - prev.position;
          } else {
            delta = 0;
          }
        }
        rgb = (next != null) && delta > 0 ? (t = (pos - prev.position) / delta, prev.linear_blend_rgb(next, t)) : prev.rgb();
        this.table[offset] = rgb[0];
        this.table[offset + 1] = rgb[1];
        this.table[offset + 2] = rgb[2];
        offset += 3;
        results.push(pos += step);
      }
      return results;
    };

    Theme.prototype.lookup = function(value) {
      if (this.table == null) {
        this.build_lookup_table();
      }
      value = Math.floor(value);
      value = value % this.table_size;
      value *= 3;
      return [this.table[value], this.table[value + 1], this.table[value + 2]];
    };

    Theme.prototype.rebuild = function(size) {
      if (size == null) {
        size = this.default_table_size;
      }
      if (this.stops.length < 2) {
        return;
      }
      return this.table = null;
    };

    Theme.prototype.construct_editor = function() {
      this.editor = document.getElementById(this.editor_id);
      this.editor_bg_container = document.createElement('div');
      this.editor_bg_container.classList.add('editor_bg_container');
      this.editor_bg = document.createElement('div');
      this.editor_bg.classList.add('editor_bg');
      this.editor_bg.classList.add('noselect');
      this.editor_bg.classList.add('clear_both');
      this.editor_bg_container.appendChild(this.editor_bg);
      this.editor.appendChild(this.editor_bg_container);
      this.editor_stop_container = document.createElement('div');
      this.editor_stop_container.classList.add('stop_container');
      this.editor_stop_container.classList.add('noselect');
      this.editor_stop_container.setAttribute('title', 'Click to add a color marker');
      this.editor.appendChild(this.editor_stop_container);
      this.editor_footer = document.createElement('div');
      this.editor_footer.classList.add('clear_both');
      this.editor.appendChild(this.editor_footer);
      this.editor_bg.addEventListener('click', this.on_editor_bg_click);
      this.drag = null;
      this.editor.addEventListener('mouseup', this.on_editor_mouseup);
      return this.editor.addEventListener('mousemove', this.on_editor_mousemove);
    };

    Theme.prototype.editor_gradient_stops_css = function() {
      var stops;
      stops = this.stops.map(function(stop) {
        return (stop.to_rgb()) + " " + (stop.position_percent());
      });
      return stops.join(', ');
    };

    Theme.prototype.editor_linear_gradient_css = function() {
      return "linear-gradient(to right, " + (this.editor_gradient_stops_css()) + ")";
    };

    Theme.prototype.editor_background_css = function() {
      return "rgba(0,0,0,0) " + (this.editor_linear_gradient_css()) + " repeat scroll 0% 0%";
    };

    Theme.prototype.update_editor_gradient = function() {
      this.editor_bg.style.background = this.editor_background_css();
      return this.rebuild();
    };

    Theme.prototype.start_drag = function(stop, event) {
      var rect;
      rect = event.target.getBoundingClientRect();
      this.drag = stop;
      this.drag.editor_el.classList.add('drag');
      this.drag_start_x = event.clientX - event.currentTarget.offsetLeft;
      this.drag_start_y = event.clientY - event.currentTarget.offsetTop;
      this.drag_x = this.drag_start_x;
      return this.drag_y = this.drag_start_y;
    };

    Theme.prototype.update_drag_position = function(event) {
      var new_offset, new_pos, rect, start_offset, width;
      rect = this.editor_stop_container.getBoundingClientRect();
      width = rect.width;
      start_offset = this.drag.position * width;
      new_offset = start_offset + event.movementX;
      new_pos = new_offset / width;
      this.drag.set_position(new_pos);
      return this.save();
    };

    Theme.prototype.on_editor_mouseup = function(event) {
      var el, j, len, ref;
      if (this.drag != null) {
        this.update_drag_position(event);
        ref = document.querySelectorAll("#" + this.editor_id + " .color_stop.drag");
        for (j = 0, len = ref.length; j < len; j++) {
          el = ref[j];
          el.classList.remove('drag');
        }
        this.drag = null;
        return APP.repaint_mandelbrot();
      }
    };

    Theme.prototype.on_editor_mousemove = function(event) {
      if (this.drag != null) {
        return this.update_drag_position(event);
      }
    };

    Theme.prototype.on_editor_bg_click = function(event) {
      var color, pos, rect, start, width, x;
      rect = this.editor_bg.getBoundingClientRect();
      start = rect.x;
      width = rect.width;
      x = event.clientX;
      pos = (x - start) / width;
      color = this.rgb_hex_at(pos);
      return this.add_stop(pos, color);
    };

    return Theme;

  })();

}).call(this);
