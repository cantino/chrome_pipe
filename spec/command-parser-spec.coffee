describe "CommandParser", ->
  env = parser = null
  beforeEach ->
    env = { terminal: {}, bin: {} }

  describe "parse", ->
    it "splits on pipes", ->
      parser = new CommandParser("something | something more       foo", env)
      parser.parse()
      expect(parser.individualCommands).toEqual [["something", ""], ["something", "more       foo"]]

  describe "valid", ->
    it "returns true when all commands are known", ->
      env.bin.something = {}
      env.bin.more = {}
      parser = new CommandParser("something | more", env)
      expect(parser.valid()).toBe true
      delete env.bin.more
      expect(parser.valid()).toBe false

    it "stores errors", ->
      env.bin.something = {}
      parser = new CommandParser("something | more foo bar", env)
      expect(parser.valid()).toBe false
      expect(parser.errors).toEqual ["Unknown command 'more'"]

    describe "execute", ->
      it "creates input and output streams and calls each command in a chain", ->
        stdin1 = stdin2 = stdout1 = stdout2 = null
        env.bin.something =
          run: (stdin, stdout) ->
            stdin1 = stdin
            stdout1 = stdout
            stdout.onReceiver -> stdout.senderClose()
        env.bin.more =
          run: (stdin, stdout) ->
            stdin2 = stdin
            stdout2 = stdout
            stdout.onReceiver -> stdout.senderClose()
        parser = new CommandParser("something | more", env)
        stdin3 = parser.execute()
        expect(stdin1).toEqual null
        expect(stdin2).toEqual stdout1
        expect(stdin3).toEqual stdout2

      it "sets the helpers as 'this' and provides an env", ->
        cmdThis = cmdEnv = null
        env.bin.something =
          run: (stdin, stdout, env) ->
            cmdThis = this
            cmdEnv = env
        parser = new CommandParser("something", env)
        stdin3 = parser.execute()
        expect(cmdThis).toEqual parser.helpers
        expect(cmdEnv).toEqual env
        expect(cmdEnv.helpers).toEqual parser.helpers

describe "Some example command flows", ->
  runCommand = (command, callback) ->
    parser = new CommandParser(command, bin: ChromePipe.Commands.Terminal)
    expect(parser.valid()).toBe true
    stdin = parser.execute()
    output = []
    stdin.receive (text, readyForMore) ->
      console.log "got #{text}"
      output.push text
      readyForMore()
    stdin.onSenderClose ->
      console.log "closed"
      callback(output)

  beforeEach ->
    spyOn(Utils, 'remote').andCallFake (cmd, args, callback) -> callback(javascript: CoffeeScript.compile(args.coffeescript))

  describe "eval", ->
    it "works with data on input", ->
      runCommand "echo 2 | eval parseInt(input) + 2 | grep 4", (output) ->
        expect(output).toEqual ["4"]
      runCommand "eval [1,2,3] | eval input * 2", (output) ->
        expect(output).toEqual [2, 4, 6]
      runCommand "eval [1,2,3] | eval input * 2 | grep 4", (output) ->
        expect(output).toEqual ["4"]

    it "works with code on input", ->
      runCommand "echo 2 + 2 | eval", (output) ->
        expect(output).toEqual [4]

    it "compiles coffeescript and emits arrays as individual items", ->
      runCommand "eval [1,2,3] | eval ((i) -> i * i)(input) | collect | eval (i - 1 for i in input)", (output) ->
        expect(output).toEqual [0, 3, 8]