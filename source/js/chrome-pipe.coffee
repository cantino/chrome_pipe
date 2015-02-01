class window.ChromePipe
  constructor: ->

  init: ->
    @listen document

  showTerminal: ->
    if @terminalWindow?
      @terminalWindow.show()
      @terminal.focus()
    else
      @terminalWindow = Utils.makeWindow
        height: '200px'
        animate: true
        closable: false
        css:
          left: 0
          right: 0
          bottom: 0
          width: "100%"

      @listen @terminalWindow.document
      Utils.load "terminal.js", callback: =>
        @terminal = new ChromePipe.Terminal(@terminalWindow, this)
        @terminal.focus()

  hideTerminal: -> @terminalWindow?.hide()

  terminalShown: -> @terminalWindow?.shown

  listen: (target) ->
    $(target).on "keydown", (e) =>
      if e.which == 84 && e.altKey
        e.preventDefault()
        if @terminalShown() then @hideTerminal() else @showTerminal()

  log: (args...) -> Utils.log args...

  # Class Methods

  @start: ->
    extension = new this()
    extension.init()
