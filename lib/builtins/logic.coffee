# #### logic builtins
_ = require('underscore')
{ArgumentError} = core = require "../core"
il = require "../interlang"
general = require "./general"

# prepend fun() before compiler.failcont
exports.prependFailcont = special(1, 'setFailcont', (compiler, cont, fun) -> (v) ->
  fc = compiler.failcont
  compiler.failcont = (v) ->
    fun();
    fc(v)
  cont(v))

exports.unifyListFun = unifyListFun = (compiler, cont, xs, ys) ->  (v) ->
  xlen = xs.length
  if ys.length isnt xlen then compiler.failcont(false)
  else for i in [0...xlen]
    if not compiler.trail.unify(xs[i], ys[i]) then return compiler.failcont(false)
  cont(true)

# unify two lists 
exports.unifyList = unifyList = special(2, 'unifyList', unifyListFun)

exports.notunifyListFun = notunifyListFun = (compiler, cont, xs, ys) ->  (v) ->
  xlen = xs.length
  if ys.length isnt xlen then compiler.failcont(false)
  else for i in [0...xlen]
    if compiler.trail.unify(xs[i], ys[i]) then return compiler.failcont(false)
  cont(true)

exports.notunifyList = notunifyList = special(2, 'notunifyList', notunifyListFun)

# todo: optimize by using arity and the signature for rules which has many clauses <br/>
# todo: database rules manipulation: abolish, assert, retract

#   rule((arguments) ->   <br/>
#  [head1, body1, <br/>
#   head2, body2, <br/>
#   ...         <br/>
#  else_]) <br/>
  # the rule's argument should be a function, <br/>
  # which return a array, which conains the rule's clauses <br/>
  # rule's clause is composed of head and body. <br/>
  # rule head will be unified with the arguments.<br/>
#  if the length of args is odd number, then the last clause is the else_ clause, <br/>
# which has not rule head, has only rule body that will always be run. <br/>
#  !!! empty clauses means succeed. <br/>
# if fails is need, rule((args..)->[fail]) should be ok.

exports.rule = (arity, name, fun) ->
  unless fun? then (fun = name; name = 'noname_rule')
  macro(arity, name, (args...) ->
    clauses = fun(args...)
    length = clauses.length
    if length==0 then return succeed
    result = for i in [0...length-1]  by 2
      head = clauses[i]
      body = clauses[i+1]
      andp(unifyList(head, args), body)
    if length-Math.floor(length/2)*2==1 then result.push(clauses[length-1])
    orp(result...))

# used by callcc and callfc
runner = (compiler, cont) -> (v) ->
  while not compiler.done then [cont, v] = cont(v)
  compiler.done = false
  return v

# borrowed from lisp, same as in lisp.coffee  <br/>
# callfc(someFunction(fc) -> body) <br/>
#current compiler.failcont can be captured in someFunction
{callfc} = require("./lisp")
exports.callfc = callfc

# if x is true then succeed, else fail 
exports.truep = special(1, 'truep', (compiler, cont, x) ->
  compiler.cont(x, (x1) ->
    if x1 then cont(x1)
    else compiler.failcont(x1)))

# if x is false then succeed, else fail 
exports.falsep = special(1, 'falsep', (compiler, cont, x) ->
  compiler.cont(x, (x1) ->
    if not x1 then cont(x1)
    else compiler.failcont(x1)))

# if fun(x) is true then succeed, else fail 
exports.unaryPredicate = unaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(1, name, (compiler, cont, x) ->
    compiler.cont(x, (x1) ->
      result = fun(x1)
      if result then cont(result)
      else compiler.failcont(result)))

# if fun(x, y) is true then succeed, else fail  
exports.binaryPredicate = binaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(2, name, (compiler, cont, x, y) ->
    x1 = null
    ycont =  compiler.cont(y,  (y1) ->
      result = fun(x1, y1)
      if result then cont(result)
      else compiler.failcont(result)
    compiler.cont(x, (v) -> x1 = v; ycont(null))))

  # == != < <= > >=: if false then fail.
exports.eqp = binaryPredicate((x, y) -> x is y)
exports.nep = binaryPredicate((x, y) -> x isnt y)
exports.ltp = binaryPredicate((x, y) -> x < y)
exports.lep = binaryPredicate((x, y) -> x <= y)
exports.gtp = binaryPredicate((x, y) -> x > y)
exports.gep = binaryPredicate((x, y) -> x >= y)

# if fun(x, y, z) is true then succeed, else fail  
exports.ternaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(3, name, (compiler, cont, x, y, z) ->
    zcont = compiler.cont(z,  (z) ->
      result = fun(x, y, z)
      if result then cont(result)
      else compiler.failcont(result))
    ycont = compiler.cont(y,  (v) -> y = v; zcont(null)
    compiler.cont(x, (v) -> x = v; ycont(null))))

# if fun(args...) is true then succeed, else fail 
exports.functionPredicate = (arity, name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(arity, name, (compiler, cont, args...) ->
    compiler.argsCont(args, (params) ->
      result = fun(params...)
      if result then cont(result)
      else compiler.failcont(result)))

# like "between" in prolog <br/>
#if y is number and x<=y<=z then succeed, else fail <br/>
#if y is Var, then try all branch by binding y with integer between x and y
exports.between = special(3, 'between', (compiler, cont, fun, x, y, z) ->
  y1 = z1 = null
  zcont = compiler.cont(z,  (zz) ->
    if x1 instanceof core.Var then throw new  core.TypeError(x)
    else if y1 instanceof core.Var then throw new core.TypeError(y)
    if y1 instanceof core.Var
      y11 = y1
      fc = compiler.failcont
      compiler.failcont = (v) ->
        y11++
        if y11>z1 then fc(v)
        else y1.bind(y11, compiler.trail); cont(y11)
      y1.bind(y11, compiler.trail); cont(y11)
    else
      if (x1<=y1<=z1) then cont(true)
      else compiler.failcont(false))
  ycont = compiler.cont(y,  (v) -> y1 = v; zcont(null))
  compiler.cont(x, (v) -> x1 = v; ycont(null)))

# try all branch by returning integer between x and y 
exports.rangep = special(2, 'rangep', (compiler, cont, x, y) ->
  # select all of values between x and y as choices
  x1 = null
  ycont = compiler.cont(y,  (y) ->
    if x1 instanceof core.Var then throw new core.TypeError(x)
    else if y1 instanceof core.Var then throw new core.TypeError(y)
    else if x1>y1 then return compiler.failcont(false)
    result = x1
    fc = compiler.failcont
    compiler.failcont = (v) ->
      result++
      if result>y1 then fc(v)
      else cont(result)
    cont(result))
  compiler.cont(x, (v) -> x1 = v; ycont(null)))

# if x is Var then succeed else fail 
exports.varp = special(1, 'varp', (compiler, cont, x) ->
   compiler.cont(x, (x1) ->
     if (x1 instanceof core.Var) then cont(true)
     else compiler.failcont(false)))

# if x is NOT Var then succeed else fail 
exports.nonvarp = special(1, 'notvarp', (compiler, cont, x) ->
  compiler.cont(x, (x1) ->
    if (x1 not instanceof core.Var) then cont(true)
    else compiler.failcont(false)))

#  if x is Var and is bound to itself then succeed else fail 
exports.freep = special(1, 'freep', (compiler, cont, x) ->
# x is a free variable?
 (v) ->
   if compiler.trail.deref(x) instanceof Var then cont(true)
   else compiler.failcont(false))

#  if x is number then succeed else fail 
exports.numberp = special(1, 'numberp', (compiler, cont, x) ->
  compiler.cont(x, (x1) ->
  if _.isNumber(x1) then cont(true)
  else compiler.failcont(false)))

#  if x is String then succeed else fail 
exports.stringp = special(1, 'stringp', (compiler, cont, x) ->
  compiler.cont(x, (x1) ->
  if _.isString(x1) then cont(true)
  else compiler.failcont(false)))

#  if x is String or Number then succeed else fail 
exports.atomp = special(1, 'atomp', (compiler, cont, x) ->
  compiler.cont(x, (x1) ->
  if _.isNumber(x1) or _.isString(x1) then cont(true)
  else compiler.failcont(false)))

#  if x is Array then succeed else fail 
exports.listp = special(1, 'listp', (compiler, cont, x) ->
  compiler.cont(x, (x1) ->
  if _.isArray(x1) then cont(true)
  else compiler.failcont(false)))

#  if x is callable then succeed else fail 
exports.callablep = special(1, 'callablep', (compiler, cont, x) ->
  compiler.cont(x, (x1) ->
  if x1 instanceof core.Apply then cont(true)
  else compiler.failcont(false)))
