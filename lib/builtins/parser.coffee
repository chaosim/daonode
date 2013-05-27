# ### parser builtins

# dao's solver have no special demand on solver'state, so we can develop any kind of parser command, to parse different kind of object, such as array, sequence, list, binary stream, tree, even any other general object, not limit to text. <br/>

# parser builtins can be used by companion with any other builtins and user command.<br/>

# logic var can be used in parser as parameter, parameterize grammar is the unique feature of dao.<br/>

# Similar to develop parser, dao can be as the base to develop a generator. We can also generate stuff at th same time of parsing.

_ = require('underscore')

dao = require "../dao"

logic = require "./logic"
general = require "./general"
lisp = require "./lisp"

[Trail, solve, Var,  ExpressionError, TypeError, special] = (dao[name]  for name in\
"Trail, solve, Var,  ExpressionError, TypeError, special".split(", "))

# ####parser control/access

# parse, setstate, getstate have no demand on solver.state <br/> <br/>
# parsesequence/parsetext, setsequence/settext, getsequence/gettext, getpos, step, lefttext, next: demand that solver.state should look like [sequence, index], and sequence can be indexed by integer. index is an integer.<br/><br/>
# lefttext, subtext, eoi, boi demand that sequence should have length property  <br/><br/>
# eol, boil demand that sequence should be an string.

# parse: parse exp on state
exports.parse = special(2, 'parse', (solver, cont, exp, state) ->
  oldState = null
  expCont = solver.cont(exp, (v, solver) ->
    solver.state = oldState
    [cont, v, solver])
  (v, solver) ->
    oldState = solver.state
    solver.state = state
    expCont(v, solver))

# parsetext: parse exp on [sequence, 0] <br/>
# parsesequence: parse exp on [sequence, 0]
exports.parsetext = exports.parsesequence = (exp, sequence) -> exports.parse(exp, [sequence, 0])

# setstate: solver.state = state
exports.setstate = special(1, 'setstate', (solver, cont, state) -> (v, solver) ->
  solver.state = state
  cont(v, solver))

# setsequence: solver.state = [@sequence, 0]<br/>
# settext: solver.state = [@sequence, 0]
exports.settext = exports.setsequence = (sequence) -> exports.setstate([sequence, 0])

# getstate: get solver.state
exports.getstate = special(0, 'getstate', (solver, cont) -> (v, solver) ->
  cont(solver.state, solver))()

# gettext: get solver.state[0]
# getsequence: get solver.state[0]
exports.gettext = exports.getsequence = special(0, 'gettext', (solver, cont) -> (v, solver) ->
  cont(solver.state[0], solver))()

# getpos: solver.state[1]
exports.getpos =special(0, 'getpos', (solver, cont) -> (v, solver) ->
  cont(solver.state[1], solver))()

# eoi: end of input, means pos>=text.length
exports.eoi = special(0, 'eoi', (solver, cont) -> (v, solver) ->
  [data, pos] = solver.state
  if pos>=data.length then cont(true, solver) else solver.failcont(v, solver))()

# boi:  begin of input, means pos==0
exports.boi = special(0, 'boi', (solver, cont) -> (v, solver) ->
  if solver.state[1] is 0 then cont(true, solver) else solver.failcont(v, solver))()

# eol: end of line text[pos] in "\r\n"
exports.eol = special(0, 'eol', (solver, cont) -> (v, solver) ->
  [data, pos] = solver.state
  if pos>=data.length then cont(true, solver)
  else
    [text, pos] = solver.state
    if text[pos] in "\r\n" then cont(true, solver)
    else solver.failcont(v, solver))()

# bol: begin of line text[pos-1] in "\r\n"
exports.bol = special(0, 'bol', (solver, cont) -> (v, solver) ->
  if solver.state[1] is 0 then cont(true, solver)
  else
    [text, pos] = solver.state
    if text[pos-1] in "\r\n" then cont(true, solver)
    else solver.failcont(v, solver))()

# step: step to next char in text
exports.step = special([0,1], 'step', (solver, cont, n=1) -> (v, solver) ->
  [text, pos] = solver.state
  solver.state = [text, pos+n]
  cont(pos+n, solver))

# lefttext: return left text
exports.lefttext =  special(0, 'lefttext', (solver, cont) -> (v, solver) ->
  [text, pos] = solver.state
  cont(text[pos...], solver))()

# subtext: return text[start...start+length]
exports.subtext =  exports.subsequence =  special([0,1,2], 'subtext', (solver, cont, length, start) -> (v, solver) ->
  [text, pos] = solver.state
  start = start? or pos
  length = length? or text.length
  cont(text[start...start+length], solver))

# nextchar: text[pos]
exports.nextchar =  special(0, 'nextchar', (solver, cont) -> (v, solver) ->
  [text, pos] = solver.state
  cont(text[pos], solver))()

# #### general predicate

# follow: if item is followed, succeed, else fail. after eval, state is restored
exports.follow = special(1, 'follow', (solver, cont, item) ->
  state = null
  itemCont =  solver.cont(item, (v, solver) ->
    solver.state = state;
    cont(v, solver))
  (v, solver) ->
    state = solver.state
    itemCont(v, solver))

# notfollow: if item is NOT followed, succeed, else fail. after eval, state is restored
exports.notfollow = special(1, 'notfollow', (solver, cont, item) ->
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

# parallel: between current state and right, all args succeed, <br/>
#  and reach the right where checkParallel(solver.state, right) is true <br/>
#  in a simple case: all clauses succeed in same length piece
exports.parallel = special(null, 'parallel', (solver, cont, args,
      checkFunction = (state, baseState) -> state[1] is baseState[1]) ->
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

# ##### normal mode, lazy mode, greedy mode
#normal mode: try the goal at first, <br/>
# after succeed, if need, backtracking happens to try the goal again.  <br/>
#greedy mode: goes forward at first,<br/>
#after succeed, no backtracking happens on the goal.<br/>
#lazy mode: goes foward without trying the goal, <br/>
# if failed, backtrack to goal and try again.<br/>
#see test_parser for more informations.

# ##### may, lazymay, greedymay
# may: aka optional
exports.may = special(1, 'may', (solver, cont, exp) ->
  exp_cont = solver.cont(exp, cont)
  (v, solver) ->
    solver.appendFailcont(cont)
    exp_cont(v, solver))

# lazymay: lazy optional
exports.lazymay = special(1, 'lazymay', (solver, cont, exp) ->
  expCont = solver.cont(exp, cont)
  (v, solver) ->
    fc = solver.failcont
    solver.failcont = (v, solver) ->
      solver.failcont = fc
      expCont(v, solver)
    cont(v, solver))

# greedymay: greedy optional
exports.greedymay = special(1, 'greedymay', (solver, cont, exp) ->
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

# #### any, lazyany, greedyany
# any: zero or more exp, normal mode <br/>
#  result should be an dao.Var, and always be bound to the result array. <br/>
#  template: the item in result array is getvalue(template)
exports.any = (exp, result, template) -> if not result then any1(exp) else any2(exp, result, template)

any1 = special(1, 'any', (solver, cont, exp) ->
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

any2 = special(3, 'any', (solver, cont, exp, result, template) ->
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
      solver.failcont = (v, solver) -> result1.pop(); fc(v, solver)
      cont(v, solver)
    [expCont, v, solver]
  expCont = solver.cont(exp, (v, solver) ->
    result1.push(solver.trail.getvalue(template))
    anyCont(v, solver))
  (v, solver) -> result1 = [];  result.bind(result1, solver.trail); anyCont(v, solver))

# lazyany: zero or more exp, lazy mode <br/>
#  result should be an dao.Var, and always be bound to the result array. <br/>
#  template: the item in reuslt array is getvalue(template)
exports.lazyany = (exp, result, template) ->
  if not result then lazyany1(exp) else lazyany2(exp, result, template)

lazyany1 = special(1, 'lazyany', (solver, cont, exp) ->
  fc = null
  anyCont = (v, solver) ->
    solver.failcont = anyFcont
    cont(v, solver)
  expcont = solver.cont(exp, anyCont)
  anyFcont = (v, solver) ->
    solver.failcont = fc
    [expcont, v, solver]
  (v, solver) ->  fc = solver.failcont; anyCont(v, solver))

lazyany2 = special(3, 'lazyany', (solver, cont, exp, result, template) ->
  result1 = fc = null
  anyCont = (v, solver) ->
    solver.failcont = anyFcont
    result.bind(result1, solver.trail)
    cont(v, solver)
  expcont = solver.cont(exp, (v, solver) ->
    result1.push(solver.trail.getvalue(template))
    anyCont(v, solver))
  anyFcont = (v, solver) ->
    solver.failcont = fc
    [expcont, v, solver]
  (v, solver) -> result1 = []; fc = solver.failcont; anyCont(v, solver))

# greedyany: zero or more exp, greedy mode
#  result should be an dao.Var, and always be bound to the result array.
#  template: the item in reuslt array is getvalue(template)
exports.greedyany = (exp, result, template) -> if not result then greedyany1(exp) else greedyany2(exp, result, template)

greedyany1 = special(1, 'greedyany', (solver, cont, exp) ->
  anyCont = (v, solver) -> [expCont, v, solver]
  expCont =  solver.cont(exp, anyCont)
  (v, solver) ->
    fc = solver.failcont;
    solver.failcont = (v, solver) -> (solver.failcont = fc; cont(v, solver))
    anyCont(v, solver))

greedyany2 = special(3, 'greedyany', (solver, cont, exp, result, template) ->
  result1 = null
  anyCont = (v, solver) -> [expCont, v, solver]
  expCont =  solver.cont(exp, (v, solver) ->  result1.push(solver.trail.getvalue(template)); anyCont(v, solver))
  (v, solver) ->
    result1 = [];
    fc = solver.failcont;
    solver.failcont = (v, solver) -> (solver.failcont = fc; result.bind(result1, solver.trail); cont(v, solver))
    anyCont(v, solver))

# ##### some, lazysome, greedysome
# some: one or more exp, normal mode <br/>
#  result should be an dao.Var, and always be bound to the result array. <br/>
#  template: the item in reuslt array is getvalue(template)
exports.some = (exp, result, template) -> if not result then some1(exp) else some2(exp, result, template)

some1 = special(1, 'some', (solver, cont, exp) ->
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

some2 = special(3, 'some', (solver, cont, exp, result, template) ->
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
      solver.failcont = (v, solver) -> result1.pop(); fc(v, solver)
      cont(v, solver)
    [expCont, v, solver]
  expCont = solver.cont(exp, (v, solver) ->
    result1.push(solver.trail.getvalue(template))
    someCont(v, solver))
  (v, solver) -> result1 = []; result.bind(result1, solver.trail); expCont(v, solver))

# lazysome: one or more exp, lazy mode <br/>
#  result should be an dao.Var, and always be bound to the result array. <br/>
#  template: the item in reuslt array is getvalue(template)
exports.lazysome = (exp, result, template) -> if not result then lazysome1(exp) else lazysome2(exp, result, template)

lazysome1 = special(1, 'lazysome', (solver, cont, exp) ->
  fc = null
  someFcont = (v, solver) ->
    solver.failcont = fc
    [expcont, v, solver]
  someCont = (v, solver) ->
    solver.failcont = someFcont
    cont(v, solver)
  expcont = solver.cont(exp, someCont)
  (v, solver) ->  fc = solver.failcont; expcont(v, solver))

lazysome2 = special(3, 'lazysome', (solver, cont, exp, result, template) ->
  result1 = fc = null
  someFcont = (v, solver) ->
    solver.failcont = fc
    [expcont, v, solver]
  someCont = (v, solver) ->
    result1.push(solver.trail.getvalue(template))
    solver.failcont = someFcont
    cont(v, solver)
  expcont = solver.cont(exp, someCont)
  (v, solver) ->
    result1 = [];
    result.bind(result1, solver.trail);
    fc = solver.failcont;
    expcont(v, solver))

# greedysome: one or more exp, greedy mode<br/>
#  result should be an dao.Var, and always be bound to the result array. <br/>
#  template: the item in reuslt array is getvalue(template)
exports.greedysome = (exp, result, template) -> if not result then greedysome1(exp) else greedysome2(exp, result, template)

greedysome1 = special(1, 'greedysome', (solver, cont, exp) ->
  someCont = (v, solver) -> [expCont, v, solver]
  expCont =  solver.cont(exp, someCont)
  (v, solver) ->
    fc = solver.failcont;
    solver.failcont = (v, solver) -> (solver.failcont = fc; cont(v, solver))
    expCont(v, solver))

greedysome2 = special(3, 'greedysome', (solver, cont, exp, result, template) ->
  result1 = null
  someCont = (v, solver) ->
    result1.push(solver.trail.getvalue(template));
    [expCont, v, solver]
  expCont =  solver.cont(exp, someCont)
  (v, solver) ->
    result1 = [];
    fc = solver.failcont;
    solver.failcont = (v, solver) -> (solver.failcont = fc; result.bind(result1, solver.trail); cont(v, solver))
    expCont(v, solver))

# times: given times of exp, expectTimes should be integer or dao.Var <br/>
#  if @expectTimes is free dao.Var, then times behaviour like any(normal node).<br/>
#  result should be an dao.Var, and always be bound to the result array.<br/>
#  template: the item in reuslt array is getvalue(template)
exports.times = (exp, expectTimes, result, template) ->
  if not result then times1(exp, expectTimes)
  else times2(exp, expectTimes, result, template)

numberTimes1Fun = (solver, cont, exp, expectTimes) ->
  expectTimes = Math.floor(expectTimes)
  if expectTimes<0 then throw new ValueError(expectTimes)
  else if expectTimes is 0 then cont
  else if expectTimes is 1 then solver.cont(exp, cont)
  else if expectTimes is 2
    expCont = solver.cont(exp, cont)
    solver.cont(exp, expCont)
  else
    i = null
    expCont = solver.cont(exp, (v, solver) ->
      i++
      if i is expectTimes then cont(v, solver)
      else expCont(v, solver))
    (v, solver) -> i = 0; expCont(v, solver)

times1Fun = (solver, cont, exp, expectTimes) ->
  if _.isNumber(expectTimes) then numberTimes1Fun(solver, cont, exp, expectTimes)
  else
    expectTimes1 = i = null
    # caution:  like any, variable expectTimes may be 0!!!
    anyCont = (v, solver) ->
      fc = solver.failcont
      trail = solver.trail
      solver.trail = new dao.Trail
      state = solver.state
      solver.failcont = (v, solver) ->
        solver.trail.undo()
        solver.trail = trail
        solver.state = state
        solver.failcont = (v, solver) -> i--; fc(v, solver)
        expectTimes1.bind(i, solver.trail)
        cont(v, solver)
      [expCont, v, solver]
    expCont = solver.cont(exp, (v, solver) -> i++; anyCont(v, solver))
    solver.cont(expectTimes, (v, solver) ->
      expectTimes1 = v
      if _.isNumber(expectTimes1)
        numberTimes1Fun(solver, cont, exp, expectTimes1)(v, solver)
      else i = 0; anyCont(v, solver))

times1 = special(2, 'times', times1Fun)

numberTimes2Fun = (solver, cont, exp, expectTimes, result, template) ->
  expectTimes = Math.floor(expectTimes)
  if expectTimes<0 then throw new ValueError(expectTimes)
  else if expectTimes is 0 then (v, solver) -> result.bind([], solver.trail); cont(v, solver)
  else if expectTimes is 1 then solver.cont(exp, (v, solver) ->
    result.bind([solver.trail.getvalue(template)], solver.trail);
    cont(v, solver))
  else if expectTimes is 2
    result1 = []
    expCont = solver.cont(exp, (v, solver) ->
      result1.push solver.trail.getvalue(template)
      result.bind(result1, solver.trail);
      cont(v, solver))
    solver.cont(exp, (v, solver) ->
      result1.push solver.trail.getvalue(template)
      expCont(v, solver))
  else
    result1 = i = null
    expCont = solver.cont(exp, (v, solver) ->
      i++
      result1.push solver.trail.getvalue(template)
      if i is expectTimes then result.bind(result1, solver.trail); cont(v, solver)
      else expCont(v, solver))
    (v, solver) -> i = 0;  result1 = []; expCont(v, solver)

times2Fun = (solver, cont, exp, expectTimes, result, template) ->
  if _.isNumber(expectTimes) then numberTimes2Fun(solver, cont, exp, expectTimes, result, template)
  else
    result1 = expectTimes1 = i = null
    anyCont = (v, solver) ->
      fc = solver.failcont
      trail = solver.trail
      solver.trail = new dao.Trail
      state = solver.state
      solver.failcont = (v, solver) ->
        solver.trail.undo()
        solver.trail = trail
        solver.state = state
        solver.failcont = (v, solver) -> i--; result1.pop(); fc(v, solver)
        expectTimes1.bind(i, solver.trail);
        cont(v, solver)
      [expCont, v, solver]
    expCont = solver.cont(exp, (v, solver) -> i++; result1.push solver.trail.getvalue(template); anyCont(v, solver))
    solver.cont(expectTimes, (v, solver) ->
      expectTimes1= v
      if _.isNumber(expectTimes1) then numberTimes2Fun(solver, cont, exp, expectTimes1, result, template)(v, solver)
      else i = 0; result1 = []; result.bind(result1, solver.trail); anyCont(v, solver))

times2 = special(4, 'times', times2Fun)

# seplist: sep separated exp, expectTimes should be integer or dao.Var <br/>
#  at least one exp is matched.<br/>
#  if expectTimes is free dao.Var, then seplist behaviour like some(normal node).<br/>
#  result should be an dao.Var, and always be bound to the result array.<br/>
#  template: the item in reuslt array is getvalue(template)
exports.seplist = (exp, options={}) ->
  # one or more exp separated by sep
  sep = options.sep or char(' ');
  expectTimes = options.times or null
  result = options.result or null;
  template = options.template or null

  vari = dao.vari
  succeed = logic.succeed; andp = logic.andp; bind = logic.bind; is_ = logic.is_
  freep = logic.freep; ifp = logic.ifp; prependFailcont = logic.prependFailcont
  list = general.list; push = general.push; pushp = general.pushp
  one = lisp.one; inc = general.inc; sub = general.sub; getvalue = general.getvalue

  if expectTimes is null
    if result is null
      andp(exp, any(andp(sep, exp)))
    else
       andp(bind(result, []), exp, pushp(result, getvalue(template)),
                  any(andp(sep, exp, pushp(result, getvalue(template)))))
  else if _.isNumber(expectTimes)
    expectTimes = Math.floor Math.max 0, expectTimes
    if result is null
      switch expectTimes
        when 0 then succeed
        when 1 then exp
        else andp(exp, times(andp(sep, exp), expectTimes-1))
    else
      switch expectTimes
        when 0 then bind(result, [])
        when 1 then andp(exp, bind(result, list(getvalue(template))))
        else andp(bind(result, []), exp, pushp(result,getvalue(template)),
                  times(andp(sep, exp, pushp(result, getvalue(template))), expectTimes-1))
  else
    n = vari('n')
    i = vari('i')
    if result is null
       ifp(freep(expectTimes), andp(exp, one(i); any(andp(sep, exp,inc(i))), bind(expectTimes, i))
           andp(exp, is_(n, sub(expectTimes, 1)), times(andp(sep, exp), n)))
    else
      andp(bind(result, []),
           ifp(freep(expectTimes),
               andp(exp, one(i),
                    push(result,getvalue(template)),
                    any(andp(sep, exp, push(result, getvalue(template)),inc(i), prependFailcont(() -> result.binding.pop(); i.binding--))),
                    bind(expectTimes, i))
               andp(exp,
                    pushp(result,getvalue(template)),
                    is_(n, sub(expectTimes, 1)),
                    times(andp(sep, exp, pushp(result,getvalue(template))),n))))

# char: match one char  <br/>
#  if x is char or bound to char, then match that given char with next<br/>
#  else match with next char, and bound x to it.
exports.char = special(1, 'char', (solver, cont, x) ->  (v, solver) ->
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

# followChar: follow given char? <br/>
#  x should be char or be bound to char, then match that given char
  
exports.followChar = special(1, 'followChar', (solver, cont, x) -> (v, solver) ->
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

# notFollowChar: not follow given char? <br/>
#  x should be char or be bound to char, then match that given char
  
exports.notFollowChar = special(1, 'notfollowChar', (solver, cont, x) -> (v, solver) ->
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

# followChars: follow one of given chars?  <br/>
#  chars should be string or be bound to char, then match that given char
  
exports.followChars = special(1, 'followChars', (solver, cont, chars) -> (v, solver) ->
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

# notFollowChars: not follow one of given chars? <br/>
#  chars should be string or be bound to char, then match that given char
  
exports.notFollowChars = special(1, 'notFollowChars', (solver, cont, chars) -> (v, solver) ->
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

# charWhen: next char pass @test? <br/>
#  @test should be an function with single argument
  
exports.charWhen = special(1, 'charWhen', (solver, cont, test) -> (v, solver) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(false, solver)
  c = data[pos]
  if test(c) then solver.state = [data, pos+1]; cont(c, solver)
  else solver.failcont(c, solver))

exports.charBetween = (x, start, end) -> exports.charWhen(x, (c) -> start<c<end)
exports.charIn = (x, set) -> exports.charWhen((c) ->  c in x)
# theses terminal should be used directly, NO suffix with ()
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

# spaces: one or more spaces(' ') <br/>
#usage: spaces # !!! NOT spaces()
exports.spaces = special(0, 'spaces', (solver, cont) -> (v, solver) ->
  [data, pos] = solver.state
  length = data.length
  if pos>=length then return solver.failcont(false, solver)
  c = data[pos]
  if c isnt ' ' then return solver.failcont(c, solver)
  p = pos+1
  while p< length and data[p] is ' ' then p++
  solver.state = [data, p]
  cont(p-pos, solver))()

# spaces0: zero or more spaces(' ') <br/>
#usage: spaces0 # !!! NOT spaces0()
exports.spaces0 = special(0, 'spaces', (solver, cont) -> (v, solver) ->
  [data, pos] = solver.state
  length = data.length
  if pos>=length then return cont(0, solver)
  c = data[pos]
  if c isnt ' ' then return cont(c, solver)
  p = pos+1
  while p< length and data[p] is ' ' then p++
  solver.state = [data, p]
  cont(p-pos, solver))()

# stringWhile: match a string, every char in the string should pass test <br/>
# test: a function with single argument <br/>
#  the string should contain on char at least.
exports.stringWhile = special(1, 'stringWhile', (solver, cont, test) -> (v, solver) ->
  [data, pos] = solver.state
  length = data.length
  if pos is length then return solver.failcont(false, solver)
  c = data[pos]
  unless test(c) then return solver.failcont(c, solver)
  p = pos+1
  while p<length and test(data[p]) then p++
  solver.state = [data, p]
  cont(data[pos...p], solver))

exports.stringBetween = (start, end) -> exports.stringWhile((c) -> start<c<end)
exports.stringIn = (set) -> exports.stringWhile((c) ->  c in set)
# theses terminal should be used directly, NO suffix with ()
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

#stringWhile0: match a string, every char in it passes test <br/>
# test: a function with single argument <br/>
#  the string can be empty string.
exports.stringWhile0 = special(1, 'stringWhile0', (solver, cont, test) -> (v, solver) ->
  [data, pos] = solver.state
  length = data.length
  if pos is length then return cont('', solver)
  c = data[pos]
  unless test(c) then return cont('', solver)
  p = pos+1
  while p<length and test(data[p]) then p++
  solver.state = [data, p]
  cont(data[pos...p], solver))

exports.stringBetween0 = (start, end) -> exports.stringWhile0((c) -> start<c<end)
exports.stringIn0 = (set) -> exports.stringWhile0((c) ->  c in set)
# theses terminal should be used directly, NO suffix with ()
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

# float: match a number, which can be float format..<br/>
#  if arg is free dao.Var, arg would be bound to the number <br/>
#  else arg should equal to the number.
exports.float = special(1, 'float', (solver, cont, arg) -> (v, solver) ->
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
  arg = solver.trail.deref(arg)
  value =  eval(text[pos:p])
  if (arg instanceof Var)
    arg.bind(value, solver.trail)
    solver.state = [data, p]
    cont(value, solver)
  else
    if _.isNumber(arg)
      if arg is value then solver.state = [data, p]; cont(arg, solver)
      else solver.failcont(v, solver)          s
    else throw new exports.TypeError(arg))

#literal: match given literal arg,  <br/>
# arg is a string or a var bound to a string.
exports.literal = special(1, 'literal', (solver, cont, arg) -> (v, solver) ->
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

#followLiteral: follow  given literal arg<br/>
# arg is a string or a var bound to a string. <br/>
#solver.state is restored after match.
exports.followLiteral = special(1, 'followLiteral', (solver, cont, arg) -> (v, solver) ->
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

#notFollowLiteral: not follow  given literal arg,  <br/>
# arg is a string or a var bound to a string. <br/>
#solver.state is restored after match.
exports.notFollowLiteral = special(1, 'followLiteral', (solver, cont, arg) -> (v, solver) ->
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

#quoteString: match a quote string quoted by quote, quote can be escapedby \
exports.quoteString = special(1, 'quoteString', (solver, cont, quote) -> (v, solver) ->
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
  solver.state = [data, p]
  cont(string, solver))

#dqstring： double quoted string "..." <br/>
#usage: dqstring  #!!! not dqstring()
dqstring = exports.quoteString('"')
#sqstring： single quoted string '...' <br/>
#usage: sqstring  #!!! not sqstring()
sqstring = exports.quoteString("'")

# todo: memo parse result <br/>
# todo: left recursive nonterminal(memo could be useful to implement this)
