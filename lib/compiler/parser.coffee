# ### parser builtins

# dao's solver have no special demand on solver'state, so we can develop any kind of parser command, to parse different kind of object, such as array, sequence, list, binary stream, tree, even any other general object, not limit to text. <br/>

# parser builtins can be used by companion with any other builtins and user command.<br/>

# logic var can be used in parser as parameter, parameterize grammar is the unique feature of dao.<br/>

# Similar to develop parser, dao can be as the base to develop a generator. We can also generate stuff at th same time of parsing.

_ = require('underscore')

{Trail, Var,  ExpressionError, TypeError} = require "./solve"
{special} = require "../core"

# ####parser control/access

# parse, setstate, getstate have no demand on solver.state <br/> <br/>
# parsesequence/parsetext, setsequence/settext, getsequence/gettext, getpos, step, lefttext, next: demand that solver.state should look like [sequence, index], and sequence can be indexed by integer. index is an integer.<br/><br/>
# lefttext, subtext, eoi, boi demand that sequence should have length property  <br/><br/>
# eol, boil demand that sequence should be an string.

# #### general predicate

defaultPureHash = (name, caller, args...) -> (name or caller.name) + args.join(',')

exports.purememo = (caller, name='', hash=defaultPureHash) ->
  if not _.isString(name) then hash  = name; name = '';
  special(null, 'purememo', (solver, cont, args...) ->
    hashValue = hash(name, caller, args...)
    if hashValue is undefined then solver.cont(caller(args...), cont)
    else
      fromCont = solver.cont(caller(args...), (v) -> solver.finished = true; [cont, v])
      (v) ->
        if solver.purememo.hasOwnProperty(hashValue) then cont(solver.purememo[hashValue])
        else
          result = [newCont, v] = solver.run(null, fromCont)
          solver.finished = false
          solver.purememo[hashValue] =  v
          result
       )

exports.clearPureMemo = special(0, 'clearPureMemo', (solver, cont) ->
  (v) -> solver._memoPureResult = {}; cont(v))()

defaultHash = (name, solver, caller, args...) -> (name or caller.name)+solver.state[1]

exports.memo = (caller, name='', hash=defaultHash) ->
  if not _.isString(name) then hash  = name; name = '';
  special(null, name, (solver, cont, args...) ->
    (v) ->
      hashValue = hash(name, solver, caller, args...)
      if hashValue is undefined then solver.cont(caller(args...), cont)
      else
        fromCont = solver.cont(caller(args...), (v) -> solver.finished = true; [cont, v])
        if solver.memo.hasOwnProperty(hashValue)
          [result, solver.state[1]] = solver.memo[hashValue]
          cont(result)
        else
          result = [newCont, v]  = solver.run(null, fromCont)
          solver.finished = false
          solver.memo[hashValue] =  [v, solver.state[1]]
          result
    )

exports.clearmemo = special(0, 'clearmemo', (solver, cont) ->
  (v) -> solver.memo = {}; cont(v))()

parallelFun = (solver, cont, state, args) ->
  length = args.length
  if length is 0 then cont
  else if length is 1 then solver.cont(args[0], cont)
  else
    leftCont = parallelFun(solver, cont, state, args[1...])
    solver.cont(args[0], (v) ->
      solver.state = state
      leftCont(v))

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
    adjustCont =  (v) ->
      if checkParallel(solver.state, right) then cont(v)
      else solver.failcont(v)
    ycont = parallelFun(solver, adjustCont, state, y)
    xcont = solver.cont(x,  (v) ->
      right = solver.state
      solver.state = state
      ycont(v))
    xcont)

# times: given times of exp, expectTimes should be integer or core.Var <br/>
#  if @expectTimes is free core.Var, then times behaviour like any(normal node).<br/>
#  result should be an core.Var, and always be bound to the result array.<br/>
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
    expCont = solver.cont(exp, (v) ->
      i++
      if i is expectTimes then cont(v)
      else expCont(v))
    (v) -> i = 0; expCont(v)

times1Fun = (solver, cont, exp, expectTimes) ->
  if _.isNumber(expectTimes) then numberTimes1Fun(solver, cont, exp, expectTimes)
  else
    expectTimes1 = i = null
    # caution:  like any, variable expectTimes may be 0!!!
    anyCont = (v) ->
      fc = solver.failcont
      trail = solver.trail
      solver.trail = new core.Trail
      state = solver.state
      solver.failcont = (v) ->
        solver.trail.undo()
        solver.trail = trail
        solver.state = state
        solver.failcont = (v) -> i--; fc(v)
        expectTimes1.bind(i, solver.trail)
        cont(v)
      [expCont, v]
    expCont = solver.cont(exp, (v) -> i++; anyCont(v))
    solver.cont(expectTimes, (v) ->
      expectTimes1 = v
      if _.isNumber(expectTimes1)
        numberTimes1Fun(solver, cont, exp, expectTimes1)(v)
      else i = 0; anyCont(v))

times1 = special(2, 'times', times1Fun)

numberTimes2Fun = (solver, cont, exp, expectTimes, result, template) ->
  expectTimes = Math.floor(expectTimes)
  if expectTimes<0 then throw new ValueError(expectTimes)
  else if expectTimes is 0 then (v) -> result.bind([], solver.trail); cont(v)
  else if expectTimes is 1 then solver.cont(exp, (v) ->
    result.bind([solver.trail.getvalue(template)], solver.trail);
    cont(v))
  else if expectTimes is 2
    result1 = []
    expCont = solver.cont(exp, (v) ->
      result1.push solver.trail.getvalue(template)
      result.bind(result1, solver.trail);
      cont(v))
    solver.cont(exp, (v) ->
      result1.push solver.trail.getvalue(template)
      expCont(v))
  else
    result1 = i = null
    expCont = solver.cont(exp, (v) ->
      i++
      result1.push solver.trail.getvalue(template)
      if i is expectTimes then result.bind(result1, solver.trail); cont(v)
      else expCont(v))
    (v) -> i = 0;  result1 = []; expCont(v)

times2Fun = (solver, cont, exp, expectTimes, result, template) ->
  if _.isNumber(expectTimes) then numberTimes2Fun(solver, cont, exp, expectTimes, result, template)
  else
    result1 = expectTimes1 = i = null
    anyCont = (v) ->
      fc = solver.failcont
      trail = solver.trail
      solver.trail = new core.Trail
      state = solver.state
      solver.failcont = (v) ->
        solver.trail.undo()
        solver.trail = trail
        solver.state = state
        solver.failcont = (v) -> i--; result1.pop(); fc(v)
        expectTimes1.bind(i, solver.trail);
        cont(v)
      [expCont, v]
    expCont = solver.cont(exp, (v) -> i++; result1.push solver.trail.getvalue(template); anyCont(v))
    solver.cont(expectTimes, (v) ->
      expectTimes1= v
      if _.isNumber(expectTimes1) then numberTimes2Fun(solver, cont, exp, expectTimes1, result, template)(v)
      else i = 0; result1 = []; result.bind(result1, solver.trail); anyCont(v))

times2 = special(4, 'times', times2Fun)

# seplist: sep separated exp, expectTimes should be integer or core.Var <br/>
#  at least one exp is matched.<br/>
#  if expectTimes is free core.Var, then seplist behaviour like some(normal node).<br/>
#  result should be an core.Var, and always be bound to the result array.<br/>
#  template: the item in reuslt array is getvalue(template)
exports.seplist = (exp, options={}) ->
  # one or more exp separated by sep
  sep = options.sep or char(' ');
  expectTimes = options.times or null
  result = options.result or null;
  template = options.template or null

  vari = core.vari
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
exports.char = (solver, x) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var
    x.bind(c, solver.trail)
    solver.state = [data, pos+1]
    pos+1
  else if x is c then (solver.state = [data, pos+1]; pos+1)
  else if _.isString(x)
    if x.length==1 then solver.failcont(pos)
    else throw new ExpressionError(x)
  else throw new TypeError(x)

# followChar: follow given char? <br/>
#  x should be char or be bound to char, then match that given char
exports.followChar = (solver, x) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var then throw new TypeError(x)
  else if x is c then pos
  else if _.isString(x)
    if x.length==1 then solver.failcont(pos)
    else throw new ValueError(x)
  else throw new TypeError(x)

# notFollowChar: not follow given char? <br/>
#  x should be char or be bound to char, then match that given char
exports.notFollowChar =(solver, x) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var then throw new TypeError(x)
  else if x is c then solver.failcont(pos)
  else if _.isString(x)
    if x.length==1 then pos
    else throw new ValueError(x)
  else throw new TypeError(x)

# followChars: follow one of given chars?  <br/>
#  chars should be string or be bound to char, then match that given char
exports.followChars = (solver, chars) ->
  # follow one of char in chars
  chars = trail.deref(chars)
  if chars instanceof Var then throw new TypeError(chars)
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  trail = solver.trail
  c = data[pos]
  if c in chars then pos
  else if not _.isString(chars)
    throw new TypeError(chars)
  else solver.failcont(pos)

# notFollowChars: not follow one of given chars? <br/>
#  chars should be string or be bound to char, then match that given char
exports.notFollowChars = (solver, chars) ->
  # not follow one of char in chars
  chars = trail.deref(chars)
  if chars instanceof Var then throw new TypeError(chars)
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  trail = solver.trail
  c = data[pos]
  if c in chars then solver.failcont(pos)
  else if not _.isString(chars)
    throw new TypeError(chars)
  else cont(pos)

# charWhen: next char pass @test? <br/>
#  @test should be an function with single argument
exports.charWhen = (solver, test) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  c = data[pos]
  if test(c) then solver.state = [data, pos+1]; pos
  else solver.failcont(pos)

# spaces: one or more spaces(' ') <br/>
#usage: spaces # !!! NOT spaces()
exports.spaces = (solver) ->
  [data, pos] = solver.state
  length = data.length
  if pos>=length then return solver.failcont(pos)
  c = data[pos]
  if c isnt ' ' then return solver.failcont(pos)
  p = pos+1
  while p< length and data[p] is ' ' then p++
  solver.state = [data, p]
  p

# spaces0: zero or more spaces(' ') <br/>
#usage: spaces0 # !!! NOT spaces0()
exports.spaces0 = (solver) ->
  [data, pos] = solver.state
  length = data.length
  if pos>=length then return pos
  c = data[pos]
  if c isnt ' ' then return pos
  p = pos+1
  while p< length and data[p] is ' ' then p++
  solver.state = [data, p]
  pos

# stringWhile: match a string, every char in the string should pass test <br/>
# test: a function with single argument <br/>
#  the string should contain on char at least.
exports.stringWhile = (solver, test) ->
  [data, pos] = solver.state
  length = data.length
  if pos is length then return solver.failcont(pos)
  c = data[pos]
  unless test(c) then return solver.failcont(pos)
  p = pos+1
  while p<length and test(data[p]) then p++
  solver.state = [data, p]
  data[pos...p]

#stringWhile0: match a string, every char in it passes test <br/>
# test: a function with single argument <br/>
#  the string can be empty string.
exports.stringWhile0 = (solver, test) ->
  [data, pos] = solver.state
  length = data.length
  if pos is length then return ''
  c = data[pos]
  unless test(c) then return ''
  p = pos+1
  while p<length and test(data[p]) then p++
  solver.state = [data, p]
  data[pos...p]

# float: match a number, which can be float format..<br/>
#  if arg is free core.Var, arg would be bound to the number <br/>
#  else arg should equal to the number.
exports.number = exports.float = (solver, arg) ->
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  p = pos
  if text[p]=='+' or text[p]=='-' then p++
  if p>=length then return solver.failcont(p)
  dot = false
  if text[p]=='.' then (dot = true; p++)
  if p>=length or text[p]<'0' or '9'<text[p] then return solver.failcont(p)
  p++
  while p<length and '0'<=text[p]<='9' then p++
  if not dot
    if p<length and text[p]=='.' then p++
    while p<length and '0'<=text[p]<='9' then p++
  if p<length-1 and text[p] == 'e' or text[p] == 'E'
    p++
    pE = p
    if p<length and (text[p]=='+' or text[p]=='-') then p++
    if p>=length or text[p]<'0' or '9'<text[p] then p = pE-1
    else while p<length and '0'<=text[p]<='9' then p++
  arg = solver.trail.deref(arg)
  value =  eval(text[pos...p])
  if (arg instanceof Var)
    arg.bind(value, solver.trail)
    solver.state = [text, p]
    p
  else
    if _.isNumber(arg)
      if arg is value then solver.state = [text, p]; p
      else solver.failcont(pos)
    else throw new TypeError(arg)

#literal: match given literal arg,  <br/>
# arg is a string or a var bound to a string.
exports.literal = (solver, arg) ->
  arg = solver.trail.deref(arg)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  i = 0
  p = pos
  length2 = arg.length
  while i<length2 and p<length and arg[i] is text[p] then i++; p++
  if i is length2
    solver.state = [text, p]
    p
  else solver.failcont(p)

#followLiteral: follow  given literal arg<br/>
# arg is a string or a var bound to a string. <br/>
#solver.state is restored after match.
exports.followLiteral = (solver, arg) ->
  arg = solver.trail.deref(arg)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  i = 0
  p = pos
  length2 = arg.length
  while i<length2 and p<length and arg[i] is text[p] then i++; p++
  if i is length2 then p
  else solver.failcont(p)

#notFollowLiteral: not follow  given literal arg,  <br/>
# arg is a string or a var bound to a string. <br/>
#solver.state is restored after match.
exports.notFollowLiteral = (solver, arg) ->
  arg = solver.trail.deref(arg)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  i = 0
  p = pos
  length2 = arg.length
  while i<length2 and p<length and arg[i] is text[p] then i++; p++
  if i is length2 then solver.failcont(p)
  else p

#quoteString: match a quote string quoted by quote, quote can be escapedby \
exports.quoteString = (solver, quote) ->
  string = ''
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  quote = solver.trail.deref(quote)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  if text[pos]!=quote then return solver.failcont(pos)
  p = pos+1
  while p<length
    char = text[p]
    p++
    if char=='\\' then p++
    else if char==quote
      string = text[pos+1...p]
      break
  if p is length then return solver.failcont(p)
  solver.state = [text, p]
  string

# fsm, for keywords

# todo: memo parse result: partial completed <br/>
# var and unify need to be thinked more.
# todo: left recursive nonterminal(memo could be useful to implement this)
