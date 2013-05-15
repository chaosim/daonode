_ = require('underscore')
I = require("f:/node-utils/src/importer")
base = "f:/daonode/src/"
I.use base+"solve: Trail, solve, Var,  ExpressionError, TypeError, special"

exports.parse = special((solver, cont, exp, state) -> (v, solver) ->
  old_state = solver.state
  solver.state = state
  solver.cont(exp, (v, solver) ->
              solver.state = old_state
              cont(v, solver))(true, solver))

exports.parsetext = exports.parsesequence = (exp, sequence) -> exports.parse(exp, [sequence, 0])

exports.setstate = special((solver, cont, state) -> (v, solver) ->
  solver.state = state
  cont(v, solver))

exports.settext = exports.setsequence = (sequence) -> exports.setstate([sequence, 0])

exports.getstate = special((solver, cont) -> (v, solver) ->
  cont(solver.state, solver))

exports.gettext = exports.getsequence = special((solver, cont) -> (v, solver) ->
  cont(solver.state[0], solver))

exports.getpos =special((solver, cont) -> (v, solver) ->
  cont(solver.state[1], solver))

exports.eoi = special((solver, cont) -> (v, solver) ->
  [data, pos] = solver.state
  if pos is data.length then cont(true, solver) else solver.failcont(v, solver))()

exports.boi = special((solver, cont) -> (v, solver) ->
  if solver.state[1] is 0 then cont(true, solver) else solver.failcont(v, solver))()

exports.step = special((solver, cont, n=1) -> (v, solver) ->
  [text, pos] = solver.state
  solver.state = [text, pos+n]
  cont(pos+n, solver))

exports.lefttext =  special((solver, cont) -> (v, solver) ->
  [text, pos] = solver.state
  cont(text[pos...], solver))

exports.subtext =  exports.subsequence =  special((solver, cont, start, end) -> (v, solver) ->
  [text, pos] = solver.state
  cont(text[(start or 0)...(end or text.length)], solver))

exports.nextchar =  special((solver, cont) -> (v, solver) ->
  [text, pos] = solver.state
  cont(text[pos], solver))

exports.may = special((solver, cont, exp) -> (v, solver) ->
  fc = solver.failcont
  exp_cont = solver.cont(exp, cont)
  solver.failcont = (v, solver) ->
    solver.failcont = fc
    cont(v, solver)
  exp_cont(v, solver))

exports.lazymay = special((solver, cont, exp) -> (v, solver) ->
  fc = solver.failcont
  solver.failcont = (v, solver) ->
    solver.failcont = fc
    solver.cont(exp, cont)(v, solver)
  cont(v, solver))

exports.greedymay = special((solver, cont, exp) -> (v, solver) ->
  fc = solver.failcont
  solver.failcont = (v, solver) ->
    solver.failcont = fc
    cont(v, solver)
  solver.cont(exp, (v, solver) ->
     solver.failcont = fc
    cont(v, solver))(v, solver))

exports.any = special((solver, cont, exp) ->
  anyCont = (v, solver) ->
    fc = solver.failcont
    solver.failcont = (v, solver) -> solver.failcont = fc; cont(v, solver)
    solver.cont(exp, anyCont)(v, solver))

exports.lazyany = special((solver, cont, exp) -> (v, solver) ->
  fc = solver.failcont
  anyCont = (v, solver) ->
    solver.failcont = anyFcont
    cont(v, solver)
  anyFcont = (v, solver) ->
    solver.failcont = fc
    solver.cont(exp, anyCont)
  anyCont(v, solver))

exports.greedyany = special((solver, cont, exp) -> (v, solver) ->
  fc = solver.failcont
  anyCont = (v, solver) ->
    solver.failcont = (v, solver) ->  solver.failcont = fc; cont(v, solver)
    solver.cont(exp, anyCont)
  anyCont(v, solver))

exports.char = special((solver, cont, x) -> (v, solver) ->
  [data, pos] = solver.state
  if pos is data.length then return solver.failcont(false, solver)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var
    trail.set(x, c)
    cont(pos+1, solver)
  else if x is c then (solver.state = [data, pos+1]; cont(pos+1, solver))
  else if _.isString(x)
    if x.length==1 then solver.failcont(false, solver)
    else throw new ExpressionError(x)
  else throw new TypeError(x))

exports.charWhen = special((solver, cont, test) -> (v, solver) ->
  [data, pos] = solver.state
  if pos is data.length then return solver.failcont(false, solver)
  c = data[pos]
  if test(c) then cont(c, solver)
  else solver.failcont(c, solver))

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

exports.stringWhile = special((solver, cont, test) -> (v, solver) ->
  [data, pos] = solver.state
  length = data.length
  if pos is length then return solver.failcont(false, solver)
  c = data[pos]
  unless test(c) then return solver.failcont(c, solver)
  p = pos+1
  while p<length and test(data[p]) then p
  cont(text[pos...p], solver))

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

exports.stringWhile0 = special((solver, cont, test) -> (v, solver) ->
  [data, pos] = solver.state
  length = data.length
  if pos is length then return cont('', solver)
  c = data[pos]
  unless test(c) then return cont('', solver)
  p = pos+1
  while p<length and test(data[p]) then p
  cont(text[pos...p], solver))

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

exports.float = special((solver, cont, arg) -> (v, solver) ->
  [text, pos] = solver.parse_state
  length = text.length
  if pos>=length then return solver.failcont(v, solver)
  if not '0'<=text[pos]<='9' and text[pos]!='.'
    return solver.failcont(v, solver)
  p = pos
  while p<length and '0'<=text[p]<='9' then p++
  if p<length and text[p]=='.' then p++
  while p<length and '0'<=text[p]<='9' then p++
  if p<length-1 and text[p] in 'eE' then (p++; p++)
  while p<length and '0'<=text[p]<='9' then p++
  if text[pos:p]=='.' then return solver.failcont(v, solver)
  val = eval(text[pos...p])
  arg = solver.trail.deref(arg)
  value =  eval(text[pos:p])
  if (arg instanceof Var)
    arg.bind(value, solver.trail)
    cont(value, solver)
  else
    if _.isNumber(arg)
      if arg is value then cont(arg, solver)
      else solver.failcont(v, solver)          s
    else throw new exports.TypeError(arg))

exports.literal = special((solver, cont, arg) -> (v, solver) ->
  [text, pos] = solver.parse_state
  length = text.length
  if pos>=length then return solver.failcont(v, solver)
  arg = solver.trail.deref(arg)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  else
    if text[pos...].indexOf(arg) is 0
      solver.state = [text, pos+arg.length]
      cont(pos+arg.length, solver)
    else solver.failcont(false, solver))


exports.quoteString = special((solver, cont, quote) -> (v, solver) ->
  string = ''
  [text, pos] = solver.parse_state
  length = text.length
  if pos>=length then return solver.failcont(v, solver)
  quote = solver.trail.deref(quote)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  if text[pos]!=quote then return solver.failcont(v, solver)
  p = pos+1
  while p<length
    char = text[p]
    p += 1
    if char=='\\' then p++
    else if char==quote
      string = text[pos+ 1...p]
      break
  if p is length then return solver.failcont(v, solver)
  cont(string, solver))

dqstring = exports.quoteString('"')
sqstring = exports.quoteString("'")