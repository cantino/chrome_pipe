class window.ChromePipeBackgroundPage
  memory: {}

  STORED_KEYS: ['commands']

  constructor: ->
    @listen()
    @updateMemory()

  updateMemory: (callback = null) ->
    @chromeStorageGet @STORED_KEYS, (answers) =>
      for key in @STORED_KEYS
        @memory[key] = answers[key] if key of answers
      callback?()

  chromeStorageGet: (variables, callback) ->
    chrome.storage.local.get variables, (answers) => callback?(answers)

  chromeStorageSet: (variables, callback) ->
    @memory[key] = value for key, value of variables
    chrome.storage.local.set variables, => callback?()

  listen: ->
    chrome.runtime.onMessage.addListener (request, sender, sendResponse) =>
      handler = =>
        Utils.log "Remote received from #{sender.tab.url} (#{sender.tab.incognito && 'incognito'}): #{JSON.stringify request}"
        switch request.command
          when 'copy'
            Utils.putInClipboard(request.payload.text)
            sendResponse()
          when 'paste'
            sendResponse(text: Utils.getFromClipboard())
          when 'coffeeCompile'
            try
              sendResponse(javascript: CoffeeScript.compile(request.payload.coffeescript))
            catch e
              sendResponse(errors: e)
          when 'getHistory'
            sendResponse(commands: @memory.commands || [])
          when 'recordCommand'
            @updateMemory =>
              @memory.commands ||= []
              @memory.commands.unshift(request.payload)
              @memory.commands = @memory.commands[0..50]
              @chromeStorageSet({ commands: @memory.commands }, -> sendResponse({}))
          else sendResponse(errors: "unknown command")

      setTimeout handler, 10
      true # Return true to indicate async message passing: http://developer.chrome.com/extensions/runtime#event-onMessage

  errorResponse: (callback, message) ->
    Utils.log message
    callback errors: [message]

window.backgroundPage = new ChromePipeBackgroundPage()