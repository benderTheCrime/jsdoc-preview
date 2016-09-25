path = require 'path'
# exec = require('child_process').execSync
jsdoc = require('jsdoc-api');
fs = require 'fs'

tempfile = require 'tempfile'

util = require './util'

slicer = if util.isWin() then '\\' else '/'
packagePath = path.dirname __dirname

getConfigFilePath = () -> atom.config.get('jsdoc-preview.configFilePath') or path.join packagePath, 'conf.json'
createTempDir = () -> tempFile = tempfile().split(slicer).slice(0, -1).join slicer

module.exports =
  toDOMFragment: (filePath, callback = () -> null) ->
    tempDir = createTempDir()
    el = document.createElement 'div'
    domFragment = document.createElement 'div'

    try

      # NOTE: In the future, you can probably use jsdoc2md
      jsdoc.renderSync
        files: filePath
        destination: createTempDir()
        configure: getConfigFilePath()
      file = fs.readFileSync path.join tempDir, 'index.html'
    catch e
      return callback e, null

    el.innerHTML = file
    nav = el.querySelector 'nav'

    [].forEach.call nav.querySelectorAll('ul li a'), (link) ->
      href = link.getAttribute('href').replace /#.*$/, ''
      domFragment.appendChild htmlFileToDOMFragment path.join tempDir, href


    domFragment.innerHTML = '<h2>No JSDocs to Preview</h2>' unless domFragment.innerHTML

    callback null, domFragment.innerHTML
  _getConfigFilePath: getConfigFilePath
  _createTempDir: createTempDir

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
