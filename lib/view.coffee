path = require 'path'

{ Emitter, Disposable, CompositeDisposable, File } = require 'atom'
{ $$$, ScrollView } = require 'atom-space-pen-views'

renderer = require './renderer'

module.exports = class extends ScrollView
  @content: -> @div class: 'jsdoc-preview native-key-bindings', tabindex: -1

  constructor: ({@editorId, @filePath}) ->
    super
    @emitter = new Emitter
    @disposables = new CompositeDisposable
    @loaded = false

  attached: ->
    return if @isAttached
    @isAttached = true

    if @editorId?
      @resolveEditor(@editorId)
    else
      if atom.workspace?
        @subscribeToFilePath(@filePath)
      else
        @disposables.add atom.packages.onDidActivateInitialPackages =>
          @subscribeToFilePath(@filePath)

  serialize: ->
    deserializer: 'JSDocPreviewView'
    filePath: @getPath() ? @filePath
    editorId: @editorId

  destroy: -> @disposables.dispose()
  onDidChangeTitle: (callback) -> @emitter.on 'did-change-title', callback
  onDidChangeModified: (callback) -> new Disposable
  onDidChangeMarkdown: (callback) -> @emitter.on 'did-change-jsdoc', callback

  subscribeToFilePath: (filePath) ->
    @file = new File(filePath)
    @emitter.emit 'did-change-title'
    @handleEvents()
    @renderJSDoc()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId(editorId)

      if @editor?
        @emitter.emit 'did-change-title' if @editor?
        @handleEvents()
        @renderJSDoc()
      else
        atom.workspace?.paneForItem(@)?.destroyItem @

    if atom.workspace?
      resolve()
    else
      @disposables.add atom.packages.onDidActivateInitialPackages resolve

  editorForId: (editorId) ->
    for editor in atom.workspace.getTextEditors()
      return editor if editor.id?.toString() is editorId.toString()
    null

  handleEvents: ->
    atom.commands.add @element,
      'core:move-up': =>
        @scrollUp()
      'core:move-down': =>
        @scrollDown()
      'core:save-as': (event) =>
        event.stopPropagation()
        @saveAs()
      'core:copy': (event) =>
        event.stopPropagation() if @copyToClipboard()
      'jsdoc-preview:zoom-in': =>
        zoomLevel = parseFloat(@css('zoom')) or 1
        @css('zoom', zoomLevel + .1)
      'jsdoc-preview:zoom-out': =>
        zoomLevel = parseFloat(@css('zoom')) or 1
        @css('zoom', zoomLevel - .1)
      'jsdoc-preview:reset-zoom': =>
        @css('zoom', 1)

    changeHandler = =>
      @renderJSDoc()

      pane = atom.workspace.paneForItem?(this) ? atom.workspace.paneForURI(@getURI())
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

    if @file?
      @disposables.add @file.onDidChange changeHandler
    else if @editor?
      @disposables.add @editor.getBuffer().onDidStopChanging ->
        changeHandler() if atom.config.get 'jsdoc-preview.liveUpdate'
      @disposables.add @editor.onDidChangePath => @emitter.emit 'did-change-title'
      @disposables.add @editor.getBuffer().onDidSave ->
        changeHandler() unless atom.config.get 'jsdoc-preview.liveUpdate'
      @disposables.add @editor.getBuffer().onDidReload ->
        changeHandler() unless atom.config.get 'jsdoc-preview.liveUpdate'

  renderJSDoc: ->
    @showLoading() unless @loaded
    @getJSDocSource().then (source) => @renderJSDocText()

  getJSDocSource: ->
    if @file?.getPath()
      @file.read()
    else if @editor?
      Promise.resolve @editor.getText()
    else
      Promise.resolve null

  renderJSDocText: () ->
    renderer.toDOMFragment @getPath(), (error, domFragment) =>
      if error
        @showError error
      else
        @loading = false
        @loaded = true
        @html domFragment
        @emitter.emit 'did-change-jsdoc'
        @originalTrigger 'jsdoc-preview:jsdoc-changed'

  getTitle: ->
    if @file?
      "#{path.basename(@getPath())} Preview"
    else if @editor?
      "#{@editor.getTitle()} Preview"
    else "JSDoc Preview"

  getURI: -> if @file then "jsdoc-preview://#{@getPath()}" else "jsdoc-preview://editor/#{@editorId}"

  getPath: ->
    if @file?
      @file.getPath()
    else if @editor?
      @editor.getPath()

  getGrammar: -> @editor?.getGrammar()

  showError: (result) ->
    failureMessage = result?.message

    @html $$$ ->
      @h2 'Previewing JSDoc Failed'
      @h3 failureMessage if failureMessage?

  showLoading: ->
    @loading = true
    @html $$$ -> @div class: 'jsdoc-spinner', 'Loading JSDoc\u2026'