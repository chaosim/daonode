I = require "../test/importer"

base  =  "../src/"

I.use base+"solve: solve vari Trail fun, macro proc rule, tofun"
I.use base+"builtins/general: add print_"
I.use base+"builtins/lisp: quote eval_"
I.use base+"builtins/logic: andp orp notp succeed fail unify findall once"
I.use base+"builtins/parser: char parsetext may any"

xexports = {}

exports.Test =
  "test 1": (test) ->
    test.equal  solve(1), 1
    test.done()

  "test vari": (test) ->
    a = vari('a')
    test.equal  solve(a), a
    test.done()

  "test print_": (test) ->
    test.equal  solve(print_('a')), null
    test.done()

  "test builtin function": (test) ->
    same = fun((x)->x)
    test.equal  solve(same(1)), 1
    add = fun((x, y) -> x+y)
    test.equal  solve(add(1, 2)), 3
    test.done()

  "test var bind unify trail": (test) ->
    trail = new Trail
    x = vari('x')
    test.equal x.binding, x
    x.bind(1, trail)
    test.ok x.unify(1, trail)
    test.ok not x.unify(2, trail)
    trail.undo()
    test.ok x.unify(2, trail)
    test.done()

  "test macro": (test) ->
    same = macro((x) -> x)
    orpm = macro((x, y) -> orp(x, y))
    test.equal  solve(same(1)), 1
    test.equal  solve(same(print_(1))), null
    test.equal  solve(orpm(fail, print_(2))), null
    test.done()

  "test proc,aka online function in dao": (test) ->
    a = proc('a', () ->
      i = 0
      add(1, 2))
    test.equal solve(a()), 3
    test.done()

  "test macro tofun": (test) ->
    orpm = macro((x, y) -> orp(x, y))
    test.equal  solve(orpm(print_(1), print_(2))), null
    test.equal  solve(tofun(orpm)(print_(1), print_(2))), null
    test.equal  solve(tofun(orpm)(quote(print_(1)), quote(print_(2)))), null
    test.done()

