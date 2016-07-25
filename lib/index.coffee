view = require './view'
renderer = require './renderer'

isView = (v) -> v instanceof view

module.exports =
  activate: ->
    atom.commands.add 'atom-workspace',
      'jsdoc-preview:toggle': => @toggle()

    previewFile = @previewFile.bind @
    atom.commands.add '.tree-view .file .name[data-name$=\\.js]', 'jsdoc-preview:toggle', previewFile
    atom.commands.add '.tree-view .file .name[data-name$=\\.javascript]', 'jsdoc-preview:toggle', previewFile
    atom.commands.add '.tree-view .file .name[data-name$=\\.es6]', 'jsdoc-preview:toggle', previewFile

    atom.workspace.addOpener (uriToOpen) =>
      [ protocol, path ] = uriToOpen.split('://')
      return unless protocol is 'jsdoc-preview'

      try
        path = decodeURI path
      catch
        return

      if path.startsWith 'editor/'
        @createView editorId: path.substring 7
      else
        @createView filePath: path

    @addJSDocCustomStyles()

  createView: (state) ->
    if state.editorId or fs.readFileSync state.filePath
      new view(state)

  toggle: ->
    if isView(atom.workspace.getActivePaneItem())
      atom.workspace.destroyActivePaneItem()
      return

    editor = atom.workspace.getActiveTextEditor()

    return unless editor? and editor.getGrammar().scopeName in [
      'source.js',
      'source.javascript',
      'source.es6'
    ]

    @addPreviewForEditor(editor) unless @removePreviewForEditor editor

  uriForEditor: (editor) -> "jsdoc-preview://editor/#{editor.id}"

  removePreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previewPane = atom.workspace.paneForURI(uri)
    if previewPane?
      previewPane.destroyItem(previewPane.itemForURI(uri))
      true
    else
      false

  addPreviewForEditor: (editor) ->
    uri = @uriForEditor editor
    previousActivePane = atom.workspace.getActivePane()
    options =
      searchAllPanes: true
      split: 'right'

    atom.workspace.open(uri, options).then (view) ->
      previousActivePane.activate() if isView view

  previewFile: ({ target }) ->
    filePath = target.dataset.path
    return unless filePath

    for editor in atom.workspace.getTextEditors() when editor.getPath() is filePath
      @addPreviewForEditor(editor)
      return

    atom.workspace.open "jsdoc-preview://#{encodeURI(filePath)}", searchAllPanes: true

  addJSDocCustomStyles: () ->
    for stylesheet in atom.config.get 'jsdoc-preview.customStyleSheets'
      unless (document.stylesheets.any (s) -> s.href is stylesheet)
        link = document.createElement 'link'
        link.rel = 'stylesheet'
        link.type = 'text/css'
        link.href = stylesheet
        document.head.appendChild link