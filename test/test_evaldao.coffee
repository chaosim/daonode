I = require("f:/node-utils/src/importer")

dao = require("../src/evaldao")

xexports = {}

exports.Test =
  setUp: (callback) ->
    @global = I.set_global dao, "solve number vari print_, and_, or_, not_, succeed, fail, unify,
                                    parse, char, jsfun apply"
    callback()
  tearDown:(callback) ->
    I.set_global  @global
    callback()

  "test 1": (test) ->
    test.equal  solve(1), 1
    test.done()
  "test vari": (test) ->
    test.deepEqual  solve(vari('a')), vari('a')
    test.done()
  "test print": (test) ->
    test.equal  solve(print_('a')), null
    test.done()
  "test and print": (test) ->
    test.equal  solve(and_(print_(1), print_(2))), null
    test.done()
  "test or print": (test) ->
    test.equal  solve(or_(print_(1), print_(2))), null
    test.done()
  "test not print": (test) ->
    test.equal  solve(not_(print_(1))), null
    test.done()
  "test not succeed": (test) ->
    test.equal  solve(not_(succeed)), false
    test.done()
  "test not fail": (test) ->
    test.equal  solve(not_(fail)), false
    test.done()
  "test unify 1 1": (test) ->
    test.equal  solve(unify(1, 1)), true
    test.done()
  "test unify 1 2": (test) ->
    test.equal  solve(unify(1, 2)), false
    test.done()
  "test unify a 1": (test) ->
    a = vari('a')
    test.equal  solve(unify(a, 1)), true
    test.equal  solve(and_(unify(a, 1), unify(a, 2))), false
    test.equal  solve(or_(and_(unify(a, 1), unify(a, 2)), unify(a, 2))), true
    test.done()

  "test char": (test) ->
    test.equal  solve(parse(char('a'), 'a')), true
    test.equal  solve(parse(and_(char('a'), char('b')), 'ab')), true
    test.done()

  "test builtin function": (test) ->
    same = jsfun((x)->x)
    test.equal  solve(apply(same, [number(1)])), 1
    add = jsfun((x, y) -> x+y)
    test.equal  solve(apply(add, [number(1), number(2)])), 3
    test.done()

exports.Test =
  setUp: (callback) ->
    @global = I.set_global dao, '''solve number vari print_, and_, or_, not_, succeed, fail, unify, vari,
                                parse, char, jsfun apply'''
    callback()
  tearDown:(callback) ->
    I.set_global  @global
    callback()

  "test 1": (test) ->
    same = jsfun((x)->x)
    test.equal  solve(apply(same, [number(1)])), 1
    test.done()
