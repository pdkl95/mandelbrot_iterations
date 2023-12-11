(function() {
  var slice = [].slice,
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  window.Motion || (window.Motion = {});

  Motion.Point = (function() {
    function Point() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      switch (args.length) {
        case 1:
          this.x = args[0].x;
          this.y = args[0].y;
          break;
        case 2:
          this.x = args[0];
          this.y = args[1];
          break;
        default:
          APP.debug("new Highlight.Point() called with " + args.length + " args: " + (args.join(', ')));
      }
      this.complex = APP.canvas_to_complex(this.x, this.y);
      this.polar_radius = Math.sqrt((this.complex.r * this.complex.r) + (this.complex.i * this.complex.i));
      this.polar_angle = Math.atan2(this.complex.i, this.complex.r);
      if (this.polar_angle < 0) {
        this.polar_angle += Math.TAU;
      }
    }

    Point.prototype.lerp = function(a, b, t) {
      return (a * (1 - t)) + (b * t);
    };

    Point.prototype.lerp2 = function(a, b, t) {
      return {
        x: this.lerp(a.x, b.x, t),
        y: this.lerp(a.y, b.y, t)
      };
    };

    Point.prototype.linear_interp_to = function(other, t) {
      return this.lerp2(this, other, t);
    };

    Point.prototype.polar_interp_to = function(other, t) {
      var a, b, dt, inv_t, r, theta;
      inv_t = 1 - t;
      r = (this.polar_radius * inv_t) + (other.polar_radius * t);
      a = this.polar_angle;
      b = other.polar_angle;
      if (b < a) {
        b += Math.TAU;
      }
      dt = modulo(b - a, Math.TAU);
      theta = dt < Math.PI ? this.polar_angle + (dt * t) : (dt = Math.TAU - dt, this.polar_angle - (dt * t));
      theta = modulo(theta, Math.TAU);
      return APP.complex_to_canvas({
        r: r * Math.cos(theta),
        i: r * Math.sin(theta)
      });
    };

    Point.prototype.ease_in_out_quart = function(t) {
      if (t < 0.5) {
        return 8 * t * t * t * t;
      } else {
        return 1 - Math.pow(-2 * t + 2, 4) / 2;
      }
    };

    Point.prototype.ease_to = function(other, t) {
      var linear, maxlinear, polar, r;
      polar = this.polar_interp_to(other, this.ease_in_out_quart(t));
      r = Math.min(this.polar_radius, other.polar_radius);
      maxlinear = 0.85;
      if (r < maxlinear) {
        linear = this.linear_interp_to(other, this.ease_in_out_quart(t));
        return this.lerp2(linear, polar, r / maxlinear);
      } else {
        return polar;
      }
    };

    return Point;

  })();

  Motion.Anim = (function() {
    function Anim(p_src, p_dst, steps) {
      this.steps = steps;
      this.src = new Motion.Point(p_src);
      this.dst = new Motion.Point(p_dst);
      this.steps = parseInt(this.steps) * 5;
      this.step_size = 1.0 / this.steps;
      this.current_step = 0;
      this.t = 0;
    }

    Anim.prototype.next = function() {
      if (this.finished()) {
        return this.dst;
      }
      this.t += this.step_size;
      this.current_step += 1;
      return this.src.ease_to(this.dst, this.t);
    };

    Anim.prototype.finished = function() {
      return this.current_step >= this.steps;
    };

    Anim.prototype.remaining = function() {
      return 1.0 - (this.current_step / this.steps);
    };

    Anim.prototype.highlight_color = function() {
      var channel;
      channel = 255 * this.remaining();
      return "rgb(" + channel + "," + channel + ",0)";
    };

    Anim.prototype.finished_color = function() {
      return "rgb(0,0,0)";
    };

    return Anim;

  })();

}).call(this);
