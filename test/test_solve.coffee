I = require "./importer"

base  =  "../lib/"

dao = require('../lib/dao')
I.use base+"dao: solve vari Trail fun, macro proc rule, tofun, dummy"
I.use base+"builtins/general: add print_, sub, eq, inc"
I.use base+"builtins/lisp: quote eval_, if_, begin"
I.use base+"builtins/logic: andp orp notp succeed fail unify findall once"
I.use base+"builtins/parser: char parsetext settext, may any"

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
    same = fun(1, (x)->x)
    test.equal  solve(same(1)), 1
    add = fun(2, (x, y) -> x+y)
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

  "test macro": (test) ->
    m = macro(0, 'a', ->)
    m()
    test.done()

  "test proc,aka online function in dao": (test) ->
    a = proc(0, 'a', () ->
      i = 0
      add(1, 2))
    test.equal solve(a()), 3
    test.done()

  "test macro tofun": (test) ->
    orpm = macro(2, (x, y) -> orp(x, y))
    test.equal  solve(orpm(print_(1), print_(2))), null
    test.equal  solve(tofun(orpm)(print_(1), print_(2))), null
    test.equal  solve(tofun(orpm)(quote(print_(1)), quote(print_(2)))), null
    test.done()

  "test 1": (test) ->
    _ = dummy('_')
    i = vari('i')
    i.binding = 0
    m = macro(0, () ->   begin(print_(i), inc(i), m()))
    test.equal  solve(m()), null
    test.equal(dao.status, dao.FAIL);
    test.done()


  "test recursive macro": (test) ->
    _ = dummy('_')
    m = macro(0, () ->  orp(andp(char(_), print_(_), m()), succeed))
    test.equal  solve(andp(settext('abc'), m())), null
    test.equal(dao.status, dao.SUCCESS);
    test.done()

xexports.Test =
  "test 1": (test) ->
    _ = dummy('_')
    m = macro(0, () ->  print_(1))
    x = m()
    test.equal  solve(andp(x, x)), null
    test.done()
