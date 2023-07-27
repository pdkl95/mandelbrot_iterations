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

    function Option(id1, _default, on_change_callback) {
      this.id = id1;
      this["default"] = _default;
      this.on_change_callback = on_change_callback != null ? on_change_callback : null;
      this.on_change = bind(this.on_change, this);
      if (this.id instanceof Element) {
        this.el = this.id;
        this.id = this.el.id;
      } else {
        this.el = window.APP.context.getElementById(this.id);
      }
      this.set(this["default"]);
      this.el.addEventListener('change', this.on_change);
    }

    Option.prototype.on_change = function(event) {
      this.set(this.get(event.target));
      if (this.on_change_callback != null) {
        return this.on_change_callback(this.value);
      }
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
      this.value = (function() {
        switch (bool_value) {
          case 'true':
            return true;
          case 'false':
            return false;
          default:
            return !!bool_value;
        }
      })();
      return this.el.checked = this.value;
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
      this.value = parseInt(number_value);
      return this.el.value = this.value;
    };

    return IntOption;

  })(UI.Option);

}).call(this);
