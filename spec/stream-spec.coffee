describe "Stream", ->
  stream = null

  beforeEach ->
    stream = new ChromePipe.Stream()

  describe "basic behavior", ->
    it "can handle a simple bind receive and then send", ->
      receivedText = null
      readyForMoreSpy = jasmine.createSpy()
      stream.receive (text, readyForMore) ->
        receivedText = text
        readyForMore()
      stream.onReceiver ->
        stream.send "hello!", readyForMoreSpy
      expect(receivedText).toEqual "hello!"
      expect(readyForMoreSpy).toHaveBeenCalled()

    it "can handle multiple steps with receive pulling more data when desired", ->
      receivedLines = []
      stream.onReceiver ->
        stream.send "hello 0", ->
          stream.send "hello 1", ->
            setTimeout ->
              stream.send "hello 2", ->
                stream.send "hello 3"
                stream.senderClose()
            , 10

      stream.receive (text, readyForMore) ->
        receivedLines.push text
        if receivedLines.length == 3
          setTimeout(readyForMore, 2)
        else
          readyForMore()

      expect(receivedLines).toEqual ["hello 0", "hello 1"]

      jasmine.Clock.tick(9)

      expect(receivedLines).toEqual ["hello 0", "hello 1"]

      jasmine.Clock.tick(1)

      expect(receivedLines).toEqual ["hello 0", "hello 1", "hello 2"]

      expect(stream.senderClosed).toBe false
      jasmine.Clock.tick(2)
      expect(stream.senderClosed).toBe true

      expect(receivedLines).toEqual ["hello 0", "hello 1", "hello 2", "hello 3"]

  describe "closing of streams", ->
    it "calls the callback on close", ->
      closeSpy = jasmine.createSpy()
      stream.onSenderClose closeSpy
      expect(closeSpy).not.toHaveBeenCalled()
      stream.receive (text, callback) -> callback()
      stream.onReceiver ->
        stream.senderClose()
      expect(closeSpy).toHaveBeenCalled()

    it "calls the callback when bound after close", ->
      stream.receive (text, callback) -> callback()
      stream.onReceiver ->
        stream.senderClose()
      closeSpy = jasmine.createSpy()
      stream.onSenderClose closeSpy
      expect(closeSpy).toHaveBeenCalled()