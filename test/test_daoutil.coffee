{StateMachine, readToken, parse} = daoutil = require('../lib/daoutil')

xexports = {}

exports.Test =
  "test StateMachine.match": (test) ->
    sm = new StateMachine([['if', 'if'], ['iff', 'iff'], ['else', 'else']])
    test.deepEqual  sm.match('if', 0), ['if', 2]
    test.deepEqual  sm.match('iff', 0), ['iff', 3]
    test.deepEqual  sm.match('ifg', 0), ['if', 2]
    test.deepEqual  sm.match('i', 0), [null, 1]
    test.deepEqual  sm.match('ig', 0), [null, 1]
    test.deepEqual  sm.match('x', 0), [null, 0]
    test.deepEqual  sm.match('if ', 0), ['if', 2]
    test.deepEqual  sm.match('else ', 0), ['else', 4]
    test.done()

  "test parse left recursive": (test) ->
    test.equal parse('Binary', '1'), 1
    test.equal parse('Binary', '++1'), 2
    test.equal parse('Binary', '1++'), 2
    test.equal parse('Binary', '1--'), 0
    test.equal parse('Binary', '(1--)--'), -1
    test.equal parse('Binary', '+1'), 1
    test.equal parse('Binary', '-1'), -1
    test.equal parse('Binary', '--1'), 0
    test.equal parse('Binary', '1+1+1'), 3
    test.equal parse('Binary', '1+(1+1)'), 3
    test.equal parse('Binary', '(1+1)+(1+1)'), 4
    test.equal parse('Binary', '1+(1+1+1)+1'), 5
    test.done()
