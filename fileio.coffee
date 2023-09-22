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
