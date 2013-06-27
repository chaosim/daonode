# #### logic builtins
{ArgumentError} = core = require "../core"

special = core.special
macro = core.macro
Trail = core.Trail
Var = core.Var

exports.succeed = special(0, 'succeed', (solver, cont) -> cont)()

exports.fail = special(0, 'fail', (solver, cont) -> (v) -> solver.failcont(v))()

# prepend fun() before solver.failcont 
exports.prependFailcont = special(1, 'setFailcont', (solver, cont, fun) -> (v) ->
  fc = solver.failcont
  solver.failcont = (v) ->
    fun();
    fc(v)
  cont(v))

# same as lisp.begin, aka "," in prolog 
exports.andp = andp = special(null, 'andp', (solver, cont, args...) -> solver.expsCont(args, cont))

orpFun = (solver, cont, args...) ->
  length = args.length
  if length is 0 then throw new ArgumentError(args)
  else if length is 1 then return solver.cont(args[0], cont)
  else if length is 2
    x = args[0]
    y = args[1]
    xcont = solver.cont(x, cont)
    ycont = solver.cont(y, cont)
  else
    x = args[0]
    y = args[1...]
    xcont = solver.cont(x, cont)
    ycont = orpFun(solver, cont, y...)
  trail = state = fc = null
  orcont = (v) ->
    trail.undo()
    solver.state = state
    solver.failcont = fc
    [ycont, v]
  (v) ->
    trail = new Trail
    state = solver.state
    fc = solver.failcont
    solver.trail = trail
    solver.failcont = orcont
    [xcont, null]

# logic choices, aka ";" in prolog 
exports.orp = orp = special(null, 'orp', orpFun)

#  make the goal x cutable 
exports.cutable = special(1, 'cutable', (solver, cont, x) ->
  cc = null
  xcont = solver.cont(x, (v) -> solver.cutCont = cc; [cont, v])
  (v) -> cc = solver.cutCont;  xcont null)

# prolog's cut, aka "!"
exports.cut = special(0, 'cut', (solver, cont) -> (v) ->
  solver.failcont = solver.cutCont
  cont(v))()

# prolog's if, aka ->
#  different from lisp.if_
exports.ifp = special([2,3], 'ifp', (solver, cont, test, action, else_) ->
  #if -> Then; _Else :- If, !, Then.<br/>
  #If -> _Then; Else :- !, Else.<br/>
  #If -> Then :- If, !, Then
  cc = null
  ccCont = (v) -> solver.cutCont = cc; cont(v)
  actionCont = solver.cont(action, ccCont)
  resultCont = solver.cont(test, (v) ->
    # add cut after test, try test only once
    solver.failcont = solver.cutCont
    actionCont(v))
  if else_?
    elseCont =  solver.cont(else_, ccCont)
    (v) ->
      # at first: make ifp cutable
      cc = solver.cutCont
      trail = new Trail
      state = solver.state
      fc = solver.failcont
      solver.failcont = (v) ->
        trail.undo()
        solver.state = state
        solver.failcont = (v) -> solver.failcont = fc; fc(v)
        elseCont(v)
      resultCont(v)
  else
    (v) ->
      cc = solver.cutCont
      resultCont(v))

# like in prolog, failure as negation. 
exports.notp = special(1, 'notp', (solver, cont, x) ->
  fc = null
  mycont = solver.cont(x, (v) ->
    solver.failcont = fc
    [fc, v])
  (v) ->
    trail = solver.trail
    solver.trail = new Trail
    fc = solver.failcont
    state = solver.state
    solver.failcont = (v) ->
      solver.trail.undo()
      solver.trail = trail
      solver.state = state
      solver.failcont = fc
      [cont, v]
    mycont(v))

# aka repeat in prolog 
exports.repeat = special(0, 'repeat', (solver, cont) ->
  (v) -> solver.failcont = cont; [cont, null])()

# update(0.1.11) findall get result by template
exports.findall = (exp, result, template) ->
  if result is undefined then findall1(exp)
  else findall2(exp, result, template)

# find all solution to the goal @exp in prolog  
findall1 = special(1, 'findall', (solver, cont, exp) ->
  fc = null
  findnext = solver.cont(exp, (v) -> solver.failcont(v))
  findallDone = (v) -> ( solver.failcont = fc; [cont, v])
  (v) -> (fc = solver.failcont; solver.failcont = findallDone; [findnext, v]))

# update(0.1.11) findall get result by template
findall2 = special(3, 'findall', (solver, cont, exp, result, template) ->
  result1 = null; fc = null
  findnext = solver.cont(exp, (v) ->
    result1.push(solver.trail.getvalue(template));
    solver.failcont(v))
  findallDone = (v) -> ( solver.failcont = fc; [cont, v])
  (v) ->
    result1 = []
    result.bind(result1, solver.trail)
    fc = solver.failcont
    solver.failcont = findallDone
    [findnext, v])

# find only one solution to the goal @x
exports.once = special(1, 'once', (solver, cont, x) ->
  fc = null
  cont1 = solver.cont(x, (v) -> (solver.failcont = fc; cont(v)))
  (v) -> fc = solver.failcont; [cont1, null])

# evaluate @exp and bind it to vari 
exports.is_ = special(2, 'is_', (solver, cont, vari, exp) ->
  # different from assign in lisp.coffee:  <br/>
  # by using vari.bind, this is saved in solver.trail<br/>
  # and can be restored in solver.failcont
  solver.cont(exp, (v) ->  vari.bind(v, solver.trail); [cont, true]))

exports.bind = special(2, 'bind', (solver, cont, vari, term) ->
  # different from is_, do not evaluate the exp instead. <br/>
  # by using vari.bind, this is saved in solver.trail <br/>
  # and can be restored in solver.failcont
  (v) ->  vari.bind(solver.trail.deref(term), solver.trail); [cont, true])

#todo: provide unify function as the third argument
exports.unifyFun = unifyFun = (solver, cont, x, y) -> (v) ->
  if solver.trail.unify(x, y) then cont(true)
  else solver.failcont(false)

# unify two items. 
exports.unify = special(2, 'unify', unifyFun)

exports.notunifyFun = notunifyFun = (solver, cont, x, y) -> (v) ->
  if not solver.trail.unify(x, y) then cont(true)
  else solver.failcont(false)

# to prove two items can NOT be unified 
exports.notunify = special(2, 'notunify', notunifyFun)

exports.unifyListFun = unifyListFun = (solver, cont, xs, ys) ->  (v) ->
  xlen = xs.length
  if ys.length isnt xlen then solver.failcont(false)
  else for i in [0...xlen]
    if not solver.trail.unify(xs[i], ys[i]) then return solver.failcont(false)
  cont(true)

# unify two lists 
exports.unifyList = unifyList = special(2, 'unifyList', unifyListFun)

exports.notunifyListFun = notunifyListFun = (solver, cont, xs, ys) ->  (v) ->
  xlen = xs.length
  if ys.length isnt xlen then solver.failcont(false)
  else for i in [0...xlen]
    if solver.trail.unify(xs[i], ys[i]) then return solver.failcont(false)
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
runner = (solver, cont) -> (v) ->
  while not solver.done then [cont, v] = cont(v)
  solver.done = false
  return v

# borrowed from lisp, same as in lisp.coffee  <br/>
# callfc(someFunction(fc) -> body) <br/>
#current solver.failcont can be captured in someFunction
{callfc} = require("./lisp")
exports.callfc = callfc

# if x is true then succeed, else fail 
exports.truep = special(1, 'truep', (solver, cont, fun, x) ->
  solver.cont(x, (x1) ->
    if x1 then cont(x1)
    else solver.failcont(x1)))

# if x is false then succeed, else fail 
exports.falsep = special(1, 'falsep', (solver, cont, fun, x) ->
  solver.cont(x, (x1) ->
    if not x1 then cont(x1)
    else solver.failcont(x1)))

# if fun(x) is true then succeed, else fail 
exports.unaryPredicate = unaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(1, name, (solver, cont, x) ->
    solver.cont(x, (x1) ->
      result = fun(x1)
      if result then cont(result)
      else solver.failcont(result)))

# if fun(x, y) is true then succeed, else fail  
exports.binaryPredicate = binaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(2, name, (solver, cont, x, y) ->
    x1 = null
    ycont =  solver.cont(y,  (y1) ->
      result = fun(x1, y1)
      if result then cont(result)
      else solver.failcont(result)
    solver.cont(x, (v) -> x1 = v; ycont(null))))

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
  special(3, name, (solver, cont, x, y, z) ->
    zcont = solver.cont(z,  (z) ->
      result = fun(x, y, z)
      if result then cont(result)
      else solver.failcont(result))
    ycont = solver.cont(y,  (v) -> y = v; zcont(null)
    solver.cont(x, (v) -> x = v; ycont(null))))

# if fun(args...) is true then succeed, else fail 
exports.functionPredicate = (arity, name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(arity, name, (solver, cont, args...) ->
    solver.argsCont(args, (params) ->
      result = fun(params...)
      if result then cont(result)
      else solver.failcont(result)))

# like "between" in prolog <br/>
#if y is number and x<=y<=z then succeed, else fail <br/>
#if y is Var, then try all branch by binding y with integer between x and y
exports.between = special(3, 'between', (solver, cont, fun, x, y, z) ->
  y1 = z1 = null
  zcont = solver.cont(z,  (zz) ->
    if x1 instanceof core.Var then throw new core.TypeError(x)
    else if y1 instanceof core.Var then throw new core.TypeError(y)
    if y1 instanceof core.Var
      y11 = y1
      fc = solver.failcont
      solver.failcont = (v) ->
        y11++
        if y11>z1 then fc(v)
        else y1.bind(y11, solver.trail); cont(y11)
      y1.bind(y11, solver.trail); cont(y11)
    else
      if (x1<=y1<=z1) then cont(true)
      else solver.failcont(false))
  ycont = solver.cont(y,  (v) -> y1 = v; zcont(null))
  solver.cont(x, (v) -> x1 = v; ycont(null)))

# try all branch by returning integer between x and y 
exports.rangep = special(2, 'rangep', (solver, cont, x, y) ->
  # select all of values between x and y as choices
  x1 = null
  ycont = solver.cont(y,  (y) ->
    if x1 instanceof core.Var then throw new core.TypeError(x)
    else if y1 instanceof core.Var then throw new core.TypeError(y)
    else if x1>y1 then return solver.failcont(false)
    result = x1
    fc = solver.failcont
    solver.failcont = (v) ->
      result++
      if result>y1 then fc(v)
      else cont(result)
    cont(result))
  solver.cont(x, (v) -> x1 = v; ycont(null)))

# if x is Var then succeed else fail 
exports.varp = special(1, 'varp', (solver, cont, x) ->
   solver.cont(x, (x1) ->
     if (x1 instanceof core.Var) then cont(true)
     else solver.failcont(false)))

# if x is NOT Var then succeed else fail 
exports.nonvarp = special(1, 'notvarp', (solver, cont, x) ->
  solver.cont(x, (x1) ->
    if (x1 not instanceof core.Var) then cont(true)
    else solver.failcont(false)))

#  if x is Var and is bound to itself then succeed else fail 
exports.freep = special(1, 'freep', (solver, cont, x) ->
# x is a free variable?
 (v) ->
   if solver.trail.deref(x) instanceof Var then cont(true)
   else solver.failcont(false))

#  if x is number then succeed else fail 
exports.numberp = special(1, 'numberp', (solver, cont, x) ->
  solver.cont(x, (x1) ->
  if _.isNumber(x1) then cont(true)
  else solver.failcont(false)))

#  if x is String then succeed else fail 
exports.stringp = special(1, 'stringp', (solver, cont, x) ->
  solver.cont(x, (x1) ->
  if _.isString(x1) then cont(true)
  else solver.failcont(false)))

#  if x is String or Number then succeed else fail 
exports.atomp = special(1, 'atomp', (solver, cont, x) ->
  solver.cont(x, (x1) ->
  if _.isNumber(x1) or _.isString(x1) then cont(true)
  else solver.failcont(false)))

#  if x is Array then succeed else fail 
exports.listp = special(1, 'listp', (solver, cont, x) ->
  solver.cont(x, (x1) ->
  if _.isArray(x1) then cont(true)
  else solver.failcont(false)))

#  if x is callable then succeed else fail 
exports.callablep = special(1, 'callablep', (solver, cont, x) ->
  solver.cont(x, (x1) ->
  if x1 instanceof core.Apply then cont(true)
  else solver.failcont(false)))
