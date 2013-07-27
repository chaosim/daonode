andp = (exps...) -> (solver) ->
  for e in exps then e(solver)
  null

orp = (exps...) -> (solver) ->
  solver.failcont = -> orp(exps[1...]...)
  exps[0](solver)
  null

print_ = (args...) -> (solver) -> console.log args...
fail = (solver) ->  solver.failcont(solver)

xexports = {}

exports.Test =
  "test print": (test) ->
    solver = {}
    test.equal  print_(1)(solver), null
    test.done()

exports.Test =
  "test and print": (test) ->
    solver = {}
    test.equal  andp(print_(1), print_(2))(solver), null
    test.done()

exports.Test =
  "test or print": (test) ->
    solver = {}
#    test.equal  orp(print_(1))(solver), null
#    test.equal  solve(orp(print_(1), print_(2))), null
    test.equal  orp(fail, print_(2))(solver), null
#    test.equal  solve(orp(fail, print_(2), print_(3))), null
#    test.equal  solve(orp(fail, fail, print_(3))), null
    test.done()

xexports.Test =
  "test succeed fail": (test) ->
    test.equal solve(succeed), null
    test.equal solve(fail), null
    test.done()

  "test not succeed fail": (test) ->
    test.equal  solve(notp(succeed)), null
    test.equal  solve(notp(fail)), null
    test.done()

  "test not print": (test) ->
    test.equal  solve(notp(print_(1))), null
    test.done()

  "test unify 1 1, 1 2": (test) ->
    test.equal  solve(unify(1, 1)), true
    test.equal  solve(unify(1, 2)), false
    test.done()

  "test unify a 1": (test) ->
    a = vari('a')
    test.equal  solve(unify(a, 1)), true
    a = vari('a')
    test.equal  solve(andp(unify(a, 1), unify(a, 2))), false
    a = vari('a')
    test.equal  solve(orp(andp(unify(a, 1), unify(a, 2)), unify(a, 2))), true
    test.done()

  "test unify logicvar": (test) ->
    a = vari('a')
    test.equal  solve(unify(a, 1)), true
    a = vari('a')
    test.equal  solve(andp(unify(a, 1), unify(a, 2))), false
    a = vari('a')
    test.equal  solve(orp(andp(unify(a, 1), unify(a, 2)), unify(a, 2))), true
    a = vari('a')
    test.equal  solve(orp(unify(a, 1), unify(a, 2))), true
    test.done()

  "test macro": (test) ->
    same = macro(1, (x) -> x)
    orpm = macro(2, (x, y) -> orp(x, y))
    test.equal  solve(same(1)), 1
    test.equal  solve(same(print_(1))), null
    test.equal  solve(orpm(fail, print_(2))), null
    test.done()

  "test unify var": (test) ->
    a = vari('a')
    test.equal  solve(unify(a, 1)), true
    test.equal  solve(andp(unify(a, 1))), true
    test.equal  solve(andp(unify(a, 1), unify(a, 2))), false
    test.equal  solve(andp(unify(a, 1), unify(a, 2), unify(a, 2))), false
    a.binding = a
    test.equal  solve(orp(andp(unify(a, 1), unify(a, 2)), unify(a, 2))), true
    test.equal  solve(orp(andp(unify(a, 1), unify(a, 2)))), false
    test.done()

  "test rule": (test) ->
    r = rule(2, (x, y)->
      [[x,y], 1, null])
    test.equal  solve(r(1,1)), 1
    test.equal core.status, core.SUCCESS
    test.done()


  "test rule2": (test) ->
    r = rule(2, (x, y)->
      [[1,2], print_(1),
       [1,1], print_(2)])
    test.equal  solve(r(1,1)), null
    test.done()

  "test findall once": (test) ->
    x = vari('x')
    result = vari('result')
    test.equal  solve(findall(orp(print_(1), print_(2)))), null
    test.equal  solve(findall(orp(print_(1), print_(2), print_(3)))), null
    test.deepEqual  solve(andp(findall(orp(unify(x, 1), unify(x, 2)), result, x), result)), [1,2]
    test.deepEqual  solve(andp(findall(fail, result, x), result)), []
    test.deepEqual  solve(andp(findall(succeed, result, 1), result)), [1]
    test.deepEqual  solve(andp(findall(once(orp(print_(1), print_(2))), result, 1), result)), [1]
    test.equal(core.status, core.SUCCESS);
    test.done()
