I = require "../test/importer"

base  =  "../lib/"

I.use base+"solve: Trail, solve, fun, macro vari"
I.use base+"builtins/general: add print_"
I.use base+"builtins/lisp: quote eval_"
I.use base+"builtins/logic: andp orp notp succeed fail unify findall once rule"
I.use base+"builtins/parser: char parsetext may any"

xexports = {}

exports.Test =
  "test and print": (test) ->
    test.equal  solve(andp(print_(1), print_(2))), null
    test.done()

  "test or print": (test) ->
    test.equal  solve(orp(print_(1))), null
    test.equal  solve(orp(print_(1), print_(2))), null
    test.equal  solve(orp(fail, print_(2))), null
    test.equal  solve(orp(fail, print_(2), print_(3))), null
    test.equal  solve(orp(fail, fail, print_(3))), null
    test.done()

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

  "test findall once": (test) ->
    test.equal  solve(findall(orp(print_(1), print_(2)))), null
    test.equal  solve(findall(orp(print_(1), print_(2), print_(3)))), null
    test.equal  solve(findall(once(orp(print_(1), print_(2))))), null
    test.done()

  "test rule": (test) ->
    r = rule(2, (x, y)->
      [[x,y], 1])
    test.equal  solve(r(1,1)), 1
    test.done()


  "test rule2": (test) ->
    r = rule(2, (x, y)->
      [[1,2], print_(1),
       [1,1], print_(2)])
    test.equal  solve(r(1,1)), null
    test.done()

  "test findall": (test) ->
    test.equal  solve(orp(findall(orp(print_(1), print_(2))),
                         print_(3))), null
    test.equal  solve(findall(once(orp(print_(1), (print_(2)))))), null
    test.done()
