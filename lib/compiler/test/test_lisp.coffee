_ = require "underscore"

{solve} = core = require('../core')
{string, begin, quote, assign, print_, jsobject,
funcall, macall, lamda, macro, jsfun,
if_, add, eq, le, inc, suffixinc, print_, loop_, until_, while_, not_
eval_, qq, uq, uqs, iff
block, break_, continue_, makeLabel,
catch_, throw_, protect, callcc} = require('../util')

vari = (name) -> name

xexports = {}

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

#exports.Test =
  "test assign inc dec": (test) ->
    a = vari('a')
    test.equal  solve(begin(assign(a, 1))), 1
    test.equal  solve(begin(assign(a, 1), a)), 1
    test.equal  solve(begin(assign(a, 1), inc(a))), 2
#    test.equal  solve(begin(assign(a, 1), inc(a), inc(a))), 3
#    test.equal  solve(begin(assign(a, 1), inc(a), inc(a), inc(a))), 4
    test.done()

#xexports.Test =
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

#exports.Test =
  "test catch throw": (test) ->
    a = vari('a')
    test.equal  solve(catch_(1, 2)), 2
    test.equal  solve(catch_(1, throw_(1, 2), 3)), 2
    test.done()

#xexports.Test =
  "test protect": (test) ->
    foo = makeLabel('foo')
    test.equal(solve(block(foo, protect(break_(foo, 1), print_(2)))), 1)
    test.equal(solve(block(foo, protect(break_(foo, 1),  print_(2), print_(3)))), 1)
    test.done()

  "test callcc": (test) ->
    test.equal solve(begin(callcc(jsfun((k) -> k(null))), add(1, 2))), 3
    test.done()



#exports.Test =
  "test block lamda": (test) ->
    a = makeLabel('a')
    b = makeLabel('b')
    x = vari('x'); f = vari('f')
    test.equal  solve(block(a, funcall(lamda([x], break_(a, 2)), 1), 3)), 2
    test.equal  solve(block(a, block(b, funcall(lamda([x], break_(b, 2)), 1), 1), 3)), 3
    test.equal  solve(block(a, block(b, funcall(lamda([x], break_(a, 2)), 1), 1), 3)), 2
    test.done()

#exports.Test =
  "test block lamda 2": (test) ->
    a = makeLabel('a')
    b = makeLabel('b')
    x = vari('x'); f = vari('f')
    test.equal  solve(block(a, block(b, assign(f, lamda([x], break_(b, 2))), funcall(f, 1), 1), 3)), 3  # optimization error
    test.equal  solve(block(a, block(b, assign(f, lamda([x], break_(a, 2))), funcall(f, 1), 1), 3)), 2  # optimization error
    test.equal  solve(block(a, assign(f, lamda([x], block(b, break_(a, 2), 1))), funcall(f, 1), 3)), 2  # optimization error
    test.done()

#xexports.Test =
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

#xexports.Test =
  "test block break continue": (test) ->
    a = makeLabel('a')
    b = makeLabel('b')
    x = vari('x')
    test.equal  solve(begin(assign(x, 1), block(a, print_(x), 1))), 1
    test.equal  solve(block(a, break_(a, 2), 1)), 2
    test.equal  solve(block(a, block(b, break_(b, 2), 1), 3)), 3
    x = vari('x')
    test.equal  solve(begin(assign(x, 1),  block(a, if_(eq(x, 5), break_(a, x)), inc(x), continue_(a)))), 5 #print_(x),
    test.done()