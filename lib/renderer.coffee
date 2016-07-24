exec = require('child_process').execSync
fs = require 'fs'

mkdirp = require 'mkdirp'

path = require 'path'

# _ = require 'underscore-plus'
# cheerio = require 'cheerio'
# fs = require 'fs-plus'
Highlights = require 'highlights'
# {$} = require 'atom-space-pen-views'
# roaster = null # Defer until used
{scopeForFenceName} = require './extension-helper'

# highlighter = null
# {resourcePath} = atom.getLoadSettings()
packagePath = path.dirname __dirname

###*
 * Funtion to calculate cube of input
 * @param {number} Number to operate on
 * @return {number} Cube of input
###
exports.toDOMFragment = (text = '', filePath, grammar, callback) ->
  # render text, filePath, (error, html) ->
    # return callback(error) if error?


    el = document.createElement 'div'
    domFragment = document.createElement 'div'
    #domFragment.innerHTML = 'foo'

    # TODO Path to config
    # TODO Path for cache
    # TODO This will generate docs for non-existent docstrings
    # TODO Show params
    # TODO Hide
    mkdirp.sync "#{packagePath}/.jsdoc-preview-docs"
    exec "#{packagePath}/node_modules/.bin/jsdoc #{filePath} -d #{packagePath}/.jsdoc-preview-docs"
    file = fs.readFileSync "#{packagePath}/.jsdoc-preview-docs/global.html"


    el.innerHTML = file

    # domFragment.appendChild el.querySelector '#main'
    # domFragment.appendChild el.querySelector 'nav'
    # domFragment.querySelector('.page-title').innerHTML = filePath.split('/').pop()

    nav = el.querySelector 'nav'

    # debugger;

    [].forEach.call nav.querySelectorAll('ul li a'), (link) ->
      # console.log link, link.href
      # debugger;

      href = link.getAttribute('href').replace /#.*$/, ''
      domFragment.appendChild htmlFileToDOMFragment "#{packagePath}/.jsdoc-preview-docs/#{href}"

    # template = document.createElement('template')
    # template.innerHTML = html
    # domFragment = template.content.cloneNode(true)

    # Default code blocks to be coffee in Literate CoffeeScript files
    # defaultCodeLanguage = 'coffee' if grammar?.scopeName is 'source.litcoffee'
    # convertCodeBlocksToAtomEditors(domFragment, defaultCodeLanguage)

    # TODO You have to grab classes from their files

    console.log domFragment, domFragment.innerHTML

    callback null, domFragment.innerHTML

exports.toHTML = (text='', filePath, grammar, callback) ->
    callback null, fs.readFileSync "#{packagePath}/.jsdoc-preview-docs/global.html"

htmlFileToDOMFragment = (filePath) ->
  el = document.createElement 'div'
  el.innerHTML = fs.readFileSync filePath

  [].forEach.call el.querySelectorAll('.tag-source'), (el) -> el.parentNode.removeChild el

  els = el.querySelectorAll 'h1, #main'

  debugger

  console.log els

  el.innerHTML = ''

  [].forEach.call els, (child) -> el.appendChild child

  console.log el

  el

# render = (text, filePath, callback) ->
  # roaster ?= require 'roaster'
  # options =
    # sanitize: false
    # breaks: atom.config.get('jsdoc-preview.breakOnSingleNewline')

  # Remove the <!doctype> since otherwise marked will escape it
  # https://github.com/chjj/marked/issues/354
  # text = text.replace(/^\s*<!doctype(\s+.*)?>\s*/i, '')

  # roaster text, options, (error, html) ->
    # return callback(error) if error?

    # html = sanitize(html)
    # html = resolveImagePaths(html, filePath)
    # callback(null, html.trim())

# sanitize = (html) ->
#   o = cheerio.load(html)
#   o('script').remove()
#   attributesToRemove = [
#     'onabort'
#     'onblur'
#     'onchange'
#     'onclick'
#     'ondbclick'
#     'onerror'
#     'onfocus'
#     'onkeydown'
#     'onkeypress'
#     'onkeyup'
#     'onload'
#     'onmousedown'
#     'onmousemove'
#     'onmouseover'
#     'onmouseout'
#     'onmouseup'
#     'onreset'
#     'onresize'
#     'onscroll'
#     'onselect'
#     'onsubmit'
#     'onunload'
#   ]
#   o('*').removeAttr(attribute) for attribute in attributesToRemove
#   o.html()

# resolveImagePaths = (html, filePath) ->
#   [rootDirectory] = atom.project.relativizePath(filePath)
#   o = cheerio.load(html)
#   for imgElement in o('img')
#     img = o(imgElement)
#     if src = img.attr('src')
#       continue if src.match(/^(https?|atom):\/\//)
#       continue if src.startsWith(process.resourcesPath)
#       continue if src.startsWith(resourcePath)
#       continue if src.startsWith(packagePath)
#
#       if src[0] is '/'
#         unless fs.isFileSync(src)
#           if rootDirectory
#             img.attr('src', path.join(rootDirectory, src.substring(1)))
#       else
#         img.attr('src', path.resolve(path.dirname(filePath), src))
#
#   o.html()

# convertCodeBlocksToAtomEditors = (domFragment, defaultLanguage='text') ->
#   if fontFamily = atom.config.get('editor.fontFamily')
#
#     for codeElement in domFragment.querySelectorAll('code')
#       codeElement.style.fontFamily = fontFamily
#
#   for preElement in domFragment.querySelectorAll('pre')
#     codeBlock = preElement.firstElementChild ? preElement
#     fenceName = codeBlock.getAttribute('class')?.replace(/^lang-/, '') ? defaultLanguage
#
#     editorElement = document.createElement('atom-text-editor')
#     editorElement.setAttributeNode(document.createAttribute('gutter-hidden'))
#     editorElement.removeAttribute('tabindex') # make read-only
#
#     preElement.parentNode.insertBefore(editorElement, preElement)
#     preElement.remove()
#
#     editor = editorElement.getModel()
#     # remove the default selection of a line in each editor
#     editor.getDecorations(class: 'cursor-line', type: 'line')[0].destroy()
#     editor.setText(codeBlock.textContent.trim())
#     if grammar = atom.grammars.grammarForScopeName(scopeForFenceName(fenceName))
#       editor.setGrammar(grammar)
#
#   domFragment
#
# tokenizeCodeBlocks = (html, defaultLanguage='text') ->
#   o = cheerio.load(html)
#
#   if fontFamily = atom.config.get('editor.fontFamily')
#     o('code').css('font-family', fontFamily)
#
#   for preElement in o('pre')
#     codeBlock = o(preElement).children().first()
#     fenceName = codeBlock.attr('class')?.replace(/^lang-/, '') ? defaultLanguage
#
#     highlighter = new Highlights(registry: atom.grammars)
#     highlightedHtml = highlighter.highlightSync
#       fileContents: codeBlock.text()
#       scopeName: scopeForFenceName(fenceName)
#
#     highlightedBlock = o(highlightedHtml)
#     # The `editor` class messes things up as `.editor` has absolutely positioned lines
#     highlightedBlock.removeClass('editor').addClass("lang-#{fenceName}")
#
#     o(preElement).replaceWith(highlightedBlock)
#
#   o.html()
