{BaseParser} = require "../lib/leftrecursive.js"

xexports = {}

class Parser1 extends BaseParser
  constructor: () ->
    @Root = @A = @recursive 'A', @A

  A: (start) =>
    (memo = @memo('A')(start)) and @char('x')(@cursor) and memo+'x'\
    or memo\
    or @char('a')(start)

class Parser2 extends BaseParser
  constructor: () ->
    @A = @recursive 'A'
    @B = @recursive 'B'
    @Root = @A

  A: (start) =>
    (memo = @look('B')(start)) and @char('x')(@cursor) and memo+'x'\
    or memo\
    or @char('a')(start)

  B: (start) =>
    @look('A')(start)\
    or @char('b')(start)

exports.Test =
  "test A: Ax|a": (test) ->
    parse = (text) -> new Parser1().parse(text)
    test.equal parse('a'), 'a'
    test.equal parse('ax'), 'ax'
    test.equal parse('axx'), 'axx'
    test.equal parse('axxx'), 'axxx'
    test.done()

exports.Test =
  "test A: Ax|a; B:A|b": (test) ->
    parse = (text) -> new Parser2().parse(text)
    test.equal parse('a'), 'a'
    test.equal parse('ax'), 'ax'
    test.equal parse('axx'), 'axx'
    test.equal parse('axxx'), 'axxx'
    test.equal parse('bxxx'), 'bxxx'
    test.equal parse('fg'), undefined
    test.equal parse(''), undefined
    test.done()
