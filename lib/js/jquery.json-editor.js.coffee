###
  Copyright (c) 2014, Andrew Cantino
  Copyright (c) 2009, Andrew Cantino & Kyle Maxwell

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.




  You will probably need to tell the editor where to find its 'add' and 'delete' images.  In your
  code, before you make the editor, do something like this:
     JSONEditor.prototype.ADD_IMG = '/javascripts/jsoneditor/add.png';
     JSONEditor.prototype.DELETE_IMG = '/javascripts/jsoneditor/delete.png';

  You can enable or disable visual truncation in the structure editor with the following:
    myEditor.doTruncation(false);
    myEditor.doTruncation(true); // The default

  You can show a 'w'ipe button that does a more aggressive delete by calling showWipe(true|false) or by passing in 'showWipe: true'.
###

class window.JSONEditor
  constructor: (wrapped, options = {}) ->
    @builderShowing = true
    @ADD_IMG ||= options.ADD_IMG || 'lib/images/add.png'
    @DELETE_IMG ||= options.DELETE_IMG || 'lib/images/delete.png'
    @functionButtonsEnabled = false
    @_doTruncation = true
    @_showWipe = options.showWipe

    @history = []
    @historyPointer = -1
    throw("Must provide an element to wrap.") if wrapped == null || (wrapped.get && wrapped.get(0) == null)
    @wrapped = $(wrapped)

    @wrapped.wrap('<div class="json-editor"></div>')
    @container = $(@wrapped.parent())
    @wrapped.hide()
    @container.css("position", "relative")
    @doAutoFocus = false
    @editingUnfocused()

    @rebuild()

  braceUI: (key, struct) ->
    $('<a class="icon" href="#"><strong>{</strong></a>').click (e) =>
      e.preventDefault()
      struct[key] = { "??": struct[key] }
      @doAutoFocus = true
      @rebuild()

  bracketUI: (key, struct) ->
    $('<a class="icon" href="#"><strong>[</a>').click (e) =>
      e.preventDefault()
      struct[key] = [ struct[key] ]
      @doAutoFocus = true
      @rebuild()

  deleteUI: (key, struct, fullDelete) ->
    $("<a class='icon' href='#' title='delete'><img src='#{@DELETE_IMG}' border=0 /></a>").click (e) =>
      e.preventDefault()
      if !fullDelete
        didSomething = false
        if struct[key] instanceof Array
          if struct[key].length > 0
            struct[key] = struct[key][0]
            didSomething = true
        else if struct[key] instanceof Object
          for subkey, subval of struct[key]
            struct[key] = struct[key][subkey]
            didSomething = true
            break

        if didSomething
          @rebuild()
          return

      if struct instanceof Array
        struct.splice(key, 1)
      else
        delete struct[key]

      @rebuild()

  wipeUI: (key, struct) ->
    $('<a class="icon" href="#" title="wipe"><strong>W</strong></a>').click (e) =>
      e.preventDefault()
      if struct instanceof Array
        struct.splice(key, 1)
      else
        delete struct[key]
      @rebuild()

  addUI: (struct) ->
    $("<a class='icon' href='#' title='add'><img src='#{@ADD_IMG}' border=0/></a>").click (e) =>
      e.preventDefault()
      if struct instanceof Array
        struct.push('??')
      else
        struct['??'] = '??'
      @doAutoFocus = true
      @rebuild()

  undo: ->
    if @saveStateIfTextChanged()
      @historyPointer -= 1 if @historyPointer > 0
      @restore()

  redo: ->
    if @historyPointer + 1 < @history.length
      if @saveStateIfTextChanged()
        @historyPointer += 1
        @restore()

  showBuilder: ->
    if @checkJsonInText()
      @setJsonFromText()
      @rebuild()
      @wrapped.hide()
      @builder.show()
      true
    else
      alert "Sorry, there appears to be an error in your JSON input.  Please fix it before continuing."
      false

  showText: ->
    @builder.hide()
    @wrapped.show()

  toggleBuilder: ->
    if @builderShowing
      @showText()
      @builderShowing = !@builderShowing
    else
      if @showBuilder()
        @builderShowing = !@builderShowing

  showFunctionButtons: (insider) ->
    @functionButtonsEnabled = true unless insider

    if @functionButtonsEnabled && !@functionButtons
      @functionButtons = $('<div class="function_buttons"></div>')

      @functionButtons.append $('<a href="#" style="padding-right: 10px;">Undo</a>').click (e) =>
        e.preventDefault()
        @undo()

      @functionButtons.append $('<a href="#" style="padding-right: 10px;">Redo</a>').click (e) =>
        e.preventDefault()
        @redo()

      @functionButtons.append $('<a id="toggle_view" href="#" style="padding-right: 10px; float: right;">Toggle View</a>').click (e) =>
        e.preventDefault()
        @toggleBuilder()

      @container.prepend(@functionButtons)

  saveStateIfTextChanged: ->
    if JSON.stringify(@json, null, 2) != @wrapped.get(0).value
      if @checkJsonInText()
        @saveState(true)
      else
        if confirm("The current JSON is malformed.  If you continue, the current JSON will not be saved.  Do you wish to continue?")
          @historyPointer += 1
          true
        else
          false
    true

  restore: ->
    if @history[@historyPointer]
      @wrapped.get(0).value = @history[@historyPointer]
      @rebuild(true)

  saveState: (skipStoreText) ->
    if @json
      @storeToText() unless skipStoreText
      text = @wrapped.get(0).value
      if @history[@historyPointer] != text
        @historyTruncate()
        @history.push(text)
        @historyPointer += 1

  fireChange: ->
    $(@wrapped).trigger 'change'

  historyTruncate: ->
    if @historyPointer + 1 < @history.length
      @history.splice(@historyPointer + 1, @history.length - @historyPointer)

  storeToText: ->
    @wrapped.get(0).value = JSON.stringify(@json, null, 2)

  getJSONText: ->
    @rebuild()
    @wrapped.get(0).value

  getJSON: ->
    @rebuild()
    @json

  rebuild: (doNotRefreshText) ->
    @setJsonFromText() unless @json
    changed = @haveThingsChanged()
    if @json && !doNotRefreshText
      @saveState()
    @cleanBuilder()
    @setJsonFromText()
    @alreadyFocused = false
    elem = @build(@json, @builder, null, null, @json)
    @recoverScrollPosition()

    # Auto-focus to edit '??' keys and values.
    if elem && elem.text() == '??' && !@alreadyFocused && @doAutoFocus
      @alreadyFocused = true
      @doAutoFocus = false

      elem = elem.find('.editable')
      elem.click()
      elem.find('input').focus().select()
      # still missing a proper scrolling into the selected input

    @fireChange() if changed

  haveThingsChanged: ->
    @json && JSON.stringify(@json, null, 2) != @wrapped.get(0).value

  saveScrollPosition: ->
    @oldScrollHeight = @builder.scrollTop()

  recoverScrollPosition: ->
    @builder.scrollTop @oldScrollHeight

  setJsonFromText: ->
    @wrapped.get(0).value = "{}" if @wrapped.get(0).value.length == 0
    try
      @wrapped.get(0).value = @wrapped.get(0).value.replace(/((^|[^\\])(\\\\)*)\\n/g, '$1\\\\n').replace(/((^|[^\\])(\\\\)*)\\t/g, '$1\\\\t')
      @json = JSON.parse(@wrapped.get(0).value)
    catch e
      alert "Got bad JSON from text."

  checkJsonInText: ->
    try
      JSON.parse @wrapped.get(0).value
      true
    catch e
      false

  logJSON: ->
    console.log(JSON.stringify(@json, null, 2))

  cleanBuilder: ->
    unless @builder
      @builder = $('<div class="builder"></div>')
      @container.append(@builder)
    @saveScrollPosition()
    @builder.text('')
    @showFunctionButtons("defined")

  updateStruct: (struct, key, val, kind, selectionStart, selectionEnd) ->
    if kind == 'key'
      if selectionStart && selectionEnd
        val = key.substring(0, selectionStart) + val + key.substring(selectionEnd, key.length)
      struct[val] = struct[key]

      # order keys
      orderrest = 0
      $.each struct, (index, value) ->
        # re-set rest of the keys
        if orderrest & index != val
          tempval = struct[index]
          delete struct[index]
          struct[index] = tempval
        if key == index
          orderrest = 1
      # end of order keys

      delete struct[key] if key != val
    else
      if selectionStart && selectionEnd
        val = struct[key].substring(0, selectionStart) + val + struct[key].substring(selectionEnd, struct[key].length)
      struct[key] = val

  getValFromStruct: (struct, key, kind) ->
    if kind == 'key'
      key
    else
      struct[key]

  doTruncation: (trueOrFalse) ->
    if @_doTruncation != trueOrFalse
      @_doTruncation = trueOrFalse
      @rebuild()

  showWipe: (trueOrFalse) ->
    if @_showWipe != trueOrFalse
      @_showWipe = trueOrFalse
      @rebuild()

  truncate: (text, length) ->
    return '-empty-' if text.length == 0
    if @_doTruncation && text.length > (length || 30)
      return text.substring(0, (length || 30)) + '...'
    text

  replaceLastSelectedFieldIfRecent: (text) ->
    if @lastEditingUnfocusedTime > (new Date()).getTime() - 200 # Short delay for unfocus to occur.
      @setLastEditingFocus(text)
      @rebuild()

  editingUnfocused: (elem, struct, key, root, kind) ->
    selectionStart = elem?.selectionStart
    selectionEnd = elem?.selectionEnd

    @setLastEditingFocus = (text) =>
      @updateStruct(struct, key, text, kind, selectionStart, selectionEnd)
      @json = root # Because self.json is a new reference due to rebuild.
    @lastEditingUnfocusedTime = (new Date()).getTime()

  edit: ($elem, key, struct, root, kind) ->
    form = $("<form></form>").css('display', 'inline')
    $input = $("<input />")
    $input.val @getValFromStruct(struct, key, kind)
    $input.addClass 'edit_field'

    blurHandler = =>
      val = $input.val()
      @updateStruct(struct, key, val, kind)
      @editingUnfocused($elem, struct, (kind == 'key' ? val : key), root, kind)
      $elem.text(@truncate(val))
      $elem.get(0).editing = false
      @rebuild() if key != val

    $input.blur blurHandler

    $input.keydown (e) =>
      if e.keyCode == 9 || e.keyCode == 13 # Tab and enter
        @doAutoFocus = true
        blurHandler()

    $(form).append($input).submit (e) =>
      e.preventDefault()
      @doAutoFocus = true
      blurHandler()

    $elem.html(form)
    $input.focus()

  editable: (text, key, struct, root, kind) ->
    self = this;
    elem = $('<span class="editable" href="#"></span>').text(@truncate(text)).click( (e) ->
      unless @editing
        @editing = true;
        self.edit($(this), key, struct, root, kind)
      true
    )
    elem

  build: (json, node, parent, key, root) ->
    elem = null
    if json instanceof Array
      bq = $(document.createElement("BLOCKQUOTE"))
      bq.append($('<div class="brackets">[</div>'))

      bq.prepend(@addUI(json))
      if parent
        bq.prepend(@wipeUI(key, parent)) if @_showWipe
        bq.prepend(@deleteUI(key, parent))

      for i in [0...json.length]
        innerbq = $(document.createElement("BLOCKQUOTE"))
        newElem = @build(json[i], innerbq, json, i, root)
        elem = newElem if newElem && newElem.text() == "??"
        bq.append(innerbq)

      bq.append($('<div class="brackets">]</div>'))
      node.append(bq)
    else if json instanceof Object
      bq = $(document.createElement("BLOCKQUOTE"))
      bq.append($('<div class="bracers">{</div>'))

      for jsonkey, jsonvalue of json
        innerbq = $(document.createElement("BLOCKQUOTE"))
        newElem = @editable(jsonkey.toString(), jsonkey.toString(), json, root, 'key').wrap('<span class="key"></b>').parent()
        innerbq.append(newElem)
        elem = newElem if newElem && newElem.text() == "??"
        if typeof jsonvalue != 'string'
          innerbq.prepend(@braceUI(jsonkey, json))
          innerbq.prepend(@bracketUI(jsonkey, json))
          innerbq.prepend(@wipeUI(jsonkey, json)) if @_showWipe
          innerbq.prepend(@deleteUI(jsonkey, json, true))

        innerbq.append($('<span class="colon">: </span>'))
        newElem = @build(jsonvalue, innerbq, json, jsonkey, root)
        elem = newElem if !elem && newElem && newElem.text() == "??"
        bq.append(innerbq)

      bq.prepend(@addUI(json))
      if parent
        bq.prepend(@wipeUI(key, parent)) if @_showWipe
        bq.prepend(@deleteUI(key, parent))

      bq.append($('<div class="bracers">}</div>'))
      node.append(bq)
    else
      elem = @editable(json.toString(), key, parent, root, 'value').wrap('<span class="val"></span>').parent();
      node.append(elem)
      node.prepend(@braceUI(key, parent))
      node.prepend(@bracketUI(key, parent))
      if parent
        node.prepend(@wipeUI(key, parent)) if @_showWipe
        node.prepend(@deleteUI(key, parent))

    elem
