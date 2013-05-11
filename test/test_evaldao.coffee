I = require("f:/node-utils/src/importer")

dao = require("../src/evaldao")

xexports = {}

exports.Test =
  setUp: (callback) ->
    @global = I.set_global dao, "solve number vari print_, and_, or_, not_, succeed, fail, unify"
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
    test.deepEqual  solve(print_('a')), null
    test.done()
  "test and print": (test) ->
    test.deepEqual  solve(and_(print_(1), print_(2))), null
    test.done()
  "test or print": (test) ->
    test.deepEqual  solve(or_(print_(1), print_(2))), null
    test.done()
  "test not print": (test) ->
    test.deepEqual  solve(not_(print_(1))), null
    test.done()
  "test not succeed": (test) ->
    test.deepEqual  solve(not_(succeed)), false
    test.done()
  "test not fail": (test) ->
    test.deepEqual  solve(not_(fail)), false
    test.done()
  "test unify 1 1": (test) ->
    test.deepEqual  solve(unify(1, 1)), true
    test.done()
  "test unify 1 2": (test) ->
    test.deepEqual  solve(unify(1, 2)), false
    test.done()
  "test unify a 1": (test) ->
    a = vari('a')
    test.deepEqual  solve(unify(a, 1)), true
    test.deepEqual  solve(and_(unify(a, 1), unify(a, 2))), false
    test.deepEqual  solve(or_(and_(unify(a, 1), unify(a, 2)), unify(a, 2))), true
    test.done()

  "test char": (test) ->
    test.deepEqual  solve(parse(char('a'), 'a')), true
    test.deepEqual  solve(parse(and_(char('a'), char('b')), 'ab')), true
    test.done()

exports.Test =
  setUp: (callback) ->
    @global = I.set_global dao, '''solve number vari print_, and_, or_, not_, succeed, fail, unify, vari,
                                parse, char'''
    callback()
  tearDown:(callback) ->
    I.set_global  @global
    callback()

  "test 1": (test) ->
    a = vari('a')
    test.deepEqual  solve(parse(and_(char('a'), char('b')), 'ab')), true
    test.done()
