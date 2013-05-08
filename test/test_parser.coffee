global._ =  require("underscore")
parser = require('../src/parser')

I = require('../src/utils')

xexports = {}

I.with_ parser, ->
  global.a = char('a')
  global.b = char('b')
  [global.x, global.y, global.z] = vars('x, y, z')

exports.ParserTest =
  setUp: (callback) ->
    @global = I.set_global parser
    callback()

  tearDown:(callback) ->
    I.set_global  @global
    callback()

  test_Char: (test) ->
    solve(a, 'a')
    solve(char(x), 'a')
    solve(and_(char(x), char(x)), 'aa')
    test.throws (-> solve(and_(char(x), char(x)), 'ab')), ParseError
    solve(and_(char(x), or_(char(x), char(y))), 'aa')
    test.done()

  test_Or: (test) ->
    solve(or_(a, b), 'b')
    test.done()

  test_and: (test) ->
    solve and_(a, b), 'ab'
    test.done()

  test_and2: (test) ->
    test.throws (-> solve and_(a, b),'ac'), ParseError
    test.done()

  test_unify: (test) ->
    solve(unify(1,1))
    test.throws (-> solve(unify(1,2)))
    solve(or_(unify(1,2), unify(1,1)))
    solve(unify(x,1))
    solve(and_(unify(x,1), unify(x,1)))
    test.throws (-> solve(and_(unify(x,1), unify(x,2))))
    solve(and_(unify(x,1), or_(unify(x, 2), unify(x,1))))
    solve(or_(and_(unify(x,1), unify(x, 2)),
              unify(x,1)))
    test.done()

  test_not: (test) ->
    solve(not_(a), 'b')
    test.throws (-> solve(not_(a), 'a')), ParseError
    test.done()

  test_print_: (test) ->
    solve(print_(1))
    solve(or_(print_(1), print_(2)))
    test.done()

xexports.ParserTest2 =
  setUp: (callback) ->
    @globals = I.set_global parser
    callback()

  tearDown:(callback) ->
    I.set_global  @globals
    callback()

  test: (test) ->
#    test.throws (-> solve(not_(a), 'a')), ParseError
#    solve(not_(a), 'b')
#    solve(print_(1))
    solve(or_(print_(1), print_(2)))
    test.done()
