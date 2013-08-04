{string} = util = require('../lib/util')
{coreSolve} = core = require('../lib/core')
{solve, compile} = dao = require('../lib/dao')

coreSolve = (v) -> v

xexports = {}

exports.Test =
  "test atomic": (test) ->
    test.equal  solve('3'), 3
    test.equal  solve('123'), 123
    test.deepEqual  solve('-123.56e-3'), coreSolve([ 128, 0.12356 ])
    test.deepEqual  solve('"1"'), coreSolve(string('"1"'))
#    test.equal  solve('a'), a
    test.done()

#exports.Test =
  "test string": (test) ->
    test.deepEqual  solve('1+1'), coreSolve([109, 1, 1])
    test.done()
