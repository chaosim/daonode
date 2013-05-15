I = require("f:/node-utils/src/importer")

base = "f:/daonode/src/"
I.use base+"solve: Trail, solve, fun, macro vari"
I.use base+"builtins/general: add print_ inc dec eq"
I.use base+"builtins/lisp: quote begin if_ iff eval_ block break_ continue_ assign "

xexports = {}

exports.Test =
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
    test.equal  solve(begin(assign(a, 1), inc(a))), 2
    test.done()

  "test block break continue": (test) ->
    test.equal  solve(block('a', 1)), 1
    test.equal  solve(block('a', break_('a', 2), 1)), 2
    test.equal  solve(block('a', block('b', break_('b', 2), 1), 3)), 3
    a = vari('a')
    test.equal  solve(begin(assign(a, 1),  block('a', if_(eq(a, 5), break_('a', a)), inc(a), continue_('a')))), 5
    test.done()

exports.Test =
  "test assign inc dec": (test) ->
    a = vari('a')
    test.equal  solve(begin(assign(a, 1),  block('a', if_(eq(a, 10000), break_('a', a)), inc(a), continue_('a')))), 1000
    test.done()

