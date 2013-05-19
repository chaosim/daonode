_ = require('underscore')

dao = require "../../src/solve"
solver = dao.solver

[Trail, solve, Var,  ExpressionError, TypeError, special] = (dao[name]  for name in\
"Trail, solve, Var,  ExpressionError, TypeError, special".split(", "))

exports.parse = special('parse', (cont, exp, state) -> (v) ->
  old_state = solver.state
  solver.state = state
  solver.cont(exp, (v) ->
    solver.state = old_state
    [cont, v])(true))

exports.parse = special('parse', (cont, exp, state) ->
  old_state = solver.state
  solver.state = state
  solver.cont(exp, (v) ->
    solver.state = old_state
    [cont, v]))

exports.parsetext = exports.parsesequence = (exp, sequence) -> exports.parse(exp, [sequence, 0])

exports.setstate = special('setstate', (cont, state) -> (v) ->
  solver.state = state
  cont(v))

exports.settext = exports.setsequence = (sequence) -> exports.setstate([sequence, 0])

exports.getstate = special('getstate', (cont) -> (v) ->
  cont(solver.state))

exports.gettext = exports.getsequence = special('gettext', (cont) -> (v) ->
  cont(solver.state[0]))

exports.getpos =special('getpos', (cont) -> (v) ->
  cont(solver.state[1]))

exports.eoi = special('eoi', (cont) -> (v) ->
  [data, pos] = solver.state
  if pos is data.length then cont(true) else solver.failcont(v))()

exports.boi = special('boi', (cont) -> (v) ->
  if solver.state[1] is 0 then cont(true) else solver.failcont(v))()

exports.step = special('step', (cont, n=1) -> (v) ->
  [text, pos] = solver.state
  solver.state = [text, pos+n]
  cont(pos+n))

exports.lefttext =  special('lefttext', (cont) -> (v) ->
  [text, pos] = solver.state
  cont(text[pos...]))

exports.subtext =  exports.subsequence =  special('subtext', (cont, length, start) -> (v) ->
  [text, pos] = solver.state
  start = start? or pos
  length = length? or text.length
  cont(text[start...start+length]))

exports.nextchar =  special('nextchar', (cont) -> (v) ->
  [text, pos] = solver.state
  cont(text[pos]))

exports.follow = special('follow', (cont, item) -> (v) ->
  state = solver.state
  solver.cont(item, (v) ->
    solver.state = state;
    cont(v))(v))

exports.may = special('may', (cont, exp) -> (v) ->
  fc = solver.failcont
  exp_cont = solver.cont(exp, cont)
  solver.failcont = (v) ->
    solver.failcont = fc
    cont(v)
  exp_cont(v))

exports.may = special('may', (cont, exp) ->
  fc = solver.failcont
  exp_cont = solver.cont(exp, cont)
  solver.failcont = (v) ->
    solver.failcont = fc
    cont(v)
  exp_cont)

exports.lazymay = special('lazymay', (cont, exp) -> (v) ->
  fc = solver.failcont
  solver.failcont = (v) ->
    solver.failcont = fc
    solver.cont(exp, cont)(v)
  cont(v))

exports.greedymay = special('greedymay', (cont, exp) -> (v) ->
  fc = solver.failcont
  solver.failcont = (v) ->
    solver.failcont = fc
    cont(v)
  solver.cont(exp, (v) ->
     solver.failcont = fc
    cont(v))(v))

exports.any = special('any', (cont, exp) ->
  anyCont = (v) ->
    fc = solver.failcont
    solver.failcont = (v) -> solver.failcont = fc; cont(v)
    solver.cont(exp, anyCont)(v)
  anyCont)

exports.any = special('any', (cont, exp) ->
  anyCont = (v) ->
    fc = solver.failcont
    trail = solver.trail
    solver.trail = new dao.Trail
    state = solver.state
    solver.failcont = (v) ->
      solver.trail.undo()
      solver.trail = trail
      solver.state = state
      solver.failcont = fc
      cont(v)
    solver.cont(exp, anyCont)(v)
  anyCont)

exports.lazyany = special('lazyany', (cont, exp) -> (v) ->
  fc = solver.failcont
  anyCont = (v) ->
    solver.failcont = anyFcont
    cont(v)
  anyFcont = (v) ->
    solver.failcont = fc
    solver.cont(exp, anyCont)
  anyCont(v))

exports.lazyany = special('lazyany', (cont, exp) ->
  fc = solver.failcont
  anyCont = (v) ->
    solver.failcont = anyFcont
    cont(v)
  expcont = solver.cont(exp, anyCont)
  anyFcont = (v) ->
    solver.failcont = fc
    expcont(v)
  anyCont)

exports.greedyany = special('greedyany', (cont, exp) -> (v) ->
  fc = solver.failcont
  anyCont = (v) ->
    solver.failcont = (v) ->  solver.failcont = fc; cont(v)
    [solver.cont(exp, anyCont), v]
  anyCont(v))

exports.char = special('char', (cont, x) ->  (v) ->
  [data, pos] = solver.state
  if pos is data.length then return solver.failcont(v)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var
    x.bind(c, solver.trail)
    solver.state = [data, pos+1]
    cont(pos+1)
  else if x is c then (solver.state = [data, pos+1]; cont(v))
  else if _.isString(x)
    if x.length==1 then solver.failcont(v)
    else throw new ExpressionError(x)
  else throw new TypeError(x))

exports.xchar = special('char', (cont, x) -> (v) ->
  [data, pos] = solver.state
  if pos is data.length then return solver.failcont(false)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var
    trail.set(x, c)
    cont(pos+1)
  else if x is c then (solver.state = [data, pos+1]; cont(pos+1))
  else if _.isString(x)
    if x.length==1 then solver.failcont(false)
    else throw new ExpressionError(x)
  else throw new TypeError(x))

exports.charWhen = special('charWhen', (cont, test) -> (v) ->
  [data, pos] = solver.state
  if pos is data.length then return solver.failcont(false)
  c = data[pos]
  if test(c) then cont(c)
  else solver.failcont(c))

exports.charBetween = (x, start, end) -> exports.charWhen(x, (c) -> start<c<end)
exports.charIn = (x, set) -> exports.charWhen(x, (c) ->  c in set)
exports.digit = exports.charWhen((c)->'0'<=c<='9')
exports.digit1_9 = exports.charWhen((c)->'1'<=c<='9')
exports.lower = exports.charWhen((c)->'a'<=c<='z')
exports.upper = exports.charWhen((c)->'A'<=c<='Z')
exports.letter = exports.charWhen((c)-> ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetter = exports.charWhen((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetterDight = exports.charWhen((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z') or ('0'<=c<='9'))
exports.tabspace = exports.charIn(' \t')
exports.whitespace = exports.charIn(' \t\r\n')
exports.newline = exports.charIn('\r\n')

exports.stringWhile = special('stringWhile', (cont, test) -> (v) ->
  [data, pos] = solver.state
  length = data.length
  if pos is length then return solver.failcont(false)
  c = data[pos]
  unless test(c) then return solver.failcont(c)
  p = pos+1
  while p<length and test(data[p]) then p
  cont(text[pos...p]))

exports.stringBetween = (start, end) -> exports.stringWhile((c) -> start<c<end)
exports.stringIn = (set) -> exports.stringWhile((c) ->  c in set)
exports.digits = exports.stringWhile((c)->'0'<=c<='9')
exports.digits1_9 = exports.stringWhile((c)->'1'<=c<='9')
exports.lowers = exports.stringWhile((c)->'a'<=c<='z')
exports.uppers = exports.stringWhile((c)->'A'<=c<='Z')
exports.letters = exports.stringWhile((c)-> ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetters = exports.stringWhile((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetterDights = exports.stringWhile((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z') or ('0'<=c<='9'))
exports.tabspaces = exports.stringIn(' \t')
exports.whitespaces = exports.stringIn(' \t\r\n')
exports.newlinespaces = exports.stringIn('\r\n')

exports.stringWhile0 = special('stringWhile0', (cont, test) -> (v) ->
  [data, pos] = solver.state
  length = data.length
  if pos is length then return cont('')
  c = data[pos]
  unless test(c) then return cont('')
  p = pos+1
  while p<length and test(data[p]) then p
  cont(text[pos...p]))

exports.stringBetween0 = (start, end) -> exports.stringWhile0((c) -> start<c<end)
exports.stringIn0 = (set) -> exports.stringWhile0((c) ->  c in set)
exports.digits0 = exports.stringWhile0((c)->'0'<=c<='9')
exports.digits1_90 = exports.stringWhile0((c)->'1'<=c<='9')
exports.lowers0 = exports.stringWhile0((c)->'a'<=c<='z')
exports.uppers0 = exports.stringWhile0((c)->'A'<=c<='Z')
exports.letters0 = exports.stringWhile0((c)-> ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetters0 = exports.stringWhile0((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z'))
exports.underlineLetterDights0 = exports.stringWhile0((c)-> (c is '_') or ('a'<=c<='z') or ('A'<=c<='Z') or ('0'<=c<='9'))
exports.tabspaces0 = exports.stringIn0(' \t')
exports.whitespaces0 = exports.stringIn0(' \t\r\n')
exports.newlines0 = exports.stringIn0('\r\n')

exports.float = special('float', (cont, arg) -> (v) ->
  [text, pos] = solver.parse_state
  length = text.length
  if pos>=length then return solver.failcont(v)
  if not '0'<=text[pos]<='9' and text[pos]!='.'
    return solver.failcont(v)
  p = pos
  while p<length and '0'<=text[p]<='9' then p++
  if p<length and text[p]=='.' then p++
  while p<length and '0'<=text[p]<='9' then p++
  if p<length-1 and text[p] in 'eE' then (p++; p++)
  while p<length and '0'<=text[p]<='9' then p++
  if text[pos:p]=='.' then return solver.failcont(v)
  val = eval(text[pos...p])
  arg = solver.trail.deref(arg)
  value =  eval(text[pos:p])
  if (arg instanceof Var)
    arg.bind(value, solver.trail)
    cont(value)
  else
    if _.isNumber(arg)
      if arg is value then cont(arg)
      else solver.failcont(v)          s
    else throw new exports.TypeError(arg))

exports.literal = special('literal', (cont, arg) -> (v) ->
  [text, pos] = solver.parse_state
  length = text.length
  if pos>=length then return solver.failcont(v)
  arg = solver.trail.deref(arg)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  else
    if text[pos...].indexOf(arg) is 0
      solver.state = [text, pos+arg.length]
      cont(pos+arg.length)
    else solver.failcont(false))

exports.quoteString = special('quoteString', (cont, quote) -> (v) ->
  string = ''
  [text, pos] = solver.parse_state
  length = text.length
  if pos>=length then return solver.failcont(v)
  quote = solver.trail.deref(quote)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  if text[pos]!=quote then return solver.failcont(v)
  p = pos+1
  while p<length
    char = text[p]
    p += 1
    if char=='\\' then p++
    else if char==quote
      string = text[pos+ 1...p]
      break
  if p is length then return solver.failcont(v)
  cont(string))

dqstring = exports.quoteString('"')
sqstring = exports.quoteString("'")
