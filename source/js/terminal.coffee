class window.ChromePipe.Terminal
  MAX_OUTPUT_BUFFER: 1024

  constructor: (win, ChromePipe, options = {}) ->
    @win = win
    @ChromePipe = ChromePipe
    @$body = win.$body
    @$body.append """
                 <div id='terminal-app'>
                   <div class='history'></div>
                   <div class='prompt-wrapper'>
                     <span class='prompt'>$</span>
                     <textarea spellcheck='false' autocorrect='false'></textarea>
                   </div>
                   <div class='history-metadata'></div>
                 </div>
                 """
    @$history = @$body.find(".history")
    @$historyMetadata = @$body.find(".history-metadata")
    @history = []
    @partialCmd = ''
    @lastAutocompleteIndex = 0
    @lastAutocompletePrefix = null
    @$textarea = @$body.find("textarea")
    @setupBin()
    @setupNewTerminalSession()
    @initInput()

  setupBin: ->
    @bin = _.chain({})
            .extend(ChromePipe.Commands.Terminal)
            .reduce(((memo, value, key) -> memo[key] = value if value.run ; memo), {})
            .value()

  setupNewTerminalSession: ->
    @remote 'getHistory', {}, (response) =>
      unless @history.length
        @history.unshift(command: command.command, output: command.output.split("\n")) for command in response.commands
        @historyIndex = @history.length

  hidePrompt: ->
    @$body.find(".prompt, textarea").hide()

  showPrompt: ->
    @$body.find(".prompt, textarea").show().focus()

  focus: ->
    @$textarea.focus()

  showHistory: (change) ->
    if change == 'up'
      @partialCmd = @val() if @historyIndex == @history.length
      @historyIndex -= 1
      @historyIndex = 0 if @historyIndex < 0
      if @history[@historyIndex]
        @$textarea.val(@history[@historyIndex].command)
        @historyPreview(@history[@historyIndex].output, @history.length - @historyIndex)
    else
      @historyIndex += 1
      if @historyIndex == @history.length
        @$textarea.val @partialCmd
        @historyPreview(null)
      else if @historyIndex > @history.length
        @historyIndex = @history.length
      else
        if @history[@historyIndex]
          @$textarea.val(@history[@historyIndex].command)
          @historyPreview(@history[@historyIndex].output, @history.length - @historyIndex)

  clearInput: ->
    @partialCmd = ''
    @historyIndex = @history.length
    @historyPreview(null)
    @val('')

  initInput: ->
#    @$body.on "click", => @$textarea.focus()

    @$textarea.on "keydown", (e) =>
      propagate = false
      autocompleteIndex = 0
      autocompletePrefix = null

      if e.which == 13 # return
        @process()
      else if e.which == 38 # up arrow
        @showHistory 'up'
      else if e.which == 40 # down arrow
        @showHistory 'down'
      else if e.which == 37 || e.which == 39 # left and right arrows
        propagate = true
      else if e.which == 9 # TAB
        val = @val()
        tokens = val.split(/[^a-zA-Z0-9_-]+/)
        lastToken = tokens[tokens.length - 1]
        rest = val.slice(0, val.length - lastToken.length)
        if lastToken.length > 0
          lastToken = @lastAutocompletePrefix if @lastAutocompletePrefix
          autocompletePrefix = lastToken
          matches = (key for key of @bin when key.indexOf(lastToken) == 0)
          if matches.length > 0
            @val rest + matches[@lastAutocompleteIndex % matches.length]
            autocompleteIndex = @lastAutocompleteIndex + 1
      else if e.which == 27 # ESC
        if @val() then @clearInput() else @hide()
      else
        propagate = true
        @historyPreview(null)
        @historyIndex = @history.length

      @lastAutocompleteIndex = autocompleteIndex
      @lastAutocompletePrefix = autocompletePrefix
      e.preventDefault() unless propagate

  val: (newVal) ->
    if newVal?
      @$textarea.val(newVal)
    else
      $.trim(@$textarea.val())

  historyPreview: (output, index = 1) ->
    if output
      @$historyMetadata.html("output##{index}: " + Utils.escapeAndLinkify(Utils.truncate(output.join(", "), 100))).show()
    else
      @$historyMetadata.hide()

  process: ->
    text = @val()
    if text
      @write "$ " + text, 'input'
      @clearInput()

      env =
        terminal: this
        onCommandFinish: []
        bin: @bin

      parser = new CommandParser(text, env)

      if parser.valid()
        @hidePrompt()

        signalCatcher = (e) =>
          if e.which == 67 && e.ctrlKey # control-c
            e.preventDefault()
            @error "Caught control-c"
            env.int = true

        @$body.on "keydown", signalCatcher

        stdin = parser.execute()

        outputLog = []

        stdin.onSenderClose =>
          @$body.off "keydown", signalCatcher
          @recordCommand text, outputLog, (response) ->
            callback(response) for callback in env.onCommandFinish
          @showPrompt()

        stdin.receive (text, readyForMore) =>
          @write text, 'output'
          outputLog.push text
          outputLog.shift() if outputLog.length > @MAX_OUTPUT_BUFFER
          readyForMore()
      else
        errorMessage = parser.errors.join(", ")
        @recordCommand text, ["Error: #{errorMessage}"]
        @error errorMessage

  error: (text) ->
    text = text.join(", ") if _.isArray(text)
    @write text, 'error'

  write: (text, type) ->
    @$history.append($("<div class='item'></div>").html(Utils.escapeAndLinkify line).addClass(type)) for line in text.toString().split("\n")
    @$history.scrollTop(@$history[0].scrollHeight)

  recordCommand: (command, output, callback) ->
    @history.push(command: command, output: output)
    @historyIndex = @history.length

    @remote 'recordCommand', { command: command, output: output.join("\n") }

  remote: (cmd, options, callback = null) ->
    Utils.remote cmd, options, callback || (response) =>
      @error(response.errors) if response.errors?

  clear: ->
    @$history.empty()

  hide: -> @ChromePipe.hideTerminal()
  show: -> @ChromePipe.showTerminal()