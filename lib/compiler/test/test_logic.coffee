_ = require "underscore"

{solve} = core = require('../core')
solvebase = require('../solve')
{begin, assign, print_,
funcall, lamda, macro,
if_, add, eq, le, inc, not_,
logicvar, unify, succeed, fail, andp, orp, notp
cutable, cut, findall
} = require('../util')

vari = (name) -> name

xexports = {}

exports.Test =
  "test succeed fail": (test) ->
    test.equal solve(succeed), true
#    test.equal(solvebase.status, solvebase.SUCCESS);
    test.equal solve(fail), false
#    test.equal(solvebase.status, solvebase.FAIL);
    test.done()

  "test and print": (test) ->
    test.equal  solve(andp(print_(1), print_(2))), null
    test.done()

#exports.Test =
  "test or print": (test) ->
#    test.equal  solve(orp(print_(1))), null
#    test.equal  solve(orp(print_(1), print_(2))), null
#    test.equal  solve(orp(fail, print_(2))), null
    test.equal  solve(orp(fail, print_(2), print_(3))), null
#    test.equal  solve(orp(fail, fail, print_(3))), null
    test.done()

#xexports.Test =
  "test not succeed fail": (test) ->
    test.equal  solve(notp(succeed)), true
    test.equal  solve(notp(fail)), false
    test.done()

  "test not print": (test) ->
    test.equal  solve(notp(print_(1))), null
    test.done()

  "test unify 1 1, 1 2": (test) ->
    test.equal  solve(unify(1, 1)), true
    test.equal  solve(unify(1, 2)), false
    test.done()

  "test unify logicvar": (test) ->
    a = vari('a')
    $a = logicvar('a')
    test.equal  solve(unify($a, 1)), true
    test.equal  solve(andp(assign(a, $a), unify(a, 1), unify(a, 2))), false
    test.equal  solve(begin(assign(a, $a), orp(andp(unify(a, 1), unify(a, 2)), unify(a, 2)))), true
    test.done()

  "test cut": (test) ->
    test.equal  solve(orp(andp(print_(1), fail), print_(2))), null
    test.equal  solve(orp(andp(print_(1), cut, fail), print_(2))), false
    test.equal  solve(orp(cutable(orp(andp(print_(1), cut, fail), print_(2))), print_(3))), null
    test.done()

xexports.Test =
  "test findall once": (test) ->
    x = vari('x')
    result = vari('result')
#    test.equal  solve(findall(orp(print_(1), print_(2)))), null
#    test.equal  solve(findall(orp(print_(1), print_(2), print_(3)))), null
    test.deepEqual solve(andp(assign(x, logicvar('x')), assign(result, logicvar('result')),
                        findall(orp(unify(x, 1), unify(x, 2)), result, x), result)), [1,2]
#    test.deepEqual  solve(andp(findall(fail, result, x), result)), []
#    test.deepEqual  solve(andp(findall(succeed, result, 1), result)), [1]
#    test.deepEqual  solve(andp(findall(once(orp(print_(1), print_(2))), result, 1), result)), [1]
#    test.equal(solvebase.status, solvebase.SUCCESS);
    test.done()

xexports.Test =
  "test macro": (test) ->
    same = macro(1, (x) -> x)
    orpm = macro(2, (x, y) -> orp(x, y))
    test.equal  solve(same(1)), 1
    test.equal  solve(same(print_(1))), null
    test.equal  solve(orpm(fail, print_(2))), null
    test.done()

  "test rule": (test) ->
    r = rule(2, (x, y)->
      [[x,y], 1, null])
    test.equal  solve(r(1,1)), 1
    test.equal solvebase.status, solvebase.SUCCESS
    test.done()


  "test rule2": (test) ->
    r = rule(2, (x, y)->
      [[1,2], print_(1),
       [1,1], print_(2)])
    test.equal  solve(r(1,1)), null
    test.done()

