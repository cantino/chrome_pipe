class window.CommandParser
  constructor: (fullCommandLine, env) ->
    @fullCommandLine = fullCommandLine
    @env = env
    @env.helpers ||= @helpers
    @errors = []
    @individualCommands = []

  parse: ->
    if @individualCommands.length == 0
      for line in @fullCommandLine.split(/\s*\|\s*/)
        firstSpace = line.indexOf(" ")
        if firstSpace != -1
          @individualCommands.push [line.slice(0, firstSpace), line.slice(firstSpace + 1)]
        else
          @individualCommands.push [line, ""]
    @individualCommands

  valid: ->
    @parse()

    for [command, args] in @individualCommands when !@env.bin[command]
      @errors.push "Unknown command '#{command}'"

    @errors.length == 0

  execute: ->
    @parse()

    stdin = null
    for [command, args] in @individualCommands
      cmdOpts = @env.bin[command]
      run = cmdOpts.run || (stdin, stdout) -> stdout.onReceiver -> stdout.senderClose()
      stdout = new ChromePipe.Stream("stdout for #{command}")
      run.call(@env.helpers, stdin, stdout, @env, args)
      stdin = stdout

    stdin

  helpers:
    argsOrStdin: (args, stdin, callback) ->
      if stdin
        stdin.receiveAll (rows) -> callback rows
      else
        callback args

    fail: (env, stdout, message) ->
      message = message.join(", ") if _.isArray(message)
      env.terminal.error message
      unless stdout.senderClosed
        if stdout.hasReceiver()
          stdout.senderClose()
        else
          stdout.onReceiver -> stdout.senderClose()
      "FAIL"