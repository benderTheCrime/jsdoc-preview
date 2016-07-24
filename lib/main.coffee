url = require 'url'
fs = require 'fs-plus'
view = require './view'
renderer = require './renderer'

# JSDocPreviewView = null

isView = (v) ->
  # JSDocPreviewView ?= view
  v instanceof view

module.exports =
  activate: ->
    # TODO This has to go back in
    # if parseFloat(atom.getVersion()) < 1.7
    #   atom.deserializers.add
    #     name: 'JSDocPreviewView'
    #     deserialize: module.exports.createView.bind module.exports

    atom.commands.add 'atom-workspace',
      'jsdoc-preview:toggle': => @toggle()
      'jsdoc-preview:copy-html': => @copyHtml()
    #   'jsdoc-preview:toggle-break-on-single-newline': ->
    #     keyPath = 'markdown-preview.breakOnSingleNewline'
    #     atom.config.set(keyPath, not atom.config.get(keyPath))

    previewFile = @previewFile.bind(this)
    # atom.commands.add '.tree-view .file .name[data-name$=\\.markdown]', 'jsdoc-preview:preview-file', previewFile
    # atom.commands.add '.tree-view .file .name[data-name$=\\.md]', 'jsdoc-preview:preview-file', previewFile
    # atom.commands.add '.tree-view .file .name[data-name$=\\.mdown]', 'jsdoc-preview:preview-file', previewFile
    # atom.commands.add '.tree-view .file .name[data-name$=\\.mkd]', 'jsdoc-preview:preview-file', previewFile
    # atom.commands.add '.tree-view .file .name[data-name$=\\.mkdown]', 'jsdoc-preview:preview-file', previewFile
    # atom.commands.add '.tree-view .file .name[data-name$=\\.ron]', 'jsdoc-preview:preview-file', previewFile
    # atom.commands.add '.tree-view .file .name[data-name$=\\.txt]', 'jsdoc-preview:preview-file', previewFile
    atom.commands.add '.tree-view .file .name[data-name$=\\.js]', 'jsdoc-preview:toggle', previewFile
    atom.commands.add '.tree-view .file .name[data-name$=\\.coffee]', 'jsdoc-preview:toggle', previewFile

    atom.workspace.addOpener (uriToOpen) =>
      [protocol, path] = uriToOpen.split('://')
      return unless protocol is 'jsdoc-preview'

      try
        path = decodeURI(path)
      catch
        return

      if path.startsWith 'editor/'
        @createView(editorId: path.substring(7))
      else
        @createView(filePath: path)

  createView: (state) ->
    if state.editorId or fs.isFileSync state.filePath
      new view(state)

  toggle: ->
    if isView(atom.workspace.getActivePaneItem())
      atom.workspace.destroyActivePaneItem()
      return

    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    grammars = atom.config.get('jsdoc-preview.grammars') ? []
    return unless editor.getGrammar().scopeName in grammars

    @addPreviewForEditor(editor) unless @removePreviewForEditor(editor)

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
    uri = @uriForEditor(editor)
    previousActivePane = atom.workspace.getActivePane()
    options = searchAllPanes: true
    # if atom.config.get('jsdoc-preview.openPreviewInSplitPane')
    options.split = 'right'
    atom.workspace.open(uri, options).then (view) ->
      previousActivePane.activate() if isView view

  previewFile: ({ target }) ->
    filePath = target.dataset.path
    return unless filePath

    for editor in atom.workspace.getTextEditors() when editor.getPath() is filePath
      @addPreviewForEditor(editor)
      return

    atom.workspace.open "jsdoc-preview://#{encodeURI(filePath)}", searchAllPanes: true

  copyHtml: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    # renderer ?= require './renderer'
    text = editor.getSelectedText() or editor.getText()

    # renderer.toHTML text, editor.getPath(), editor.getGrammar(), (error, html) ->
    #   if error
    #     console.warn('Copying Markdown as HTML failed', error)
    #   else
    #     atom.clipboard.write(html)
