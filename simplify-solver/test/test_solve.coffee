{solve, vari, Trail, fun, fun2, macro, proc, rule, tofun, dummy} = core = require('../core')
#I.use base+"builtins/general: add print_, sub, eq, inc"
{quote, eval_, if_, begin} = require "../builtins/lisp"
#I.use base+"builtins/logic: andp orp notp succeed fail unify findall once"
#I.use base+"builtins/parser: char parsetext settext, may any"

xexports = {}

exports.Test =
  "test 1": (test) ->
    test.equal  solve(1), 1
    test.equal  solve(begin(1, 2)), 2
    test.done()

#xexports.Test =
  "test vari": (test) ->
    a = vari('a')
    test.equal  solve(a), a
    test.done()

xexports.Test =
  "test print_": (test) ->
    test.equal  solve(print_('a')), null
    test.done()

exports.Test =
  "test builtin function": (test) ->
    same = fun(1, (x)->x)
    test.equal  solve(same(1)), 1
    test.done()

#exports.Test =
  "test builtin function 2": (test) ->
    add = fun(2, (x, y) -> x+y)
    test.equal  solve(add(1, 2)), 3
    list = fun(7, (x1, x2, x3, x4, x5, x6, x7) -> [x1, x2, x3, x4, x5, x6, x7])
    test.deepEqual  solve(list(1, 2, 3, 4, 5, 6, 7)), [1, 2, 3, 4, 5, 6, 7]
    list2 = fun(8, (x1, x2, x3, x4, x5, x6, x7, x8) -> [x1, x2, x3, x4, x5, x6, x7, x8])
    test.deepEqual  solve(list2(1, 2, 3, 4, 5, 6, 7, 8)), [1, 2, 3, 4, 5, 6, 7, 8]
    test.done()

xexports.Test =
  "test var bind unify trail": (test) ->
    trail = new Trail
    x = vari('x')
    test.equal x.binding, x
    x.bind(1, trail)
    test.ok trail.unify(1, x)
    test.ok not trail.unify(2, x)
    trail.undo()
    test.ok trail.unify(x, 2)
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
    test.equal solve(begin(a(), a())), 3
    test.equal solve(begin(a(), add(1,1))), 2
    test.done()

  "test macro tofun": (test) ->
    orpm = macro(2, (x, y) -> orp(x, y))
    test.equal  solve(orpm(print_(1), print_(2))), null
    test.equal  solve(tofun(orpm)(print_(1), print_(2))), null
    test.equal  solve(tofun(orpm)(quote(print_(1)), quote(print_(2)))), null
    test.done()

  "test macro 1": (test) ->
    m = macro(1, (x) -> if x is 0 then print_(x) else m(x-1))
    test.equal  solve(m(5)), null
    test.done()

  "test fun2": (test) ->
    m = fun2(1, (x) -> if_(eq(x,0),print_(x), m(sub(x,1))))
    test.equal  solve(m(5)), null
    test.done()


  "test macro 2": (test) ->
    _ = dummy('_')
    m = macro(0, () ->  print_(1))
    x = m()
    test.equal  solve(andp(x, x)), null
    test.equal(core.status, core.SUCCESS);
    test.done()

  "test recursive macro2": (test) ->
    _ = dummy('_')
    m = macro(0, () ->  orp(andp(char(_), print_(_), m()),
                            succeed))
    test.equal  solve(andp(settext('abc'), m())), null
    test.equal(core.status, core.SUCCESS);
    test.done()

  "test recursive macro1": (test) ->
    m = macro(1, (x) -> if x is 0 then print_(x) else begin(print_(x), m(x-1)))
    test.equal  solve(m(5)), null
    test.equal(core.status, core.SUCCESS);
    test.done()
