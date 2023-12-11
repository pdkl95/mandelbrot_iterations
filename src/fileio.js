(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.FileIO || (window.FileIO = {});

  FileIO.download = function(filename, filedata, mimetype) {
    var file, link, url;
    if (mimetype == null) {
      mimetype = 'text/plain';
    }
    file = new File([filedata], filename, {
      type: mimetype
    });
    link = document.createElement('a');
    url = URL.createObjectURL(file);
    link.href = url;
    link.download = file.name;
    link.click();
    return window.URL.revokeObjectURL(url);
  };

  FileIO.Uploader = (function() {
    function Uploader(input_id, button_id) {
      this.input_id = input_id;
      this.button_id = button_id != null ? button_id : null;
      this.on_input_change = bind(this.on_input_change, this);
      this.on_button_click = bind(this.on_button_click, this);
      this.input_el = document.getElementById(this.input_id);
      this.input_el.addEventListener('change', this.on_input_change, false);
      if (this.button_id != null) {
        this.button_el = document.getElementById(this.button_id);
        this.button_el.addEventListener('click', this.on_button_click);
      }
      this.on_upload_callbacks = [];
    }

    Uploader.prototype.on_upload = function(callback_func) {
      return this.on_upload_callbacks.push(callback_func);
    };

    Uploader.prototype.send_upload_callbacks = function(filedata) {
      var callback, i, len, ref, results;
      ref = this.on_upload_callbacks;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        callback = ref[i];
        results.push(callback(filedata));
      }
      return results;
    };

    Uploader.prototype.on_button_click = function(event) {
      return this.input_el.click();
    };

    Uploader.prototype.on_input_change = function(event) {
      var enc, file, reader;
      if (this.input_el.files.length < 1) {
        return;
      }
      file = this.input_el.files[0];
      enc = new TextDecoder("utf-8");
      reader = new FileReader();
      reader.onload = (function(_this) {
        return function() {
          return _this.send_upload_callbacks(enc.decode(reader.result));
        };
      })(this);
      return reader.readAsArrayBuffer(file);
    };

    return Uploader;

  })();

}).call(this);
