path = require 'path'
exec = require('child_process').execSync
fs = require 'fs'
tempfile = require 'tempfile'

packagePath = path.dirname __dirname

getConfigFilePath = () -> atom.config.get('jsdoc-preview.configFilePath') or path.join packagePath, 'conf.json'
createTempFolder = () -> tempfile().split('/').slice(0, -1).join '/'

module.exports =
  toDOMFragment: (filePath, callback = () -> null) ->
    tempfolder = null
    el = document.createElement 'div'
    domFragment = document.createElement 'div'

    try
      tempFolder = createTempFolder()

      exec "#{packagePath}/node_modules/.bin/jsdoc #{filePath} -c #{getConfigFilePath()} -d #{tempFolder}"

      file = fs.readFileSync path.join tempFolder, 'index.html'
    catch e
      return callback e, null

    el.innerHTML = file
    nav = el.querySelector 'nav'

    [].forEach.call nav.querySelectorAll('ul li a'), (link) ->
      href = link.getAttribute('href').replace /#.*$/, ''
      domFragment.appendChild htmlFileToDOMFragment path.join tempFolder, href


    domFragment.innerHTML = '<h2>No JSDocs to Preview</h2>' unless domFragment.innerHTML

    callback null, domFragment.innerHTML
  _getConfigFilePath: getConfigFilePath
  _createTempFolder: createTempFolder

htmlFileToDOMFragment = (filePath) ->
  el = document.createElement 'div'
  el.innerHTML = fs.readFileSync filePath

  [].forEach.call el.querySelectorAll('.tag-source'), (el) ->
    el.parentNode.removeChild el

  els = el.querySelectorAll '#main'

  el.innerHTML = ''

  [].forEach.call els, (child) ->
    if child.id is 'main'
      el.appendChild child
    else
      el.innerHTML = child.outerHTML + el.innerHTML

  el