I = require "../test/importer"

base = "../src/"
I.use base+"solve: Trail, solve, fun, macro vari debug"
I.use base+"builtins/lisp: begin"
I.use base+"builtins/logic: andp orp notp succeed fail unify findall once"
I.use base+"builtins/parser: char parsetext settext may any greedyany lazyany eoi"

xexports = {}

#debug 4555454

exports.Test =
  "test may char": (test) ->
    test.equal  solve(parsetext(may(char('a')), 'a')), null
#    test.equal  solve(parsetext(may(char('a')), 'b')), false
    test.done()

  "test greedyany": (test) ->
    test.equal  solve(parsetext(greedyany(char('a')), 'a')), false
    test.equal  solve(parsetext(greedyany(char('a')), 'aa')), false
    test.equal  solve(parsetext(greedyany(char('a')), 'b')), false
    test.done()

  "test char": (test) ->
    test.equal  solve(parsetext(char('a')), 'a'), null
    test.equal  solve(parsetext(char('a')), 'b'), null
#    test.equal  solve(begin(settext('a'), char('a'))), 1
#    test.equal  solve(parsetext(andp(char('a'), char('b')), 'ab')), 2
    test.done()

  "test any": (test) ->
#    test.equal  solve(parsetext(any(char('a')), 'a')), false
#    test.equal  solve(parsetext(any(char('a')), 'aa')), false
    test.equal  solve(parsetext(any(char('a')), 'b')), null
    test.equal  solve(parsetext(begin(any(char('a')), eoi), 'b')), null
    test.equal  solve(parsetext(eoi, '')), true

  "test lazyany": (test) ->
#    test.equal  solve(parsetext(any(char('a')), 'a')), false
#    test.equal  solve(parsetext(any(char('a')), 'aa')), false
    test.equal  solve(parsetext(lazyany(char('a')), 'b')), null
    test.equal  solve(parsetext(begin(lazyany(char('a')), eoi), 'b')), null
    test.done()
