{addRecCircles, setMemoRules, memo, char, cur} = parser = p  = require "../lib/leftrecursive.js"

a = char('a'); b = char('b'); x = char('x')
memoA = memo('A'); memoB = memo('B')

parse1 = (text) ->
  rules =
    A: (start) ->
      (m = memoA(start)) and x(p.cur()) and m+'x'\
      or m\
      or a(start)
  parser.clear()
  addRecCircles(['A'])
  setMemoRules(rules)
  parser.parse(text, rules['A'])

parse2 = (text) ->
  rules =
    A: (start) =>
      (m = memoB(start)) and x(p.cur()) and m+'x'\
      or m\
      or a(start)

    B: (start) ->
      memoA(start)\
      or b(start)
  addRecCircles(['A', 'B'])
  setMemoRules(rules)
  parser.parse(text, rules['A'])

xexports = {}

exports.Test =
  "test A: Ax|a": (test) ->
    parse = parse1
    test.equal parse('a'), 'a'
    test.equal parse('ax'), 'ax'
    test.equal parse('axx'), 'axx'
    test.equal parse('axxx'), 'axxx'
    test.done()

#xexports.Test =
  "test A: Bx|a; B:A|b": (test) ->
    parse = parse2
    test.equal parse('a'), 'a'
    test.equal parse('ax'), 'ax'
    test.equal parse('axx'), 'axx'
    test.equal parse('axxx'), 'axxx'
    test.equal parse('b'), 'b'
    test.equal parse('bx'), 'bx'
    test.equal parse('bxxx'), 'bxxx'
    test.equal parse('bxxxg'), 'bxxx'
    test.equal parse('fg'), undefined
    test.equal parse(''), undefined
    test.done()