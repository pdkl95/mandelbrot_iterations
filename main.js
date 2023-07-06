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
      this.on_mouseout = bind(this.on_mouseout, this);
      this.on_mouseenter = bind(this.on_mouseenter, this);
      this.on_mousemove = bind(this.on_mousemove, this);
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
      if ((this.graph_width !== this.graph_ui_width) || (this.graph_height !== this.graph_ui_height)) {
        this.debug('Canvas #graph is not the same size as canvas #graph_ui');
      }
      this.mouse_active = false;
      this.mouse = {
        x: 0,
        y: 0
      };
      this.graph_wrapper.addEventListener('mousemove', this.on_mousemove);
      this.graph_wrapper.addEventListener('mouseenter', this.on_mouseenter);
      this.graph_wrapper.addEventListener('mouseout', this.on_mouseout);
      this.maxiter = 100;
      this.renderbox = {
        start: {
          r: -2,
          i: -1
        },
        end: {
          r: 1,
          i: 1
        }
      };
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

    MandelIter.prototype.on_mousemove = function(event) {
      var cc, oldx, oldy, ref;
      ref = this.mouse, oldx = ref[0], oldy = ref[1];
      cc = this.graph_canvas.getBoundingClientRect();
      this.mouse.x = event.pageX - cc.left;
      this.mouse.y = event.pageY - cc.top;
      if ((oldx !== this.mouse.x) || (oldy !== this.mouse.y)) {
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

    MandelIter.prototype.draw_background = function() {
      var c, data, i, img, in_set, j, n, pos, ref, ref1, ref2, val, x, y;
      this.graph_ctx.fillStyle = 'rgb(0,0,0)';
      this.graph_ctx.fillRect(0, 0, this.graph_width, this.graph_height);
      console.log('createImageData()');
      img = this.graph_ctx.getImageData(0, 0, this.graph_width, this.graph_height);
      data = img.data;
      console.log('Iterating over pixels;..');
      for (y = i = 0, ref = this.graph_height; 0 <= ref ? i <= ref : i >= ref; y = 0 <= ref ? ++i : --i) {
        for (x = j = 0, ref1 = this.graph_width; 0 <= ref1 ? j <= ref1 : j >= ref1; x = 0 <= ref1 ? ++j : --j) {
          c = this.canvas_to_render_coord(x, y);
          ref2 = this.mandelbrot(c), n = ref2[0], in_set = ref2[1];
          if (!in_set) {
            pos = 4 * (x + (y * this.graph_width));
            val = Math.pow(n / this.maxiter, 0.5) * 255;
            data[pos] = val;
            data[pos + 1] = val;
            data[pos + 2] = val;
          }
        }
      }
      console.log('putImageData()');
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

    MandelIter.prototype.draw_ui = function() {
      var isize, osize, p, pos, ref, step;
      this.draw_ui_scheduled = false;
      this.graph_ui_ctx.clearRect(0, 0, this.graph_width, this.graph_height);
      if (this.mouse_active) {
        pos = this.canvas_to_render_coord(this.mouse.x, this.mouse.y);
        this.graph_ui_ctx.beginPath();
        this.graph_ui_ctx.moveTo(this.mouse.x, this.mouse.y);
        ref = this.mandelbrot_orbit(pos, 30);
        for (step of ref) {
          p = this.render_coord_to_canvas(step.z);
          this.graph_ui_ctx.lineTo(p.x, p.y);
        }
        this.graph_ui_ctx.lineWidth = 1;
        this.graph_ui_ctx.strokeStyle = '#fffe9b';
        this.graph_ui_ctx.stroke();
        isize = 3;
        osize = isize * 3;
        this.graph_ui_ctx.beginPath();
        this.graph_ui_ctx.moveTo(this.mouse.x + isize, this.mouse.y + isize);
        this.graph_ui_ctx.lineTo(this.mouse.x + osize, this.mouse.y);
        this.graph_ui_ctx.lineTo(this.mouse.x + isize, this.mouse.y - isize);
        this.graph_ui_ctx.lineTo(this.mouse.x, this.mouse.y - osize);
        this.graph_ui_ctx.lineTo(this.mouse.x - isize, this.mouse.y - isize);
        this.graph_ui_ctx.lineTo(this.mouse.x - osize, this.mouse.y);
        this.graph_ui_ctx.lineTo(this.mouse.x - isize, this.mouse.y + isize);
        this.graph_ui_ctx.lineTo(this.mouse.x, this.mouse.y + osize);
        this.graph_ui_ctx.lineTo(this.mouse.x + isize, this.mouse.y + isize);
        this.graph_ui_ctx.fillStyle = 'rgba(255,249,187, 0.1)';
        this.graph_ui_ctx.fill();
        this.graph_ui_ctx.lineWidth = 2;
        this.graph_ui_ctx.strokeStyle = '#bb7e24';
        this.graph_ui_ctx.stroke();
        this.graph_ui_ctx.lineWidth = 1;
        this.graph_ui_ctx.strokeStyle = '#d5c312';
        return this.graph_ui_ctx.stroke();
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

  $(document).ready((function(_this) {
    return function() {
      APP = new MandelIter(document);
      return APP.init();
    };
  })(this));

}).call(this);
