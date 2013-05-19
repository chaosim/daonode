I = require "../test/importer"

base = "../src/"
I.use base+"solve: Trail, solve, fun, macro vari debug dummy"
I.use base+"builtins/lisp: begin"
I.use base+"builtins/logic: andp orp notp succeed fail unify findall once"
I.use base+"builtins/parser: char parsetext settext may any greedyany lazyany eoi"

xexports = {}

exports.Test =
  "test char": (test) ->
    test.equal  solve(parsetext(char('a'), 'a')), null
    test.equal  solve(parsetext(char('a'), 'b')), null
    test.equal  solve(begin(settext('a'), char('a'))), null
    test.equal  solve(parsetext(andp(char('a'), char('b')), 'ab')), null
    test.done()

  "test may char": (test) ->
    test.equal  solve(parsetext(may(char('a')), 'a')), null
    test.equal  solve(parsetext(begin(may(char('a')), eoi), 'a')), true
    test.equal  solve(parsetext(begin(may(char('a')), eoi), 'ab')), null
    test.equal  solve(parsetext(may(char('a')), 'b')), null
    test.done()

  "test greedyany": (test) ->
    _ = dummy('_')
    test.equal  solve(parsetext(greedyany(char(_)), 'a')), 1
    test.equal  solve(parsetext(greedyany(char(_)), 'ab')), 2
    test.equal  solve(parsetext(greedyany(char(_)), 'abc')), 3
    test.equal  solve(parsetext(begin(greedyany(char(_)), eoi), 'abc')), true
    test.equal  solve(parsetext(begin(greedyany(char(_)), char('c'), eoi), 'abc')), 3
    test.equal  solve(parsetext(greedyany(char('a')), 'aa')), null
    test.equal  solve(parsetext(greedyany(char('a')), 'b')), null
    test.done()

exports.Test =
  "test any": (test) ->
    _ = dummy('_')
#    test.equal  solve(parsetext(any(char(_)), 'a')), 1
#    test.equal  solve(parsetext(any(char(_)), 'ab')), 2
#    test.equal  solve(parsetext(any(char(_)), 'abc')), 3
#    test.equal  solve(parsetext(begin(any(char(_)), eoi), 'abc')), true
    test.equal  solve(parsetext(begin(any(char(_)), char('c'), eoi), 'abc')), 3
#    test.equal  solve(parsetext(any(char('a')), 'a')), false
#    test.equal  solve(parsetext(any(char('a')), 'aa')), false
#    test.equal  solve(parsetext(any(char('a')), 'b')), null
#    test.equal  solve(parsetext(begin(any(char('a')), eoi), 'b')), null
#    test.equal  solve(parsetext(eoi, '')), true

xexports.Test =  "test lazyany": (test) ->
#    test.equal  solve(parsetext(any(char('a')), 'a')), false
#    test.equal  solve(parsetext(any(char('a')), 'aa')), false
    test.equal  solve(parsetext(lazyany(char('a')), 'b')), null
    test.equal  solve(parsetext(begin(lazyany(char('a')), eoi), 'b')), null
    test.done()
