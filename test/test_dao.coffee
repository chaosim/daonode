#{solve, compile} = dao = require('../lib/dao')

xexports = {}

xexports.Test =
  "test atomic": (test) ->
    test.equal  solve('1'), 1
    test.equal  solve('123'), 123
    test.equal  solve('-123.56e-3'), -123.56e-3
    test.equal  solve('"1"'), "1"
    test.equal  solve('3'), 3
#    test.equal  solve('a'), a
    test.done()

  "test string": (test) ->
    test.equal  solve('1+1'), 2
    test.done()
