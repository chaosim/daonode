_ = require "underscore"

{solve} = core = require('../core')
{string, begin, quote, assign, print_, jsobject,
funcall, macall, lamda, macro, jsfun,
if_, add, eq, le, inc, suffixinc, print_, loop_, until_, while_, not_
eval_, qq, uq, uqs, iff
block, break_, continue_, makeLabel,
catch_, throw_, protect} = require('../util')

xexports = {}

vari = (name) -> name

exports.Test =
  "test assign inc dec": (test) ->
    a = vari('a')
    blk = makeLabel('x')
    test.equal  solve(begin(assign(a, 1),  block(blk, if_(eq(a, 10), break_(blk, a)), inc(a), continue_(blk)))), 10
    test.done()

  "test eval_ quote": (test) ->
    test.equal  solve(quote(1)), 1
    test.equal  solve(eval_(quote(1), string('f:/daonode/lib/compiler/test/compiled2.js'))), 1
    test.done()

  "test assign inc dec": (test) ->
    a = vari('a')
    test.equal  solve(begin(assign(a, 1))), 1
    test.equal  solve(begin(assign(a, 1), a)), 1
    test.equal  solve(begin(assign(a, 1), inc(a))), 2
    test.equal  solve(begin(assign(a, 1), inc(a), inc(a))), 3
    test.equal  solve(begin(assign(a, 1), inc(a), inc(a), inc(a))), 4
    test.done()

  "test begin": (test) ->
    test.equal  solve(begin(1)), 1
    test.equal  solve(begin(1, 2)), 2
    test.equal  solve(begin(1, 2, 3)), 3
    test.done()

  "test if_": (test) ->
    test.equal  solve(if_(1, 2, 3)), 2
    test.equal  solve(if_(0, 2, 3)), 3
    test.done()

  "test iff": (test) ->
    test.equal  solve(iff([[1, 2]], 3)), 2
    test.equal  solve(iff([[0, 2], [1, 3]], 5)), 3
    test.done()

  "test block break continue": (test) ->
    a = makeLabel('a')
    b = makeLabel('b')
    x = vari('x')
    test.equal  solve(begin(assign(x, 1), block(a, print_(x), 1))), 1
    test.equal  solve(block(a, break_(a, 2), 1)), 2
    test.equal  solve(block(a, block(b, break_(b, 2), 1), 3)), 3
    test.equal  solve(block(a, block(b, funcall(lamda([x], break_(b, 2)), 1), 1), 3)), 3
    test.equal  solve(block(a, block(b, funcall(lamda([x], break_(a, 2)), 1), 1), 3)), 2
    x = vari('x')
    test.equal  solve(begin(assign(x, 1),  block(a, if_(eq(x, 5), break_(a, x)), inc(x), continue_(a)))), 5 #print_(x),
    test.done()

  "test loop while until": (test) ->
    x = vari('x')
    a = makeLabel('x')
    test.equal  solve(begin(assign(x, 1),  block(a, if_(eq(x, 5), break_(a, x)), print_(x), inc(x), continue_(a)))), 5
    test.equal  solve(begin(assign(x, 1),  block(a, if_(eq(x, 5), break_(x)), print_(x), inc(x), continue_()))), 5
    test.equal  solve(begin(assign(x, 1),  loop_(a, if_(eq(x, 5), break_(a, x)), print_(x), inc(x)))), 5
    test.equal  solve(begin(assign(x, 1),  loop_(a, print_(x), if_(eq(x, 5), break_(x)), inc(x)))), 5
    test.equal  solve(begin(assign(x, 1),  while_(a, le(x, 5), print_(x), inc(x)))), null
    test.equal  solve(begin(assign(x, 1),  until_(a, print_(x), inc(x), eq(x, 5)))), null
    test.done()

  "test catch throw": (test) ->
    a = vari('a')
    test.equal  solve(catch_(1, 2)), 2
    test.equal  solve(catch_(1, throw_(1, 2), 3)), 2
    test.done()

  "test protect": (test) ->
    foo = makeLabel('foo')
    test.equal(solve(block(foo, protect(break_(foo, 1), print_(2)))), 1)
    test.equal(solve(block(foo, protect(break_(foo, 1),  print_(2), print_(3)))), 1)
    test.done()

xexports.Test =
  "test callcc": (test) ->
    test.equal solve(begin(callcc((k) -> k(null)), add(1, 2))), 3
    test.done()

xexports.Test =
  "test callfc": (test) ->
    a = null
    solve(orp(callfc((k) -> a = k), add(1, 2)))
    test.equal a(null), 3
    x = vari('x')
    x.binding = 5
    solve(orp(callfc((k) -> a = k), add(x, 2)))
    test.equal a(null), 7
    test.done()

  "test argsCont": (test) ->
    incall = fun(-1, (args...) ->_.map(args, (x) -> x+1))
    test.deepEqual  solve(incall(1)), [2]
    test.deepEqual  solve(incall(1, 2)), [2, 3]
    test.deepEqual  solve(incall(1, 2, 3)), [2, 3, 4]
    test.deepEqual  solve(incall(1, 2, 3, 4)), [2, 3, 4, 5]
    test.deepEqual  solve(incall(1, 2, 3, 4, 5)), [2, 3, 4, 5, 6]
    test.deepEqual  solve(incall(1, 2, 3, 4, 5, 6)), [2, 3, 4, 5, 6, 7]
    test.deepEqual  solve(incall(1, 2, 3, 4, 5, 6, 7)), [2, 3, 4, 5, 6, 7, 8]
    test.deepEqual  solve(incall(1, 2, 3, 4, 5, 6, 7, 8)), [2, 3, 4, 5, 6, 7, 8, 9]
    test.deepEqual  solve(incall(1, 2, 3, 4, 5, 6, 7, 8, 9)), [2, 3, 4, 5, 6, 7, 8, 9, 10]
    test.done()
