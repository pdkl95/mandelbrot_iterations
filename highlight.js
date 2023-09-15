(function() {
  var natb, natt, step7,
    slice = [].slice;

  window.Highlight || (window.Highlight = {});

  Highlight.items = {};

  Highlight.sequences = {};

  Highlight.Item = (function() {
    Item.next_serialnum = function() {
      this._serialnum || (this._serialnum = 0);
      return this._serialnum++;
    };

    function Item(r, i1, name) {
      this.r = r;
      this.i = i1;
      this.name = name;
      this.serial = Highlight.Item.next_serialnum();
      this.id = "hl-item-" + this.serial;
      Highlight.items[this.id] = this;
    }

    Item.prototype.li_title = function() {
      return this.r + " + " + this.i + "i";
    };

    Item.prototype.create_li = function() {
      var el;
      el = document.createElement('li');
      el.id = this.id;
      el.classList.add('highlight_item');
      el.textContent = this.name;
      return el;
    };

    Item.prototype.li = function() {
      return this.li_el || (this.li_el = this.create_li());
    };

    Item.prototype.select = function() {
      var el, j, len, ref;
      ref = document.querySelectorAll('#highlight_list .highlight_item.selected');
      for (j = 0, len = ref.length; j < len; j++) {
        el = ref[j];
        el.classList.remove('selected');
      }
      return this.li_el.classList.add('selected');
    };

    return Item;

  })();

  Highlight.Sequence = (function() {
    Sequence.next_serialnum = function() {
      this._serialnum || (this._serialnum = 0);
      return this._serialnum++;
    };

    function Sequence(group_name, name) {
      this.group_name = group_name;
      this.name = name;
      this.serial = Highlight.Sequence.next_serialnum();
      this.id = "hl-seq-" + this.serial;
      Highlight.sequences[this.id] = this;
      this.items = [];
    }

    Sequence.prototype.description = function() {
      return this.group_name + " - " + this.name;
    };

    Sequence.prototype.add = function() {
      var item, item_args;
      item_args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      item = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Highlight.Item, item_args, function(){});
      return this.items.push(item);
    };

    Sequence.prototype.add_to_groups = function(parent) {
      this.option_el = document.createElement('option');
      this.option_el.id = this.id;
      this.option_el.value = this.id;
      this.option_el.textContent = this.description();
      return parent.appendChild(this.option_el);
    };

    Sequence.prototype.li_items = function() {
      return this.items.map(function(i) {
        return i.li();
      });
    };

    Sequence.prototype.select = function(list_el) {
      var j, len, li_el, ref, results;
      this.current_idx = 0;
      list_el.replaceChildren();
      ref = this.li_items();
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        li_el = ref[j];
        results.push(list_el.appendChild(li_el));
      }
      return results;
    };

    Sequence.prototype.current = function() {
      if (this.current_idx == null) {
        this.current_idx = 0;
      }
      return this.items[this.current_idx];
    };

    Sequence.prototype.prev = function() {
      this.current_idx--;
      if (this.current_idx < 0) {
        this.current_idx = this.items.length - 1;
      }
      return this.current();
    };

    Sequence.prototype.next = function() {
      this.current_idx++;
      if (this.current_idx >= this.items.length) {
        this.current_idx = 0;
      }
      return this.current();
    };

    return Sequence;

  })();

  natb = new Highlight.Sequence("Natural Numbers", "Bulbs");

  natb.add(0.0, 0.0, "Period 1 Cardioid");

  natb.add(-1.0, 0.0, "Period 2 Bulb");

  natb.add(-0.13080895008605875, 0.7441860465116279, "Period 3 Bulb");

  natb.add(0.27710843373493965, 0.5322997416020672, "Period 4 Bulb");

  natb.add(0.37890705679862435, 0.3357622739018089, "Period 5 Bulb");

  natb.add(0.39013769363166784, 0.2164857881136979, "Period 6 Bulb");

  natb.add(0.37823580034423365, 0.1444961240310032, "Period 7 Bulb");

  natt = new Highlight.Sequence("Natural Numbers", "Tangent Point");

  natt.add(-1.0, 0.0, "Period 2 Tangent Point");

  natt.add(-0.12534581653163057, 0.6494540047116335, "Period 3 Tangent Point");

  natt.add(0.25014244320041534, 0.4997574456139653, "Period 4 Tangent Point");

  natt.add(0.3565970347803682, 0.3288718747652626, "Period 5 Tangent Point");

  natt.add(0.3749373532678093, 0.21617198000410243, "Period 6 Tangent Point");

  natt.add(0.3673160480625435, 0.1471806613953346, "Period 7 Tangent Point");

  step7 = new Highlight.Sequence("Step Size", "Period 7");

  step7.add(0.37823580034423365, 0.1444961240310032, "Period 7 Step 1 Bulb (1/7)");

  step7.add(0.12380378657487201, 0.613514211886304, "Period 7 Step 2 Bulb (2/7)");

  step7.add(-0.6248795180722884, 0.42529715762273756, "Period 7 Step 3 Bulb (3/7)");

  step7.add(-0.6248795180722884, -0.42529715762273756, "Period 7 Step 4 Bulb (4/7)");

  step7.add(0.12380378657487201, -0.613514211886304, "Period 7 Step 5 Bulb (5/7)");

  step7.add(0.37823580034423365, -0.1444961240310032, "Period 7 Step 6 Bulb (6/7)");

}).call(this);
