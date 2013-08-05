ObjecttoString = Object.prototype.toString
exports.isNumber = isNumber = (x) -> ObjecttoString.call(x) == '[object Number]'
exports.isInteger = isInteger = (x) -> ObjecttoString.call(x) == '[object Number]' and x % 1 == 0
exports.isString = isString = (x) -> ObjecttoString.call(x) is '[object String]'
exports.isArray = isArray = (x) -> ObjecttoString.call(x) is '[object Array]'
exports.isObject = isObject = (x) -> x is Object(x)

index = 0
newHeadName = (text) ->
  names = text.split(' ')
  for name in names
    exports[name] = global[name] = index
  index++

newHeadName(names) for names in [
 'QUOTE SEXPR_HEAD_FIRST', 'EVAL', 'STRING', 'BEGIN',
 'NONLOCAL', 'VARIABLE', 'UNIQUEVAR', 'UNIQUECONST',
 'ASSIGN', 'AUGMENTASSIGN', 'INC', 'SUFFIXINC', 'DEC',
 'SUFFIXDEC', 'INCP', 'SUFFIXINCP', 'DECP', 'SUFFIXDECP', 'IF',
 'RETURN', 'JSTHROW',
 'SWITCH', 'JSFUN', 'DIRECT', 'PURE', 'EFFECT', 'IO',
 'LAMDA', 'MACRO', 'EVALARG', 'ARRAY', 'UARRAY',
 'MAKEOBJECT', 'UOBJECT', 'CONS', 'FUNCALL', 'MACROCALL', 'JSFUNCALL',
 'FOR', 'FORIN', 'FOROF', 'TRY', 'BLOCK', 'BREAK', 'CONTINUE',
 'CATCH', 'THROW', ' UNWINDPROTECT', 'CALLCC', 'CALLFC',
 'QUASIQUOTE', 'UNQUOTE', 'UNQUOTESLICE', 'PUSH', 'LIST', 'INDEX',
 'HEADLIST', 'LISTTAIL'
 'ATTR', 'LENGTH,SLICE,POP', 'INSTANCEOF',
 'LOGICVAR', 'DUMMYVAR ', 'UNIFY', 'NOTUNIFY',
 'IS', 'BIND', 'GETVALUE',
 'SUCCEED', 'FAIL', 'PUSHP',
 'ORP', 'ORP2', 'ORP3', 'NOTP', 'NOTP2', 'NOTP3'
 'IFP', 'REPEAT', 'CUTABLE', 'CUT', 'FINDALL', 'ONCE',
 'PARSE', 'PARSEDATA', 'SETPARSERSTATE',
 'SETPARSERDATA', 'SETPARSERCURSOR', 'GETPARSERSTATE',
 'GETPARSERDATA', 'GETPARSERCURSOR', 'EOI', 'BOI', 'EOL',
 'BOL', 'STEP', 'LEFTPARSERDATA', 'SUBPARSERDATA', 'NEXTCHAR',
 'MAY', 'LAZYMAY', 'GREEDYMAY', 'ANY', 'LAZYANY', 'GREEDYANY',
 'PARALLEL', 'FOLLOW', 'NOTFOLLOW',
 'ADD', 'SUB', 'MUL', 'DIV', 'MOD', 'AND', 'OR', 'NOT',
 'BITAND', 'BITOR', 'BITXOR', 'LSHIFT', 'RSHIFT',
 'EQ', 'NE', 'LE', 'LT', 'GT', 'GE', 'NEG', 'POSITIVE',
 'BITNOT SEXPR_HEAD_LAST']

vari = (name) -> name
exports.vars = (names) -> vari(name) for name in split names,  reElements
exports.nonlocal = (names...) -> [NONLOCAL, names...]
exports.variable = variable = (names...) -> [VARIABLE, names...]

exports.string = string = (s) -> [STRING, s]

exports.quote = (exp) -> [QUOTE, exp]
exports.eval_ = (exp, path) -> [EVAL, exp, path]

exports.begin = begin = (exps...) -> [BEGIN, exps...]

exports.assign = assign = (left, exp) -> [ASSIGN, left, exp]
exports.addassign = (left, exp) -> [AUGMENTASSIGN, 'add', left, exp]
exports.subassign = (left, exp) -> [AUGMENTASSIGN, 'sub', left, exp]
exports.mulassign = (left, exp) -> [AUGMENTASSIGN, 'mul', left, exp]
exports.divassign = (left, exp) -> [AUGMENTASSIGN, 'div', left, exp]
exports.modassign = (left, exp) -> [AUGMENTASSIGN, 'mod', left, exp]
exports.andassign = (left, exp) -> [AUGMENTASSIGN, 'and_', left, exp]
exports.orassign = (left, exp) -> [AUGMENTASSIGN, 'or_', left, exp]
exports.bitandassign = (left, exp) -> [AUGMENTASSIGN, 'bitand', left, exp]
exports.bitorassign = (left, exp) -> [AUGMENTASSIGN, 'bitor', left, exp]
exports.bitxorassign = (left, exp) -> [AUGMENTASSIGN, 'bitxor', left, exp]
exports.lshiftassign = (left, exp) -> [AUGMENTASSIGN, 'lshift', left, exp]
exports.rshiftassign = (left, exp) -> [AUGMENTASSIGN, 'rshift', left, exp]

exports.if_ = if_ = (test, then_, else_) -> [IF, test, then_, else_]
exports.iff = iff = (clauses, else_) ->
  length =  clauses.length
  if length is 0 then throw new Error "iff clauses should have at least one clause."
  else
    [test, then_] = clauses[0]
    if length is 1 then if_(test, then_, else_)
    else if_(test, then_, iff(clauses[1...], else_))

exports.switch_ = (test, clauses...) -> [SWITCH, test, clauses...]
exports.return_ = (value) -> [RETURN, value]
exports.jsthrow = (value) -> [JSTHROW, value]

exports.array = (args...) -> [ARRAY, args...]
exports.uarray = (args...) -> [UARRAY, args...]
exports.cons = (head, tail) -> [CONS, head, tail]
exports.makeobject = (args...) -> [MAKEOBJECT, args...]
exports.uobject = (args...) -> [UOBJECT, args...]
exports.funcall = funcall = (caller, args...) -> [FUNCALL, caller, args...]
exports.jsfuncall = jsfuncall = (caller, args...) -> [JSFUNCALL, caller, args...]
exports.macall = (caller, args...) -> [MACROCALL, caller, args...]

exports.jsobject = (exp) -> [JSOBJECT, exp]
exports.jsfun = jsfun = (exp) -> [JSFUN, exp]

exports.print_ = (exps...) -> [JSFUNCALL, io(jsfun('console.log'))].concat(exps)

exports.direct = (exp) -> [DIRECT, exp]

exports.pure = io = (exp) -> [PURE, exp]
exports.effect = sideEffect = (exp) -> [EFFECT, exp]
exports.io = io = (exp) -> [IO, exp]

exports.lamda = lambda = (params, body...) -> [LAMDA, params].concat(body)
exports.macro = macro = (params, body...) -> [MACRO, params].concat(body)
exports.qq  = quasiquote = (exp) -> [QUASIQUOTE, exp]
exports.uq  = unquote = (exp) -> [UNQUOTE, exp]
exports.uqs  = unquoteSlice = (exp) -> [UNQUOTESLICE, exp]

isLabel = (label) -> isArray(label) and label.length is 2 and label[0] is 'label'

exports.makeLabel = makeLabel = (label) -> ['label', label]

defaultLabel = ['label', '']

exports.block = block = (label, body...) ->
  if not isLabel(label) then label = makeLabel(''); body = [label].concat(body)
  [BLOCK, label, body...]

exports.break_ = break_ = (label=defaultLabel, value=null) ->
  if value != null and not isLabel(label) then throw new TypeError([label, value])
  if value is null and not isLabel(label) then (value = label; label = makeLabel(''))
  [BREAK, label, value]

exports.continue_ = continue_ = (label=defaultLabel) -> [CONTINUE,  label]

exports.jsbreak = jsbreak = (label) -> [JSBREAK, label]
exports.jscontinue_ = jscontinue = (label) -> [JSCONTINUE,  label]

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

# until
exports.dowhile = (label,body..., test) ->
  if not isLabel(label) then (label = defaultLabel; test = label; body = [test].concat body)
  body = body.concat([if_(test, continue_(label))])
  block(label, body...)

exports.for_ = (init, test, step, body...) -> [FOR, init, test, step, body...]

exports.forin = (vari, container, body...) -> [FORIN, vari, container, body...]

exports.try_ = (test, catches, final) -> [TRY, test, catches, final]

exports.catch_ =  (tag, forms...) -> [CATCH, tag, forms...]
exports.throw_ = (tag, form) -> [THROW, tag, form]
exports.protect = (form, cleanup...) -> [UNWINDPROTECT, form, cleanup...]
exports.callcc = (fun) -> [CALLCC, fun]
exports.callfc = (fun) -> [CALLFC, fun]

exports.inc = inc = (item) -> [INC, item]
exports.suffixinc = (item) -> [SUFFIXINC, item]
exports.dec = (item) -> [DEC, item]
exports.suffixdec = (item) -> [SUFFIXDEC, item]
exports.incp = incp = (item) -> [INCP, item]
exports.suffixincp = (item) -> [SUFFIXINCP, item]
exports.decp = (item) -> [DECP, item]
exports.suffixdecp = (item) -> [SUFFIXDECP, item]

exports.add = (args...) -> [ADD, args...]
exports.sub = (args...) -> [SUB, args...]
exports.mul = (args...) ->  [MUL, args...]
exports.div = (args...) -> [DIV, args...]
exports.mod = (args...) -> [MOD, args...]
exports.and_ = (args...) -> [AND, args...]
exports.or_ = (args...) -> [OR, args...]
exports.not_ = not_ = (x) -> [NOT, x]
exports.bitand = (args...) -> [BITAND, args...]
exports.bitor = (args...) -> [BITOR, args...]
exports.bitxor = (args...) -> [BITXOR, args...]
exports.lsfhift = (args...) -> [LSHIFT, args...]
exports.rshift = (args...) -> [RSHIFT, args...]
exports.eq = (args...) -> [EQ, args...]
exports.ne = (args...) -> [NE, args...]
exports.le = (args...) -> [LE, args...]
exports.lt = (args...) -> [LT, args...]
exports.gt = (args...) -> [GT, args...]
exports.ge = (args...) -> [GE, args...]
exports.neg = (args...) -> [NEG, args...]
exports.bitnot = (args...) -> [BITNOT, args...]
exports.index = index = (args...) -> [INDEX, args...]
exports.push = push = (args...) -> [PUSH, args...]
exports.list = list = (args...) -> [LIST, args...]
exports.headList = headList = (args...) -> [HEADLIST, args...]
exports.listTail = listTail = (args...) -> [LISTTAIL, args...]
exports.pushp = pushp = (args...) -> [PUSHP, args...]
exports.attr =(args...) -> [ATTR, args...]
exports.length = (args...) -> [LENGTH, args...]
exports.slice = (args...) -> [SLICE, args...]
exports.pop = (args...) -> [POP, args...]
exports.instanceof = (args...) -> [INSTANCEOF, args...]
exports.concat = (args...) -> jsfuncall('concat', args...)

# logic

exports.logicvar = (name) -> [LOGICVAR, name]
exports.dummy = (name) -> [DUMMYVAR, name]

exports.unify = unify = (args...) -> [UNIFY, args...]
exports.notunify = (args...) -> [NOTUNIFY, args...]

exports.succeed = [SUCCEED]
exports.fail = [FAIL]

exports.andp = andp = exports.begin
exports.orp = orp = (exps...) ->
  length = exps.length
  if length is 0 then throw new ArgumentError(exps)
  else if length is 1 then exps[0]
  else if length is 2 then [ORP, exps...]
  else [ORP, exps[0], orp(exps[1...]...)]
exports.orp2 = orp2 = (exps...) ->
  length = exps.length
  if length is 0 then throw new ArgumentError(exps)
  else if length is 1 then exps[0]
  else if length is 2 then [ORP2, exps...]
  else [ORP2, exps[0], orp2(exps[1...]...)]
exports.orp3 = orp3 = (exps...) ->
  length = exps.length
  if length is 0 then throw new ArgumentError(exps)
  else if length is 1 then exps[0]
  else if length is 2 then [ORP3, exps...]
  else [ORP3, exps[0], orp3(exps[1...]...)]
exports.notp = (goal) -> [NOTP, goal]
exports.notp2 = (goal) -> [NOTP2, goal]
exports.notp3 = (goal) -> [NOTP3, goal]
exports.repeat = [REPEAT]
exports.cutable = (goal) -> [CUTABLE, goal]
exports.cut = [CUT]
exports.once = (goal) -> [ONCE, goal]
exports.findall = (goal, result, template) -> [FINDALL, goal, result, template]
exports.is_ = (vari, exp) -> [IS, vari, exp]
exports.bind = bind = (vari, term) -> [BIND, vari, term]
exports.getvalue = getvalue = (term) -> [GETVALUE, term]

# parser
exports.parse =  (exp, state) -> [PARSE, exp, state]
exports.parsedata = exports.parsetext = (exp, data) -> [PARSEDATA, exp, data]
exports.setdata = exports.settext = (data) -> [SETPARSERDATA, data]
exports.setcursor =  (cursor) -> [SETPARSERCURSOR, cursor]
exports.setstate =  (state) -> [SETPARSERSTATE, state]
exports.getstate =  [GETPARSERSTATE]
exports.getdata =  [GETPARSERDATA]
exports.getcursor =  [GETPARSERCURSOR]
exports.eoi = [EOI]
exports.boi =  [BOI]
# eol: end of line text[cursor] in "\r\n"
exports.eol =  [EOL]
# bol: bein of line text[cursor-1] in "\r\n"
exports.bol =  [BOL]
exports.step = (n) -> [STEP, n]
# leftdata: return left data
exports.leftdata =  [LEFTPARSERDATA]
# subdata: return data[start...start+length]
exports.subdata =  (length, start) -> [SUBPARSERDATA, length, start]
# nextchar: data[cursor]
exports.nextchar =  [NEXTCHAR]

# ##### may, lazymay, greedymay
# may: aka optional
exports.may = (exp) -> [MAY, exp]
# lazymay: lazy optional
exports.lazymay = (exp) -> [LAZYMAY, exp]
# greedymay: greedy optional
exports.greedymay = (exp) -> [GREEDYMAY, exp]

index = 1
exports.uniquevar = uniquevar = (name) -> [UNIQUEVAR, name, index++]
exports.uniqueconst = uniqueconst = (name) -> [UNIQUECONST, name, index++]

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
  if not result?  then [ANY, exp]
  else
    result1 = uniqueconst('result')
    begin(assign(result1, []), any(andp(exp, push(result1, getvalue(template)))),
             unify(result, result1))

# lazyany: zero or more exp, lazy mode <br/>
#  result should be an core.Var, and always be bound to the result array. <br/>
#  template: the item in result array is getvalue(template)
exports.lazyany = lazyany = (exp, result, template) ->
  if not result?  then [LAZYANY, exp]
  else
    result1 = uniqueconst('result')
    begin(assign(result1, []),
                lazyany(andp(exp, push(result1, getvalue(template)))),
                unify(result, result1))

# greedyany: zero or more exp, greedy mode
#  result should be an core.Var, and always be bound to the result array.
#  template: the item in result array is getvalue(template)
exports.greedyany = greedyany = (exp, result, template) ->
  if not result?  then [GREEDYANY, exp]
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
  if not result?  then andp(exp, [ANY, exp])
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
  if not result?  then andp(exp, [LAZYANY, exp])
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
  if not result?  then andp(exp, [GREEDYANY, exp])
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

exports.parallel = (args...) -> [PARALLEL, args...]
exports.follow = (x) -> [FOLLOW, x]
exports.notfollow = (x) -> [NOTFOLLOW, x]

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