(function() {
  var natb, natt, step7,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  window.Highlight || (window.Highlight = {});

  Highlight.items = {};

  Highlight.sequences = {};

  Highlight.saved_locations = {};

  Highlight.Item = (function() {
    Item.next_serialnum = function() {
      this._serialnum || (this._serialnum = 0);
      return this._serialnum++;
    };

    function Item(r, i1, name) {
      this.r = r;
      this.i = i1;
      this.name = name != null ? name : null;
      this.serial = Highlight.Item.next_serialnum();
      this.id = "hl-item-" + this.serial;
      Highlight.items[this.id] = this;
    }

    return Item;

  })();

  Highlight.SavedItem = (function(superClass) {
    extend(SavedItem, superClass);

    SavedItem.storage_id = function(idx) {
      return "saved_loc[" + idx + "]";
    };

    function SavedItem() {
      var args, parent_collection;
      parent_collection = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      this.parent_collection = parent_collection;
      this.on_name_cell_input = bind(this.on_name_cell_input, this);
      this.on_set_c_button_click = bind(this.on_set_c_button_click, this);
      this.on_delete_button_click = bind(this.on_delete_button_click, this);
      SavedItem.__super__.constructor.apply(this, args);
      this.serial = Highlight.Sequence.next_serialnum();
      this.name || (this.name = "Save #" + this.serial);
      this.row_id = "saved_item-row-" + this.serial;
      Highlight.saved_locations[this.row_id] = this;
    }

    SavedItem.prototype.create_set_c_button = function(value) {
      var el, text;
      text = APP.fmtfloat.format(value);
      el = document.createElement('a');
      el.innerText = text;
      el.classList.add('set_c_button');
      el.addEventListener('click', this.on_set_c_button_click);
      return el;
    };

    SavedItem.prototype.create_tr = function(parent) {
      if (this.tr_el != null) {
        return this.tr_el;
      }
      this.tr_el = parent.insertRow(-1);
      this.tr_el.id = this.row_id;
      this.name_cell = this.tr_el.insertCell(0);
      this.real_cell = this.tr_el.insertCell(1);
      this.imag_cell = this.tr_el.insertCell(2);
      this.btn_cell = this.tr_el.insertCell(3);
      this.name_cell.innerText = this.name;
      this.name_cell.classList.add('name');
      this.name_cell.contentEditable = true;
      this.name_cell.addEventListener('input', this.on_name_cell_input);
      this.real_cell.append(this.create_set_c_button(this.r));
      this.imag_cell.append(this.create_set_c_button(this.i));
      this.delete_button = document.createElement('button');
      this.delete_button.classList.add('delete');
      this.delete_button.innerHTML = '&times;';
      this.delete_button.addEventListener('click', this.on_delete_button_click);
      this.btn_cell.appendChild(this.delete_button);
      return this.tr_el;
    };

    SavedItem.prototype.serialize = function() {
      if (this.name != null) {
        return this.r + "|" + this.i + "|" + this.name;
      } else {
        return this.r + "|" + this.i;
      }
    };

    SavedItem.prototype.save = function(idx) {
      if (idx == null) {
        idx = this.save_idx;
      }
      if (idx != null) {
        this.save_idx = idx;
        console.log('save', Highlight.SavedItem.storage_id(idx), this.serialize());
        return APP.storage_set(Highlight.SavedItem.storage_id(idx), this.serialize());
      } else {
        return APP.warn("Saving location \"" + this.name + "\" failed!");
      }
    };

    SavedItem.prototype.remove_storage = function() {
      if (this.save_idx != null) {
        return APP.storage_remove(Highlight.SavedItem.storage_id(this.save_idx));
      }
    };

    SavedItem.prototype.remove = function() {
      var idx;
      this.remove_storage();
      this.tr_el.remove();
      idx = this.parent_collection.items.indexOf(this);
      this.parent_collection.items.splice(idx, 1);
      return delete Highlight.saved_locations[this.row_id];
    };

    SavedItem.prototype.on_delete_button_click = function(event) {
      var loc, row;
      row = event.target.parentElement.parentElement;
      if (row != null) {
        loc = Highlight.saved_locations[row.id];
        if (loc != null) {
          return loc.remove();
        }
      }
    };

    SavedItem.prototype.on_set_c_button_click = function(event) {
      var loc, row;
      row = event.target.parentElement.parentElement;
      if (row != null) {
        loc = Highlight.saved_locations[row.id];
        if (loc != null) {
          return loc.set_c(this);
        }
      }
    };

    SavedItem.prototype.set_c = function(item) {
      return APP.animate_to(APP.complex_to_canvas(item));
    };

    SavedItem.prototype.on_name_cell_input = function(event) {
      var loc, row;
      row = event.target.parentElement;
      if (row != null) {
        loc = Highlight.saved_locations[row.id];
        if (loc != null) {
          loc.name = event.target.innerText;
          return this.save();
        }
      }
    };

    return SavedItem;

  })(Highlight.Item);

  Highlight.SequenceItem = (function() {
    function SequenceItem() {}

    SequenceItem.prototype.li_title = function() {
      return this.r + " + " + this.i + "i";
    };

    SequenceItem.prototype.create_li = function() {
      var el;
      el = document.createElement('li');
      el.id = this.id;
      el.classList.add('highlight_item');
      el.textContent = this.name;
      return el;
    };

    SequenceItem.prototype.li = function() {
      return this.li_el || (this.li_el = this.create_li());
    };

    SequenceItem.prototype.select = function() {
      var el, j, len, ref;
      ref = document.querySelectorAll('#highlight_list .highlight_item.selected');
      for (j = 0, len = ref.length; j < len; j++) {
        el = ref[j];
        el.classList.remove('selected');
      }
      return this.li_el.classList.add('selected');
    };

    return SequenceItem;

  })();

  Highlight.ItemCollection = (function() {
    function ItemCollection() {
      this.items = [];
    }

    return ItemCollection;

  })();

  Highlight.SavedLocations = (function(superClass) {
    extend(SavedLocations, superClass);

    SavedLocations.next_serialnum = function() {
      this._serialnum || (this._serialnum = 0);
      return this._serialnum++;
    };

    function SavedLocations(id) {
      this.id = id;
      SavedLocations.__super__.constructor.call(this);
      this.tbody_id = this.id + "_body";
      this.el = document.getElementById(this.id);
      this.tbody_el = document.getElementById(this.tbody_id);
    }

    SavedLocations.prototype.create_new_saved_item = function() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Highlight.SavedItem, [this].concat(slice.call(args)), function(){});
    };

    SavedLocations.prototype.append = function(item) {
      item.create_tr(this.tbody_el);
      return this.items.push(item);
    };

    SavedLocations.prototype.add = function(z) {
      this.append(this.create_new_saved_item(z.r, z.i));
      return this.save();
    };

    SavedLocations.prototype.save = function() {
      var idx, item, j, len, ref;
      ref = this.items;
      for (idx = j = 0, len = ref.length; j < len; idx = ++j) {
        item = ref[idx];
        item.save(idx);
      }
      return APP.storage_set('num_saved_locations', this.items.length);
    };

    SavedLocations.prototype.deserialize = function(str) {
      return (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Highlight.SavedItem, [this].concat(slice.call(str.split('|'))), function(){});
    };

    SavedLocations.prototype.load_item_from_storage = function(idx) {
      var item, str;
      str = APP.storage_get(Highlight.SavedItem.storage_id(idx));
      if (str != null) {
        item = this.deserialize(str);
        item.save_idx = idx;
        return item;
      } else {
        return null;
      }
    };

    SavedLocations.prototype.load_storage = function() {
      var idx, item, j, n, ref;
      n = APP.storage_get_int('num_saved_locations');
      for (idx = j = 0, ref = n; 0 <= ref ? j <= ref : j >= ref; idx = 0 <= ref ? ++j : --j) {
        item = this.load_item_from_storage(idx);
        if (item != null) {
          this.append(item);
        }
      }
      return n;
    };

    return SavedLocations;

  })(Highlight.ItemCollection);

  Highlight.Sequence = (function(superClass) {
    extend(Sequence, superClass);

    Sequence.next_serialnum = function() {
      this._serialnum || (this._serialnum = 0);
      return this._serialnum++;
    };

    function Sequence(group_name, name) {
      this.group_name = group_name;
      this.name = name;
      Sequence.__super__.constructor.call(this);
      this.serial = Highlight.Sequence.next_serialnum();
      this.id = "hl-seq-" + this.serial;
      Highlight.sequences[this.id] = this;
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
      })(Highlight.SequenceItem, item_args, function(){});
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

  })(Highlight.ItemCollection);

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
