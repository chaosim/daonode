{prepareGrammar, char, setRules} = parser = p  = require "../lib/leftRecursive.js"

hasOwnProperty = Object.hasOwnProperty

#rec = parser.recursive

a = char('a'); b = char('b'); x = char('x')

parse1 = (text) ->
  rules =
    A: (start) ->
      (m = rules.A(start)) and x(p.cur()) and m+'x' or m\
      or a(start)
  parser.parse(text, rules['A'], rules)

parse2 = (text) ->
  rules =
    A: (start) ->
      (m =  rules.B(start)) and x(p.cur()) and m+'x' or m\
      or a(start)
    B: (start) -> rules.A(start) or b(start)
  parser.parse(text, rules['A'], rules)

parse3 = (text) ->
  rules =
    A: (start) ->
      (m =  rules.B(start)) and x(p.cur()) and m+'x' or m\
      or a(start)
    B: (start) -> rules.C(start)
    C: (start) -> rules.A(start) or b(start)
  parser.parse(text, rules['A'], rules)

xexports = {}

exports.Test =
  "test A: Ax|a": (test) ->
    parse = parse1
    test.equal parse('a'), 'a'
    test.equal parse('ax'), 'ax'
    test.equal parse('axx'), 'axx'
    test.equal parse('axxx'), 'axxx'
    test.done()

exports.Test =
  "test A: Bx|a; B:A|b": (test) ->
    parse = parse2
#    test.equal parse('a'), 'a'
    test.equal parse('ax'), 'ax'
#    test.equal parse('axx'), 'axx'
#    test.equal parse('axxx'), 'axxx'
#    test.equal parse('b'), 'b'
#    test.equal parse('bx'), 'bx'
#    test.equal parse('bxxx'), 'bxxx'
#    test.equal parse('bxg'), 'bx'
#    test.equal parse('bxxg'), 'bxx'
#    test.equal parse('bxxxg'), 'bxxx'
#    test.equal parse('fg'), undefined
#    test.equal parse(''), undefined
    test.done()

exports.Test =
  "test A: Bx|a; B:C; C:A|b": (test) ->
    parse = parse3
    test.equal parse('a'), 'a'
#    test.equal parse('ax'), 'ax'
#    test.equal parse('axx'), 'axx'
#    test.equal parse('axxx'), 'axxx'
#    test.equal parse('b'), 'b'
#    test.equal parse('bx'), 'bx'
#    test.equal parse('bxxx'), 'bxxx'
#    test.equal parse('bxg'), 'bx'
#    test.equal parse('bxxg'), 'bxx'
#    test.equal parse('bxxxg'), 'bxxx'
#    test.equal parse('fg'), undefined
#    test.equal parse(''), undefined
    test.done()

xexports.Test =
  "test compute Left Recursive": (test) ->
    grammar = g =
      A: (start) ->
        g.B(start) and g.C(p.cur)\
        or g.D(start) and g.E(p.cur)\
        or g.E(start)
      B: (start) -> g.A(start)
      C: (start) ->
      D: (start) ->
      E: (start) ->
    map = prepareGrammar(grammar)
    test.deepEqual map['A'], ['B', 'A', 'D', 'E']
    test.deepEqual map['B'], ['A', 'B', 'D', 'E']
    test.equal hasOwnProperty.call(parser.recursiveRules, 'A'), true
    test.equal hasOwnProperty.call(parser.recursiveRules, 'B'), true
    test.equal hasOwnProperty.call(parser.recursiveRules, 'D'), false
    test.done()