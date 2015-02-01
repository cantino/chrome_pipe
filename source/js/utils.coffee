window.Utils =
  attachElement: (elem, target = null) ->
    head = target || document.getElementsByTagName('head')[0]
    if head
      head.appendChild elem
    else
      document.body.appendChild elem

  loadScript: (src, opts = {}) ->
    script = document.createElement('SCRIPT')
    script.setAttribute('type', 'text/javascript');
    script.setAttribute('src', @forChrome(src + (if opts.reload then "?r=#{Math.random()}" else "")));
    @attachElement script
    @whenTrue((-> window[opts.loads]?), opts.then) if opts.loads? && opts.then?

  loadCSS: (href, opts = {}) ->
    link = document.createElement('LINK')
    link.setAttribute('rel', 'stylesheet')
    link.setAttribute('href', @forChrome(href))
    link.setAttribute('type', 'text/css')
    link.setAttribute('media', opts.media || 'all')
    @attachElement link, opts.target

  forChrome: (path) ->
    if path.match(/^http/i) then path else chrome?.extension?.getURL(path)

  afterRender: (callback) ->
    c = =>
      try
        callback.call(@)
      catch e
        Utils.log("Exception in afterRender", e, e?.stack)

    window.setTimeout c, 1

  log: (s...) -> console.log?("ChromePipe: ", s...) if typeof console != 'undefined'

  reload: (e = null) ->
    e.preventDefault() if e
    window.location.reload()

  newWindow: (url) -> window.open(url, '_blank')

  redirectTo: (url) -> window.location.href = url

  alert: (message) -> alert message

  urlMatches: (pattern) -> @location()?.match(pattern)

  location: -> window.location?.href

  title: -> $.trim $("title").text()

  domain: -> window.location?.origin?.replace(/^https?:\/\//i, '')

  load: (path, opts = {}) ->
    @pathCache ||= {}

    if @pathCache[path]
      opts.callback?()
    else
      @pathCache[path] = true
      xhr = new XMLHttpRequest()
      xhr.open("GET", chrome.extension.getURL(path), true)
      xhr.onreadystatechange = (e) ->
        if xhr.readyState == 4 && xhr.status == 200
          if opts.exports
            module = {}
            eval "(function() { " + xhr.responseText + " })();"
            window[opts.exports] = module.exports
          else
            eval xhr.responseText
          opts.callback?()
      xhr.send(null)

  whenTrue: (condition, callback) ->
    go = =>
      if condition()
        callback()
      else
        setTimeout go, 50
    go()

  not: (func) -> return -> !func()

  putInClipboard: (text) ->
    $elem = $('<textarea />')
    $('body').append($elem)
    $elem.text(text).select()
    document.execCommand("copy", true)
    $elem.remove()

  getFromClipboard: ->
    pasteTarget = document.createElement("div");
    pasteTarget.contentEditable = true;
    actElem = document.activeElement.appendChild(pasteTarget).parentNode
    pasteTarget.focus()
    document.execCommand("Paste", null, null)
    paste = pasteTarget.innerText
    actElem.removeChild(pasteTarget)
    paste

  remote: (command, payload, callback = ->) ->
    chrome.runtime.sendMessage { command: command, payload: payload }, (response) -> callback response

  escape: (text) ->
    entityMap =
      "&": "&amp;"
      "<": "&lt;"
      ">": "&gt;"
      '"': '&quot;'
      "'": '&#39;'

    String(text).replace(/[&<>"']/g, (s) -> entityMap[s] )

  escapeAndLinkify: (text) ->
    @escape(text).replace(/https?:\/\/[^\s]+/i, (s) -> "<a href='#{s}' target='_blank'>#{s}</a>")

  truncate: (text, length) ->
    if text.length > length - 3
      text.slice(0, length - 3) + "..."
    else
      text

  makeWindow: (options = {}) ->
    $wrapper = $("<div class='chrome-pipe-wrapper'><iframe></iframe></div>")
    $("body").append $wrapper
    $wrapper.css(options.css) if options.css?
    $iframe = $wrapper.find("iframe")
    iframeDocument = $iframe.contents()

    win =
      shown: true
      height: options.height || '500px'
      $wrapper: $wrapper
      $iframe: $iframe
      document: iframeDocument
      $body: iframeDocument.find("body")
      $head: iframeDocument.find("head")

      hide: ->
        @shown = false
        if options.animate
          @$wrapper.animate { height: '0px' }, 150, =>
            @$wrapper.hide()
        else
          @$wrapper.hide()

      show: ->
        @shown = true
        if options.animate
          @$wrapper.css('height', '0px').show()
          @$wrapper.animate({ height: @height }, 150)
        else
          @$wrapper.css('height', @height).show()

      close: ->
        if options.animate
          @$wrapper.animate { height: '0px' }, 150, =>
            @$wrapper.remove()
        else
          @$wrapper.remove()

    win.$body.addClass('chrome-pipe-iframe')
    Utils.loadCSS "chrome.css", target: win.$head.get(0)

    unless options.closable == false
      $("<div class='close-window'>&#x2715;</div>").appendTo(win.$body).on 'click', ->
        options.onClose?()
        win.close()

    win.$iframe.css('height', win.height)
    win.show()

    win