{solve} = core = require('../core')
{string, begin, quote, assign, print_, jsobject,\
  funcall, macall, lamda, macro, jsfun, \
  if_, add, eq, inc, suffixinc,\
  eval_, qq, uq, uqs} = require('../util')

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

  "test vari assign": (test) ->
    x = 'x'
    test.equal  solve(begin(assign(x, 1), x)), 1
    test.equal  solve(begin(assign(x, 1), inc(x))), 2
    test.equal  solve(begin(assign(x, 1), suffixinc(x))), 1
    test.done()

  "test js vari": (test) ->
    console_log = 'console.log'
    test.equal  solve(console_log), console.log
    test.done()

  "test jsfun": (test) ->
    console_log = 'console.log'
    test.equal  solve(funcall(jsfun(console_log), 1)), null
    test.equal  solve(print_(1, 2)), null
    test.done()

  "test vop: add, eq": (test) ->
    test.equal  solve(add(1, 1)), 2
    test.equal  solve(eq(1, 1)), true
    test.equal  solve(begin(eq(1, 1), add(1, 1))), 2
    test.done()

  "test lambda": (test) ->
    x = 'x'; y = 'y'
    test.equal  solve(funcall(lamda([x], 1), 1)), 1
    test.equal  solve(funcall(lamda([x, y], add(x, y)), 1, 1)), 2
    test.done()

xexports.Test =
  "test macro": (test) ->
    x = 'x'; y = 'y'; z = 'z'
    test.equal  solve(macall(macro([x], 1), print_(1))), 1
    test.equal  solve(macall(macro([x], x), print_(1))), null
    test.equal  solve(macall(macro([x, y, z], if_(x, y, z)), eq(1, 1), print_(1), print_(2))), null
    test.done()

  "test eval_ quote": (test) ->
    test.equal  solve(eval_(quote(1), string('f:/daonode/lib/compiler/test/compiled2.js'))), 1
    test.equal  solve(eval_(quote(print_(1)), string('f:/daonode/lib/compiler/test/compiled2.js'))), null
    test.done()

  "test quasiquote": (test) ->
    test.equal solve(qq(1)), 1
    a = add(1, 2)
    test.deepEqual solve(qq(a)), a
    test.deepEqual solve(qq(uq(a))), 3
    test.deepEqual solve(qq(uqs([1,2]))), [1,2]
    test.deepEqual solve(qq(add(uqs([1,2])))), a
#    test.deepEqual solve(qq(add(uqs(uqs([1,2]))))), a
    test.done()

xexports.Test =
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
    x = 'x'
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
