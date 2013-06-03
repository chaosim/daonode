_ = require "underscore"

{solve, vari, fun, macro, fun2, recursive} = core = require('../core')
{ quote, eval_, begin, assign, if_, iff, block, break_, continue_, loop_, while_, until_,\
  catch_, throw_, protect, callcc} = require('../builtins/lisp')
{print_, le, eq, add, sub, inc, suffixinc} = require('../builtins/general')

xexports = {}

xexports.Test =
  "test assign inc dec": (test) ->
    a = vari('a')
    #3.772s    ---> 1.274s: see git log  -> 1.242s
    test.equal  solve(begin(assign(a, 1),  block('a', if_(eq(a, 10000000), break_('a', a)), inc(a), continue_('a')))), 10000000
    test.done()

exports.Test =
  "test eval_ quote": (test) ->
    test.equal  solve(quote(1)), 1
    test.equal  solve(eval_(quote(1))), 1
    test.done()

  "test assign inc dec": (test) ->
    a = vari('a')
    test.equal  solve(begin(assign(a, 1), a)), 1
    test.equal  solve(begin(assign(a, 1), inc(a))), 2
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
    test.equal  solve(block('a', 1)), 1
    test.equal  solve(block('a', break_('a', 2), 1)), 2
    test.equal  solve(block('a', block('b', break_('b', 2), 1), 3)), 3
    x = vari('x')
    test.equal  solve(begin(assign(x, 1),  block('a', if_(eq(x, 5), break_('a', x)), inc(x), continue_('a')))), 5
    test.done()

  "test loop while until": (test) ->
    x = vari('x')
    test.equal  solve(begin(assign(x, 1),  block('x', if_(eq(x, 5), break_('x', x)), print_(x), inc(x), continue_('x')))), 5
    test.equal  solve(begin(assign(x, 1),  block('x', if_(eq(x, 5), break_(x)), print_(x), inc(x), continue_()))), 5
    test.equal  solve(begin(assign(x, 1),  loop_('x', if_(eq(x, 5), break_('x', x)), print_(x), inc(x)))), 5
    test.equal  solve(begin(assign(x, 1),  loop_('x', print_(x), if_(eq(x, 5), break_(x)), inc(x)))), 5
    test.equal  solve(begin(assign(x, 1),  while_('x', le(x, 5), print_(x), inc(x)))), null
    test.equal  solve(begin(assign(x, 1),  until_('x', print_(x), inc(x), eq(x, 5)))), null
    test.done()

  "test catch throw": (test) ->
    a = vari('a')
    test.equal  solve(catch_(1, 2)), 2
    test.equal  solve(catch_(1, throw_(1, 2), 3)), 2
    test.done()

  "test protect": (test) ->
    a = vari('a')
    test.equal(solve(block('foo', protect(break_('foo', 1), print_(2)))), 1)
    test.equal(solve(block('foo', protect(break_('foo', 1),  print_(2), print_(3)))), 1)
    test.done()

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

  "test quasiquote": (test) ->
    test.equal solve(qq(1)), 1
    a = add(1, 2)
    test.deepEqual solve(qq(a)), a
    test.deepEqual solve(qq(uq(a))), 3
    test.deepEqual solve(qq(uqs([1,2]))), new UnquoteSliceValue([1,2])
    test.deepEqual solve(qq(add(uqs([1,2])))), a
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
