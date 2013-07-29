{solve, Error} = core = require('../lib/core')
{variable, string, begin, quote, assign, addassign, print_, jsobject,\
  funcall, macall, lamda, macro, jsfun, \
  if_, add, eq, inc, suffixinc,\
  eval_, qq, uq, uqs} = require('../lib/util')

vari = (name) -> name

xexports = {}

exports.Test =
  "test vari assign": (test) ->
    x = 'x'
    test.equal  solve(begin(assign(x, 1))), 1
    test.equal  solve(begin(assign(x, 1), x)), 1
    test.equal  solve(begin(variable(x), assign(x, 1), addassign(x, 2), x)), 3
    test.equal  solve(begin(variable(x), assign(x, 1), inc(x))), 2
    #    test.equal  solve(begin(inc(x))), 2
    test.equal  solve(begin(variable(x), assign(x, 1), suffixinc(x))), 1
    test.done()

#xexports.Test =
  "test 1": (test) ->
    test.equal  solve(1), 1
    test.done()

#xexports.Test =
  "test begin": (test) ->
    test.equal  solve(begin(1, 2)), 2
    test.done()

#xexports.Test =
  "test quote": (test) ->
    test.equal  solve(quote(1)), 1
    test.done()

#xexports.Test =
  "test js vari": (test) ->
    console_log = 'console.log'
    test.equal  solve(console_log), console.log
    test.done()

#exports.Test =
  "test jsfun": (test) ->
    console_log = 'console.log'
    test.equal  solve(funcall(jsfun(console_log), 1)), null
    test.equal  solve(print_(1, 2)), null
    x = vari('x')
    test.equal  solve(begin(assign(x, 1),print_(x))), null
    test.done()

#xexports.Test =
  "test vop: add, eq": (test) ->
    test.equal  solve(add(1, 1)), 2
    test.equal  solve(eq(1, 1)), true
    test.equal  solve(begin(eq(1, 1), add(1, 1))), 2
    test.done()

  "test eval_ quote": (test) ->
    test.equal  solve(eval_(quote(1), string('f:/daonode/lib/compiler/test/compiled2.js'))), 1
    test.equal  solve(eval_(quote(print_(1)), string('f:/daonode/lib/compiler/test/compiled2.js'))), null
    test.done()

#xexports.Test =
  "test quasiquote": (test) ->
    test.equal solve(qq(1)), 1
    a = add(1, 2)
    test.deepEqual solve(qq(a)), a
    test.deepEqual solve(qq(uq(a))), 3
    test.deepEqual solve(qq(uqs([1,2]))), [1,2]
    test.deepEqual solve(qq(add(uqs([1,2])))), a
    test.throws (-> solve(qq(add(uqs(uqs([1,2])))))), Error
    test.done()

#xexports.Test =
  "test lambda": (test) ->
    x = 'x'; y = 'y'
    f = vari('f')
    test.equal  solve(funcall(lamda([x], x), 1)), 1
    test.equal  solve(funcall(lamda([x, y], add(x, y)), 1, 1)), 2
    test.equal  solve(begin(assign(f, lamda([], 1)), funcall(f))), 1
    test.done()

#exports.Test =
  "test macro": (test) ->
    x = 'x'; y = 'y'; z = 'z'
    test.equal  solve(macall(macro([x], 1), print_(1))), 1
    test.equal  solve(macall(macro([x], x), print_(1))), null
    test.done()

#xexports.Test =
  "test macro2": (test) ->
    x = 'x'; y = 'y'; z = 'z'
    test.equal  solve(macall(macro([x, y, z], if_(x, y, z)), eq(1, 1), print_(1), print_(2))), null
    test.done()

