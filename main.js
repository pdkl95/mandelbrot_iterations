(function() {
  var APP, MandelIter, TAU,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  APP = null;

  TAU = 2 * Math.PI;

  MandelIter = (function() {
    function MandelIter(context) {
      this.context = context;
      this.schedule_ui_draw = bind(this.schedule_ui_draw, this);
      this.draw_ui_callback = bind(this.draw_ui_callback, this);
      this.canvas_to_render_coord = bind(this.canvas_to_render_coord, this);
      this.on_mouseout = bind(this.on_mouseout, this);
      this.on_mouseenter = bind(this.on_mouseenter, this);
      this.on_mousemove = bind(this.on_mousemove, this);
      this.on_graph_click = bind(this.on_graph_click, this);
      this.on_zoom_amount_change = bind(this.on_zoom_amount_change, this);
      this.on_button_zoom_click = bind(this.on_button_zoom_click, this);
      this.on_button_reset_click = bind(this.on_button_reset_click, this);
    }

    MandelIter.prototype.init = function() {
      console.log('Starting init()...');
      this.running = false;
      this.content_el = this.context.getElementById('content');
      this.graph_wrapper = this.context.getElementById('graph_wrapper');
      this.graph_canvas = this.context.getElementById('graph');
      this.graph_ui_canvas = this.context.getElementById('graph_ui');
      this.graph_ctx = this.graph_canvas.getContext('2d', {
        alpha: false
      });
      this.graph_ui_ctx = this.graph_ui_canvas.getContext('2d', {
        alpha: true
      });
      this.graph_width = this.graph_canvas.width;
      this.graph_height = this.graph_canvas.height;
      this.graph_ui_width = this.graph_canvas.width;
      this.graph_ui_height = this.graph_canvas.height;
      this.graph_aspect = this.graph_width / this.graph_height;
      if ((this.graph_width !== this.graph_ui_width) || (this.graph_height !== this.graph_ui_height)) {
        this.debug('Canvas #graph is not the same size as canvas #graph_ui');
      }
      this.button_reset = this.context.getElementById('button_reset');
      this.button_zoom = this.context.getElementById('button_zoom');
      this.zoom_amount = this.context.getElementById('zoom_amount');
      this.button_reset.addEventListener('click', this.on_button_reset_click);
      this.button_zoom.addEventListener('click', this.on_button_zoom_click);
      this.zoom_amount.addEventListener('change', this.on_zoom_amount_change);
      this.mouse_active = false;
      this.mouse = {
        x: 0,
        y: 0
      };
      this.orbit_mouse = {
        x: 0,
        y: 0
      };
      this.graph_wrapper.addEventListener('mousemove', this.on_mousemove);
      this.graph_wrapper.addEventListener('mouseenter', this.on_mouseenter);
      this.graph_wrapper.addEventListener('mouseout', this.on_mouseout);
      this.graph_wrapper.addEventListener('click', this.on_graph_click);
      this.pause_mode = false;
      this.zoon_mode = false;
      this.antialias = true;
      this.maxiter = 100;
      this.reset_renderbox();
      this.draw_ui_scheduled = false;
      console.log('init() completed!');
      return this.draw_background();
    };

    MandelIter.prototype.debug = function(msg) {
      var timestamp;
      if (this.debugbox == null) {
        this.debugbox = $('#debugbox');
        this.debugbox_hdr = this.debugbox.find('.hdr');
        this.debugbox_msg = this.debugbox.find('.msg');
        this.debugbox.removeClass('hidden');
      }
      timestamp = new Date();
      this.debugbox_hdr.text(timestamp.toISOString());
      return this.debugbox_msg.text('' + msg);
    };

    MandelIter.prototype.reset_renderbox = function() {
      return this.renderbox = {
        start: {
          r: -2,
          i: -1
        },
        end: {
          r: 1,
          i: 1
        }
      };
    };

    MandelIter.prototype.pause_mode_on = function() {
      return this.pause_mode = true;
    };

    MandelIter.prototype.pause_mode_off = function() {
      return this.pause_mode = false;
    };

    MandelIter.prototype.pause_mode_toggle = function() {
      if (this.pause_mode) {
        return this.pause_mode_off();
      } else {
        return this.pause_mode_on();
      }
    };

    MandelIter.prototype.zoom_mode_on = function() {
      return this.zoom_mode = true;
    };

    MandelIter.prototype.zoom_mode_off = function() {
      return this.zoom_mode = false;
    };

    MandelIter.prototype.zoom_mode_toggle = function() {
      if (this.zoom_mode) {
        return this.zoom_mode_off();
      } else {
        return this.zoom_mode_on();
      }
    };

    MandelIter.prototype.on_button_reset_click = function(event) {
      this.reset_renderbox();
      this.zoom_mode_off();
      return this.draw_background();
    };

    MandelIter.prototype.on_button_zoom_click = function(event) {
      return this.zoom_mode_toggle();
    };

    MandelIter.prototype.on_zoom_amount_change = function(event) {
      if (this.zoom_mode) {
        return this.schedule_ui_draw();
      }
    };

    MandelIter.prototype.get_zoom_window = function() {
      var w, zoom;
      zoom = this.zoom_amount.options[this.zoom_amount.selectedIndex].value;
      w = {
        w: this.graph_width * zoom,
        h: this.graph_height * zoom
      };
      w.x = this.mouse.x < w.w ? 0 : this.mouse.x - w.w;
      w.y = this.mouse.y < w.h ? 0 : this.mouse.y - w.h;
      return w;
    };

    MandelIter.prototype.on_graph_click = function(event) {
      var newend, newstart, w;
      if (this.zoom_mode) {
        console.log('zoom click');
        w = this.get_zoom_window();
        newstart = this.canvas_to_render_coord(w.x, w.y);
        newend = this.canvas_to_render_coord(w.x + w.w, w.y + w.h);
        this.renderbox.start = newstart;
        this.renderbox.end = newend;
        this.zoom_mode = false;
        return this.draw_background();
      } else {
        this.pause_mode_toggle();
        return console.log('pause mode:', this.pause_mode);
      }
    };

    MandelIter.prototype.on_mousemove = function(event) {
      var cc, oldx, oldy, ref;
      ref = this.mouse, oldx = ref[0], oldy = ref[1];
      cc = this.graph_canvas.getBoundingClientRect();
      this.mouse.x = event.pageX - cc.left;
      this.mouse.y = event.pageY - cc.top;
      if ((oldx !== this.mouse.x) || (oldy !== this.mouse.y)) {
        if (!this.pause_mode) {
          this.orbit_mouse.x = this.mouse.x;
          this.orbit_mouse.y = this.mouse.y;
        }
        this.mouse_active = true;
        return this.schedule_ui_draw();
      }
    };

    MandelIter.prototype.on_mouseenter = function(event) {
      this.mouse_active = true;
      return this.schedule_ui_draw();
    };

    MandelIter.prototype.on_mouseout = function(event) {
      this.mouse_active = false;
      return this.schedule_ui_draw();
    };

    MandelIter.prototype.canvas_to_render_coord = function(x, y) {
      return {
        r: this.renderbox.start.r + (x / this.graph_width) * (this.renderbox.end.r - this.renderbox.start.r),
        i: this.renderbox.start.i + (y / this.graph_height) * (this.renderbox.end.i - this.renderbox.start.i)
      };
    };

    MandelIter.prototype.render_coord_to_canvas = function(z) {
      return {
        x: ((z.r - this.renderbox.start.r) / (this.renderbox.end.r - this.renderbox.start.r)) * this.graph_width,
        y: ((z.i - this.renderbox.start.i) / (this.renderbox.end.i - this.renderbox.start.i)) * this.graph_height
      };
    };

    MandelIter.prototype.mandelbrot = function(c) {
      var d, n, p, z;
      n = 0;
      d = 0;
      z = {
        r: 0,
        i: 0
      };
      while ((d <= 2) && (n < this.maxiter)) {
        p = {
          r: Math.pow(z.r, 2) - Math.pow(z.i, 2),
          i: 2 * z.r * z.i
        };
        z = {
          r: p.r + c.r,
          i: p.i + c.i
        };
        d = Math.pow(z.r, 2) + Math.pow(z.i, 2);
        n += 1;
      }
      return [n, d <= 2];
    };

    MandelIter.prototype.mandel_color_value = function(x, y) {
      var c, in_set, n, ref;
      c = this.canvas_to_render_coord(x, y);
      ref = this.mandelbrot(c), n = ref[0], in_set = ref[1];
      if (in_set) {
        return 0;
      } else {
        return n;
      }
    };

    MandelIter.prototype.draw_background = function() {
      var data, i, img, j, pos, ref, ref1, val, x, y;
      this.graph_ctx.fillStyle = 'rgb(0,0,0)';
      this.graph_ctx.fillRect(0, 0, this.graph_width, this.graph_height);
      console.log('createImageData()');
      img = this.graph_ctx.getImageData(0, 0, this.graph_width, this.graph_height);
      data = img.data;
      for (y = i = 0, ref = this.graph_height; 0 <= ref ? i <= ref : i >= ref; y = 0 <= ref ? ++i : --i) {
        for (x = j = 0, ref1 = this.graph_width; 0 <= ref1 ? j <= ref1 : j >= ref1; x = 0 <= ref1 ? ++j : --j) {
          val = this.mandel_color_value(x, y);
          if (this.antialias) {
            val += this.mandel_color_value(x + 0.5, y);
            val += this.mandel_color_value(x, y + 0.5);
            val += this.mandel_color_value(x + 0.5, y + 0.5);
            val /= 4;
          }
          pos = 4 * (x + (y * this.graph_width));
          val = Math.pow(val / this.maxiter, 0.5) * 255;
          data[pos] = val;
          data[pos + 1] = val;
          data[pos + 2] = val;
        }
      }
      return this.graph_ctx.putImageData(img, 0, 0);
    };

    MandelIter.prototype.mandelbrot_orbit = function*(c, max_yield) {
      var d, n, p, results, z;
      if (max_yield == null) {
        max_yield = this.maxiter;
      }
      n = 0;
      d = 0;
      z = {
        r: 0,
        i: 0
      };
      yield ({
        z: z,
        n: n
      });
      results = [];
      while ((d <= 2) && (n < max_yield)) {
        p = {
          r: Math.pow(z.r, 2) - Math.pow(z.i, 2),
          i: 2 * z.r * z.i
        };
        z = {
          r: p.r + c.r,
          i: p.i + c.i
        };
        d = Math.pow(z.r, 2) + Math.pow(z.i, 2);
        n += 1;
        results.push((yield {
          z: z,
          n: n
        }));
      }
      return results;
    };

    MandelIter.prototype.draw_orbit = function() {
      var isize, mx, my, osize, p, pos, ref, step;
      mx = this.orbit_mouse.x;
      my = this.orbit_mouse.y;
      pos = this.canvas_to_render_coord(mx, my);
      this.graph_ui_ctx.beginPath();
      this.graph_ui_ctx.lineWidth = 2;
      this.graph_ui_ctx.strokeStyle = 'rgba(255,255,108,0.5)';
      this.graph_ui_ctx.moveTo(mx, my);
      ref = this.mandelbrot_orbit(pos, 50);
      for (step of ref) {
        if (step.n > 0) {
          p = this.render_coord_to_canvas(step.z);
          this.graph_ui_ctx.lineTo(p.x, p.y);
          this.graph_ui_ctx.stroke();
          this.graph_ui_ctx.beginPath();
          this.graph_ui_ctx.moveTo(p.x, p.y);
        }
      }
      isize = 3;
      osize = isize * 3;
      this.graph_ui_ctx.beginPath();
      this.graph_ui_ctx.moveTo(mx + isize, my + isize);
      this.graph_ui_ctx.lineTo(mx + osize, my);
      this.graph_ui_ctx.lineTo(mx + isize, my - isize);
      this.graph_ui_ctx.lineTo(mx, my - osize);
      this.graph_ui_ctx.lineTo(mx - isize, my - isize);
      this.graph_ui_ctx.lineTo(mx - osize, my);
      this.graph_ui_ctx.lineTo(mx - isize, my + isize);
      this.graph_ui_ctx.lineTo(mx, my + osize);
      this.graph_ui_ctx.lineTo(mx + isize, my + isize);
      this.graph_ui_ctx.fillStyle = 'rgba(255,249,187, 0.1)';
      this.graph_ui_ctx.fill();
      this.graph_ui_ctx.lineWidth = 2;
      this.graph_ui_ctx.strokeStyle = '#bb7e24';
      this.graph_ui_ctx.stroke();
      this.graph_ui_ctx.lineWidth = 1;
      this.graph_ui_ctx.strokeStyle = '#d5c312';
      return this.graph_ui_ctx.stroke();
    };

    MandelIter.prototype.draw_zoom = function() {
      var region, w;
      this.graph_ui_ctx.save();
      w = this.get_zoom_window();
      region = new Path2D();
      region.rect(0, 0, this.graph_width, this.graph_height);
      region.rect(w.x, w.y, w.w, w.h);
      this.graph_ui_ctx.clip(region, "evenodd");
      this.graph_ui_ctx.fillStyle = 'rgba(255,232,232,0.333)';
      this.graph_ui_ctx.fillRect(0, 0, this.graph_width, this.graph_height);
      return this.graph_ui_ctx.restore();
    };

    MandelIter.prototype.draw_ui = function() {
      this.draw_ui_scheduled = false;
      this.graph_ui_ctx.clearRect(0, 0, this.graph_width, this.graph_height);
      if (this.mouse_active) {
        if (this.zoom_mode) {
          return this.draw_zoom();
        } else {
          return this.draw_orbit();
        }
      }
    };

    MandelIter.prototype.draw_ui_callback = function() {
      return APP.draw_ui();
    };

    MandelIter.prototype.schedule_ui_draw = function() {
      if (!this.draw_ui_scheduled) {
        window.requestAnimationFrame(this.draw_ui_callback);
        return this.draw_ui_scheduled = true;
      }
    };

    return MandelIter;

  })();

  document.addEventListener('DOMContentLoaded', (function(_this) {
    return function() {
      APP = new MandelIter(document);
      return APP.init();
    };
  })(this));

}).call(this);
