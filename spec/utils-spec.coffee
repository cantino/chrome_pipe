describe "Utils", ->
  describe "not", ->
    it "returns the inverse of a function, as a function", ->
      expect(Utils.not(-> true)()).toEqual false
      expect(Utils.not(-> false)()).toEqual true

  describe "whenTrue", ->
    it "calls the callback when the condition returns true", ->
      result = false
      something = -> result
      callback = jasmine.createSpy("callback")
      Utils.whenTrue something, callback
      expect(callback).not.toHaveBeenCalled()
      result = true
      jasmine.Clock.tick(49)
      expect(callback).not.toHaveBeenCalled()
      jasmine.Clock.tick(2)
      expect(callback).toHaveBeenCalled()

  describe "escape", ->
    it "should escape HTML", ->
      expect(Utils.escape("<strong>hi & stuff</strong>")).toEqual "&lt;strong&gt;hi &amp; stuff&lt;/strong&gt;"

  describe "escapeAndLinkify", ->
    it "should make links clickable and escape HTML", ->
      expect(Utils.escapeAndLinkify("> http://google.com/foo/bar?a=b <br/>\"")).toEqual "&gt; <a href='http://google.com/foo/bar?a=b' target='_blank'>http://google.com/foo/bar?a=b</a> &lt;br/&gt;&quot;"
