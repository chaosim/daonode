ObjecttoString = Object.prototype.toString
exports.isNumber = isNumber = (x) -> ObjecttoString.call(x) == '[object Number]'
exports.isInteger = isInteger = (x) -> ObjecttoString.call(x) == '[object Number]' and x % 1 == 0
exports.isString = isString = (x) -> ObjecttoString.call(x) is '[object String]'
exports.isArray = isArray = (x) -> ObjecttoString.call(x) is '[object Array]'
exports.isObject = isObject = (x) -> x is Object(x)

[exports.QUOTE, exports.EVAL, exports.STRING, exports.BEGIN,
 exports.NONLOCAL, exports.VARIABLE, exports.UNIQUEVAR, exports.UNIQUECONST,
 exports.ASSIGN, exports.AUGMENTASSIGN, exports.INC, exports.SUFFIXINC, exports.DEC,
 exports.SUFFIXDEC, exports.INCP, exports.SUFFIXINCP, exports.DECP, exports.SUFFIXDECP, exports.IF,
 exports.SWITCH, exports.JSFUN, exports.DIRECT, exports.PURE, exports.EFFECT, exports.IO,
 exports.LAMDA, exports.MACRO, exports.EVALARG, exports.ARRAY, exports.UARRAY,
 exports.MAKEOBJECT, exports.UOBJECT, exports.CONS, exports.FUNCALL, exports.MACROCALL, exports.JSFUNCALL,
 exports.FOR, exports.FORIN, exports.FOROF, exports.TRY, exports.BLOCK, exports.BREAK, exports.CONTINUE,
 exports.CATCH, exports.THROW,  exports.UNWINDPROTECT, exports.CALLCC, exports.CALLFC,
 exports.QUASIQUOTE, exports.UNQUOTE, exports.UNQUOTESLICE, exports.PUSH, exports.LIST, INDEX,
 exports.ATTR, exports.LENGTH,exports.SLICE,exports.POP, exports.INSTANCEOF,
 exports.LOGICVAR, exports.DUMMYVAR , exports.UNIFY, exports.NOTUNIFY,
 exports.IS, exports.BIND, exports.GETVALUE,
 exports.SUCCEED, exports.FAIL, exports.PUSHP,
 exports.ORP, exports.ORP2, exports.ORP3, exports.NOTP, exports.NOTP2, exports.NOTP3
 exports.IFP, exports.REPEAT, exports.CUTABLE, exports.CUT, exports.FINDALL, exports.ONCE,
 exports.PARSE, exports.PARSEDATA, exports.SETPARSERSTATE,
 exports.SETPARSERDATA, exports.SETPARSERCURSOR, exports.GETPARSERSTATE,
 exports.GETPARSERDATA, exports.GETPARSERCURSOR, exports.EOI, exports.BOI, exports.EOL,
 exports.BOL, exports.STEP, exports.LEFTPARSERDATA, exports.SUBPARSERDATA, exports.NEXTCHAR,
 exports.MAY, exports.LAZYMAY, exports.GREEDYMAY, exports.ANY, exports.LAZYANY, exports.GREEDYANY,
 exports.PARALLEL, exports.FOLLOW, exports.NOTFOLLOW,
 exports.ADD, exports.SUB, exports.MUL, exports.DIV, exports.MOD, exports.AND, exports.OR, exports.NOT,
 exports.BITAND, exports.BITOR, exports.BITXOR, exports.LSHIFT, exports.RSHIFT,
 exports.EQ, exports.NE, exports.LE, exports.LT, exports.GT, exports.GE, exports.NEG, exports.BITNOT]  = [1...1000]

exports.SEXPR_HEAD_FIRST = 1; exports.SEXPR_HEAD_LAST = exports.BITNOT

vari = (name) -> name
exports.vars = (names) -> vari(name) for name in split names,  reElements
exports.nonlocal = (names...) -> [exports.NONLOCAL, names...]
exports.variable = variable = (names...) -> [exports.VARIABLE, names...]

exports.string = string = (s) -> [exports.STRING, s]

exports.quote = (exp) -> [exports.QUOTE, exp]
exports.eval_ = (exp, path) -> [exports.EVAL, exp, path]

exports.begin = begin = (exps...) -> [exports.BEGIN, exps...]

exports.assign = assign = (left, exp) -> [exports.ASSIGN, left, exp]
exports.addassign = (left, exp) -> [exports.AUGMENTASSIGN, 'add', left, exp]
exports.subassign = (left, exp) -> [exports.AUGMENTASSIGN, 'sub', left, exp]
exports.mulassign = (left, exp) -> [exports.AUGMENTASSIGN, 'mul', left, exp]
exports.divassign = (left, exp) -> [exports.AUGMENTASSIGN, 'div', left, exp]
exports.modassign = (left, exp) -> [exports.AUGMENTASSIGN, 'mod', left, exp]
exports.andassign = (left, exp) -> [exports.AUGMENTASSIGN, 'and_', left, exp]
exports.orassign = (left, exp) -> [exports.AUGMENTASSIGN, 'or_', left, exp]
exports.bitandassign = (left, exp) -> [exports.AUGMENTASSIGN, 'bitand', left, exp]
exports.bitorassign = (left, exp) -> [exports.AUGMENTASSIGN, 'bitor', left, exp]
exports.bitxorassign = (left, exp) -> [exports.AUGMENTASSIGN, 'bitxor', left, exp]
exports.lshiftassign = (left, exp) -> [exports.AUGMENTASSIGN, 'lshift', left, exp]
exports.rshiftassign = (left, exp) -> [exports.AUGMENTASSIGN, 'rshift', left, exp]

exports.if_ = if_ = (test, then_, else_) -> [exports.IF, test, then_, else_]
exports.iff = iff = (clauses, else_) ->
  length =  clauses.length
  if length is 0 then throw new Error "iff clauses should have at least one clause."
  else
    [test, then_] = clauses[0]
    if length is 1 then if_(test, then_, else_)
    else if_(test, then_, iff(clauses[1...], else_))

exports.switch_ = (test, clauses, else_) -> [exports.SWITCH, test, clauses, else_]

exports.array = (args...) -> [exports.ARRAY, args...]
exports.uarray = (args...) -> [exports.UARRAY, args...]
exports.cons = (head, tail) -> [exports.CONS, head, tail]
exports.makeobject = (args...) -> [exports.MAKEOBJECT, args...]
exports.uobject = (args...) -> [exports.UOBJECT, args...]
exports.funcall = funcall = (caller, args...) -> [exports.FUNCALL, caller, args...]
exports.jsfuncall = (caller, args...) -> [exports.JSFUNCALL, caller, args...]
exports.macall = (caller, args...) -> [exports.MACROCALL, caller, args...]

exports.jsobject = (exp) -> [exports.JSOBJECT, exp]
exports.jsfun = jsfun = (exp) -> [exports.JSFUN, exp]

exports.print_ = (exps...) -> [exports.JSFUNCALL, io(jsfun('console.log'))].concat(exps)

exports.direct = (exp) -> [exports.DIRECT, exp]

exports.pure = io = (exp) -> [exports.PURE, exp]
exports.effect = sideEffect = (exp) -> [exports.EFFECT, exp]
exports.io = io = (exp) -> [exports.IO, exp]

exports.lamda = lambda = (params, body...) -> [exports.LAMDA, params].concat(body)
exports.macro = macro = (params, body...) -> [exports.MACRO, params].concat(body)
exports.qq  = quasiquote = (exp) -> [exports.QUASIQUOTE, exp]
exports.uq  = unquote = (exp) -> [exports.UNQUOTE, exp]
exports.uqs  = unquoteSlice = (exp) -> [exports.UNQUOTESLICE, exp]

isLabel = (label) -> isArray(label) and label.length is 2 and label[0] is 'label'

exports.makeLabel = makeLabel = (label) -> ['label', label]

defaultLabel = ['label', '']

exports.block = block = (label, body...) ->
  if not isLabel(label) then label = makeLabel(''); body = [exports.label].concat(body)
  [exports.BLOCK, label, body...]

exports.break_ = break_ = (label=defaultLabel, value=null) ->
  if value != null and not isLabel(label) then throw new TypeError([exports.label, value])
  if value is null and not isLabel(label) then (value = label; label = makeLabel(''))
  [exports.BREAK, label, value]

exports.continue_ = continue_ = (label=defaultLabel) -> [exports.CONTINUE,  label]

exports.jsbreak = jsbreak = (label) -> [exports.JSBREAK, label]
exports.jscontinue_ = jscontinue = (label) -> [exports.JSCONTINUE,  label]

# loop
exports.loop_ = (label, body...) ->
  if not isLabel(label) then (label = defaultLabel; body = [exports.label].concat body)
  block(label, body.concat([exports.continue_(label)])...)

# while
exports.while_ = (label, test, body...) ->
  if not isLabel(label) then (label = defaultLabel; test = label; body = [exports.test].concat body)
  block(label, [exports.if_(not_(test), break_(label))].concat(body).concat([exports.continue_(label)])...)

# until
exports.until_ = (label,body..., test) ->
  if not isLabel(label) then (label = defaultLabel; test = label; body = [exports.test].concat body)
  body = body.concat([exports.if_(not_(test), continue_(label))])
  block(label, body...)

# until
exports.dowhile = (label,body..., test) ->
  if not isLabel(label) then (label = defaultLabel; test = label; body = [exports.test].concat body)
  body = body.concat([exports.if_(test, continue_(label))])
  block(label, body...)

exports.for_ = (init, test, step, body...) -> [exports.FOR, init, test, step, body...]

exports.forin = (vari, container, body...) -> [exports.FORIN, vari, container, body...]

exports.try_ = (test, catches, final) -> [exports.TRY, test, catches, final]

exports.catch_ =  (tag, forms...) -> [exports.CATCH, tag, forms...]
exports.throw_ = (tag, form) -> [exports.THROW, tag, form]
exports.protect = (form, cleanup...) -> [exports.UNWINDPROTECT, form, cleanup...]
exports.callcc = (fun) -> [exports.CALLCC, fun]
exports.callfc = (fun) -> [exports.CALLFC, fun]

exports.inc = inc = (item) -> [exports.INC, item]
exports.suffixinc = (item) -> [exports.SUFFIXINC, item]
exports.dec = (item) -> [exports.DEC, item]
exports.suffixdec = (item) -> [exports.SUFFIXDEC, item]
exports.incp = incp = (item) -> [exports.INCP, item]
exports.suffixincp = (item) -> [exports.SUFFIXINCP, item]
exports.decp = (item) -> [exports.DECP, item]
exports.suffixdecp = (item) -> [exports.SUFFIXDECP, item]

exports.add = (args...) -> [exports.ADD, args...]
exports.sub = (args...) -> [exports.SUB, args...]
exports.mul = (args...) ->  [exports.MUL, args...]
exports.div = (args...) -> [exports.DIV, args...]
exports.mod = (args...) -> [exports.MOD, args...]
exports.and_ = (args...) -> [exports.AND, args...]
exports.or_ = (args...) -> [exports.OR, args...]
exports.not_ = not_ = (x) -> [exports.NOT, x]
exports.bitand = (args...) -> [exports.BITAND, args...]
exports.bitor = (args...) -> [exports.BITOR, args...]
exports.bitxor = (args...) -> [exports.BITXOR, args...]
exports.lsfhift = (args...) -> [exports.LSHIFT, args...]
exports.rshift = (args...) -> [exports.RSHIFT, args...]
exports.eq = (args...) -> [exports.EQ, args...]
exports.ne = (args...) -> [exports.NE, args...]
exports.le = (args...) -> [exports.LE, args...]
exports.lt = (args...) -> [exports.LT, args...]
exports.gt = (args...) -> [exports.GT, args...]
exports.ge = (args...) -> [exports.GE, args...]
exports.neg = (args...) -> [exports.NEG, args...]
exports.bitnot = (args...) -> [exports.BITNOT, args...]
exports.index = index = (args...) -> [exports.INDEX, args...]
exports.push = push = (args...) -> [exports.PUSH, args...]
exports.list = list = (args...) -> [exports.LIST, args...]
exports.pushp = pushp = (args...) -> [exports.PUSHP, args...]
exports.attr =(args...) -> [exports.ATTR, args...]
exports.length = (args...) -> [exports.LENGTH, args...]
exports.slice = (args...) -> [exports.SLICE, args...]
exports.pop = (args...) -> [exports.POP, args...]
exports.instanceof = (args...) -> [exports.INSTANCEOF, args...]

# logic

exports.logicvar = (name) -> [exports.LOGICVAR, name]
exports.dummy = (name) -> [exports.DUMMYVAR, name]

exports.unify = unify = (args...) -> [exports.UNIFY, args...]
exports.notunify = (args...) -> [exports.NOTUNIFY, args...]

exports.succeed = [exports.SUCCEED]
exports.fail = [exports.FAIL]

exports.andp = andp = exports.begin
exports.orp = orp = (exps...) ->
  length = exps.length
  if length is 0 then throw new ArgumentError(exps)
  else if length is 1 then exps[0]
  else if length is 2 then [exports.ORP, exps...]
  else [exports.ORP, exps[0], orp(exps[1...]...)]
exports.orp2 = orp2 = (exps...) ->
  length = exps.length
  if length is 0 then throw new ArgumentError(exps)
  else if length is 1 then exps[0]
  else if length is 2 then [exports.ORP2, exps...]
  else [exports.ORP2, exps[0], orp2(exps[1...]...)]
exports.orp3 = orp3 = (exps...) ->
  length = exps.length
  if length is 0 then throw new ArgumentError(exps)
  else if length is 1 then exps[0]
  else if length is 2 then [exports.ORP3, exps...]
  else [exports.ORP3, exps[0], orp3(exps[1...]...)]
exports.notp = (goal) -> [exports.NOTP, goal]
exports.notp2 = (goal) -> [exports.NOTP2, goal]
exports.notp3 = (goal) -> [exports.NOTP3, goal]
exports.repeat = [exports.REPEAT]
exports.cutable = (goal) -> [exports.CUTABLE, goal]
exports.cut = [exports.CUT]
exports.once = (goal) -> [exports.ONCE, goal]
exports.findall = (goal, result, template) -> [exports.FINDALL, goal, result, template]
exports.is_ = (vari, exp) -> [exports.IS, vari, exp]
exports.bind = bind = (vari, term) -> [exports.BIND, vari, term]
exports.getvalue = getvalue = (term) -> [exports.GETVALUE, term]

# parser
exports.parse =  (exp, state) -> [exports.PARSE, exp, state]
exports.parsedata =  (exp, data) -> [exports.PARSEDATA, exp, data]
exports.setdata =  (data) -> [exports.SETPARSERDATA, data]
exports.setcursor =  (cursor) -> [exports.SETPARSERCURSOR, cursor]
exports.setstate =  (state) -> [exports.SETPARSERSTATE, state]
exports.getstate =  [exports.GETPARSERSTATE]
exports.getdata =  [exports.GETPARSERDATA]
exports.getcursor =  [exports.GETPARSERCURSOR]
exports.eoi = [exports.EOI]
exports.boi =  [exports.BOI]
# eol: end of line text[exports.cursor] in "\r\n"
exports.eol =  [exports.EOL]
# bol: bein of line text[exports.cursor-1] in "\r\n"
exports.bol =  [exports.BOL]
exports.step = (n) -> [exports.STEP, n]
# leftdata: return left data
exports.leftdata =  [exports.LEFTPARSERDATA]
# subdata: return data[exports.start...start+length]
exports.subdata =  (length, start) -> [exports.SUBPARSERDATA, length, start]
# nextchar: data[cursor]
exports.nextchar =  [exports.NEXTCHAR]

# ##### may, lazymay, greedymay
# may: aka optional
exports.may = (exp) -> [exports.MAY, exp]
# lazymay: lazy optional
exports.lazymay = (exp) -> [exports.LAZYMAY, exp]
# greedymay: greedy optional
exports.greedymay = (exp) -> [exports.GREEDYMAY, exp]

index = 1
exports.uniquevar = uniquevar = (name) -> [exports.UNIQUEVAR, name, index++]
exports.uniqueconst = uniqueconst = (name) -> [exports.UNIQUECONST, name, index++]

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
  if not result?  then [exports.ANY, exp]
  else
    result1 = uniqueconst('result')
    begin(assign(result1, []), any(andp(exp, push(result1, getvalue(template)))),
             unify(result, result1))

# lazyany: zero or more exp, lazy mode <br/>
#  result should be an core.Var, and always be bound to the result array. <br/>
#  template: the item in result array is getvalue(template)
exports.lazyany = lazyany = (exp, result, template) ->
  if not result?  then [exports.LAZYANY, exp]
  else
    result1 = uniqueconst('result')
    begin(assign(result1, []),
                lazyany(andp(exp, push(result1, getvalue(template)))),
                unify(result, result1))

# greedyany: zero or more exp, greedy mode
#  result should be an core.Var, and always be bound to the result array.
#  template: the item in result array is getvalue(template)
exports.greedyany = greedyany = (exp, result, template) ->
  if not result?  then [exports.GREEDYANY, exp]
  else
    result1 = uniqueconst('result')
    begin(assign(result1, []),
                greedyany(andp(exp, push(result1, getvalue(template)))),
                unify(result, result1))

# ##### some, lazysome, greedysome
# some: one or more exp, normal mode <br/>
#  result should be an core.Var, and always be bound to the result array. <br/>
#  template: the item in result array is getvalue(template)
exports.some = (exp, result, template) ->
  if not result?  then andp(exp, [exports.ANY, exp])
  else
    result1 = uniqueconst('result')
    begin(['result'],
                assign(result1, []),
                exp, push(result1, getvalue(template)),
                any(andp(exp, push(result1, getvalue(template)))),
                unify(result, result1))

# lazysome: one or more exp, lazy mode <br/>
#  result should be an core.Var, and always be bound to the result array. <br/>
#  template: the item in result array is getvalue(template)
exports.lazysome = (exp, result, template) ->
  if not result?  then andp(exp, [exports.LAZYANY, exp])
  else
    result1 = uniqueconst('result')
    begin(assign(result1, []),
                exp, push(result1, getvalue(template)),
                lazyany(andp(exp, push(result1, getvalue(template)))),
                unify(result, result1))

# greedysome: one or more exp, greedy mode<br/>
#  result should be an core.Var, and always be bound to the result array. <br/>
#  template: the item in result array is getvalue(template)
exports.greedysome = (exp, result, template) ->
  if not result?  then andp(exp, [exports.GREEDYANY, exp])
  else
    result1 = uniqueconst('result')
    begin(assign(result1, []),
              exp, push(result1, getvalue(template)),
              greedyany(andp(exp, push(result1, getvalue(template)))),
              unify(result, result1))

exports.times = times = (exp, expectTimes, result, template) ->
  n = uniquevar('n')
  if not result? then begin(variable(n), assign(n, 0), any(andp(exp, incp(n))), unify(expectTimes, n))
  else
   result1 = uniqueconst('result')
   begin(variable(n), assign(n, 0), assign(result1, []),
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
  if result isnt null then result1 = uniqueconst('result')
  if expectTimes is null
    if result is null
      andp(exp, any(andp(sep, exp)))
    else
      andp(assign(result1, []), exp, pushp(result1, getvalue(template)),
           any(andp(sep, exp, pushp(result1, getvalue(template)))), unify(result, result1))
  else if isInteger(expectTimes)
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
    n = uniquevar('n')
    if result is null
     orp(andp(variable(n), exp, assign(n, 1), any(andp(sep, exp, incp(n))), unify(expectTimes, n)),
         unify(expectTimes, 0))
    else
      orp(andp(variable(n), exp, assign(n, 1), assign(result1, list(getvalue(template))),
                    any(andp(sep, exp, pushp(result1, getvalue(template)), incp(n))),
              unify(expectTimes, n), unify(result, result1)),
         andp(unify(expectTimes, 0), unify(result, [])))

exports.parallel = (args...) -> [exports.PARALLEL, args...]
exports.follow = (x) -> [exports.FOLLOW, x]
exports.notfollow = (x) -> [exports.NOTFOLLOW, x]

# char: match one char  <br/>
#  if x is char or bound to char, then match that given char with next<br/>
#  else match with next char, and bound x to it.
for name in ['char', 'followChars', 'notFollowChars', 'charWhen', 'spaces', 'spaces0',
             'stringWhile', 'stringWhile0', 'number', 'literal', 'followLiteral',
             'notFollowLiteral', 'quoteString', 'identifier']
  exports[name] = do (name = name) -> (args...) -> funcall(jsfun('parser.'+name), 'solver', args...)

char = exports.char
charWhen = exports.charWhen
stringWhile = exports.stringWhile
stringWhile0 = exports.stringWhile0

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