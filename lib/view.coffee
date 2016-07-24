path = require 'path'

{Emitter, Disposable, CompositeDisposable, File} = require 'atom'
{$, $$$, ScrollView} = require 'atom-space-pen-views'
# Grim = require 'grim'
_ = require 'underscore-plus'
fs = require 'fs-plus'

renderer = require './renderer'

module.exports = class extends ScrollView
  @content: ->
    @div class: 'jsdoc-preview native-key-bindings', tabindex: -1

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

  destroy: ->
    @disposables.dispose()

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  onDidChangeModified: (callback) ->
    # No op to suppress deprecation warning
    new Disposable

  onDidChangeMarkdown: (callback) ->
    @emitter.on 'did-change-jsdoc', callback

  subscribeToFilePath: (filePath) ->
    @file = new File(filePath)
    @emitter.emit 'did-change-title'
    @handleEvents()
    @renderMarkdown()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId(editorId)

      if @editor?
        @emitter.emit 'did-change-title' if @editor?
        @handleEvents()
        @renderMarkdown()
      else
        # The editor this preview was created for has been closed so close
        # this preview since a preview cannot be rendered without an editor
        atom.workspace?.paneForItem(this)?.destroyItem(this)

    if atom.workspace?
      # debugger;
      resolve()
    else
      #  debugger
      @disposables.add atom.packages.onDidActivateInitialPackages resolve

  editorForId: (editorId) ->
    for editor in atom.workspace.getTextEditors()
      return editor if editor.id?.toString() is editorId.toString()
    null

  handleEvents: ->
    # debugger
    # @disposables.add atom.grammars.onDidAddGrammar => _.debounce((=> @renderMarkdown()), 250)
    # @disposables.add atom.grammars.onDidUpdateGrammar _.debounce((=> @renderMarkdown()), 250)

    atom.commands.add @element,
      'core:move-up': =>
        debugger
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
      @renderMarkdown()

      # TODO: Remove paneForURI call when ::paneForItem is released
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

    # @disposables.add atom.config.onDidChange 'jsdoc-preview.breakOnSingleNewline', changeHandler

    # @disposables.add atom.config.observe 'jsdoc-preview.useGitHubStyle', (useGitHubStyle) =>
    #   if useGitHubStyle
    #     @element.setAttribute('data-use-github-style', '')
    #   else
    #     @element.removeAttribute('data-use-github-style')

  renderMarkdown: ->
    @showLoading() unless @loaded
    @getJSDocSource().then (source) => @renderJSDocText(source) if source?

  getJSDocSource: ->
    if @file?.getPath()
      @file.read()
    else if @editor?
      Promise.resolve(@editor.getText())
    else
      Promise.resolve(null)

  getHTML: (callback) ->
    @getJSDocSource().then (source) =>
      return unless source?
      renderer.toHTML source, @getPath(), @getGrammar(), callback

  renderJSDocText: (text) ->
    renderer.toDOMFragment text, @getPath(), @getGrammar(), (error, domFragment) =>
      if error
        @showError(error)
      else

        @element = domFragment
        @loading = false
        @loaded = true
        @html(domFragment)
        @emitter.emit 'did-change-jsdoc'
        @originalTrigger('jsdoc-preview:jsdoc-changed')

  getTitle: ->
    if @file?
      "#{path.basename(@getPath())} Preview"
    else if @editor?
      "#{@editor.getTitle()} Preview"
    else
      "JSDoc Preview"

  getIconName: ->
    "markdown"

  getURI: ->
    if @file?
      "jsdoc-preview://#{@getPath()}"
    else
      "jsdoc-preview://editor/#{@editorId}"

  getPath: ->
    if @file?
      @file.getPath()
    else if @editor?
      @editor.getPath()

  getGrammar: ->
    @editor?.getGrammar()

  # getDocumentStyleSheets: -> # This function exists so we can stub it
  #   document.styleSheets

  # getTextEditorStyles: ->
  #   textEditorStyles = document.createElement 'atom-styles'
  #   textEditorStyles.initialize atom.styles
  #   textEditorStyles.setAttribute 'context', 'atom-text-editor'
  #   document.body.appendChild textEditorStyles

    # Extract style elements content
    # Array.prototype.slice.apply(textEditorStyles.childNodes).map (styleElement) ->
    #   styleElement.innerText

  # getJSDocPreviewCSS: ->
  #
  #
  #   # TODO Custom css
  #   rules = []
  #   # ruleRegExp = /\.jsdoc-preview/
  #   # cssUrlRefExp = /url\(atom:\/\/jsdoc-preview\/assets\/(.*)\)/
  #
  #   for stylesheet in @getDocumentStyleSheets()
  #     if stylesheet.rules?
  #       for rule in stylesheet.rules
  #
  #         # We only need `.markdown-review` css
  #         rules.push(rule.cssText) # if rule.selectorText?.match(ruleRegExp)?
  #
  #   rules
  #     # .concat(@getTextEditorStyles())
  #     .join('\n')
  #     # .replace(/atom-text-editor/g, 'pre.editor-colors')
  #     #.replace(/:host/g, '.host') # Remove shadow-dom :host selector causing problem on FF
  #     # .replace cssUrlRefExp, (match, assetsName, offset, string) -> # base64 encode assets
  #     #   assetPath = path.join __dirname, '../assets', assetsName
  #     #   originalData = fs.readFileSync assetPath, 'binary'
  #     #   base64Data = new Buffer(originalData, 'binary').toString('base64')
  #     #   "url('data:image/jpeg;base64,#{base64Data}')"

  showError: (result) ->
    failureMessage = result?.message

    @html $$$ ->
      @h2 'Previewing JSDoc Failed'
      @h3 failureMessage if failureMessage?

  showLoading: ->
    @loading = true
    @html $$$ ->
      @div class: 'jsdoc-spinner', 'Loading JSDoc\u2026'

  copyToClipboard: ->
    return false if @loading

    selection = window.getSelection()
    selectedText = selection.toString()
    selectedNode = selection.baseNode

    # Use default copy event handler if there is selected text inside this view
    return false if selectedText and selectedNode? and (@[ 0 ] is selectedNode or $.contains(@[ 0 ], selectedNode))

    @getHTML (error, html) ->
      if error?
        console.warn('Copying JSDoc as HTML failed', error)
      else
        atom.clipboard.write(html)

    true

  saveAs: ->
    return if @loading

    filePath = @getPath()
    title = 'JSDoc to HTML'
    if filePath
      title = path.parse(filePath).name
      filePath += '.html'
    else
      filePath = 'untitled.html'
      if projectPath = atom.project.getPaths()[0]
        filePath = path.join(projectPath, filePath)

    if htmlFilePath = atom.showSaveDialogSync(filePath)

      @getHTML (error, htmlBody) =>
        if error?
          console.warn('Saving JSDoc as HTML failed', error)
        else
          #
          # html = """
          #   <!DOCTYPE html>
          #   <html>
          #     <head>
          #         <meta charset="utf-8" />
          #         <title>#{title}</title>
          #         <style>#{@getJSDocPreviewCSS()}</style>
          #     </head>
          #     <body class='jsdoc-preview' data-use-github-style>#{htmlBody}</body>
          #   </html>""" + "\n" # Ensure trailing newline

          # fs.writeFileSync(htmlFilePath, html)
          fs.writeFileSync htmlFilePath, htmlBody
          atom.workspace.open htmlFilePath

  # isEqual: (other) -> @[0] is other?[0] # Compare DOM elements

# if Grim.includeDeprecatedAPIs
#   MarkdownPreviewView::on = (eventName) ->
#     if eventName is 'jsdoc-preview:jsdoc-changed'
#       Grim.deprecate("Use MarkdownPreviewView::onDidChangeMarkdown instead of the 'jsdoc-preview:jsdoc-changed' jQuery event")
#     super
