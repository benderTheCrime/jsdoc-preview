path = require 'path'
exec = require('child_process').execSync
fs = require 'fs'

packagePath = path.dirname __dirname

exports.toDOMFragment = (text = '', filePath, grammar, callback) ->
    el = document.createElement 'div'
    domFragment = document.createElement 'div'

    # TODO This causes performance issues
    exec "rm -rf #{packagePath}/.jsdoc-preview-doc/*"
    exec "touch #{packagePath}/.jsdoc-preview-doc/.keep"

    try
      exec "#{packagePath}/node_modules/.bin/jsdoc #{filePath} -c #{getConfig()} -d #{packagePath}/.jsdoc-preview-doc"

      file = fs.readFileSync "#{packagePath}/.jsdoc-preview-doc/index.html"
    catch e
      return callback e, null

    el.innerHTML = file

    nav = el.querySelector 'nav'

    [].forEach.call nav.querySelectorAll('ul li a'), (link) ->
      href = link.getAttribute('href').replace /#.*$/, ''
      domFragment.appendChild htmlFileToDOMFragment "#{packagePath}/.jsdoc-preview-doc/#{href}"

    unless domFragment.innerHTML
      domFragment.innerHTML = '<h2>No JSDocs to Preview</h2>'

    callback null, domFragment.innerHTML

getConfig = () ->
  config = atom.config.get 'jsdoc-preview.configFilePath'
  config = "#{packagePath}/conf.json" if config is 'conf.json'

  config

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