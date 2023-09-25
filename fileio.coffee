window.FileIO or= {}

FileIO.download = (filename, filedata, mimetype = 'text/plain') ->
  file = new File([filedata], filename, {type: mimetype})
  link = document.createElement('a')
  url = URL.createObjectURL(file)

  link.href = url
  link.download = file.name
  #document.appendChild(link)

  link.click()

  #document.body.removeChild(link)
  window.URL.revokeObjectURL(url)

class FileIO.Uploader
  constructor: (@input_id, @button_id = null) ->
    @input_el = document.getElementById(@input_id)
    @input_el.addEventListener('change', @on_input_change, false)

    if @button_id?
      @button_el = document.getElementById(@button_id)
      @button_el.addEventListener('click',  @on_button_click)

    @on_upload_callbacks = []

  on_upload: (callback_func) ->
    @on_upload_callbacks.push(callback_func)

  send_upload_callbacks: (filedata) ->
    for callback in @on_upload_callbacks
      callback(filedata)

  on_button_click: (event) =>
    @input_el.click()

  on_input_change: (event) =>
    return if @input_el.files.length < 1
    file = @input_el.files[0]

    enc    = new TextDecoder("utf-8")
    reader = new FileReader()

    reader.onload = () =>
      @send_upload_callbacks(enc.decode(reader.result))

    reader.readAsArrayBuffer(file)
