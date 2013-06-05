{solve, vari} = core = require('../core')
{begin, quote, vari, assign, print_, jsobject} = require('../util')
xexports = {}

xexports.Test =
  "test fun2": (test) ->
    f = (x) -> if x==0 then print_(x)# else  f(x-1)
    m = fun2(1, f)
    #    f = (x) -> if x==0 then print_(x) else  f(x-1)
    #    m = fun2(1, recursive('f', f))
    test.equal  solve(m(sub(5, 1))), null
    test.done()

exports.Test =
  "test 1": (test) ->
    test.equal  solve(1), 1
    test.done()

  "test begin": (test) ->
    test.equal  solve(begin(1, 2)), 2
    test.done()

  "test quote": (test) ->
    test.equal  solve(quote(1)), 1
    test.done()

exports.Test =
  "test assign": (test) ->
    a = vari('a')
    test.equal  solve(assign(a, 1)), 1
    test.done()

xexports.Test =
  "test eval_ quote": (test) ->
    test.equal  solve(eval_(quote(1))), 1
    test.done()

xexports.Test =
  "test assign inc suffixinc vari": (test) ->
    a = vari('a')
#    test.equal  solve(begin(assign(a, 1), a)), 1
    test.equal  solve(begin(assign(a, 1), inc(a))), 2
#    test.equal  solve(begin(assign(a, 1), suffixinc(a))), 1
    test.done()

xexports.Test =
  "test print_": (test) ->
    test.equal  solve(print_('a', 1)), null
    test.done()

xexports.Test =
  "test jsobject": (test) ->
    test.equal  solve(jsobject('console.log')), console.log
    test.done()

xexports.Test =
  "test eq add": (test) ->
    test.equal  solve(eq(1, 1)), true
    test.equal  solve(add(1, 2)), 3
    test.done()

  "test macro": (test) ->
    same = macro((x) -> 1)
    test.equal  solve(same(print_(1))), 1
    same = macro((x) -> x)
    test.equal  solve(same(print_(1))), null
#    orpm = macro((x, y) -> orp(x, y))
#    test.equal  solve(same(1)), 1
    test.equal  solve(same(print_(1))), null
#    test.equal  solve(orpm(fail, print_(2))), null
    test.done()

  "test macro 1": (test) ->
    m = macro(1, (x) -> if x is 0 then print_(x) else begin(print_(x); m(x-1)))
    test.equal  solve(m(5)), null
    test.done()

  "test builtin function": (test) ->
    same = fun(1, (x)->x)
    test.equal  solve(same(1)), 1
    add = fun(2, (x, y) -> x+y)
    test.equal  solve(add(1, 2)), 3
    f =  (x) -> if x==0 then x else f(x-1)
    f = fun(1, recursive('f', f))
    test.equal  solve(f(1)), 0
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
