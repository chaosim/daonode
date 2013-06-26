_ = require('underscore')

vari = (name) -> name
exports.string = string = (s) -> ["string", s]
exports.vars = (names) -> vari(name) for name in split names,  reElements

exports.quote = (exp) -> ["quote", exp]
exports.eval_ = (exp, path) -> ["eval", exp, path]
exports.begin = begin = (exps...) -> ["begin"].concat(exps)

exports.assign = assign = (left, exp) -> ["assign", left, exp]
exports.augassign = (left, exp) -> ["augment-assign", op, left, exp]
exports.addassign = (left, exp) -> ["augment-assign", 'add', left, exp]
exports.subassign = (left, exp) -> ["augment-assign", 'sub', left, exp]
exports.mulassign = (left, exp) -> ["augment-assign", 'mul', left, exp]
exports.divassign = (left, exp) -> ["augment-assign", 'div', left, exp]
exports.modassign = (left, exp) -> ["augment-assign", 'mod', left, exp]
exports.andassign = (left, exp) -> ["augment-assign", 'and', left, exp]
exports.orassign = (left, exp) -> ["augment-assign", 'or', left, exp]
exports.bitandassign = (left, exp) -> ["augment-assign", 'bitand', left, exp]
exports.bitorassign = (left, exp) -> ["augment-assign", 'bitor', left, exp]
exports.bitxorassign = (left, exp) -> ["augment-assign", 'bitxor', left, exp]
exports.lshiftassign = (left, exp) -> ["augment-assign", 'lshift', left, exp]
exports.rshiftassign = (left, exp) -> ["augment-assign", 'rshift', left, exp]

exports.if_ = if_ = (test, then_, else_) -> ["if", test, then_, else_]
exports.iff = iff = (clauses, else_) ->
  length =  clauses.length
  if length is 0 then throw new Error "iff clauses should have at least one clause."
  else
    [test, then_] = clauses[0]
    if length is 1 then if_(test, then_, else_)
    else if_(test, then_, iff(clauses[1...], else_))

exports.funcall = (caller, args...) -> ["funcall", caller].concat(args)
exports.macall = (caller, args...) -> ["macall", caller].concat(args)

exports.jsobject = (exp) -> ["jsobject", exp]
exports.jsfun = jsfun = (exp) -> ["jsfun", exp]

exports.pure = io = (exp) -> ["pure", exp]
exports.effect = sideEffect = (exp) -> ["effect", exp]
exports.io = io = (exp) -> ["io", exp]

exports.lamda = lambda = (params, body...) -> ["lambda", params].concat(body)
exports.macro = macro = (params, body...) -> ["macro", params].concat(body)
exports.qq  = quasiquote = (exp) -> ["quasiquote", exp]
exports.uq  = unquote = (exp) -> ["unquote", exp]
exports.uqs  = unquoteSlice = (exp) -> ["unquote-slice", exp]

isLabel = (label) -> _.isArray(label) and label.length is 2 and label[0] is 'label'

exports.makeLabel = makeLabel = (label) -> ['label', label]

defaultLabel = ['label', '']

exports.block = block = (label, body...) ->
  if not isLabel(label) then label = makeLabel(''); body = [label].concat(body)
  ['block', label, body...]

exports.break_ = break_ = (label=defaultLabel, value=null) ->
  if value != null and not isLabel(label) then throw new TypeError([label, value])
  if value is null and not isLabel(label) then (value = label; label = makeLabel(''))
  ['break', label, value]

exports.continue_ = continue_ = (label=defaultLabel) -> ['continue',  label]

# loop
exports.loop_ = (label, body...) ->
  if not isLabel(label) then (label = defaultLabel; body = [label].concat body)
  block(label, body.concat([continue_(label)])...)

# while
exports.while_ = (label, test, body...) ->
  if not isLabel(label) then (label = defaultLabel; test = label; body = [test].concat body)
  block(label, [if_(not_(test), break_(label))].concat(body).concat([continue_(label)])...)

# until
exports.until_ = (label,body..., test) ->
  if not isLabel(label) then (label = defaultLabel; test = label; body = [test].concat body)
  body = body.concat([if_(not_(test), continue_(label))])
  block(label, body...)

exports.catch_ =  (tag, forms...) -> ['catch', tag, forms...]
exports.throw_ = (tag, form) -> ['throw', tag, form]
exports.protect = (form, cleanup...) -> ['unwind-protect', form, cleanup...]
exports.callcc = (fun) -> ['callcc', fun]

exports.print_ = (exps...) -> ['funcall', io(jsfun('console.log'))].concat(exps)

exports.vop = vop = (name, args...) -> ["vop_"+name].concat(args)

exports.inc = inc = (item) -> ['inc', item]

exports.suffixinc = (item) -> ['suffixinc', item]

exports.dec = (item) -> ['dec', item]

exports.suffixdec = (item) -> ['suffixdec', item]

exports.incp = incp = (item) -> ['incp', item]

exports.suffixincp = (item) -> ['suffixincp', item]

exports.decp = (item) -> ['decp', item]

exports.suffixdecp = (item) -> ['suffixdecp', item]

il = require("./interlang")

for name, _o of il
  try instance = _o?()
  catch e then continue
  if instance instanceof il.VirtualOperation and name not in il.excludes
    do (name=name) -> exports[name] = (args...) -> vop(name, args...)

list = exports.list
push = exports.push
exports.pushp = pushp = (list, value) -> ['pushp', list, value]
not_ = exports.not_

# logic

exports.logicvar = (name) -> ['logicvar', name]
exports.dummy = (name) -> ['dummy', name]

exports.unify = unify = (x, y) -> ['unify', x, y]
exports.notunify = (x, y) -> ['notunify', x, y]

exports.succeed = ['succeed']
exports.fail = ['fail']

exports.andp = andp = exports.begin
exports.orp = orp = (exps...) ->
  length = exps.length
  if length is 0 then throw new ArgumentError(exps)
  else if length is 1 then exps[0]
  else if length is 2 then ['orp', exps...]
  else ['orp', exps[0], orp(exps[1...]...)]
exports.notp = (goal) -> ['notp', goal]
exports.repeat = ['repeat']
exports.cutable = (goal) -> ['cutable', goal]
exports.cut = ['cut']
exports.findall = (goal, result, template) -> ['findall', goal, result, template]
exports.is_ = (vari, exp) -> ['is_', vari, exp]
exports.bind = bind = (vari, term) -> ['bind', vari, term]
exports.getvalue = getvalue = (term) -> ['getvalue', term]

# parser
exports.parse =  (exp, state) -> ['parse', exp, state]
exports.parsetext =  (exp, text) -> ['parsetext', exp, text]
exports.settext =  (text) -> ['settext', text]
exports.setpos =  (pos) -> ['setpos', pos]
exports.setstate =  (state) -> ['setstate', state]
exports.getstate =  ['getstate']
exports.gettext =  ['gettext']
exports.getpos =  ['getpos']
exports.eoi = ['eoi']
exports.boi =  ['boi']
# eol: end of line text[pos] in "\r\n"
exports.eol =  ['eol']
# bol: bein of line text[pos-1] in "\r\n"
exports.bol =  ['bol']
exports.step = (n) -> ['step', n]
# lefttext: return left text
exports.lefttext =  ['lefttext']
# subtext: return text[start...start+length]
exports.subtext =  (length, start) -> ['subtext', length, start]
# nextchar: text[pos]
exports.nextchar =  ['nextchar']

# ##### may, lazymay, greedymay
# may: aka optional
exports.may = (exp) -> ['may', exp]
# lazymay: lazy optional
exports.lazymay = (exp) -> ['lazymay', exp]
# greedymay: greedy optional
exports.greedymay = (exp) -> ['greedymay', exp]

index = 1
exports.internalvar = internalvar = (name) -> name+'_$$'+index++

# ##### normal mode, lazy mode, greedy mode
#normal mode: try the goal at first, <br/>
# after succeed, if need, backtracking happens to try the goal again.  <br/>
#greedy mode: goes forward at first,<br/>
#after succeed, no backtracking happens on the goal.<br/>
#lazy mode: goes foward without trying the goal, <br/>
# if failed, backtrack to goal and try again.<br/>
#see test_parser for more informations.

# ##### any, lazyany, greedyany
# any: zero or more exp, normal mode <br/>
#  result should be an core.Var, and always be bound to the result array. <br/>
#  template: the item in result array is getvalue(template)
exports.any = any = (exp, result, template) ->
  if not result?  then ['any', exp]
  else
    result1 = internalvar('result')
    begin(assign(result1, []), any(andp(exp, push(result1, getvalue(template)))),
             unify(result, result1))

# lazyany: zero or more exp, lazy mode <br/>
#  result should be an core.Var, and always be bound to the result array. <br/>
#  template: the item in result array is getvalue(template)
exports.lazyany = lazyany = (exp, result, template) ->
  if not result?  then ['lazyany', exp]
  else
    result1 = internalvar('result')
    begin(assign(result1, []),
                lazyany(andp(exp, push(result1, getvalue(template)))),
                unify(result, result1))

# greedyany: zero or more exp, greedy mode
#  result should be an core.Var, and always be bound to the result array.
#  template: the item in result array is getvalue(template)
exports.greedyany = greedyany = (exp, result, template) ->
  if not result?  then ['greedyany', exp]
  else
    result1 = internalvar('result')
    begin(assign(result1, []),
                greedyany(andp(exp, push(result1, getvalue(template)))),
                unify(result, result1))

# ##### some, lazysome, greedysome
# some: one or more exp, normal mode <br/>
#  result should be an core.Var, and always be bound to the result array. <br/>
#  template: the item in result array is getvalue(template)
exports.some = (exp, result, template) ->
  if not result?  then andp(exp, ['any', exp])
  else
    result1 = internalvar('result')
    begin(['result'],
                assign(result1, []),
                exp, push(result1, getvalue(template)),
                any(andp(exp, push(result1, getvalue(template)))),
                unify(result, result1))

# lazysome: one or more exp, lazy mode <br/>
#  result should be an core.Var, and always be bound to the result array. <br/>
#  template: the item in result array is getvalue(template)
exports.lazysome = (exp, result, template) ->
  if not result?  then andp(exp, ['lazyany', exp])
  else
    result1 = internalvar('result')
    begin(assign(result1, []),
                exp, push(result1, getvalue(template)),
                lazyany(andp(exp, push(result1, getvalue(template)))),
                unify(result, result1))

# greedysome: one or more exp, greedy mode<br/>
#  result should be an core.Var, and always be bound to the result array. <br/>
#  template: the item in result array is getvalue(template)
exports.greedysome = (exp, result, template) ->
  if not result?  then andp(exp, ['greedyany', exp])
  else
    result1 = internalvar('result')
    begin(assign(result1, []),
              exp, push(result1, getvalue(template)),
              greedyany(andp(exp, push(result1, getvalue(template)))),
              unify(result, result1))

exports.times = times = (exp, expectTimes, result, template) ->
  n = internalvar('n')
  if not result? then begin(assign(n, 0), any(andp(exp, incp(n))), unify(expectTimes, n))
  else
   result1 = internalvar('result')
   begin(assign(n, 0), assign(result1, []),
             any(andp(exp, incp(n), pushp(result1, getvalue(template)))),
             unify(expectTimes, n), unify(result, result1))

# seplist: sep separated exp, expectTimes should be integer or core.Var <br/>
#  at least one exp is matched.<br/>
#  if expectTimes is free core.Var, then seplist behaviour like some(normal node).<br/>
#  result should be an core.Var, and always be bound to the result array.<br/>
#  template: the item in result array is getvalue(template)
exports.seplist = (exp, options={}) ->
  # one or more exp separated by sep
  sep = options.sep or char(string(' '));
  expectTimes = options.times or null
  result = options.result or null;
  template = options.template or null
  if result isnt null then result1 = internalvar('result')
  if expectTimes is null
    if result is null
      andp(exp, any(andp(sep, exp)))
    else
      andp(assign(result1, []), exp, pushp(result1, getvalue(template)),
           any(andp(sep, exp, pushp(result1, getvalue(template)))), unify(result, result1))
  else if _.isNumber(expectTimes)
    expectTimes = Math.floor Math.max 0, expectTimes
    if result is null
      switch expectTimes
        when 0 then succeed
        when 1 then exp
        else andp(exp, times(andp(sep, exp), expectTimes-1))
    else
      switch expectTimes
        when 0 then unify(result, [])
        when 1 then andp(exp, unify(result, list(getvalue(template))))
        else andp(assign(result1, []), exp, pushp(result1, getvalue(template)),
                  times(andp(sep, exp, pushp(result1, getvalue(template))), expectTimes-1), unify(result, result1))
  else
    n = internalvar('n')
    if result is null
     orp(andp(exp, assign(n, 1), any(andp(sep, exp, incp(n))), unify(expectTimes, n)),
         unify(expectTimes, 0))
    else
      orp(andp(exp, assign(n, 1), assign(result1, list(getvalue(template))),
                    any(andp(sep, exp, pushp(result1, getvalue(template)), incp(n))),
              unify(expectTimes, n), unify(result, result1)),
         andp(unify(expectTimes, 0), unify(result, [])))

exports.parallel = (x, y) -> ['parallel', x, y]
exports.follow = (x) -> ['follow', x]
exports.notfollow = (x) -> ['notfollow', x]

# char: match one char  <br/>
#  if x is char or bound to char, then match that given char with next<br/>
#  else match with next char, and bound x to it.
exports.char = char = (x) -> ['char', x]
exports.followChars = (chars) ->  ['followChars', chars]
exports.notFollowChars = (chars) ->  ['notFollowChars', chars]
exports.charWhen = charWhen = (test) ->  ['charWhen', test]

exports.charBetween = (start, end) -> charWhen((c) -> start<c<end)
charIn = charIn = (set) -> charWhen((c) ->  c in set)
# theses terminal should be used directly, NO suffix with ()
exports.digit = charWhen((c)->'0'<=c<='9')
exports.digit1_9 = charWhen((c)->'1'<=c<='9')
exports.lower = charWhen((c)->'a'<=c<='z')
exports.upper = charWhen((c)->'A'<=c<='Z')
exports.letter = charWhen((c)-> ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetter = charWhen((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetterDight = charWhen((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z') or ('0'<=c<='9'))
exports.tabspace = charIn(' \t')
exports.whitespace = charIn(' \t\r\n')
exports.newline = charIn('\r\n')

# spaces: one or more spaces(' ') <br/>
#usage: spaces # !!! NOT spaces()
exports.spaces = ['spaces']
# spaces0: zero or more spaces(' ') <br/>
#usage: spaces0 # !!! NOT spaces0()
exports.spaces0 = ['spaces0']

# stringWhile: match a string, every char in the string should pass test <br/>
# test: a function with single argument <br/>
#  the string should contain on char at least.
exports.stringWhile = stringWhile = (test) ->  ['stringWhile', test]

exports.stringBetween = (start, end) -> stringWhile((c) -> start<c<end)
exports.stringIn = stringIn = (set) -> stringWhile((c) ->  c in set)
# theses terminal should be used directly, NO suffix with ()
exports.digits = stringWhile((c)->'0'<=c<='9')
exports.digits1_9 = stringWhile((c)->'1'<=c<='9')
exports.lowers = stringWhile((c)->'a'<=c<='z')
exports.uppers = stringWhile((c)->'A'<=c<='Z')
exports.letters = stringWhile((c)-> ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetters = stringWhile((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetterDights = stringWhile((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z') or ('0'<=c<='9'))
exports.tabspaces = stringIn(' \t')
exports.whitespaces = stringIn(' \t\r\n')
exports.newlinespaces = stringIn('\r\n')

#stringWhile0: match a string, every char in it passes test <br/>
# test: a function with single argument <br/>
#  the string can be empty string.
exports.stringWhile0 = stringWhile0 = (test) ->  ['stringWhile0', test]

exports.stringBetween0 = (start, end) -> stringWhile0((c) -> start<c<end)
exports.stringIn0 = stringIn0 = (set) -> stringWhile0((c) ->  c in set)
# theses terminal should be used directly, NO suffix with ()
exports.digits0 = stringWhile0((c)->'0'<=c<='9')
exports.digits1_90 = stringWhile0((c)->'1'<=c<='9')
exports.lowers0 = stringWhile0((c)->'a'<=c<='z')
exports.uppers0 = stringWhile0((c)->'A'<=c<='Z')
exports.letters0 = stringWhile0((c)-> ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetters0 = stringWhile0((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetterDights0 = stringWhile0((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z') or ('0'<=c<='9'))
exports.tabspaces0 = stringIn0(' \t')
exports.whitespaces0 = stringIn0(' \t\r\n')
exports.newlines0 = stringIn0('\r\n')

# float: match a number, which can be float format..<br/>
#  if arg is free core.Var, arg would be bound to the number <br/>
#  else arg should equal to the number.
exports.number = exports.float = (arg) ->  ['number', arg]

#literal: match given literal arg,  <br/>
# arg is a string or a var bound to a string.
exports.literal = (arg) ->  ['literal', arg]

#followLiteral: follow  given literal arg<br/>
# arg is a string or a var bound to a string. <br/>
#solver.state is restored after match.
exports.followLiteral = (arg) ->  ['followLiteral', arg]

#notFollowLiteral: not follow  given literal arg,  <br/>
# arg is a string or a var bound to a string. <br/>
#solver.state is restored after match.
exports.notFollowLiteral = (arg) ->  ['notFollowLiteral', arg]

#quoteString: match a quote string quoted by quote, quote can be escapedby \
exports.quoteString = (arg) ->  ['quoteString', arg]

#dqstring： double quoted string "..." <br/>
#usage: dqstring  #!!! not dqstring()
exports.dqstring = exports.quoteString('"')
#sqstring： single quoted string '...' <br/>
#usage: sqstring  #!!! not sqstring()
exports.sqstring = exports.quoteString("'")
