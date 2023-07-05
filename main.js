(function() {
  var APP, MandelIter, Point, TAU,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  APP = null;

  TAU = 2 * Math.PI;

  Point = (function() {
    function Point(x, y, color) {
      this.color = color;
      this.hover = false;
      this.selected = false;
      this.order = 0;
      this.radius = 5;
      if (this.color == null) {
        this.color = '#000';
      }
      this.position = {
        x: x,
        y: y
      };
      this.move(x, y);
    }

    Point.prototype.move = function(x, y) {
      this.x = x;
      this.y = y;
      this.ix = Math.floor(this.x);
      return this.iy = Math.floor(this.y);
    };

    Point.prototype.contains = function(x, y) {
      var dist, dx, dy;
      dx = this.x - x;
      dy = this.y - y;
      dist = Math.sqrt((dx * dx) + (dy * dy));
      return dist <= this.radius;
    };

    Point.prototype.update = function(t) {
      this.position.x = this.x;
      return this.position.y = this.y;
    };

    Point.prototype.draw = function() {
      var ctx;
      ctx = APP.graph_ctx;
      if (this.hover) {
        ctx.beginPath();
        ctx.fillStyle = '#ff0';
        ctx.strokeStyle = '#000';
        ctx.lineWidth = 1;
        ctx.arc(this.x, this.y, this.radius * 3, 0, TAU);
        ctx.fill();
        ctx.stroke();
      }
      ctx.beginPath();
      ctx.fillStyle = this.color;
      ctx.arc(this.x, this.y, this.radius, 0, TAU);
      return ctx.fill();
    };

    return Point;

  })();

  MandelIter = (function() {
    function MandelIter(context) {
      this.context = context;
      this.schedule_first_frame = bind(this.schedule_first_frame, this);
      this.first_update_callback = bind(this.first_update_callback, this);
      this.schedule_next_frame = bind(this.schedule_next_frame, this);
      this.update_callback = bind(this.update_callback, this);
      this.update = bind(this.update, this);
      this.on_mousemove = bind(this.on_mousemove, this);
    }

    MandelIter.prototype.init = function() {
      console.log('Starting init()...');
      this.running = false;
      this.content_el = this.context.getElementById('content');
      this.graph_wrapper = this.context.getElementById('graph_wrapper');
      this.graph_canvas = this.context.getElementById('graph');
      this.graph_ctx = this.graph_canvas.getContext('2d', {
        alpha: true
      });
      this.graph_width = this.graph_canvas.width;
      this.graph_height = this.graph_canvas.height;
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

    MandelIter.prototype.get_mouse_coord = function(event) {
      var cc;
      cc = this.graph_canvas.getBoundingClientRect();
      return {
        x: event.pageX - cc.left,
        y: event.pageY - cc.top
      };
    };

    MandelIter.prototype.on_mousemove = function(event) {
      var i, len, mouse, oldhover, oldx, oldy, order, p, ref, results;
      mouse = this.get_mouse_coord(event);
      ref = this.points;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        order = ref[i];
        results.push((function() {
          var j, len1, results1;
          results1 = [];
          for (j = 0, len1 = order.length; j < len1; j++) {
            p = order[j];
            oldx = p.x;
            oldy = p.y;
            if (p.selected) {
              p.x = mouse.x;
              p.y = mouse.y;
            }
            oldhover = p.hover;
            if (p.contains(mouse.x, mouse.y)) {
              p.hover = true;
            } else {
              p.hover = false;
            }
            if ((p.hover !== oldhover) || (p.x !== oldx) || (p.y !== oldy)) {
              results1.push(this.update_and_draw());
            } else {
              results1.push(void 0);
            }
          }
          return results1;
        }).call(this));
      }
      return results;
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
          c = {
            r: this.renderbox.start.r + (x / this.graph_width) * (this.renderbox.end.r - this.renderbox.start.r),
            i: this.renderbox.start.i + (y / this.graph_height) * (this.renderbox.end.i - this.renderbox.start.i)
          };
          ref2 = this.mandelbrot(c), n = ref2[0], in_set = ref2[1];
          if (!in_set) {
            pos = 4 * (x + (y * this.graph_width));
            val = Math.pow(n / this.maxiter, 0.5) * 255;
            data[pos] = val;
            data[pos + 1] = Math.floor(val - (n / 1));
            data[pos + 2] = Math.floor(val - (n / 2));
          }
        }
      }
      console.log('putImageData()');
      return this.graph_ctx.putImageData(img, 0, 0);
    };

    MandelIter.prototype.update = function() {};

    MandelIter.prototype.draw = function() {
      var i, len, order, p, ref, results;
      this.graph_ctx.clearRect(0, 0, this.graph_canvas.width, this.graph_canvas.height);
      this.draw_bezier();
      ref = this.points;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        order = ref[i];
        results.push((function() {
          var j, len1, results1;
          results1 = [];
          for (j = 0, len1 = order.length; j < len1; j++) {
            p = order[j];
            results1.push(p.draw());
          }
          return results1;
        })());
      }
      return results;
    };

    MandelIter.prototype.update_and_draw = function() {
      this.update();
      return this.draw();
    };

    MandelIter.prototype.update_callback = function(timestamp) {
      var elapsed;
      this.frame_is_scheduled = false;
      elapsed = timestamp - this.prev_anim_timestamp;
      if (elapsed > 0) {
        this.prev_anim_timestamp = this.anim_timestamp;
        this.update();
        this.draw();
      }
      if (this.running) {
        this.schedule_next_frame();
      }
      return null;
    };

    MandelIter.prototype.schedule_next_frame = function() {
      if (!this.frame_is_scheduled) {
        this.frame_is_scheduled = true;
        window.requestAnimationFrame(this.update_callback);
      }
      return null;
    };

    MandelIter.prototype.first_update_callback = function(timestamp) {
      this.anim_timestamp = timestamp;
      this.prev_anim_timestamp = timestamp;
      this.frame_is_scheduled = false;
      return this.schedule_next_frame();
    };

    MandelIter.prototype.schedule_first_frame = function() {
      this.frame_is_scheduled = true;
      window.requestAnimationFrame(this.first_update_callback);
      return null;
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
