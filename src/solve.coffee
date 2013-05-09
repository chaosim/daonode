dao = exports

class dao.NoSolution
  constructor: (@exp) ->
  toString: () -> @exp.toString()

class dao.Solutions
  constructor: (@exp, @solutions) ->
  next: () -> @solutions.next()

class dao.Bindings
  getitem:  (vari) -> @[vari] or vari
  setitem: (vari, value) -> @[vari] = value
  detitem: (vari) -> delete @[vari]
  copy: () -> new dao.Bindings(_.clone(@))
  deref: (exp) -> if exp.deref? then exp.deref(@) else exp
  get_value: (exp, memo, bindings) -> if exp.getvalue? then exp.deref(@, memo, bindings) else exp

class dao.LogicVar
  constructor: (@name) ->

  deref: (bindings) ->
    # todo:
    # how to shorten the binding chain? need to change solver.fail_cont.
    # deref(solver) can help
    while 1
      next = bindings.getitem(@)
      if not isinstance(next, LogicVar) or next is @
        return next
      else next

  getvalue: (memo, bindings) ->
    if memo.hasOwnProperty(@) then  memo[@]
    else
      result = @deref(bindings)
      if isinstance(result, LogicVar)
        memo[@] = result
        result
      if result.getvalue? then result.getvalue(memo, bindings)
      else
        memo[@] = result
        result

  unify: (x, y, solver) ->
    solver.bindings[x] = y
    true

  __eq__: (x, y) -> x.constructor is y.constructor and x.name==y.name
  __hash__: () ->  hash(@name)
  toString: () ->  "%s"%@name

class dao.DummyVar extends dao.LogicVar
  deref: (bindings) -> @

class dao.Cons
  constructor: (@head, @tail) ->

  unify: (other, solver) ->
    if @constructor isnt  other.constructor
      return solver.fail_cont.callOn(false)
    if solver.unify(@head, other.head)
      if solver.unify(@tail, other.tail)
        return true
    return solver.fail_cont.callOn(false)

  match: (other) ->
    if @constructor isnt  other.constructor then return false
    return match(@head, other.head) and match(@tail, other.tail)

  unify_rule_head: (other, env, subst) ->
    if @constructor isnt  other.constructor then return
    for _ in unify_rule_head(@head, other.head, env, subst)
      for _ in unify_rule_head(@tail, other.tail, env, subst)
        pyyield true

  copy_rule_head: (env) ->
    head = copy_rule_head(@head, env)
    tail = copy_rule_head(@tail, env)
    if head==@head and tail==@tail then return @
    Cons(head, tail)

  getvalue: (memo, env) ->
    head = get_value(@head, memo, env)
    tail = get_value(@tail, memo, env)
    return Cons(head, tail)

  take_value: (env) ->
    head = take_value(@head, env)
    tail = take_value(@tail, env)
    if head==@head and tail==@tail then return @
    return Cons(head, tail)

  copy: (memo) ->  Cons(copy(@head, memo), copy(@tail, memo))

  closure: (env) ->
    head = closure(@head, env)
    tail = closure(@tail, env)
    if head==@head and tail==@tail
      return @
    return Cons(head, tail)

  __eq__: (other) -> @constructor is other.constructor and @head is other.head and @tail is other.tail

  __iter__: () ->
    tail = @
    while 1
      pyyield tail.head
      if tail.tail is nil then return
      else if isinstance(tail.tail, Cons)
        tail = tail.tail
      else
        pyyield tail.tail
        return
  length: () ->  (e for e in @).length
  toString: () ->  "L(#{join(' ', [e for e in @])})"

cons = (head, tail) -> new dao.Cons head, tail

class dao.Nil
  alpha: (env, compiler) -> new il.Nil()
  length: () ->  0
  __iter__: () -> if 0 then pyyield
  toString: () ->  'nil'

dao.nil = new dao.Nil()

dao.conslist = (elements...) ->
  result = nil
  for term in reversed(elements)
    result = new dao.Cons(term, result)
  result

dao.cons2tuple = (item) ->
  if not isinstance(item, Cons) and not isinstance(item, Array)
     item
  else (cons2tuple(x) for x in item)

class dao.UnquoteSplice
  constructor: (Qitem) ->
  toString: () ->  ",@#{@item}"

class dao.ExpressionWithCode
  constructor: (@exp, @fun) ->
  __eq__: (x, y) ->  (x.constructor is y.constructor and x.exp==y.exp) or x.exp==y
  __iter__ = () ->  iter(@exp)
  toString: () -> @exp.toString()

class dao.Macro

class dao.MacroFunction extends dao.Macro
  constructor: (@fun) ->
  callOn:(args...) ->  @fun(args...)

class dao.MacroRules extends dao.Macro
  constructor: (@fun) ->
  callOn: (args...) -> @fun(args...)
  default_end_cont: (v) -> throw new dao.NoSolution(v)

class dao.Solver
  constructor: () ->
    @bindings = new dao.Bindings() # for logic variable, unify
    @parse_state = undefined
    @catch_cont_map = {}
    @cut_cont = @cut_or_cont = @fail_cont = default_end_cont

  unify: (x, y) ->
    x = deref(x, @bindings)
    y = deref(y, @bindings)
    try  x_unify = x.unify
    catch e
      try  y_unify = y.unify
      catch e
        if x is y then return true
      return @fail_cont.callOn(false)
    return y_unify(x, @)
    return x_unify(y, @)

  find_catch_cont: (tag) ->
    try cont_stack = @catch_cont_map[tag]
    catch e then throw new dao.UncaughtThrow(tag)
    cont_stack.pop()
