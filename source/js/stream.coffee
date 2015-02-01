class window.ChromePipe.Stream
  constructor: (name) ->
    @name = name
    @senderClosed = false
    @receiverClosed = false

  senderClose: ->
    throw "Cannot sender-close already sender-closed stream '#{@name}'" if @senderClosed
    throw "Cannot close stream not opened for read '#{@name}'" unless @receiveCallback
    Utils.log "Stream#<#{@name}> received senderClose"
    @senderClosed = true
    @onSenderCloseCallback?()

  receiverClose: ->
    throw "Cannot receiver-close already receiver-closed stream '#{@name}'" if @receiverClosed
    throw "Cannot close stream not opened for read '#{@name}'" unless @receiveCallback
    Utils.log "Stream#<#{@name}> received receiverClose"
    @receiverClosed = true
    @onReceiverCloseCallback?()

  onSenderClose: (callback) ->
    throw "Cannot bind more than one sender-close callback to '#{@name}'" if @onSenderCloseCallback
    @onSenderCloseCallback = callback
    @onSenderCloseCallback() if @senderClosed

  onReceiverClose: (callback) ->
    throw "Cannot bind more than one receiver-close callback to '#{@name}'" if @onReceiverCloseCallback
    @onReceiverCloseCallback = callback
    @onReceiverCloseCallback() if @receiverClosed

  onReceiver: (callback) ->
    throw "Cannot bind more than one receiver callback to '#{@name}'" if @onReceiverCallback
    @onReceiverCallback = callback
    @onReceiverCallback() if @receiveCallback

  hasReceiver: -> !!@onReceiverCallback

  send: (text, readyForMore = ->) ->
    throw "Cannot write to sender-closed stream '#{@name}'" if @senderClosed
    throw "Cannot write to stream not opened for read '#{@name}'" unless @receiveCallback
    throw "Cannot write to receiver-closed stream '#{@name}" if @receiverClosed
    Utils.log "Stream#<#{@name}> sent '#{text}'"
    @receiveCallback(text, readyForMore)

  receive: (callback) ->
    throw "Cannot bind more than one receive callback to '#{@name}'" if @receiveCallback
    @receiveCallback = callback
    @onReceiverCallback?()

  receiveAll: (callback) ->
    fullData = []
    @receive (text, readyForMore) ->
      fullData.push text
      readyForMore()
    @onSenderClose -> callback fullData
