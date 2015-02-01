window.ChromePipe.Commands ||= {}
window.ChromePipe.Commands.Terminal ||= {}

$.extend window.ChromePipe.Commands.Terminal,
  eval:
    desc: "Run inline CoffeeScript"
    run: (stdin, stdout, env, args) ->

      evalAndEmit = (javascript, input, readyForMore) ->
        result = eval(javascript)
        result = result.split(/\n/) if _.isString(result)
        result = [result] unless _.isArray(result)

        if result.length > 0
          for line, index in result
            if index == result.length - 1 && readyForMore?
              stdout.send line, readyForMore
            else
              stdout.send line
        else
          readyForMore() if readyForMore?

      closed = false
      pendingCount = 0
      stdout.onReceiver ->
        if stdin
          stdin.onSenderClose ->
            closed = true
            stdout.senderClose() if pendingCount == 0

          stdin.receive (input, readyForMore) ->
            source = if args then args else input
            pendingCount += 1
            Utils.remote "coffeeCompile", { coffeescript: "return #{source}" }, (response) ->
              pendingCount -= 1
              try
                throw response.errors if response.errors
                evalAndEmit response.javascript, input, readyForMore
                stdout.senderClose() if closed && pendingCount == 0
              catch e
                env.helpers.fail(env, stdout, e)
        else if args
          Utils.remote "coffeeCompile", { coffeescript: "return #{args}" }, (response) ->
            try
              throw response.errors if response.errors
              evalAndEmit response.javascript
              stdout.senderClose()
            catch e
              env.helpers.fail(env, stdout, e)
        else
          env.helpers.fail(env, stdout, "args or stdin required")