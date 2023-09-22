(function() {
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

}).call(this);
