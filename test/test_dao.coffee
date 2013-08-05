{string, add, neg} = util = require('../lib/util')
core = require('../lib/core')
{solve, compile} = dao = require('../lib/dao')

coreSolve = core.solve
coreSolve = (v) -> v

xexports = {}

exports.Test =
  "test atomic": (test) ->
    test.equal  solve('3'), 3
    test.equal  solve('123'), 123
    test.deepEqual  solve('-123.56e-3'), coreSolve(neg(0.12356))
    test.deepEqual  solve('"1"'), coreSolve(string('"1"'))
#    test.equal  solve('a'), a
    test.done()

#xexports.Test =
  "test add": (test) ->
    test.deepEqual  solve('1+1'), coreSolve(add(1, 1))
    test.deepEqual  solve('(1+1)'), coreSolve(add(1, 1))
    test.deepEqual  solve('(1+1)+1'), coreSolve(add(add(1, 1), 1))
    test.done()
