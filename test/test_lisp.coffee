I = require("../test/importer")

base = "../src/"
I.use base+"solve: Trail, solve, solver, fun, macro proc vari debug done faildone UnquoteSliceValue"
I.use base+"builtins/general: add print_ inc dec eq le"
I.use base+"builtins/logic: orp"
I.use base+"""builtins/lisp: quote begin if_ iff eval_ block break_ continue_ assign loop_ while_ until_
          catch_ throw_ protect callcc callfc qq uq uqs
          """

xexports = {}

exports.Test =
  "test assign inc dec": (test) ->
    a = vari('a')
    # 1.992s
    test.equal  solve(begin(assign(a, 1),  block('a', if_(eq(a, 1000000), break_('a', a)), inc(a), continue_('a')))), 10000000
    test.done()

xexports.Test =
  "test if_ iff begin": (test) ->
    test.equal  solve(begin(1)), 1
    test.equal  solve(begin(1, 2)), 2
    test.equal  solve(begin(1, 2, 3)), 3
    test.equal  solve(if_(1, 2, 3)), 2
    test.equal  solve(iff([[1, 2]], 3)), 2
    test.equal  solve(iff([[0, 2], [1, 3]], 5)), 3
    test.done()

  "test eval_ quote": (test) ->
    exp = if_(1, 2, 3)
    test.equal  solve(quote(exp)), exp
    test.equal  solve(eval_(quote(exp))), 2
    test.done()

  "test assign inc dec": (test) ->
    a = vari('a')
    test.equal  solve(begin(assign(a, 1), a)), 1
    test.equal  solve(begin(assign(a, 1), inc(a), a)), 2
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

  "test block break continue": (test) ->
    test.equal  solve(block('a', 1)), 1
    test.equal  solve(block('a', break_('a', 2), 1)), 2
    test.equal  solve(block('a', block('b', break_('b', 2), 1), 3)), 3
    a = vari('a')
    test.equal  solve(begin(assign(a, 1),  block('a', if_(eq(a, 5), break_('a', a)), inc(a), continue_('a')))), 5
    test.done()

  "test assign inc dec": (test) ->
    a = vari('a')
    test.equal  solve(begin(assign(a, 1),  block('a', if_(eq(a, 5), break_('a', a)), print_(a), inc(a), continue_('a')))), 5
    test.equal  solve(begin(assign(a, 1),  loop_('a', if_(eq(a, 5), break_('a', a)), print_(a), inc(a)))), 5
    test.equal  solve(begin(assign(a, 1),  block('a', if_(eq(a, 5), break_(a)), print_(a), inc(a), continue_()))), 5
    test.equal  solve(begin(assign(a, 1),  loop_('a', print_(a), if_(eq(a, 5), break_(a)), inc(a)))), 5
    test.equal  solve(begin(assign(a, 1),  while_('a', le(a, 5), print_(a), inc(a)))), null
    test.equal  solve(begin(assign(a, 1),  until_('a', print_(a), inc(a), eq(a, 5)))), null
    test.done()

  "test callcc": (test) ->
    a = null
    solve(begin(callcc((k) -> a = k), add(1, 2)))
    test.equal(a(), 3)
    test.done()

  "test callfc": (test) ->
    a = null
    solve(callfc((k) -> a = k))
    test.equal(a(), a)
    test.done()

  "test quasiquote": (test) ->
    test.equal solve(qq(1)), 1
    a = add(1, 2)
    test.deepEqual solve(qq(a)), a
    test.deepEqual solve(qq(uq(a))), 3
    test.deepEqual solve(qq(uqs([1,2]))), new UnquoteSliceValue([1,2])
    test.deepEqual solve(qq(add(uqs([1,2])))), a
    test.done()
