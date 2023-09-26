(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  window.Color || (window.Color = {});

  Color.RGB = (function() {
    function RGB(value) {
      if (value == null) {
        value = '#000000';
      }
      this.r - 0;
      this.g = 0;
      this.b = 0;
      this.set(value);
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

    RGB.prototype.set = function(value) {
      switch (typeof value) {
        case 'string':
          return this.set_string(value);
        case 'object':
          return this.set_rgb(value.g, value.b, value.g);
        default:
          return APP.warn("Cannot set color to a", value);
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
      var position, rest;
      position = arguments[0], rest = 2 <= arguments.length ? slice.call(arguments, 1) : [];
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
      return this.position;
    };

    return Stop;

  })(Color.RGB);

  Color.Theme = (function() {
    function Theme(name1) {
      this.name = name1;
      this.default_table_size = 256;
      this.named_color = {};
      this.stops = [];
    }

    Theme.prototype.find_stop_at = function(pos) {};

    Theme.prototype.add_stop = function(position, value) {
      var color, index;
      if ((position < 0) || (position > 1)) {
        APP.warn("Color positions in a Theme must satisfy 0 <= position <= 1");
      }
      color = new Color.Stop(position, value);
      index = this.find_stop_at(position);
      if (index != null) {
        this.stops[index] = color;
      } else {
        this.stops.push(color);
        this.sort_stops();
      }
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

    Theme.prototype.color_at = function(pos) {
      var j, len, prev, ref, stop;
      prev = this.stops[0];
      ref = this.stops;
      for (j = 0, len = ref.length; j < len; j++) {
        stop = ref[j];
        if (pos > stop.position) {
          return prev;
        }
        prev = stop;
      }
      return prev;
    };

    Theme.prototype.rgb_at = function(pos) {
      var delta, next, prev, t;
      prev = this.color_at(pos);
      if (prev.next != null) {
        next = prev.next;
        delta = next.position - prev.position;
        t = pos - delta;
        return prev.linear_blend_rgb(next, t);
      } else {
        return prev.rgb();
      }
    };

    Theme.prototype.reset_lookup_table = function(size) {
      if (size == null) {
        size = this.default_table_size;
      }
      return this.table = this.build_lookup_table(size);
    };

    Theme.prototype.build_lookup_table = function(size) {
      var delta, next, offset, pos, prev, results, rgb, step, stop_index, t;
      if (size == null) {
        size = this.default_table_size;
      }
      this.table = new Uint8Array(size * 3);
      stop_index = 0;
      prev = this.stops[stop_index++];
      next = this.stops[stop_index++];
      step = 1.0 / size;
      pos = 0;
      offset = 0;
      delta = t;
      results = [];
      while (pos < 1.0) {
        if (pos >= next.position) {
          prev = next;
          next = this.stops[stop_index++];
        }
        delta = next.position - prev.position;
        t = (pos - prev.position) / delta;
        rgb = prev.linear_blend_rgb(next, t);
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
      return [this.table[value], this.table[value + 1], this.table[value + 2]];
    };

    return Theme;

  })();

}).call(this);
