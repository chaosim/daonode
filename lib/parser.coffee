# ### parser builtins

# dao's solver have no special demand on solver'state, so we can develop any kind of parser command, to parse different kind of object, such as array, sequence, list, binary stream, tree, even any other general object, not limit to text. <br/>

# parser builtins can be used by companion with any other builtins and user command.<br/>

# logic var can be used in parser as parameter, parameterize grammar is the unique feature of dao.<br/>

# Similar to develop parser, dao can be as the base to develop a generator. We can also generate stuff at th same time of parsing.

{isInteger, isString, isArray, isNumber} = require("./util")

{Trail, Var,  ExpressionError, TypeError, SolverFail} = require "./solve"

# char: match one char  <br/>
#  if x is char or bound to char, then match that given char with next<br/>
#  else match with next char, and bound x to it.
exports.char = (solver, x, cont) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var
    x.bind(c, solver.trail)
    solver.state = [data, pos+1]
    cont(pos+1)
  else if x is c then (solver.state = [data, pos+1]; cont(pos+1))
  else if isString(x)
    if x.length==1 then return solver.failcont(pos)
    else throw new ExpressionError(x)
  else throw new TypeError(x)

# followChar: follow given char? <br/>
#  x should be char or be bound to char, then match that given char
exports.followChar = (solver, x, cont) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var then throw new TypeError(x)
  else if x is c then cont(pos)
  else if isString(x)
    if x.length==1 then return solver.failcont(pos)
    else throw new ValueError(x)
  else throw new TypeError(x)

# notFollowChar: not follow given char? <br/>
#  x should be char or be bound to char, then match that given char
exports.notFollowChar =(solver, x, cont) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  trail = solver.trail
  x = trail.deref(x)
  c = data[pos]
  if x instanceof Var then throw new TypeError(x)
  else if x is c then return solver.failcont(pos)
  else if isString(x)
    if x.length==1 then cont(pos)
    else throw new ValueError(x)
  else throw new TypeError(x)

# followChars: follow one of given chars?  <br/>
#  chars should be string or be bound to char, then match that given char
exports.followChars = (solver, chars, cont) ->
  # follow one of char in chars
  chars = trail.deref(chars)
  if chars instanceof Var then throw new TypeError(chars)
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  trail = solver.trail
  c = data[pos]
  if c in chars then cont(pos)
  else if not isString(chars)
    throw new TypeError(chars)
  else return solver.failcont(pos)

# notFollowChars: not follow one of given chars? <br/>
#  chars should be string or be bound to char, then match that given char
exports.notFollowChars = (solver, chars, cont) ->
  # not follow one of char in chars
  chars = trail.deref(chars)
  if chars instanceof Var then throw new TypeError(chars)
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  trail = solver.trail
  c = data[pos]
  if c in chars then return solver.failcont(pos)
  else if not isString(chars)
    throw new TypeError(chars)
  else cont(pos)

# charWhen: next char pass @test? <br/>
#  @test should be an function with single argument
exports.charWhen = (solver, test, cont) ->
  [data, pos] = solver.state
  if pos>=data.length then return solver.failcont(pos)
  c = data[pos]
  if test(c) then solver.state = [data, pos+1]; cont(pos)
  else return solver.failcont(pos)

# spaces: one or more spaces(' ') <br/>
#usage: spaces # !!! NOT spaces()
exports.spaces = (solver, cont) ->
  [data, pos] = solver.state
  length = data.length
  if pos>=length then return solver.failcont(pos)
  c = data[pos]
  if c isnt ' ' then return solver.failcont(pos)
  p = pos+1
  while p< length and data[p] is ' ' then p++
  solver.state = [data, p]
  cont(p)

# spaces0: zero or more spaces(' ') <br/>
#usage: spaces0 # !!! NOT spaces0()
exports.spaces0 = (solver, cont) ->
  [data, pos] = solver.state
  length = data.length
  if pos>=length then return pos
  c = data[pos]
  if c isnt ' ' then return pos
  p = pos+1
  while p< length and data[p] is ' ' then p++
  solver.state = [data, p]
  cont(pos)

# stringWhile: match a string, every char in the string should pass test <br/>
# test: a function with single argument <br/>
#  the string should contain on char at least.
exports.stringWhile = (solver, test, cont) ->
  [data, pos] = solver.state
  length = data.length
  if pos is length then return solver.failcont(pos)
  c = data[pos]
  unless test(c) then return solver.failcont(pos)
  p = pos+1
  while p<length and test(data[p]) then p++
  solver.state = [data, p]
  cont(data[pos...p])

#stringWhile0: match a string, every char in it passes test <br/>
# test: a function with single argument <br/>
#  the string can be empty string.
exports.stringWhile0 = (solver, test, cont) ->
  [data, pos] = solver.state
  length = data.length
  if pos is length then return ''
  c = data[pos]
  unless test(c) then return ''
  p = pos+1
  while p<length and test(data[p]) then p++
  solver.state = [data, p]
  cont(data[pos...p])

# float: match a number, which can be float format..<br/>
#  if arg is free core.Var, arg would be bound to the number <br/>
#  else arg should equal to the number.
exports.number = exports.float = (solver, cont) ->
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
  value =  eval(text[pos...p])
  if isNumber(value) then solver.state = [text, p]; cont(value)
  else return solver.failcont(pos)

#literal: match given literal arg,  <br/>
# arg is a string or a var bound to a string.
exports.literal = (solver, arg, cont) ->
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
    cont(p)
  else return solver.failcont(p)

#followLiteral: follow  given literal arg<br/>
# arg is a string or a var bound to a string. <br/>
#solver.state is restored after match.
exports.followLiteral = (solver, arg, cont) ->
  arg = solver.trail.deref(arg)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  i = 0
  p = pos
  length2 = arg.length
  while i<length2 and p<length and arg[i] is text[p] then i++; p++
  if i is length2 then cont(p)
  else return solver.failcont(p)

#notFollowLiteral: not follow  given literal arg,  <br/>
# arg is a string or a var bound to a string. <br/>
#solver.state is restored after match.
exports.notFollowLiteral = (solver, arg, cont) ->
  arg = solver.trail.deref(arg)
  if (arg instanceof Var) then throw new exports.TypeError(arg)
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  i = 0
  p = pos
  length2 = arg.length
  while i<length2 and p<length and arg[i] is text[p] then i++; p++
  if i is length2 then return solver.failcont(p)
  else cont(p)

#quoteString: match a quote string quoted by quote, quote can be escapedby \
exports.quoteString = (solver, cont) ->
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  quote = text[pos]
  if quote!="'" and quote!='"' then return solver.failcont(pos)
  p = pos+1
  while p<length
    char = text[p]
    p++
    if char=='\\' then p++
    else if char==quote
      solver.state = [text, p++]
      return cont(text[pos...p])
  return solver.failcont(p)

exports.identifier = (solver, cont) ->
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  c = text[pos]
  if not (c=='_' or 'a'<=c<='z' or 'A'<=c<='Z') then return solver.failcont(pos)
  p = pos+1
  while p<length and c=text[p] and (c=='_' or 'a'<=c<='z' or 'A'<=c<='Z' or '0'<=c<='9')
    p++
  solver.state = [text, p]
  cont(text[pos...p])
