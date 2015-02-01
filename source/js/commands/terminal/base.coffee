window.ChromePipe.Commands ||= {}
window.ChromePipe.Commands.Terminal ||= {}

$.extend window.ChromePipe.Commands.Terminal,
  exit:
    desc: "Close the terminal"
    run: (stdin, stdout, env) ->
      stdout.onReceiver ->
        env.terminal.hide()
        stdout.senderClose()

  clear:
    desc: "Clear the terminal"
    run: (stdin, stdout, env) ->
      stdout.onReceiver ->
        env.terminal.clear()
        stdout.senderClose()

  bugmenot:
    desc: "Launch BugMeNot for this site, or the site passed"
    run: (stdin, stdout, env, args) ->
      args = Utils.domain() unless args
      stdout.onReceiver ->
        env.terminal.hide()
        env.helpers.argsOrStdin [args], stdin, (domains) ->
          domain = domains[0]
          unless env.int
            window.open("http://bugmenot.com/view/" + domain, 'BugMeNot', 'height=500,width=700').focus?()
          stdout.send "Launching BugMeNot for '#{domain}'"
          stdout.senderClose()

  selectorgadget:
    desc: "Launch selectorGadget"
    run: (stdin, stdout, env) ->
      stdout.onReceiver ->
        env.terminal.hide()
        Utils.loadCSS "vendor/selectorgadget/selectorgadget_combined.css"
        Utils.load "vendor/selectorgadget/selectorgadget_combined.js", callback: =>
          SelectorGadget.toggle();

        Utils.whenTrue (-> $("#selectorgadget_path_field").length > 0 || env.int), ->
          lastVal = null
          interval = setInterval ->
            val = $("#selectorgadget_path_field").val()
            lastVal = val unless val == "No valid path found."
          , 100
          Utils.whenTrue (-> $("#selectorgadget_path_field").length == 0 || env.int), ->
            clearInterval interval
            env.terminal.show()
            stdout.send lastVal || 'unknown'
            stdout.senderClose()

  random_link:
    desc: "Open a random page link"
    run: (stdin, stdout) ->
      stdout.onReceiver ->
        Utils.newWindow document.links[Math.floor(Math.random() * document.links.length)].href
        stdout.senderClose()

  waybackmachine:
    desc: "Open this page in Archive.org's Wayback Machine"
    run: (stdin, stdout) ->
      stdout.onReceiver ->
        Utils.newWindow 'http://web.archive.org/web/*/' + Utils.domain()
        stdout.senderClose()

  help:
    desc: "This help view"
    run: (stdin, stdout, env) ->
      stdout.onReceiver ->
        stdout.send ("#{cmd} - #{opts.desc}" for cmd, opts of env.bin when opts.desc?).join("\n")
        stdout.senderClose()

  gist:
    desc: "Make a new GitHub gist"
    run: (stdin, stdout, env, args) ->
      stdout.onReceiver ->
        if stdin
          stdin.receiveAll (rows) ->
            if env.int
              stdout.senderClose()
            else
              files = {}
              files[args || 'data.txt'] = { content: rows.join("\n") }
              $.post("https://api.github.com/gists", JSON.stringify({ public: true, files: files })).fail(-> stdout.senderClose()).done (resp) ->
                stdout.send resp.html_url
                stdout.senderClose()
        else
          Utils.newWindow "https://gist.github.com/"
          stdout.senderClose()

  namegrep:
    desc: "Grep for domain names"
    run: (stdin, stdout, env, args) ->
      stdout.onReceiver ->
        env.helpers.argsOrStdin [args], stdin, (lines) ->
          Utils.newWindow "http://namegrep.com/##{lines.join("|")}"
          stdout.senderClose()

  requestbin:
    desc: "Make a requestb.in"
    run: (stdin, stdout, env, args) ->
      stdout.onReceiver ->
        env.helpers.argsOrStdin [args], stdin, (lines) ->
          if env.int
            stdout.senderClose()
          else
            $.post "http://requestb.in/api/v1/bins", { private: lines[0] == "private" }, (response) ->
              stdout.send "http://requestb.in/#{response['name']}?inspect"
              stdout.senderClose()

  selection:
    desc: "Get the current document selection"
    run: (stdin, stdout, env) ->
      stdout.onReceiver ->
        for line in document.getSelection().toString().split("\n")
          stdout.send line
        stdout.senderClose()

  echo:
    desc: "Output to the terminal"
    run: (stdin, stdout, env, args) ->
      stdout.onReceiver ->
        stdout.send args
        stdout.senderClose()

  grep:
    desc: "Search for lines matching a pattern"
    run: (stdin, stdout, env, args) ->
      return @fail(env, stdout, "stdin required for grep") unless stdin
      pattern = new RegExp(args, 'i')
      stdout.onReceiver ->
        stdin.onSenderClose -> stdout.senderClose()
        stdin.receive (text, readyForMore) ->
          matches = _.filter(String(text).split("\n"), (line) -> line.match(pattern))
          if matches.length > 0
            for line, index in matches
              if index == matches.length - 1
                stdout.send line, readyForMore
              else
                stdout.send line
          else
            readyForMore()

  _:
    desc: "Access the previous command's output"
    run: (stdin, stdout, env, args) ->
      args = '1' unless args
      stdout.onReceiver ->
        env.helpers.argsOrStdin [args], stdin, (back) ->
          for line in (env.terminal.history[env.terminal.historyIndex - parseInt(back[0])]?.output || [])
            stdout.send line
          stdout.senderClose()

  text:
    desc: "Access the page's text"
    run: (stdin, stdout, env, args) ->
      args = 'body' unless args
      stdout.onReceiver ->
        env.helpers.argsOrStdin [args], stdin, (selectors) ->
          for selector in selectors
            for item in $(selector)
              stdout.send $(item).text()
          stdout.senderClose()

  collect:
    desc: "Grab all input into an array"
    run: (stdin, stdout, env, args) ->
      stdout.onReceiver ->
        env.helpers.argsOrStdin [args], stdin, (rows) ->
          stdout.send rows
          stdout.senderClose()

  jquery:
    desc: "Access the page's dom"
    run: (stdin, stdout, env, args) ->
      args = 'body' unless args
      stdout.onReceiver ->
        env.helpers.argsOrStdin [args], stdin, (selectors) ->
          for selector in selectors
            for elem in $(selector)
              stdout.send $(elem)
          stdout.senderClose()

  tick:
    desc: "Read once per second"
    run: (stdin, stdout, env, args) ->
      return @fail(env, stdout, "stdin required for tick") unless stdin
      stdout.onReceiver ->
        stdin.onSenderClose -> stdout.senderClose()
        stdin.receive (line, readyForMore) ->
          stdout.send line
          setTimeout ->
            if env.int
              stdout.senderClose() unless stdout.senderClosed
            else
              readyForMore()
          , parseInt(args) || 500

  yes:
    desc: "Emit the given text continuously"
    run: (stdin, stdout, env, args) ->
      stdout.onReceiver ->
        env.helpers.argsOrStdin [args], stdin, (text) ->
          emit = ->
            # for sanity
            setTimeout ->
              if env.int
                stdout.senderClose()
              else
                stdout.send text[0], emit
            , 50
          emit()

  bgPage:
    desc: "Manually execute a background page command"
    run: (stdin, stdout, env, args) ->
      args = 'fetch' unless args
      stdout.onReceiver ->
        env.helpers.argsOrStdin [args], stdin, (cmdLine) ->
          [cmd, rest...] = cmdLine[0].split(" ")

          payload = {}
          for segment in rest
            [k, v] = [segment.slice(0, segment.indexOf(':')), segment.slice(segment.indexOf(':') + 1)]
            payload[k] = v

          Utils.remote cmd, payload, (response) ->
            stdout.send JSON.stringify(response)
            stdout.senderClose()

  pbcopy:
    desc: "Put data into the clipboard"
    run: (stdin, stdout, env, args) ->
      stdout.onReceiver ->
        env.helpers.argsOrStdin [args], stdin, (lines) ->
          Utils.remote 'copy', { text: lines.join("\n") }, (response) ->
            stdout.senderClose()

  pbpaste:
    desc: "Pull data from the clipboard"
    run: (stdin, stdout, env, args) ->
      stdout.onReceiver ->
        Utils.remote 'paste', {}, (response) ->
          for line in response.text.split("\n")
            stdout.send line
          stdout.senderClose()

  hn:
    desc: "Search hn"
    run: (stdin, stdout, env, args) ->
      stdout.onReceiver ->
        env.helpers.argsOrStdin [args], stdin, (query) ->
          Utils.newWindow 'https://hn.algolia.com/?q=' + encodeURIComponent(query)
          stdout.senderClose()
