(function() {
  var MandelIter, TAU,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.APP = null;

  TAU = 2 * Math.PI;

  MandelIter = (function() {
    MandelIter.deferred_background_render_callback = null;

    function MandelIter(context) {
      this.context = context;
      this.schedule_ui_draw = bind(this.schedule_ui_draw, this);
      this.draw_ui_callback = bind(this.draw_ui_callback, this);
      this.canvas_to_complex = bind(this.canvas_to_complex, this);
      this.on_julia_draw_local_false = bind(this.on_julia_draw_local_false, this);
      this.on_julia_draw_local_true = bind(this.on_julia_draw_local_true, this);
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
      this.on_mandel_color_scale_change = bind(this.on_mandel_color_scale_change, this);
      this.on_keydown = bind(this.on_keydown, this);
    }

    MandelIter.prototype.init = function() {
      var fmtfloatopts, format_color_scale;
      console.log('Starting init()...');
      this.running = false;
      this.colorize_themes = {
        linear_greyscale: [1, 1, 1],
        greyish_purple: [2, 0.8, 2]
      };
      this.default_mandel_theme = 'linear_greyscale';
      this.default_julia_theme = 'greyish_purple';
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
      this.status = this.context.getElementById('status');
      this.status_current = 'loading';
      this.show_tooltips = this.context.getElementById('show_tooltips');
      this.show_tooltips.addEventListener('change', this.on_show_tooltips_change);
      this.show_tooltips.checked = true;
      this.graph_wrapper = this.context.getElementById('graph_wrapper');
      this.graph_mandel_canvas = this.context.getElementById('graph_mandel');
      this.graph_julia_canvas = this.context.getElementById('graph_julia');
      this.graph_ui_canvas = this.context.getElementById('graph_ui');
      this.graph_mandel_ctx = this.graph_mandel_canvas.getContext('2d', {
        alpha: false
      });
      this.graph_julia_ctx = this.graph_julia_canvas.getContext('2d', {
        alpha: true
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
        keyboard_step: new UI.FloatOption('keyboard_step', 0.01),
        highlight_trace_path: new UI.BoolOption('highlight_trace_path', false),
        highlight_internal_angle: new UI.BoolOption('highlight_internal_angle', false),
        trace_path_edge_distance: new UI.FloatOption('trace_path_edge_distance'),
        trace_path: new UI.SelectOption('trace_path'),
        trace_speed: new UI.FloatOption('trace_speed'),
        orbit_draw_length: new UI.IntOption('orbit_draw_length'),
        orbit_draw_lines: new UI.BoolOption('orbit_draw_lines', true),
        orbit_draw_points: new UI.BoolOption('orbit_draw_points', true),
        orbit_point_size: new UI.FloatOption('orbit_point_size', 2),
        julia_draw_local: new UI.BoolOption('julia_draw_local', false),
        julia_more_when_paused: new UI.BoolOption('julia_more_when_paused', true),
        julia_local_margin: new UI.IntOption('julia_local_margin', 80),
        julia_local_max_size: new UI.IntOption('julia_local_max_size', 750),
        julia_local_opacity: new UI.PercentOption('julia_local_opacity', 0.6),
        julia_local_pixel_size: new UI.IntOption('julia_local_pixel_size', 3),
        julia_max_iter_paused: new UI.IntOption('julia_max_iter_paused', 250),
        julia_max_iterations: new UI.IntOption('julia_max_iterations', 100),
        mandel_max_iterations: new UI.IntOption('mandel_max_iterations', 120),
        mandel_color_scale_r: new UI.FloatOption('mandel_color_scale_r', this.colorize_themes[this.default_mandel_theme][0]),
        mandel_color_scale_g: new UI.FloatOption('mandel_color_scale_g', this.colorize_themes[this.default_mandel_theme][1]),
        mandel_color_scale_b: new UI.FloatOption('mandel_color_scale_b', this.colorize_themes[this.default_mandel_theme][2])
      };
      this.option.julia_draw_local.register_callback({
        on_true: this.on_julia_draw_local_true,
        on_false: this.on_julia_draw_local_false
      });
      this.option.julia_local_pixel_size.set_label_text_formater(function(value) {
        return value + "x";
      });
      format_color_scale = function(value) {
        return parseFloat(value).toFixed(2);
      };
      this.option.mandel_color_scale_r.set_label_text_formater(format_color_scale);
      this.option.mandel_color_scale_g.set_label_text_formater(format_color_scale);
      this.option.mandel_color_scale_b.set_label_text_formater(format_color_scale);
      this.option.mandel_color_scale_r.register_callback({
        on_change: this.on_mandel_color_scale_change
      });
      this.option.mandel_color_scale_g.register_callback({
        on_change: this.on_mandel_color_scale_change
      });
      this.option.mandel_color_scale_b.register_callback({
        on_change: this.on_mandel_color_scale_change
      });
      this.pointer_angle = 0;
      this.pointer_angle_step = TAU / 96;
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
      this.reset_renderbox();
      this.draw_ui_scheduled = false;
      this.shift_step_accel = 0.333;
      this.ctrl_step_accel = 0.1;
      this.alt_step_accel = 0.01;
      this.defer_highres_frames = 0;
      this.deferred_render_passes = 3;
      this.deferred_render_pass_scale = 3;
      this.initial_render_pixel_size = Math.pow(this.deferred_render_pass_scale, this.deferred_render_passes);
      this.render_lines_per_pass = 24;
      this.rendering_note = this.context.getElementById('rendering_note');
      this.rendering_note_hdr = this.context.getElementById('rendering_note_hdr');
      this.rendering_note_value = this.context.getElementById('rendering_note_value');
      this.rendering_note_progress = this.context.getElementById('rendering_note_progress');
      this.main_bulb_center = {
        r: -1,
        i: 0
      };
      this.main_bulb_tangent_point = {
        r: -3 / 4,
        i: 0
      };
      this.main_bulb_radius = this.main_bulb_tangent_point.r - this.main_bulb_center.r;
      this.orbit_bb = {
        min_x: 0,
        max_x: 0,
        min_y: 0,
        max_y: 0
      };
      this.local_julia = {
        width: 0,
        height: 0,
        x: 0,
        y: 0
      };
      document.addEventListener('keydown', this.on_keydown);
      console.log('init() completed!');
      return this.draw_background();
    };

    MandelIter.prototype.on_keydown = function(event) {
      var accel;
      accel = 1.0;
      if (event.shiftKey) {
        accel = this.shift_step_accel;
      }
      if (event.ctrlKey) {
        accel = this.ctrl_step_accel;
      }
      if (event.altKey) {
        accel = this.alt_step_accel;
      }
      switch (event.code) {
        case 'Space':
          this.pause_mode_toggle();
          event.preventDefault();
          break;
        case 'ArrowUp':
          this.mouse_step_up(accel);
          break;
        case 'ArrowDown':
          this.mouse_step_down(accel);
          break;
        case 'ArrowLeft':
          this.mouse_step_left(accel);
          break;
        case 'ArrowRight':
          this.mouse_step_right(accel);
          break;
        default:
          return;
      }
      return event.preventDefault();
    };

    MandelIter.prototype.debug = function(msg) {
      var timestamp;
      if (this.debugbox == null) {
        this.debugbox = this.context.getElementById('debugbox');
        this.debugbox_hdr = this.context.getElementById('debugbox_hdr');
        this.debugbox_msg = this.context.getElementById('debugbox_msg');
        this.debugbox.classList.remove('hidden');
      }
      timestamp = new Date();
      this.debugbox_hdr.textContent = timestamp.toISOString();
      return this.debugbox_msg.textContent = '' + msg;
    };

    MandelIter.prototype.current_mandel_theme = function() {
      if ((this.option.mandel_color_scale_r != null) && (this.option.mandel_color_scale_g != null) && (this.option.mandel_color_scale_r != null)) {
        return [this.option.mandel_color_scale_r.value, this.option.mandel_color_scale_g.value, this.option.mandel_color_scale_b.value];
      } else {
        return this.colorize_themes[this.default_mandel_theme];
      }
    };

    MandelIter.prototype.current_julia_theme = function() {
      return this.colorize_themes[this.default_julia_theme];
    };

    MandelIter.prototype.on_mandel_color_scale_change = function() {
      return this.repaint_mandelbrot();
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
      this.canvas_num_pixels = w * h;
      console.log("resize: " + w + "x" + h + ", " + this.canvas_num_pixels + " pixels");
      this.graph_mandel_canvas.width = w;
      this.graph_mandel_canvas.height = h;
      this.graph_width = this.graph_mandel_canvas.width;
      this.graph_height = this.graph_mandel_canvas.height;
      this.graph_julia_canvas.width = this.graph_mandel_canvas.width;
      this.graph_julia_canvas.height = this.graph_mandel_canvas.height;
      this.graph_ui_canvas.width = this.graph_mandel_canvas.width;
      this.graph_ui_canvas.height = this.graph_mandel_canvas.height;
      this.graph_ui_width = this.graph_mandel_canvas.width;
      this.graph_ui_height = this.graph_mandel_canvas.height;
      this.graph_aspect = this.graph_width / this.graph_height;
      wpx = w + "px";
      hpx = h + "px";
      this.graph_wrapper.style.width = wpx;
      this.graph_wrapper.style.height = hpx;
      this.graph_ui_canvas.style.width = wpx;
      this.graph_ui_canvas.style.height = hpx;
      this.graph_julia_canvas.style.width = wpx;
      this.graph_julia_canvas.style.height = hpx;
      this.graph_mandel_canvas.style.width = wpx;
      this.graph_mandel_canvas.style.height = hpx;
      if (!((this.mandel_values != null) && this.mandel_values.length === this.canvas_num_pixels)) {
        this.mandel_values = new Float64Array(this.canvas_num_pixels);
      }
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

    MandelIter.prototype.set_status = function(klass) {
      if (this.status_current != null) {
        this.status.classList.remove(this.status_current);
      }
      this.status.classList.add(klass);
      return this.status_current = klass;
    };

    MandelIter.prototype.pause_mode_on = function() {
      this.pause_mode = true;
      return this.set_status('paused');
    };

    MandelIter.prototype.pause_mode_off = function() {
      this.pause_mode = false;
      this.schedule_ui_draw();
      return this.set_status('normal');
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
      this.trace_angle = parseFloat(this.trace_slider.value);
      return this.schedule_ui_draw();
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
        this.option.julia_draw_local.set(false);
        return this.draw_background();
      } else {
        return this.pause_mode_toggle();
      }
    };

    MandelIter.prototype.on_mousemove = function(event) {
      return this.set_mouse_position(event.layerX, event.layerY);
    };

    MandelIter.prototype.set_mouse_position = function(newx, newy) {
      var oldx, oldy;
      oldx = this.mouse.x;
      oldy = this.mouse.y;
      this.mouse.x = newx;
      this.mouse.y = newy;
      if (this.mouse.x < 0) {
        this.mouse.x = 0;
      }
      if (this.mouse.y < 0) {
        this.mouse.y = 0;
      }
      if (this.mouse.x > this.graph_width) {
        this.mouse.x = this.graph_width;
      }
      if (this.mouse.y > this.graph_height) {
        this.mouse.y = this.graph_height;
      }
      if ((oldx !== this.mouse.x) || (oldy !== this.mouse.y)) {
        if (!this.pause_mode) {
          this.orbit_mouse.x = this.mouse.x;
          this.orbit_mouse.y = this.mouse.y;
        }
        this.mouse_active = true;
        return this.schedule_ui_draw();
      }
    };

    MandelIter.prototype.move_mouse_position = function(dx, dy, accel) {
      var oldx, oldy, pos;
      if (accel == null) {
        accel = 1.0;
      }
      oldx = this.orbit_mouse.x;
      oldy = this.orbit_mouse.y;
      this.set_mouse_position(this.orbit_mouse.x + (dx * accel), this.orbit_mouse.y + (dy * accel));
      this.orbit_mouse.x = this.mouse.x;
      this.orbit_mouse.y = this.mouse.y;
      pos = this.canvas_to_complex(this.orbit_mouse.x, this.orbit_mouse.y);
      this.loc_c.innerText = this.complex_to_string(pos);
      return this.defer_highres_frames = 1;
    };

    MandelIter.prototype.mouse_step_up = function(accel) {
      if (accel == null) {
        accel = 1.0;
      }
      return this.move_mouse_position(0, -this.option.keyboard_step.value, accel);
    };

    MandelIter.prototype.mouse_step_down = function(accel) {
      if (accel == null) {
        accel = 1.0;
      }
      return this.move_mouse_position(0, this.option.keyboard_step.value, accel);
    };

    MandelIter.prototype.mouse_step_left = function(accel) {
      if (accel == null) {
        accel = 1.0;
      }
      return this.move_mouse_position(-this.option.keyboard_step.value, 0, accel);
    };

    MandelIter.prototype.mouse_step_right = function(accel) {
      if (accel == null) {
        accel = 1.0;
      }
      return this.move_mouse_position(this.option.keyboard_step.value, 0, accel);
    };

    MandelIter.prototype.on_mouseenter = function(event) {
      this.mouse_active = true;
      return this.schedule_ui_draw();
    };

    MandelIter.prototype.on_mouseout = function(event) {
      this.mouse_active = false;
      return this.schedule_ui_draw();
    };

    MandelIter.prototype.on_julia_draw_local_true = function() {
      return this.graph_julia_canvas.classList.remove('hidden');
    };

    MandelIter.prototype.on_julia_draw_local_false = function() {
      return this.graph_julia_canvas.classList.add('hidden');
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
      while ((d <= 4) && (n < this.mandel_maxiter)) {
        p = {
          r: (z.r * z.r) - (z.i * z.i),
          i: 2 * z.r * z.i
        };
        z = {
          r: p.r + c.r,
          i: p.i + c.i
        };
        d = (z.r * z.r) + (z.i * z.i);
        n += 1;
      }
      return [n, d <= 4];
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

    MandelIter.prototype.set_rendering_note = function(text) {
      if (text != null) {
        this.rendering_note.classList.remove('hidden');
        this.rendering_note_value.textContent = text;
        return this.set_rendering_note_progress();
      } else {
        this.rendering_note.classList.add('hidden');
        return this.rendering_note_value.textContent = '';
      }
    };

    MandelIter.prototype.hide_rendering_note = function() {
      return this.set_rendering_note(null);
    };

    MandelIter.prototype.set_rendering_note_progress = function() {
      var perc;
      perc = parseInt((this.lines_finished / this.graph_height) * 100);
      this.rendering_note_progress.value = perc;
      return this.rendering_note_progress.textContent = perc + "%";
    };

    MandelIter.prototype.draw_background = function() {
      this.set_status('rendering');
      this.graph_julia_ctx.clearRect(0, 0, this.graph_width, this.graph_height);
      this.graph_mandel_ctx.fillStyle = 'rgb(0,0,0)';
      this.graph_mandel_ctx.fillRect(0, 0, this.graph_width, this.graph_height);
      this.render_pixel_size = this.initial_render_pixel_size;
      this.lines_finished = 0;
      this.set_rendering_note("...");
      return this.schedule_background_render_pass();
    };

    MandelIter.prototype.do_antialias = function() {
      return this.antialias && this.render_pixel_size <= 1;
    };

    MandelIter.prototype.schedule_background_render_pass = function() {
      var render_msg;
      this.render_mandel_img = this.graph_mandel_ctx.getImageData(0, 0, this.graph_width, this.graph_height);
      render_msg = this.render_pixel_size + "x";
      if (this.do_antialias()) {
        render_msg += " (antialias)";
      }
      this.set_rendering_note(render_msg);
      console.log(render_msg);
      return setTimeout((function(_this) {
        return function() {
          return _this.deferred_background_render_callback();
        };
      })(this), 5);
    };

    MandelIter.prototype.schedule_background_render_more_lines = function() {
      this.set_rendering_note_progress();
      return setTimeout((function(_this) {
        return function() {
          return _this.deferred_background_render_callback();
        };
      })(this), 0);
    };

    MandelIter.prototype.deferred_background_render_callback = function() {
      var dirtyheight, elapsed, lastline;
      elapsed = 0;
      while ((this.lines_finished < this.graph_height) && (elapsed < 1000)) {
        lastline = this.render_mandelbrot(this.render_pixel_size, this.do_antialias());
        dirtyheight = lastline - this.lines_finished;
        this.graph_mandel_ctx.putImageData(this.render_mandel_img, 0, 0, 0, this.lines_finished, this.graph_width, dirtyheight);
        this.lines_finished = lastline;
        elapsed = performance.now();
      }
      if (this.lines_finished < this.graph_height) {
        return this.schedule_background_render_more_lines();
      } else if (this.render_pixel_size > 1) {
        this.render_pixel_size /= this.deferred_render_pass_scale;
        this.lines_finished = 0;
        return this.schedule_background_render_pass();
      } else {
        console.log('finished rendering, @render_pixel_size = ' + this.render_pixel_size);
        this.hide_rendering_note();
        return this.set_status('normal');
      }
    };

    MandelIter.prototype.render_mandelbrot = function(pixelsize, do_antialias) {
      var aamult, aastep, aax, aay, iter, j, k, l, o, px, py, q, ref, ref1, ref10, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, s, stopline, val, x, y;
      this.mandel_maxiter = this.option.mandel_max_iterations.value;
      stopline = this.lines_finished + this.render_lines_per_pass;
      if (stopline >= this.graph_height) {
        stopline = this.graph_height;
      }
      this.current_theme = this.current_mandel_theme();
      this.current_image = this.render_mandel_img;
      aamult = 2;
      aastep = 1.0 / aamult;
      for (y = j = ref = this.lines_finished, ref1 = stopline, ref2 = pixelsize; ref2 > 0 ? j <= ref1 : j >= ref1; y = j += ref2) {
        for (x = k = 0, ref3 = this.graph_width, ref4 = pixelsize; ref4 > 0 ? k <= ref3 : k >= ref3; x = k += ref4) {
          val = 0;
          if (do_antialias) {
            iter = 0;
            for (aay = l = 0, ref5 = aamult, ref6 = aastep; ref6 > 0 ? l <= ref5 : l >= ref5; aay = l += ref6) {
              for (aax = o = 0, ref7 = aamult, ref8 = aastep; ref8 > 0 ? o <= ref7 : o >= ref7; aax = o += ref8) {
                val += this.mandel_color_value(x + aax, y + aay);
                iter++;
              }
            }
            val /= iter;
          } else {
            val = this.mandel_color_value(x, y);
          }
          for (py = q = 0, ref9 = pixelsize; 0 <= ref9 ? q <= ref9 : q >= ref9; py = 0 <= ref9 ? ++q : --q) {
            for (px = s = 0, ref10 = pixelsize; 0 <= ref10 ? s <= ref10 : s >= ref10; px = 0 <= ref10 ? ++s : --s) {
              this.render_pixel(x + px, y + py, val);
            }
          }
        }
      }
      return stopline;
    };

    MandelIter.prototype.render_pixel = function(x, y, value) {
      var pos1x, pos4x;
      if (x < this.graph_width && y < this.graph_height) {
        pos1x = x + (y * this.graph_width);
        pos4x = 4 * pos1x;
        value /= this.mandel_maxiter;
        this.mandel_values[pos1x] = value;
        return this.colorize_pixel(value, pos4x);
      }
    };

    MandelIter.prototype.colorize_pixel = function(value, offset) {
      value = Math.pow(value, 0.5) * 255;
      this.current_image.data[offset] = value * this.current_theme[0];
      this.current_image.data[offset + 1] = value * this.current_theme[1];
      return this.current_image.data[offset + 2] = value * this.current_theme[2];
    };

    MandelIter.prototype.repaint_canvas = function(ctx, values, theme) {
      var j, k, pos1x, pos4x, ref, ref1, x, y;
      if (!((ctx != null) && (values != null))) {
        return;
      }
      this.current_image = this.graph_mandel_ctx.getImageData(0, 0, this.graph_width, this.graph_height);
      this.current_theme = theme;
      for (y = j = 0, ref = this.graph_height; 0 <= ref ? j <= ref : j >= ref; y = 0 <= ref ? ++j : --j) {
        for (x = k = 0, ref1 = this.graph_width; 0 <= ref1 ? k <= ref1 : k >= ref1; x = 0 <= ref1 ? ++k : --k) {
          pos1x = x + (y * this.graph_width);
          pos4x = 4 * pos1x;
          this.colorize_pixel(this.mandel_values[pos1x], pos4x);
          this.current_image.data[pos4x + 3] = 255;
        }
      }
      return ctx.putImageData(this.current_image, 0, 0);
    };

    MandelIter.prototype.repaint_mandelbrot = function() {
      return this.repaint_canvas(this.graph_mandel_ctx, this.mandel_values, this.current_mandel_theme());
    };

    MandelIter.prototype.mandelbrot_orbit = function*(c, max_yield) {
      var d, n, p, results, z;
      if (max_yield == null) {
        max_yield = this.mandel_maxiter;
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
      while ((d <= 4) && (n < max_yield)) {
        p = {
          r: (z.r * z.r) - (z.i * z.i),
          i: 2 * z.r * z.i
        };
        z = {
          r: p.r + c.r,
          i: p.i + c.i
        };
        d = (z.r * z.r) + (z.i * z.i);
        n += 1;
        results.push((yield {
          z: z,
          n: n
        }));
      }
      return results;
    };

    MandelIter.prototype.draw_orbit = function(c) {
      var draw_lines, draw_points, isize, julia_bb, mx, my, osize, p, point_size, pos, ref, step;
      mx = c.x;
      my = c.y;
      pos = this.canvas_to_complex(mx, my);
      this.loc_c.innerText = this.complex_to_string(pos);
      draw_lines = this.option.orbit_draw_lines.value;
      draw_points = this.option.orbit_draw_points.value;
      point_size = this.option.orbit_point_size.value;
      julia_bb = this.option.julia_draw_local.value;
      this.graph_ui_ctx.save();
      this.graph_ui_ctx.lineWidth = 2;
      this.graph_ui_ctx.strokeStyle = 'rgba(255,255,108,0.35)';
      this.graph_ui_ctx.fillStyle = 'rgba(255,249,187, 0.6)';
      if (draw_lines) {
        this.graph_ui_ctx.beginPath();
        this.graph_ui_ctx.moveTo(mx, my);
      }
      if (draw_lines || draw_points) {
        if (julia_bb) {
          this.orbit_bb.min_x = this.graph_width;
          this.orbit_bb.max_x = 0;
          this.orbit_bb.min_y = this.graph_height;
          this.orbit_bb.max_y = 0;
        }
        ref = this.mandelbrot_orbit(pos, this.option.orbit_draw_length.value);
        for (step of ref) {
          if (step.n > 0) {
            p = this.complex_to_canvas(step.z);
            if (draw_lines) {
              this.graph_ui_ctx.lineTo(p.x, p.y);
              this.graph_ui_ctx.stroke();
            }
            if (draw_points) {
              this.graph_ui_ctx.beginPath();
              this.graph_ui_ctx.arc(p.x, p.y, point_size, 0, TAU, false);
              this.graph_ui_ctx.fill();
            }
            if (draw_lines) {
              this.graph_ui_ctx.beginPath();
              this.graph_ui_ctx.moveTo(p.x, p.y);
            }
            if (julia_bb) {
              this.orbit_bb.min_x = Math.min(this.orbit_bb.min_x, p.x);
              this.orbit_bb.max_x = Math.max(this.orbit_bb.max_x, p.x);
              this.orbit_bb.min_y = Math.min(this.orbit_bb.min_y, p.y);
              this.orbit_bb.max_y = Math.max(this.orbit_bb.max_y, p.y);
            }
          }
        }
      }
      isize = 3.2;
      osize = isize * 3.4;
      this.graph_ui_ctx.beginPath();
      this.graph_ui_ctx.save();
      this.graph_ui_ctx.translate(mx, my);
      this.graph_ui_ctx.rotate(this.pointer_angle);
      this.graph_ui_ctx.translate(-1 * mx, -1 * my);
      this.graph_ui_ctx.moveTo(mx + isize, my + isize);
      this.graph_ui_ctx.lineTo(mx + osize, my);
      this.graph_ui_ctx.lineTo(mx + isize, my - isize);
      this.graph_ui_ctx.lineTo(mx, my - osize);
      this.graph_ui_ctx.lineTo(mx - isize, my - isize);
      this.graph_ui_ctx.lineTo(mx - osize, my);
      this.graph_ui_ctx.lineTo(mx - isize, my + isize);
      this.graph_ui_ctx.lineTo(mx, my + osize);
      this.graph_ui_ctx.lineTo(mx + isize, my + isize);
      this.graph_ui_ctx.fillStyle = 'rgba(255,249,187, 0.2)';
      this.graph_ui_ctx.fill();
      this.graph_ui_ctx.lineWidth = 1;
      this.graph_ui_ctx.strokeStyle = '#F09456';
      this.graph_ui_ctx.stroke();
      this.graph_ui_ctx.lineWidth = 1;
      this.graph_ui_ctx.strokeStyle = '#F2CE72';
      this.graph_ui_ctx.stroke();
      this.graph_ui_ctx.restore();
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

    MandelIter.prototype.julia = function(c, z) {
      var d, n, pi, pr, zi, zr;
      n = 0;
      d = 0;
      zr = z.r;
      zi = z.i;
      while ((d <= 4) && (n < this.julia_maxiter)) {
        pr = (zr * zr) - (zi * zi);
        pi = 2 * zr * zi;
        zr = pr + c.r;
        zi = pi + c.i;
        d = (zr * zr) + (zi * zi);
        n += 1;
      }
      return [n, d <= 4];
    };

    MandelIter.prototype.julia_color_value = function(c, x, y) {
      var in_set, n, p, ref;
      p = this.canvas_to_complex(x, y);
      ref = this.julia(this.canvas_to_complex(c.x, c.y), this.canvas_to_complex(x, y)), n = ref[0], in_set = ref[1];
      if (in_set) {
        return 0;
      } else {
        return n;
      }
    };

    MandelIter.prototype.draw_local_julia = function(c) {
      var highres, j, k, l, margin2x, maxsize, maxx, maxy, o, opacity, orbit_cx, orbit_cy, pixelsize, pos1x, pos4x, px, py, ref, ref1, ref2, ref3, ref4, ref5, val, x, y;
      if ((this.local_julia.width > 0) && (this.local_julia.height > 0)) {
        this.graph_julia_ctx.clearRect(this.local_julia.x, this.local_julia.y, this.local_julia.width, this.local_julia.height);
      }
      pixelsize = this.option.julia_local_pixel_size.value;
      this.julia_maxiter = this.option.julia_max_iterations.value;
      opacity = Math.ceil(this.option.julia_local_opacity.value * 256);
      highres = this.pause_mode && this.option.julia_more_when_paused.value;
      if (this.defer_highres_frames > 0) {
        this.defer_highres_frames = this.defer_highres_frames - 1;
        highres = false;
        this.schedule_ui_draw();
      }
      if (highres) {
        this.local_julia.x = 0;
        this.local_julia.y = 0;
        this.local_julia.width = this.graph_width;
        this.local_julia.height = this.graph_height;
        pixelsize = 1;
        this.julia_maxiter = this.option.julia_max_iter_paused.value;
      } else {
        orbit_cx = Math.floor((this.orbit_bb.max_x + this.orbit_bb.min_x) / 2);
        orbit_cy = Math.floor((this.orbit_bb.max_y + this.orbit_bb.min_y) / 2);
        maxsize = this.option.julia_local_max_size.value;
        margin2x = this.option.julia_local_margin.value * 2;
        this.local_julia.width = this.orbit_bb.max_x - this.orbit_bb.min_x + margin2x;
        this.local_julia.height = this.orbit_bb.max_y - this.orbit_bb.min_y + margin2x;
        this.local_julia.width = Math.floor(this.local_julia.width);
        this.local_julia.height = Math.floor(this.local_julia.height);
        if (this.local_julia.width > maxsize) {
          this.local_julia.width = maxsize;
        }
        if (this.local_julia.height > maxsize) {
          this.local_julia.height = maxsize;
        }
        if (this.local_julia.width > this.graph_width) {
          this.local_julia.width = this.graph_width;
        }
        if (this.local_julia.height > this.graph_height) {
          this.local_julia.height = this.graph_height;
        }
        this.local_julia.x = orbit_cx - Math.floor(this.local_julia.width / 2);
        this.local_julia.y = orbit_cy - Math.floor(this.local_julia.height / 2);
        if (this.local_julia.x < 0) {
          this.local_julia.x = 0;
        }
        if (this.local_julia.y < 0) {
          this.local_julia.y = 0;
        }
        maxx = Math.floor(this.graph_width - this.local_julia.width);
        maxy = Math.floor(this.graph_height - this.local_julia.height);
        if (this.local_julia.x > maxx) {
          this.local_julia.x = maxx;
        }
        if (this.local_julia.y > maxy) {
          this.local_julia.y = maxy;
        }
      }
      this.current_image = this.graph_julia_ctx.createImageData(this.local_julia.width, this.local_julia.height);
      this.current_theme = this.current_julia_theme();
      for (y = j = 0, ref = this.local_julia.height, ref1 = pixelsize; ref1 > 0 ? j <= ref : j >= ref; y = j += ref1) {
        for (x = k = 0, ref2 = this.local_julia.width, ref3 = pixelsize; ref3 > 0 ? k <= ref2 : k >= ref2; x = k += ref3) {
          px = x + this.local_julia.x;
          py = y + this.local_julia.y;
          val = this.julia_color_value(c, px, py);
          val /= 255;
          for (py = l = 0, ref4 = pixelsize; 0 <= ref4 ? l <= ref4 : l >= ref4; py = 0 <= ref4 ? ++l : --l) {
            for (px = o = 0, ref5 = pixelsize; 0 <= ref5 ? o <= ref5 : o >= ref5; px = 0 <= ref5 ? ++o : --o) {
              pos1x = (x + px) + ((y + py) * this.current_image.width);
              pos4x = 4 * pos1x;
              this.colorize_pixel(val, pos4x);
              this.current_image.data[pos4x + 3] = opacity;
            }
          }
        }
      }
      return this.graph_julia_ctx.putImageData(this.current_image, this.local_julia.x, this.local_julia.y);
    };

    MandelIter.prototype.draw_orbit_features = function(c) {
      this.draw_orbit(c);
      if (this.option.julia_draw_local.value) {
        return this.draw_local_julia(c);
      }
    };

    MandelIter.prototype.draw_trace_animation = function() {
      this.draw_orbit_features(this.current_trace_location);
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
      return this.draw_orbit(this.orbit_mouse);
    };

    MandelIter.prototype.draw_ui = function() {
      this.draw_ui_scheduled = false;
      this.graph_ui_ctx.clearRect(0, 0, this.graph_width, this.graph_height);
      this.pointer_angle = this.pointer_angle + this.pointer_angle_step;
      if (this.pointer_angle >= TAU) {
        this.pointer_angle = this.pointer_angle - TAU;
      }
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
          return this.draw_orbit_features(this.orbit_mouse);
        }
      } else {
        if (this.pause_mode) {
          return this.draw_orbit_features(this.orbit_mouse);
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
