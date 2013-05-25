# #### logic builtins
solve = require "../dao"

special = solve.special
macro = solve.macro
Trail = solve.Trail
Var = solve.Var

exports.succeed = special(0, 'succeed', (solver, cont) -> cont)()

exports.fail = special(0, 'fail', (solver, cont) -> (v, solver) -> solver.failcont(v, solver))()

# prepend fun() before solver.failcont 
exports.prependFailcont = special(1, 'setFailcont', (solver, cont, fun) -> (v, solver) ->
  fc = solver.failcont
  solver.failcont = (v, solver) ->
    fun();
    fc(v, solver)
  cont(v, solver))

# same as lisp.begin, aka "," in prolog 
exports.andp = special(null, 'andp', (solver, cont, args...) -> solver.expsCont(args, cont))

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
  orcont = (v, solver) ->
    trail.undo()
    solver.state = state
    solver.failcont = fc
    [ycont, v, solver]
  (v, solver) ->
    trail = new Trail
    state = solver.state
    fc = solver.failcont
    solver.trail = trail
    solver.failcont = orcont
    [xcont, null, solver]

# logic choices, aka ";" in prolog 
exports.orp = special(null, 'orp', orpFun)

#  make the goal x cutable 
exports.cutable = special(1, 'cutable', (solver, cont, x) ->
  cc = null
  xcont = solver.cont(x, (v, solver) -> solver.cutCont = cc; [cont, v, solver])
  (v, solver) -> cc = solver.cutCont;  xcont null, solver)

# prolog's cut, aka "!"
exports.cut = special(0, 'cut', (solver, cont) -> (v, solver) ->
  solver.failcont = solver.cutCont
  cont(v, solver))()

# prolog's if, aka ->
#  different from lisp.if_
exports.ifp = special([2,3], 'ifp', (solver, cont, test, action, else_) ->
  #if -> Then; _Else :- If, !, Then.<br/>
  #If -> _Then; Else :- !, Else.<br/>
  #If -> Then :- If, !, Then
  cc = null
  ccCont = (v, solver) -> solver.cutCont = cc; cont(v, solver)
  actionCont = solver.cont(action, ccCont)
  resultCont = solver.cont(test, (v, solver) ->
    # add cut after test, try test only once
    solver.failcont = solver.cutCont
    actionCont(v, solver))
  if else_?
    elseCont =  solver.cont(else_, ccCont)
    (v, solver) ->
      # at first: make ifp cutable
      cc = solver.cutCont
      trail = new Trail
      state = solver.state
      fc = solver.failcont
      solver.failcont = (v, solver) ->
        trail.undo()
        solver.state = state
        solver.failcont = (v, solver) -> solver.failcont = fc; fc(v, solver)
        elseCont(v, solver)
      resultCont(v, solver)
  else
    (v, solver) ->
      cc = solver.cutCont
      resultCont(v, solver))

# like in prolog, failure as negation. 
exports.notp = special(1, 'notp', (solver, cont, x) ->
  fc = null
  mycont = solver.cont(x, (v, solver) ->
    solver.failcont = fc
    [fc, v, solver])
  (v, solver) ->
    trail = solver.trail
    solver.trail = new Trail
    fc = solver.failcont
    state = solver.state
    solver.failcont = (v, solver) ->
      solver.trail.undo()
      solver.trail = trail
      solver.state = state
      solver.failcont = fc
      [cont, v, solver]
    mycont(v, solver))

# aka repeat in prolog 
exports.repeat = special(0, 'repeat', (solver, cont) ->
  (v, solver) -> solver.failcont = cont; [cont, null, solver])()

# find all solution to the goal @exp in prolog  
exports.findall = special(1, 'findall', (solver, cont, exp) ->
  fc = null
  findnext = solver.cont(exp, (v, solver) -> solver.failcont(v, solver))
  findallDone = (v, solver) -> ( solver.failcont = fc; [cont, v, solver])
  (v, solver) -> (fc = solver.failcont; solver.failcont = findallDone; [findnext, v, solver]))

# find only one solution to the goal @x  
exports.once = special(1, 'once', (solver, cont, x) ->
  fc = null
  cont1 = solver.cont(x, (v, solver) -> (solver.failcont = fc; cont(v, solver)))
  (v, solver) -> fc = solver.failcont; [cont1, null, solver])

# evaluate @exp and bind it to vari 
exports.is_ = special(2, 'is_', (solver, cont, vari, exp) ->
  # different from assign in lisp.coffee:  <br/>
  # by using vari.bind, this is saved in solver.trail<br/>
  # and can be restored in solver.failcont
  solver.cont(exp, (v, solver) ->  vari.bind(v, solver.trail); [cont, true, solver]))

exports.bind = special(2, 'bind', (solver, cont, vari, term) ->
  # different from is_, do not evaluate the exp instead. <br/>
  # by using vari.bind, this is saved in solver.trail <br/>
  # and can be restored in solver.failcont
  (v, solver) ->  vari.bind(term, solver.trail); [cont, true, solver])

#todo: provide unify function as the third argument
exports.unifyFun = unifyFun = (solver, cont, x, y) -> (v, solver) ->
  if solver.trail.unify(x, y) then cont(true, solver)
  else solver.failcont(false, solver)

# unify two items. 
exports.unify = special(2, 'unify', unifyFun)

exports.notunifyFun = notunifyFun = (solver, cont, x, y) -> (v, solver) ->
  if not solver.trail.unify(x, y) then cont(true, solver)
  else solver.failcont(false, solver)

# to prove two items can NOT be unified 
exports.notunify = special(2, 'notunify', notunifyFun)

exports.unifyListFun = unifyListFun = (solver, cont, xs, ys) ->  (v, solver) ->
  xlen = xs.length
  if ys.length isnt xlen then solver.failcont(false, solver)
  else for i in [0...xlen]
    if not solver.trail.unify(xs[i], ys[i]) then return solver.failcont(false, solver)
  cont(true, solver)

# unify two lists 
exports.unifyList = unifyList = special(2, 'unifyList', unifyListFun)

exports.notunifyListFun = notunifyListFun = (solver, cont, xs, ys) ->  (v, solver) ->
  xlen = xs.length
  if ys.length isnt xlen then solver.failcont(false, solver)
  else for i in [0...xlen]
    if solver.trail.unify(xs[i], ys[i]) then return solver.failcont(false, solver)
  cont(true, solver)

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

# borrowed from lisp, same as in lisp.coffee  <br/>
# todo: need a trampoline for running the current continuation until done or faildone
exports.callfc = special(1, 'callfc', (solver, cont, fun) -> (v, solver) ->
                         result = fun(solver.failcont)[1]
                         solver.done = false
                         cont(result, solver))

# if x is true then succeed, else fail 
exports.truep = special(1, 'truep', (solver, cont, fun, x) ->
  solver.cont(x, (x1, solver) ->
    if x1 then cont(x1, solver)
    else solver.failcont(x1, solver)))

# if x is false then succeed, else fail 
exports.falsep = special(1, 'falsep', (solver, cont, fun, x) ->
  solver.cont(x, (x1, solver) ->
    if not x1 then cont(x1, solver)
    else solver.failcont(x1, solver)))

# if fun(x) is true then succeed, else fail 
exports.unaryPredicate = unaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(1, name, (solver, cont, x) ->
    solver.cont(x, (x1, solver) ->
      result = fun(x1)
      if result then cont(result, solver)
      else solver.failcont(result, solver)))

# if fun(x, y) is true then succeed, else fail  
exports.binaryPredicate = binaryPredicate = (name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(2, name, (solver, cont, x, y) ->
    x1 = null
    ycont =  solver.cont(y,  (y1, solver) ->
      result = fun(x1, y1)
      if result then cont(result, solver)
      else solver.failcont(result, solver)
    solver.cont(x, (v, solver) -> x1 = v; ycont(null, solver))))

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
    zcont = solver.cont(z,  (z, solver) ->
      result = fun(x, y, z)
      if result then cont(result, solver)
      else solver.failcont(result, solver))
    ycont = solver.cont(y,  (v, solver) -> y = v; zcont(null, solver)
    solver.cont(x, (v, solver) -> x = v; ycont(null, solver))))

# if fun(args...) is true then succeed, else fail 
exports.functionPredicate = (arity, name, fun) ->
  unless fun? then (fun = name; name = 'noname')
  special(arity, name, (solver, cont, args...) ->
    solver.argsCont(args, (params, solver) ->
      result = fun(params...)
      if result then cont(result, solver)
      else solver.failcont(result, solver)))

# like "between" in prolog <br/>
#if y is number and x<=y<=z then succeed, else fail <br/>
#if y is Var, then try all branch by binding y with integer between x and y
exports.between = special(3, 'between', (solver, cont, fun, x, y, z) ->
  y1 = z1 = null
  zcont = solver.cont(z,  (zz, solver) ->
    if x1 instanceof dao.Var then throw dao.TypeError(x)
    else if y1 instanceof dao.Var then throw new dao.TypeError(y)
    if y1 instanceof dao.Var
      y11 = y1
      fc = solver.failcont
      solver.failcont = (v, solver) ->
        y11++
        if y11>z1 then fc(v, solver)
        else y1.bind(y11, solver.trail); cont(y11, solver)
      y1.bind(y11, solver.trail); cont(y11, solver)
    else
      if (x1<=y1<=z1) then cont(true, solver)
      else solver.failcont(false, solver))
  ycont = solver.cont(y,  (v, solver) -> y1 = v; zcont(null, solver))
  solver.cont(x, (v, solver) -> x1 = v; ycont(null, solver)))

# try all branch by returning integer between x and y 
exports.rangep = special(2, 'rangep', (solver, cont, x, y) ->
  # select all of values between x and y as choices
  x1 = null
  ycont = solver.cont(y,  (y, solver) ->
    if x1 instanceof dao.Var then throw dao.TypeError(x)
    else if y1 instanceof dao.Var then throw new dao.TypeError(y)
    else if x1>y1 then return solver.failcont(false, solver)
    result = x1
    fc = solver.failcont
    solver.failcont = (v, solver) ->
      result++
      if result>y1 then fc(v, solver)
      else cont(result, solver)
    cont(result, solver))
  solver.cont(x, (v, solver) -> x1 = v; ycont(null, solver)))

# if x is Var then succeed else fail 
exports.varp = special(1, 'varp', (solver, cont, x) ->
   solver.cont(x, (x1, solver) ->
     if (x1 instanceof dao.Var) then cont(true, solver)
     else solver.failcont(false, solver)))

# if x is NOT Var then succeed else fail 
exports.nonvarp = special(1, 'notvarp', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
    if (x1 not instanceof dao.Var) then cont(true, solver)
    else solver.failcont(false, solver)))

#  if x is Var and is bound to itself then succeed else fail 
exports.freep = special(1, 'freep', (solver, cont, x) ->
# x is a free variable?
 (v, solver) ->
   if solver.trail.deref(x) instanceof Var then cont(true, solver)
   else solver.failcont(false, solver))

#  if x is number then succeed else fail 
exports.numberp = special(1, 'numberp', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
  if _.isNumber(x1) then cont(true, solver)
  else solver.failcont(false, solver)))

#  if x is String then succeed else fail 
exports.stringp = special(1, 'stringp', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
  if _.isString(x1) then cont(true, solver)
  else solver.failcont(false, solver)))

#  if x is String or Number then succeed else fail 
exports.atomp = special(1, 'atomp', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
  if _.isNumber(x1) or _.isString(x1) then cont(true, solver)
  else solver.failcont(false, solver)))

#  if x is Array then succeed else fail 
exports.listp = special(1, 'listp', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
  if _.isArray(x1) then cont(true, solver)
  else solver.failcont(false, solver)))

#  if x is callable then succeed else fail 
exports.callablep = special(1, 'callablep', (solver, cont, x) ->
  solver.cont(x, (x1, solver) ->
  if x1 instanceof dao.Apply then cont(true, solver)
  else solver.failcont(false, solver)))
