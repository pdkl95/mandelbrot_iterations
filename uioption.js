(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  window.UI || (window.UI = {});

  UI.Option = (function() {
    Option.create_input_element = function(type, id) {
      var el;
      if (type == null) {
        type = null;
      }
      if (id == null) {
        id = null;
      }
      el = window.APP.context.createElement('input');
      if (id != null) {
        el.id = id;
      }
      if (type != null) {
        el.type = type;
      }
      return el;
    };

    function Option(id1, default_value, callback) {
      this.id = id1;
      if (default_value == null) {
        default_value = null;
      }
      this.callback = callback != null ? callback : {};
      this.on_change = bind(this.on_change, this);
      if (this.id instanceof Element) {
        this.el = this.id;
        this.id = this.el.id;
      } else {
        this.el = window.APP.context.getElementById(this.id);
        if (this.el == null) {
          console.log("ERROR - could not find element with id=\"" + this.id + "\"");
        }
      }
      this.label_id = this.id + "_label";
      this.label_el = window.APP.context.getElementById(this.label_id);
      if (default_value != null) {
        this["default"] = default_value;
      } else {
        this["default"] = this.detect_default_value();
      }
      this.set(this["default"]);
      this.el.addEventListener('change', this.on_change);
    }

    Option.prototype.detect_default_value = function() {
      return this.get();
    };

    Option.prototype.register_callback = function(opt) {
      var func, key, name, ref, results;
      if (opt == null) {
        opt = {};
      }
      for (name in opt) {
        func = opt[name];
        this.callback[name] = func;
      }
      ref = this.callback;
      results = [];
      for (key in ref) {
        func = ref[key];
        if (func == null) {
          results.push(delete this.callback[name]);
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Option.prototype.set_value = function(new_value) {
      this.value = new_value;
      if (this.label_el != null) {
        return this.label_el.innerText = this.label_text();
      }
    };

    Option.prototype.label_text = function() {
      return "" + this.value;
    };

    Option.prototype.on_change = function(event) {
      var base;
      this.set(this.get(event.target));
      return typeof (base = this.callback).on_change === "function" ? base.on_change(this.value) : void 0;
    };

    Option.prototype.enable = function() {
      return this.el.disabled = false;
    };

    Option.prototype.disable = function() {
      return this.el.disabled = true;
    };

    Option.prototype.destroy = function() {
      if (this.el != null) {
        this.el.remove();
      }
      return this.el = null;
    };

    return Option;

  })();

  UI.BoolOption = (function(superClass) {
    extend(BoolOption, superClass);

    function BoolOption() {
      return BoolOption.__super__.constructor.apply(this, arguments);
    }

    BoolOption.create = function() {
      var id1, opt, parent, rest;
      parent = arguments[0], id1 = arguments[1], rest = 3 <= arguments.length ? slice.call(arguments, 2) : [];
      this.id = id1;
      opt = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(UI.BoolOption, [UIOption.create_input_element('checkbox', this.id)].concat(slice.call(rest)), function(){});
      parent.appendChild(opt.el);
      return opt;
    };

    BoolOption.prototype.get = function(element) {
      if (element == null) {
        element = this.el;
      }
      return element.checked;
    };

    BoolOption.prototype.set = function(bool_value) {
      var base, base1, newvalue, oldvalue;
      oldvalue = this.value;
      newvalue = (function() {
        switch (bool_value) {
          case 'true':
            return true;
          case 'false':
            return false;
          default:
            return !!bool_value;
        }
      })();
      this.el.checked = newvalue;
      this.set_value(newvalue);
      if (oldvalue !== newvalue) {
        if (newvalue) {
          return typeof (base = this.callback).on_true === "function" ? base.on_true() : void 0;
        } else {
          return typeof (base1 = this.callback).on_false === "function" ? base1.on_false() : void 0;
        }
      }
    };

    return BoolOption;

  })(UI.Option);

  UI.IntOption = (function(superClass) {
    extend(IntOption, superClass);

    function IntOption() {
      return IntOption.__super__.constructor.apply(this, arguments);
    }

    IntOption.create = function() {
      var id1, opt, parent, rest;
      parent = arguments[0], id1 = arguments[1], rest = 3 <= arguments.length ? slice.call(arguments, 2) : [];
      this.id = id1;
      opt = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(UI.IntOption, [UIOption.create_input_element('number', this.id)].concat(slice.call(rest)), function(){});
      parent.appendChild(opt.el);
      return opt;
    };

    IntOption.prototype.get = function(element) {
      if (element == null) {
        element = this.el;
      }
      return parseInt(element.value);
    };

    IntOption.prototype.set = function(number_value) {
      this.set_value(parseInt(number_value));
      return this.el.value = this.value;
    };

    return IntOption;

  })(UI.Option);

  UI.FloatOption = (function(superClass) {
    extend(FloatOption, superClass);

    function FloatOption() {
      return FloatOption.__super__.constructor.apply(this, arguments);
    }

    FloatOption.create = function() {
      var id1, opt, parent, rest;
      parent = arguments[0], id1 = arguments[1], rest = 3 <= arguments.length ? slice.call(arguments, 2) : [];
      this.id = id1;
      opt = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(UI.IntOption, [UIOption.create_input_element(null, this.id)].concat(slice.call(rest)), function(){});
      parent.appendChild(opt.el);
      return opt;
    };

    FloatOption.prototype.get = function(element) {
      if (element == null) {
        element = this.el;
      }
      return parseFloat(element.value);
    };

    FloatOption.prototype.set = function(number_value) {
      this.set_value(parseFloat(number_value));
      return this.el.value = this.value;
    };

    return FloatOption;

  })(UI.Option);

  UI.PercentOption = (function(superClass) {
    extend(PercentOption, superClass);

    function PercentOption() {
      return PercentOption.__super__.constructor.apply(this, arguments);
    }

    PercentOption.prototype.label_text = function() {
      var perc;
      perc = parseInt(this.value * 100);
      return perc + "%";
    };

    return PercentOption;

  })(UI.FloatOption);

  UI.SelectOption = (function(superClass) {
    extend(SelectOption, superClass);

    function SelectOption() {
      return SelectOption.__super__.constructor.apply(this, arguments);
    }

    SelectOption.prototype.get = function(element) {
      if (element == null) {
        element = this.el;
      }
      return element.options[element.selectedIndex].value;
    };

    SelectOption.prototype.set = function(option_name) {
      var opt;
      opt = this.option_with_name(option_name);
      if (opt != null) {
        this.set_value(opt.value);
        return opt.selected = true;
      }
    };

    SelectOption.prototype.values = function() {
      return this.el.options.map(function(x) {
        return x.name;
      });
    };

    SelectOption.prototype.option_with_name = function(name) {
      var i, len, opt, ref;
      ref = this.el.options;
      for (i = 0, len = ref.length; i < len; i++) {
        opt = ref[i];
        if (opt.value === name) {
          return opt;
        }
      }
      return null;
    };

    return SelectOption;

  })(UI.Option);

}).call(this);
