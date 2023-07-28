(function() {
  var MandelIter, TAU,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.APP = null;

  TAU = 2 * Math.PI;

  MandelIter = (function() {
    function MandelIter(context) {
      this.context = context;
      this.schedule_ui_draw = bind(this.schedule_ui_draw, this);
      this.draw_ui_callback = bind(this.draw_ui_callback, this);
      this.canvas_to_complex = bind(this.canvas_to_complex, this);
      this.on_mouseout = bind(this.on_mouseout, this);
      this.on_mouseenter = bind(this.on_mouseenter, this);
      this.on_mousemove = bind(this.on_mousemove, this);
      this.on_graph_click = bind(this.on_graph_click, this);
      this.on_zoom_amount_change = bind(this.on_zoom_amount_change, this);
      this.on_button_zoom_click = bind(this.on_button_zoom_click, this);
      this.on_button_reset_click = bind(this.on_button_reset_click, this);
      this.on_trace_slider_input = bind(this.on_trace_slider_input, this);
      this.on_button_trace_cardioid_click = bind(this.on_button_trace_cardioid_click, this);
      this.on_content_wrapper_resize = bind(this.on_content_wrapper_resize, this);
      this.deferred_fit_canvas_to_width = bind(this.deferred_fit_canvas_to_width, this);
      this.on_show_tooltips_change = bind(this.on_show_tooltips_change, this);
    }

    MandelIter.prototype.init = function() {
      var fmtfloatopts;
      console.log('Starting init()...');
      this.running = false;
      fmtfloatopts = {
        notation: 'standard',
        style: 'decimal',
        useGrouping: false,
        minimumIntegerDigits: 1,
        maximumFractionDigits: 3,
        signDisplay: 'always'
      };
      this.fmtfloat = new Intl.NumberFormat(void 0, fmtfloatopts);
      fmtfloatopts['signDisplay'] = 'never';
      this.fmtfloatnosign = new Intl.NumberFormat(void 0, fmtfloatopts);
      this.content_el = this.context.getElementById('content');
      this.show_tooltips = this.context.getElementById('show_tooltips');
      this.show_tooltips.addEventListener('change', this.on_show_tooltips_change);
      this.show_tooltips.checked = true;
      this.graph_wrapper = this.context.getElementById('graph_wrapper');
      this.graph_canvas = this.context.getElementById('graph');
      this.graph_ui_canvas = this.context.getElementById('graph_ui');
      this.graph_ctx = this.graph_canvas.getContext('2d', {
        alpha: false
      });
      this.graph_ui_ctx = this.graph_ui_canvas.getContext('2d', {
        alpha: true
      });
      this.resize_canvas(900, 600);
      this.fit_canvas_to_width();
      this.loc_c = this.context.getElementById('loc_c');
      this.loc_radius = this.context.getElementById('loc_radius');
      this.loc_theta = this.context.getElementById('loc_theta');
      this.button_reset = this.context.getElementById('button_reset');
      this.button_zoom = this.context.getElementById('button_zoom');
      this.zoom_amount = this.context.getElementById('zoom_amount');
      this.button_reset.addEventListener('click', this.on_button_reset_click);
      this.button_zoom.addEventListener('click', this.on_button_zoom_click);
      this.zoom_amount.addEventListener('change', this.on_zoom_amount_change);
      this.option = {
        highlight_trace_path: new UI.BoolOption('highlight_trace_path', false),
        highlight_internal_angle: new UI.BoolOption('highlight_internal_angle', false),
        trace_path_edge_distance: new UI.FloatOption('trace_path_edge_distance'),
        trace_path: new UI.SelectOption('trace_path'),
        trace_speed: new UI.FloatOption('trace_speed')
      };
      this.trace_angle = 0;
      this.trace_steps = 60 * 64;
      this.trace_angle_step = TAU / this.trace_steps;
      this.trace_slider = this.context.getElementById('trace_slider');
      this.trace_slider.addEventListener('input', this.on_trace_slider_input);
      this.trace_slider.value = this.trace_angle;
      this.trace_animation_enabled = false;
      this.button_trace_cardioid = this.context.getElementById('button_trace_cardioid');
      this.button_trace_cardioid.addEventListener('click', this.on_button_trace_cardioid_click);
      this.trace_cardioid_off();
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
      this.defer_resize = false;
      this.pause_mode = false;
      this.zoon_mode = false;
      this.antialias = true;
      this.maxiter = 100;
      this.reset_renderbox();
      this.draw_ui_scheduled = false;
      this.main_bulb_center = {
        r: -1,
        i: 0
      };
      this.main_bulb_tangent_point = {
        r: -3 / 4,
        i: 0
      };
      this.main_bulb_radius = this.main_bulb_tangent_point.r - this.main_bulb_center.r;
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

    MandelIter.prototype.complex_to_string = function(z) {
      var istr, rstr;
      rstr = this.fmtfloat.format(z.r);
      istr = this.fmtfloatnosign.format(z.i);
      if (z.i === 0) {
        return rstr;
      } else if (z.r === 0) {
        if (z.i === 1) {
          return 'i';
        } else if (z.i === -1) {
          return '-i';
        } else {
          return 'i';
        }
      } else {
        if (z.i < 0) {
          if (z.i === -1) {
            return rstr + ' - i';
          } else {
            return rstr + ' - ' + istr + 'i';
          }
        } else {
          if (z.i === 1) {
            return rstr + ' + i';
          } else {
            return rstr + ' + ' + istr + 'i';
          }
        }
      }
    };

    MandelIter.prototype.on_show_tooltips_change = function(event) {
      if (this.show_tooltips.checked) {
        return this.content_el.classList.add('show_tt');
      } else {
        return this.content_el.classList.remove('show_tt');
      }
    };

    MandelIter.prototype.resize_canvas = function(w, h) {
      var hpx, wpx;
      console.log('resize', w, h);
      this.graph_canvas.width = w;
      this.graph_canvas.height = h;
      this.graph_width = this.graph_canvas.width;
      this.graph_height = this.graph_canvas.height;
      this.graph_ui_canvas.width = this.graph_canvas.width;
      this.graph_ui_canvas.height = this.graph_canvas.height;
      this.graph_ui_width = this.graph_canvas.width;
      this.graph_ui_height = this.graph_canvas.height;
      this.graph_aspect = this.graph_width / this.graph_height;
      wpx = w + "px";
      hpx = h + "px";
      this.graph_wrapper.style.width = wpx;
      this.graph_wrapper.style.height = hpx;
      this.graph_ui_canvas.style.width = wpx;
      this.graph_ui_canvas.style.height = hpx;
      this.graph_canvas.style.width = wpx;
      this.graph_canvas.style.height = hpx;
      if ((this.graph_width !== this.graph_ui_width) || (this.graph_height !== this.graph_ui_height)) {
        return this.debug('Canvas #graph is not the same size as canvas #graph_ui');
      }
    };

    MandelIter.prototype.fit_canvas_to_width = function() {
      var h, w;
      w = this.content_el.clientWidth;
      w -= 9;
      h = Math.floor(w / this.graph_aspect);
      return this.resize_canvas(w, h);
    };

    MandelIter.prototype.deferred_fit_canvas_to_width = function() {
      console.log('deferred');
      this.fit_canvas_to_width();
      this.draw_background();
      return this.defer_resize = false;
    };

    MandelIter.prototype.on_content_wrapper_resize = function(event) {
      if (this.defer_resize) {
        return console.log("already deferred");
      } else {
        console.log('setting defferred fit timeout');
        this.defer_resise = true;
        return setTimeout(this.deferred_fit_canvas_to_width, 5000);
      }
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
      this.pause_mode = false;
      return this.schedule_ui_draw();
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

    MandelIter.prototype.trace_cardioid_on = function() {
      this.button_trace_cardioid.textContent = 'Stop';
      this.button_trace_cardioid.classList.remove('inactive');
      this.button_trace_cardioid.classList.add('enabled');
      this.trace_slider.disabled = false;
      this.trace_slider.value = this.trace_angle;
      return this.trace_animation_enabled = true;
    };

    MandelIter.prototype.trace_cardioid_off = function() {
      this.button_trace_cardioid.textContent = 'Start';
      this.button_trace_cardioid.classList.remove('enabled');
      this.button_trace_cardioid.classList.add('inactive');
      this.trace_slider.disabled = true;
      return this.trace_animation_enabled = false;
    };

    MandelIter.prototype.trace_cardioid_toggle = function() {
      if (this.trace_animation_enabled) {
        return this.trace_cardioid_off();
      } else {
        return this.trace_cardioid_on();
      }
    };

    MandelIter.prototype.on_button_trace_cardioid_click = function(event) {
      return this.trace_cardioid_toggle();
    };

    MandelIter.prototype.on_trace_slider_input = function(event) {
      return this.trace_angle = parseFloat(this.trace_slider.value);
    };

    MandelIter.prototype.on_button_reset_click = function(event) {
      this.reset_renderbox();
      this.zoom_mode_off();
      this.trace_cardioid_off();
      return this.draw_background();
    };

    MandelIter.prototype.on_button_zoom_click = function(event) {
      if (!this.zoom_mode) {
        this.trace_cardioid_off();
      }
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
        w = this.get_zoom_window();
        newstart = this.canvas_to_complex(w.x, w.y);
        newend = this.canvas_to_complex(w.x + w.w, w.y + w.h);
        this.renderbox.start = newstart;
        this.renderbox.end = newend;
        this.zoom_mode = false;
        return this.draw_background();
      } else {
        return this.pause_mode_toggle();
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

    MandelIter.prototype.rectangular_to_polar_angle = function(r, i) {
      return Math.atan2(i, r);
    };

    MandelIter.prototype.polar_to_rectangular = function(radius, angle) {
      return {
        r: radius * Math.cos(angle),
        i: radius * Math.sin(angle)
      };
    };

    MandelIter.prototype.canvas_to_complex = function(x, y) {
      return {
        r: this.renderbox.start.r + (x / this.graph_width) * (this.renderbox.end.r - this.renderbox.start.r),
        i: this.renderbox.start.i + (y / this.graph_height) * (this.renderbox.end.i - this.renderbox.start.i)
      };
    };

    MandelIter.prototype.complex_to_canvas = function(z) {
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
      c = this.canvas_to_complex(x, y);
      ref = this.mandelbrot(c), n = ref[0], in_set = ref[1];
      if (in_set) {
        return 0;
      } else {
        return n;
      }
    };

    MandelIter.prototype.draw_background = function() {
      var data, img, j, k, pos, ref, ref1, val, x, y;
      this.graph_ctx.fillStyle = 'rgb(0,0,0)';
      this.graph_ctx.fillRect(0, 0, this.graph_width, this.graph_height);
      img = this.graph_ctx.getImageData(0, 0, this.graph_width, this.graph_height);
      data = img.data;
      for (y = j = 0, ref = this.graph_height; 0 <= ref ? j <= ref : j >= ref; y = 0 <= ref ? ++j : --j) {
        for (x = k = 0, ref1 = this.graph_width; 0 <= ref1 ? k <= ref1 : k >= ref1; x = 0 <= ref1 ? ++k : --k) {
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

    MandelIter.prototype.draw_orbit = function(c) {
      var isize, mx, my, osize, p, pos, ref, step;
      mx = c.x;
      my = c.y;
      pos = this.canvas_to_complex(mx, my);
      this.loc_c.innerText = this.complex_to_string(pos);
      this.graph_ui_ctx.save();
      this.graph_ui_ctx.beginPath();
      this.graph_ui_ctx.lineWidth = 2;
      this.graph_ui_ctx.strokeStyle = 'rgba(255,255,108,0.5)';
      this.graph_ui_ctx.moveTo(mx, my);
      ref = this.mandelbrot_orbit(pos, 200);
      for (step of ref) {
        if (step.n > 0) {
          p = this.complex_to_canvas(step.z);
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
      this.graph_ui_ctx.lineWidth = 2;
      this.graph_ui_ctx.strokeStyle = '#d5c312';
      this.graph_ui_ctx.stroke();
      return this.graph_ui_ctx.restore();
    };

    MandelIter.prototype.main_bulb = function(theta) {
      var rec, shrink;
      theta = theta % TAU;
      shrink = this.option.trace_path_edge_distance.value;
      rec = this.polar_to_rectangular(this.main_bulb_radius - shrink, theta);
      rec.r += this.main_bulb_center.r;
      return this.complex_to_canvas(rec);
    };

    MandelIter.prototype.cardioid = function(theta) {
      var a, ct, mcos, shrink;
      theta = theta % TAU;
      shrink = this.option.trace_path_edge_distance.value;
      ct = Math.cos(theta);
      mcos = 1 - ct;
      mcos = mcos * (1 - shrink);
      a = {
        r: ct,
        i: Math.sin(theta)
      };
      a.r = ((a.r * 0.5) * mcos) + 0.25 - (shrink * 0.5);
      a.i = (a.i * 0.5) * mcos;
      return this.complex_to_canvas(a);
    };

    MandelIter.prototype.draw_cardioid_trace_path = function() {
      var first, p, step_size, steps, theta;
      this.graph_ui_ctx.save();
      steps = 100;
      step_size = TAU / steps;
      theta = 0;
      p = this.cardioid(theta);
      first = p;
      this.graph_ui_ctx.save();
      this.graph_ui_ctx.beginPath();
      this.graph_ui_ctx.moveTo(p.x, p.y);
      while (theta < TAU) {
        theta = theta + step_size;
        p = this.cardioid(theta);
        this.graph_ui_ctx.lineTo(p.x, p.y);
      }
      this.graph_ui_ctx.lineTo(first.x, first.y);
      this.graph_ui_ctx.lineWidth = 2;
      this.graph_ui_ctx.strokeStyle = '#61E0F6';
      this.graph_ui_ctx.stroke();
      return this.graph_ui_ctx.restore();
    };

    MandelIter.prototype.draw_cardioid_internal_angle = function() {
      var angle, circle, m, origin, origin_tangent_point, outer, radius, zorigin, zorigin_tangent_point;
      angle = null;
      if (this.trace_animation_enabled) {
        angle = this.trace_angle;
      } else if (this.mouse_active) {
        if (this.zoom_mode) {

        } else {
          m = this.canvas_to_complex(this.orbit_mouse.x, this.orbit_mouse.y);
          angle = this.rectangular_to_polar_angle(m.r, m.i);
        }
      } else {

      }
      if (angle == null) {
        return null;
      }
      zorigin = {
        r: 0,
        i: 0
      };
      zorigin_tangent_point = {
        r: 0.5,
        i: 0
      };
      origin = this.complex_to_canvas(zorigin);
      origin_tangent_point = this.complex_to_canvas(zorigin_tangent_point);
      radius = (origin_tangent_point.x - origin.x) / 2;
      circle = this.polar_to_rectangular(0.5, angle);
      this.loc_radius.innerText = this.fmtfloat.format(radius);
      this.loc_theta.innerText = this.fmtfloat.format(angle);
      this.graph_ui_ctx.save();
      this.graph_ui_ctx.lineWidth = 2;
      outer = this.complex_to_canvas(circle);
      this.graph_ui_ctx.beginPath();
      this.graph_ui_ctx.moveTo(origin.x, origin.y);
      this.graph_ui_ctx.lineTo(outer.x, outer.y);
      this.graph_ui_ctx.lineTo(this.current_trace_location.x, this.current_trace_location.y);
      this.graph_ui_ctx.strokeStyle = '#F67325';
      this.graph_ui_ctx.stroke();
      this.graph_ui_ctx.beginPath();
      this.graph_ui_ctx.arc(origin.x, origin.y, radius, 0, TAU, false);
      this.graph_ui_ctx.strokeStyle = '#00FF47';
      this.graph_ui_ctx.stroke();
      this.graph_ui_ctx.beginPath();
      this.graph_ui_ctx.arc(outer.x, outer.y, radius, 0, TAU, false);
      this.graph_ui_ctx.strokeStyle = '#21CC50';
      this.graph_ui_ctx.stroke();
      return this.graph_ui_ctx.restore();
    };

    MandelIter.prototype.draw_main_bulb_trace_path = function() {
      var center, radius, tangent, ztangent;
      center = this.complex_to_canvas(this.main_bulb_center);
      ztangent = {
        r: this.main_bulb_tangent_point.r - this.option.trace_path_edge_distance.value,
        i: this.main_bulb_tangent_point.i
      };
      tangent = this.complex_to_canvas(ztangent);
      radius = tangent.x - center.x;
      this.graph_ui_ctx.beginPath();
      this.graph_ui_ctx.arc(center.x, center.y, radius, 0, TAU, false);
      this.graph_ui_ctx.strokeStyle = '#00FF47';
      return this.graph_ui_ctx.stroke();
    };

    MandelIter.prototype.draw_trace_animation = function() {
      this.draw_orbit(this.current_trace_location);
      if (!this.pause_mode) {
        this.trace_angle = this.trace_angle + this.option.trace_speed.value;
        if (this.trace_angle >= TAU) {
          this.trace_angle = this.trace_angle - TAU;
        }
        return this.trace_slider.value = this.trace_angle;
      }
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
      this.graph_ui_ctx.restore();
      this.orbit_mouse = this.cardioid(this.trace_angle);
      return this.draw_orbit();
    };

    MandelIter.prototype.draw_ui = function() {
      this.draw_ui_scheduled = false;
      this.graph_ui_ctx.clearRect(0, 0, this.graph_width, this.graph_height);
      if (this.trace_animation_enabled) {
        this.current_trace_location = (function() {
          switch (this.option.trace_path.value) {
            case 'main_cardioid':
              return this.cardioid(this.trace_angle);
            case 'main_bulb':
              return this.main_bulb(this.trace_angle);
          }
        }).call(this);
      } else {
        this.current_trace_location = this.orbit_mouse;
      }
      if (this.option.highlight_trace_path.value) {
        switch (this.option.trace_path.value) {
          case 'main_cardioid':
            this.draw_cardioid_trace_path();
            break;
          case 'main_bulb':
            this.draw_main_bulb_trace_path();
        }
      }
      if (this.option.highlight_internal_angle.value) {
        switch (this.option.trace_path.value) {
          case 'main_cardioid':
            this.draw_cardioid_internal_angle();
        }
      }
      if (this.trace_animation_enabled) {
        return this.draw_trace_animation();
      } else if (this.mouse_active) {
        if (this.zoom_mode) {
          return this.draw_zoom();
        } else {
          return this.draw_orbit(this.orbit_mouse);
        }
      }
    };

    MandelIter.prototype.draw_ui_callback = function() {
      APP.draw_ui();
      if (!this.pause_mode) {
        return this.schedule_ui_draw();
      }
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
      window.APP = new MandelIter(document);
      window.APP.init();
      return window.APP.schedule_ui_draw();
    };
  })(this));

}).call(this);
