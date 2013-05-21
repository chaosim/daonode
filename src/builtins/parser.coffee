_ = require('underscore')

dao = require "../../src/solve"

[Trail, solve, Var,  ExpressionError, TypeError, special] = (dao[name]  for name in\
"Trail, solve, Var,  ExpressionError, TypeError, special".split(", "))

exports.parse = special('parse', (solver, cont, exp, state) -> (v, solver) ->
  old_state = solver.state
  solver.state = state
  solver.cont(exp, (v, solver) ->
    solver.state = old_state
    [cont, v, solver])(v, solver))

exports.parse = special('parse', (solver, cont, exp, state) ->
  old_state = solver.state
  solver.state = state
  solver.cont(exp, (v, solver) ->
    solver.state = old_state
    [cont, v, solver]))

exports.parsetext = exports.parsesequence = (exp, sequence) -> exports.parse(exp, [sequence, 0])

exports.setstate = special('setstate', (solver, cont, state) -> (v, solver) ->
  solver.state = state
  cont(v, solver))

exports.settext = exports.setsequence = (sequence) -> exports.setstate([sequence, 0])

exports.getstate = special('getstate', (solver, cont) -> (v, solver) ->
  cont(solver.state, solver))

exports.gettext = exports.getsequence = special('gettext', (solver, cont) -> (v, solver) ->
  cont(solver.state[0], solver))

exports.getpos =special('getpos', (solver, cont) -> (v, solver) ->
  cont(solver.state[1], solver))

exports.eoi = special('eoi', (solver, cont) -> (v, solver) ->
  [data, pos] = solver.state
  if pos>=data.length then cont(true, solver) else solver.failcont(v, solver))()

exports.boi = special('boi', (solver, cont) -> (v, solver) ->
  if solver.state[1] is 0 then cont(true, solver) else solver.failcont(v, solver))()

exports.step = special('step', (solver, cont, n=1) -> (v, solver) ->
  [text, pos] = solver.state
  solver.state = [text, pos+n]
  cont(pos+n, solver))

exports.lefttext =  special('lefttext', (solver, cont) -> (v, solver) ->
  [text, pos] = solver.state
  cont(text[pos...], solver))

exports.subtext =  exports.subsequence =  special('subtext', (solver, cont, length, start) -> (v, solver) ->
  [text, pos] = solver.state
  start = start? or pos
  length = length? or text.length
  cont(text[start...start+length], solver))

exports.nextchar =  special('nextchar', (solver, cont) -> (v, solver) ->
  [text, pos] = solver.state
  cont(text[pos], solver))

exports.follow = special('follow', (solver, cont, item) ->
  state = null
  itemCont =  solver.cont(item, (v, solver) ->
    solver.state = state;
    cont(v, solver))
  (v, solver) ->
    state = solver.state
    itemCont(v, solver))

exports.notfollow = special('notfollow', (solver, cont, item) ->
  fc = state = null
  itemCont =  solver.cont(item, (v, solver) ->
    solver.state = state
    fc(v, solver))
  (v, solver) ->
    fc = solver.failcont
    solver.failcont = cont
    state = solver.state
    itemCont(v, solver))

parallelFun = (solver, cont, state, args) ->
  length = args.length
  if length is 0 then cont
  else if length is 1 then solver.cont(args[0], cont)
  else
    leftCont = parallelFun(solver, cont, state, args[1...])
    solver.cont(args[0], (v, solver) ->
      solver.state = state
      leftCont(v, solver))

exports.checkParallel = checkFunction = (state, baseState) -> state[1] is baseState[1]

exports.parallel = special('parallel', (solver, cont, args...) ->
  # from current position to right pass all of args
  length = args.length
  if length is 0 then throw new ArgumentError(args)
  else if length is 1 then return solver.cont(args[0], cont)
  else
    right = null
    if length is 2
      x = args[0]
      y = [args[1]]
    else
      x = args[0]
      y = args[1...]
    adjustCont =  (v, solver) ->
      if checkParallel(solver.state, right) then cont(v, solver)
      else solver.failcont(v, solver)
    ycont = parallelFun(solver, adjustCont, state, y)
    xcont = solver.cont(x,  (v, solver) ->
      right = solver.state
      solver.state = state
      ycont(v, solver))
    xcont)

exports.may = special('may', (solver, cont, exp) ->
  exp_cont = solver.cont(exp, cont)
  (v, solver) ->
    solver.appendFailcont(cont)
    exp_cont(v, solver))

exports.lazymay = special('lazymay', (solver, cont, exp) ->
  expCont = solver.cont(exp, cont)
  (v, solver) ->
    fc = solver.failcont
    solver.failcont = (v, solver) ->
      solver.failcont = fc
      expCont(v, solver)
    cont(v, solver))

exports.greedymay = special('greedymay', (solver, cont, exp) ->
  fc = null
  expCont = solver.cont(exp, (v, solver) ->
    solver.failcont = fc
    cont(v, solver))
  (v, solver) ->
    fc = solver.failcont
    solver.failcont = (v, solver) ->
      solver.failcont = fc
      cont(v, solver)
    expCont(v, solver))

any = (exp, result, template) -> if not reslult then any1(exp) else any2(exp, result, template)

exports.any1 = special('any', (solver, cont, exp) ->
  anyCont = (v, solver) ->
    fc = solver.failcont
    trail = solver.trail
    solver.trail = new dao.Trail
    state = solver.state
    solver.failcont = (v, solver) ->
      solver.trail.undo()
      solver.trail = trail
      solver.state = state
      solver.failcont = fc
      cont(v, solver)
    [expCont, v, solver]
  expCont = solver.cont(exp, anyCont)
  anyCont)

exports.any2 = special('any', (solver, cont, exp, result, template) ->
  result1 = null
  anyCont = (v, solver) ->
    fc = solver.failcont
    trail = solver.trail
    solver.trail = new dao.Trail
    state = solver.state
    solver.failcont = (v, solver) ->
      solver.trail.undo()
      solver.trail = trail
      solver.state = state
      solver.failcont = fc
      result.bind(result1)
      cont(v, solver)
    [expCont, v, solver]
  expCont = solver.cont(exp, (v, solver) ->
    result1.push(solver.trail.getvalue(template))
    anyCont(v, solver))
  (v, solver) -> result1 = []; anyCont(v, solver))

lazyany = (exp, result, template) -> if not reslult then lazyany1(exp) else lazyany2(exp, result, template)

exports.lazyany1 = special('lazyany', (solver, cont, exp) ->
  fc = null
  anyCont = (v, solver) ->
    solver.failcont = anyFcont
    cont(v, solver)
  expcont = solver.cont(exp, anyCont)
  anyFcont = (v, solver) ->
    solver.failcont = fc
    [expcont, v, solver]
  (v, solver) ->  fc = solver.failcont; anyCont(v, solver))

exports.lazyany2 = special('lazyany', (solver, cont, exp, result, template) ->
  result1 = fc = null
  anyCont = (v, solver) ->
    result1.push(solver.trail.getvalue(template))
    solver.failcont = anyFcont
    cont(v, solver)
  expcont = solver.cont(exp, anyCont)
  anyFcont = (v, solver) ->
    solver.failcont = fc
    result.bind(result1)
    [expcont, v, solver]
  (v, solver) -> result1 = []; fc = solver.failcont; anyCont(v, solver))

greedyany = (exp, result, template) -> if not reslult then greedyany1(exp) else greedyany2(exp, result, template)

exports.greedyany1 = special('greedyany', (solver, cont, exp) ->
  anyCont = (v, solver) -> [expCont, v, solver]
  expCont =  solver.cont(exp, anyCont)
  (v, solver) ->
    fc = solver.failcont;
    solver.failcont = (v, solver) -> (solver.failcont = fc; cont(v, solver))
    anyCont(v, solver))

exports.greedyany2 = special('greedyany', (solver, cont, exp, result, template) ->
  result1 = null
  anyCont = (v, solver) ->
    result1.push(solver.trail.getvalue(template));
    [expCont, v, solver]
  expCont =  solver.cont(exp, anyCont)
  (v, solver) ->
    result1 = [];
    fc = solver.failcont;
    solver.failcont = (v, solver) -> (solver.failcont = fc; result.bind(result1); cont(v, solver))
    anyCont(v, solver))

some = (exp, result, template) -> if not result then some1(exp) else some2(exp, result, template)

exports.some1 = special('some', (solver, cont, exp) ->
  someCont = (v, solver) ->
    fc = solver.failcont
    trail = solver.trail
    solver.trail = new dao.Trail
    state = solver.state
    solver.failcont = (v, solver) ->
      solver.trail.undo()
      solver.trail = trail
      solver.state = state
      solver.failcont = fc
      cont(v, solver)
    [expCont, v, solver]
  expCont = solver.cont(exp, someCont)
  expCont)

exports.some2 = special('some', (solver, cont, exp, result, template) ->
  result1 = null
  someCont = (v, solver) ->
    fc = solver.failcont
    trail = solver.trail
    solver.trail = new dao.Trail
    state = solver.state
    solver.failcont = (v, solver) ->
      solver.trail.undo()
      solver.trail = trail
      solver.state = state
      solver.failcont = fc
      result.bind(result1)
      cont(v, solver)
    [expCont, v, solver]
  expCont = solver.cont(exp, (v, solver) ->
    result1.push(solver.trail.getvalue(template))
    someCont(v, solver))
  (v, solver) -> result1 = []; expCont(v, solver))

lazysome = (exp, result, template) -> if not result then lazysome1(exp) else lazysome2(exp, result, template)

exports.lazysome1 = special('lazysome', (solver, cont, exp) ->
  fc = null
  someFcont = (v, solver) ->
    solver.failcont = fc
    [expcont, v, solver]
  someCont = (v, solver) ->
    solver.failcont = someFcont
    cont(v, solver)
  expcont = solver.cont(exp, someCont)
  (v, solver) ->  fc = solver.failcont; expcont(v, solver))

exports.lazysome2 = special('lazysome', (solver, cont, exp, result, template) ->
  result1 = fc = null
  someFcont = (v, solver) ->
    solver.failcont = fc
    result.bind(result1)
    [expcont, v, solver]
  someCont = (v, solver) ->
    result1.push(solver.trail.getvalue(template))
    solver.failcont = someFcont
    cont(v, solver)
  expcont = solver.cont(exp, someCont)
  (v, solver) -> result1 = []; fc = solver.failcont; expcont(v, solver))

greedysome = (exp, result, template) -> if not result then greedysome1(exp) else greedysome2(exp, result, template)

exports.greedysome1 = special('greedysome', (solver, cont, exp) ->
  someCont = (v, solver) -> [expCont, v, solver]
  expCont =  solver.cont(exp, someCont)
  (v, solver) ->
    fc = solver.failcont;
    solver.failcont = (v, solver) -> (solver.failcont = fc; cont(v, solver))
    expCont(v, solver))

exports.greedysome2 = special('greedysome', (solver, cont, exp, result, template) ->
  result1 = null
  someCont = (v, solver) ->
    result1.push(solver.trail.getvalue(template));
    [expCont, v, solver]
  expCont =  solver.cont(exp, someCont)
  (v, solver) ->
    result1 = [];
    fc = solver.failcont;
    solver.failcont = (v, solver) -> (solver.failcont = fc; result.bind(result1); cont(v, solver))
    expCont(v, solver))

times = (exp, expectTimes, result, template) ->
  if not result then times1(exp, expectTimes)
  else times2(exp, expectTimes, result, template)

numberTimes1Fun = (solver, cont, exp, expectTimes) ->
  expectTimes = Math.ceil(expectTimes)
  if expectTimes<0 then throw new ValueError(expectTimes)
  else if i is 0 then cont
  else if i is 1 then solver.cont(exp, cont)
  else if i is 2
    expCont = solver.cont(exp, cont)
    solver.cont(exp, expCont)
  else
    i = null
    expCont = solver.cont(exp, (v, solver) ->
      i++
      if i is expectTimes then cont(v, solver)
      else timesCont(v, solver))
    (v, solver) -> i = 0; timesCont = (v, solver) -> expCont(v, solver)

times1Fun = (solver, cont, exp, expectTimes) ->
  if _.isNumber(expectTimes) then numberTimes1Fun(solver, cont, exp, expectTimes)
  else
    expecTimes1 = i = null

    cont1 = (v, solver) -> expectTimes1.bind(i); cont(v, solver)
    anyCont = (v, solver) ->
      i++
      fc = solver.failcont
      trail = solver.trail
      solver.trail = new dao.Trail
      state = solver.state
      solver.failcont = (v, solver) ->
        i--
        solver.trail.undo()
        solver.trail = trail
        solver.state = state
        solver.failcont = fc
        cont1(v, solver)
      [expCont, v, solver]
    expCont = solver.cont(exp, anyCont)
    solver.cont(expectTimes, (v, solver) ->
      expectTimes1= v
      if _.isNumber(expectTimes1) then numberTimes1Fun(solver, cont, exp, expectTimes1)
      else
        (v, solver) -> i = 0; anyCont(v, solver))

exports.times1 = special('times', times1Fun)

numberTimes2Fun = (solver, cont, exp, expectTimes, result, template) ->
  expectTimes = Math.ceil(expectTimes)
  if expectTimes<0 then throw new ValueError(expectTimes)
  else if i is 0 then (v, solver) -> result.bind([]); cont(v, solver)
  else if i is 1 then solver.cont(exp, (v, solver) ->
    result.bind([solver.trail.getvalue(template)]);
    cont(v, solver))
  else if i is 2
    result1 = []
    expCont = solver.cont(exp, (v, solver) ->
      result1.push solver.trail.getvalue(template)
      result.bind(result1);
      cont(v, solver))
    solver.cont(exp, (v, solver) ->
      result1.push solver.trail.getvalue(template)
      expCont(v, solver))
  else
    result1 = i = null
    expCont = solver.cont(exp, (v, solver) ->
      i++
      result1.push solver.trail.getvalue(template)
      if i is expectTimes then (v, solver) ->  result.bind(result1); cont(v, solver)
      else timesCont(v, solver))
    (v, solver) -> i = 0;  result1 = []; timesCont = (v, solver) -> expCont(v, solver)

times2Fun = (solver, cont, exp, expectTimes, result, template) ->
  if _.isNumber(expectTimes) then numberTimes2Fun(solver, cont, exp, expectTimes, result, template)
  else
    expecTimes1 = i = null
    cont1 = (v, solver) -> expectTimes1.bind(i); cont(v, solver)
    anyCont = (v, solver) ->
      i++
      fc = solver.failcont
      trail = solver.trail
      solver.trail = new dao.Trail
      state = solver.state
      solver.failcont = (v, solver) ->
        i--
        solver.trail.undo()
        solver.trail = trail
        solver.state = state
        solver.failcont = fc
        cont1(v, solver)
      [expCont, v, solver]
    expCont = solver.cont(exp, anyCont)
    solver.cont(expectTimes, (v, solver) ->
      expectTimes1= v
      if _.isNumber(expectTimes1) then numberTimes2Fun(solver, cont, exp, expectTimes1, result, template)
      else
        (v, solver) -> i = 0; anyCont(v, solver))

exports.times2 = special('times', times2Fun)

exports.char = special('char', (solver, cont, x) ->  (v, solver) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(v, solver)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var
    x.bind(c, solver.trail)
    solver.state = [data, pos+1]
    cont(pos+1, solver)
  else if x is c then (solver.state = [data, pos+1]; cont(v, solver))
  else if _.isString(x)
    if x.length==1 then solver.failcont(v, solver)
    else throw new ExpressionError(x)
  else throw new TypeError(x))

exports.followChar = special('followChar', (solver, cont, arg) -> (v, solver) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(v, solver)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var then throw new TypeError(x)
  else if x is c then (cont(pos, solver))
  else if _.isString(x)
    if x.length==1 then solver.failcont(v, solver)
    else throw new ValueError(x)
  else throw new TypeError(x))

exports.notFollowChar = special('followChar', (solver, cont, x) -> (v, solver) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(v, solver)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var then throw new TypeError(x)
  else if x is c then solver.failcont(pos, solver)
  else if _.isString(x)
    if x.length==1 then cont(v, solver)
    else throw new ValueError(x)
  else throw new TypeError(x))

exports.followChars = special('followChar', (solver, cont, chars) -> (v, solver) ->
  # follow one of char in chars
  chars = trail.deref(chars)
  if chars instanceof Var then throw new TypeError(chars)
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(v, solver)
  trail = solver.trail
  c = data[pos]
  if c in chars then cont(pos, solver)
  else if not _.isString(chars)
    throw new TypeError(chars)
  else solver.failcont(pos, solver))

exports.notFollowChars = special('followChar', (solver, cont, chars) -> (v, solver) ->
  # not follow one of char in chars
  chars = trail.deref(chars)
  if chars instanceof Var then throw new TypeError(chars)
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(v, solver)
  trail = solver.trail
  c = data[pos]
  if c in chars then solver.failcont(pos, solver)
  else if not _.isString(chars)
    throw new TypeError(chars)
  else cont(pos, solver))

exports.charWhen = special('charWhen', (solver, cont, test) -> (v, solver) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(false, solver)
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

exports.spaces = special('spaces', (solver, cont) -> (v, solver) ->
  # 1 or more spaces
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(false, solver)
  c = data[pos]
  if c isnt ' ' then return solver.failcont(c, solver)
  p = pos+1
  while p< length and data[p] is ' ' then p++
  cont(p-pos, solver))

exports.spaces0 = special('spaces', (solver, cont) -> (v, solver) ->
  # 0 or more spaces
  [data, pos] = solver.state
  if pos>=data.length then return cont(0, solver)
  c = data[pos]
  if c isnt ' ' then return cont(c, solver)
  p = pos+1
  while p< length and data[p] is ' ' then p++
  cont(p-pos, solver))

exports.stringWhile = special('stringWhile', (solver, cont, test) -> (v, solver) ->
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

exports.stringWhile0 = special('stringWhile0', (solver, cont, test) -> (v, solver) ->
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

exports.float = special('float', (solver, cont, arg) -> (v, solver) ->
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

exports.literal = special('literal', (solver, cont, arg) -> (v, solver) ->
  arg = solver.trail.deref(arg)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  [text, pos] = solver.parse_state
  length = text.length
  if pos>=length then return solver.failcont(v, solver)
  i = 0
  p = pos
  length2 = arg.length
  while i<length2 and p<length and arg[i] is text[p] then i++; p++
  if i is length2
    solver.state = [text, p]
    cont(p, solver)
  else solver.failcont(p, solver))

exports.followLiteral = special('followLiteral', (solver, cont, arg) -> (v, solver) ->
  arg = solver.trail.deref(arg)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  [text, pos] = solver.parse_state
  length = text.length
  if pos>=length then return solver.failcont(v, solver)
  i = 0
  p = pos
  length2 = arg.length
  while i<length2 and p<length and arg[i] is text[p] then i++; p++
  if i is length2 then cont(p, solver)
  else solver.failcont(p, solver))

exports.notFollowLiteral = special('followLiteral', (solver, cont, arg) -> (v, solver) ->
  arg = solver.trail.deref(arg)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  [text, pos] = solver.parse_state
  length = text.length
  if pos>=length then return solver.failcont(v, solver)
  i = 0
  p = pos
  length2 = arg.length
  while i<length2 and p<length and arg[i] is text[p] then i++; p++
  if i is length2 then solver.failcont(p, solver)
  else cont(p, solver))


exports.quoteString = special('quoteString', (solver, cont, quote) -> (v, solver) ->
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
