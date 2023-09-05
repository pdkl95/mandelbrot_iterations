(function() {
  var slice = [].slice;

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
    }

    Point.prototype.linear_interp_to = function(other, t) {
      var inv_t;
      inv_t = 1 - t;
      return {
        x: (this.x * inv_t) + (other.x * t),
        y: (this.y * inv_t) + (other.y * t)
      };
    };

    Point.prototype.ease_in_out_quart = function(t) {
      if (t < 0.5) {
        return 8 * t * t * t * t;
      } else {
        return 1 - Math.pow(-2 * t + 2, 4) / 2;
      }
    };

    Point.prototype.ease_to = function(other, t) {
      return this.linear_interp_to(other, this.ease_in_out_quart(t));
    };

    return Point;

  })();

  Motion.Anim = (function() {
    function Anim(p_src, p_dst, steps) {
      this.steps = steps;
      this.src = new Motion.Point(p_src);
      this.dst = new Motion.Point(p_dst);
      this.steps = parseInt(this.steps);
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

    return Anim;

  })();

}).call(this);
