_ = require "underscore"
fs = require "fs"
set = require( "f:/node-utils/src/set").set
dict = require( "f:/node-utils/src/utils").dict
il = require("interlang")

isinstance = (x, klass) -> (x instanceof klass)
assert = (arg,  message) -> unless arg then throw new dao.Error(message or '')
join = (sep, list) -> list.join(sep)

prelude = ''

dao = exports

dao.eval = (exp, env) ->  dao.solve(exp, env).next()

dao.solve = (exp, env, path) ->
  path = path or 'f:\\daonode\\test\\compiled.js'
  dao.compileToJSFile exp, env, path
  compiled = require(path)
  new dao.Solutions(exp, compiled.fun())

dao.compileToJSFile = (exp, path, env) ->
  path = path or "f:\\daonode\\test\\compiled.js"
  code = dao.compileToJavascript exp, env
  fs.writeSync fs.openSync(path, 'w'), code

dao.compileToJavascript = (exp, env) ->
  compiler = new dao.Compiler()
  exp = dao.element(exp)
  exp = exp.alpha(env, compiler)
  exp = exp.cps(compiler, compiler.cont)
  exp.analyse(compiler)
  #  exp = exp.optimize(new dao.Environment(), compiler)
  #exp = exp.tail_recursive_convert()
  exp = il.begin(exp.javascriptize(env, compiler)[0])
  if (exp instanceof il.Begin)
    exp = exp.statements[0]
  exp = new il.Lamda([], exp)
  exp.body = exp.body.replace_return_with_pyyield()
  exp = new il.Call(exp, new il.ConstLocalVar('this'))
  exp.to_code(compiler)
#  return prelude + result

class dao.BaseCommand

class dao.Exception

class dao.StopIteration extends dao.Exception

class dao.UncaughtThrow  extends dao.Exception
  constructor: (@tag) ->
  toString: () -> @tag

class dao.SyntaxError  extends dao.Exception

class dao.Error extends dao.Exception
  constructor: (@message) ->
  toString: () -> @message

class dao.CompileError extends dao.Exception

class dao.CompileTypeError  extends dao.CompileError
  constructor:(@exp) ->
  toString: () -> @exp.toString()

class dao.ArityError extends dao.CompileError

class dao.VariableNotBound extends dao.CompileError
  constructor:(@vari) ->
  toString: () -> @vari.toString()

class dao.NotImplemented extends dao.CompileError
  constructor:(@message) ->
  toString: () -> @message

class dao.Environment
  '''environment for compilation, in alpha convert, block/exit/continue'''
  constructor:(@outer) -> @bindings = {}
  extend: () -> Environment()

  getitem: (vari) ->
    try  return @bindings[vari]
    catch e
      result = @outer
      while result isnt undefined
        try return @bindings[vari]
        catch e then result = @outer
      throw new dao.VariableNotBound(vari)

  setitem: (vari, value) ->  @bindings[vari] = value

  toString: () ->
    result = ''
    while x isnt undefined
      result += @bindings.toString()
      x = @outer
    return result

class dao.Compiler
  constructor: (env = new dao.Environment(), options) ->
    options = options or {}

    @newvar_map = {} #{'name':index}

    @cont = options.done or new il.Done(@new_var(new il.ConstLocalVar('v')))
    # for code generation
    @language = options.language  or "javascript"
    @indent_space = options.indent_space or "  "

    # for block/exit/continue
    @block_label_stack = []
    @exit_block_cont_map = {}
    @next_block_cont_map = {}
    @continue_block_cont_map = {}  # huh, next_block_cont_map or this?
    @protect_cont = @cont

    # for optimization
    @ref_count = {} # vari's reference count
    @called_count = {} # lambda's reference count
    @occur_count = {}
    @recursive_call_path = []

    @lamda_stack = []
    @recusive_variables_stack = [set()]

  new_var: (vari) ->
    try
      suffix = str(@newvar_map[vari.name])
      @newvar_map[vari.name] += 1
      vari.constructor(vari.name+suffix)
    catch e
      @newvar_map[vari.name] = 1
      vari

  get_inner_block_label: () ->
    if @block_label_stack then @block_label_stack[-1][1]
    else throw new dao.BlockError("should not escape from top level outside of all block.")

  get_block_label: (old_label) ->
    for i in range(@block_label_stack.length)
      if old_label==@block_label_stack[-(i+1)][0]
        return @block_label_stack[-(i+1)][1]
      throw new dao.BlockError("Block %s is not found."%old_label)

  indent: (code, level=1) ->
    '''javascript's famous indent'''
    lines = code.split('\n')
    lines = (times_string(@indent_space, level) + line for line in lines)
    join('\n', lines)

times_string = (str, n) -> result = ''; result.concat str for i in [1..n]; result

MAX_EXTEND_CODE_SIZE = 10

import_names = []

register_fun = (name, fun) ->
  name = new_func_name(name)
  fun.func_name = name
  globals()[name] = fun
  import_names.append(name)
  fun

new_func_name_map = {}

new_func_name = (name) ->
  try
    suffix = str(new_func_name_map[name])
    new_func_name_map[name] += 1
    name+suffix
  catch e
    new_func_name_map[name] = 1
    name

dao.element = (exp)->
  if (exp instanceof dao.Element) then exp
  else
    try new dao.type_map[typeof(exp)](exp)
    catch e then throw new dao.CompileTypeError(exp)

class dao.Element

class dao.Atom extends dao.Element
  constructor: (@item) ->
  alpha: (env, compiler) -> @
  cps: (compiler, cont) ->  cont.callOn(@interlang())
  quasiquote: (compiler, cont) -> cont.callOn(@interlang())
  subst: (bindings) -> @
  interlang: ( ) -> new il.Atom(@item)
  equal: (x, y) ->  x.constructor is y.constructor and x.item==y.item
  to_code: (compiler) -> "#{@constructor.name}(#{@item})"
  toString: ( ) ->  "#{@item}"

class dao.Number extends dao.Atom
  equal: (x, y) -> Atom.equal(x, y) or (isinstance(y, int) and x.item==y)
  interlang: ( ) -> new il.Integer(@item)

number = (value) -> new dao.Number(value)

class dao.Integer extends dao.Number

dao.integer = (value) -> new dao.Integer(value)

class dao.Float extends dao.Atom
  equal: (x, y) -> Atom.equal(x, y) or (isinstance(y, float) and x.item==y)
  interlang: ( ) ->  new il.Float(@item)

dao.float = (value) -> new dao.Float(value)

class dao.String extends dao.Atom
  equal: (x, y) ->  Atom.equal(x, y) or (isinstance(y, str) and x.item==y)
  interlang: ( ) ->  new il.String(@item)

dao.string = (value) -> new dao.String(value)

class dao.List extends dao.Atom
  equal: (x, y) ->  Atom.equal(x, y) or (isinstance(y, list) and x.item==y)
  interlang: ( ) -> new il.List(@item)

dao.list = (value) -> new dao.List(value)

class dao.Dict extends dao.Atom
  equal: (x, y) ->  Atom.equal(x, y) or (isinstance(y, dict) and x.item==y)
  interlang: ( ) ->  new il.Dict(@item)

dao.dict = (value) -> new dao.Dict(value)

class dao.Bool extends dao.Atom
  equal: (x, y) ->  Atom.equal(x, y) or (isinstance(y, bool) and x.item==y)
  interlang: ( ) ->  new il.Bool(@item)

dao.bool = (value) -> new dao.Bool(value)

class dao.Symbol extends dao.Atom
  equal: (x, y) ->  classeq(x, y) and x.item==y.item
  interlang: ( ) ->  new il.Symbol(@item)

dao.symbol = (value) -> new dao.Symbol(value)

class dao.Klass extends dao.Atom
  toString: ( ) ->  "Klass(#{@item})"
  interlang: ( ) ->  new il.Klass(@item)

dao.klass = (value) -> new dao.Klass(value)

class dao.PyFunction extends dao.Atom
  toString: ( ) ->  "PyFunction(#{@item})"
  interlang: ( ) ->  new il.PyFunction(@item)

dao.pyfunction = (value) -> new dao.PyFunction(value)

dao.TRUE = new dao.Bool(true)
dao.FALSE = new dao.Bool(false)
dao.NULL = new dao.Atom(null)

dao.make_tuple = (value) -> new dao.Tuple((element(x) for x in value)...)

class dao.Tuple extends dao.Atom
  constructor: (items...)-> @item = items
  interlang: ( ) ->  new il.Tuple((x.interlang() for x in @item)...)
  to_code:  (compiler) -> "#{@constructor.name}(#{join(', ', [x for x in @item])})"
  __iter__: ( ) ->  iter(@item)
  toString: ( ) ->  "#{@constructor.name}(#{@item})"

dao.varialbe = (name) -> new dao.Var(name)

class dao.Var extends dao.Element
  constructor: (@name) ->
  callOn: (args...) -> Apply((element(arg) for arg in args))
  alpha: (env, compiler) -> env[@]
  subst: (bindings) ->
    try bindings[@]
    catch e then return @
  cps: (compiler, cont) -> cont.callOn(@interlang())
  cps_convert_unify: (x, y, compiler, cont) ->
    try y.cps_convert_unify
    catch e
      x = x.interlang()
      y = y.interlang()
      x1 = compiler.new_var(new il.ConstLocalVar(x.name))
      return il.begin(
                       new il.Assign(x1, new il.Deref(x)), #for LogicVar, could be optimized when generate code.
                       new il.If(il.IsLogicVar(x1),
                                 il.begin(il.SetBinding(x1, y),
                                          il.append_failcont.callOn(compiler, new il.DelBinding(x1)),
                                          cont.callOn(il.TRUE)),
                                 new il.If(il.Eq(x1, y), cont.callOn(il.TRUE), il.failcont.callOn(il.TRUE))))
    x = x.interlang()
    y = y.interlang()
    x1 = compiler.new_var(new il.ConstLocalVar(x.name))
    y1 = compiler.new_var(new il.ConstLocalVar(y.name))
    il.begin(
              new il.Assign(x1, new il.Deref(x)), #for LogicVar, could be optimized when generate code.
              new il.Assign(y1, new il.Deref(y)),
              new il.If(il.IsLogicVar(x1),
                        il.begin(il.SetBinding(x1, y1),
                                 il.append_failcont.callOn(compiler, new il.DelBinding(x1)),
                                 cont.callOn(il.TRUE)),
                        il.begin(
                                  new il.If(il.IsLogicVar(y1),
                                            il.begin(il.SetBinding(y1, x1),
                                                     il.append_failcont.callOn(compiler, new il.DelBinding(y1)),
                                                     cont.callOn(il.TRUE)),
                                            new il.If(il.Eq(x1, y1), cont.callOn(il.TRUE), il.failcont.callOn(il.TRUE))))))

  cps_call: (compiler, cont, args) ->
    # see The 90 minute Scheme to C compiler by Marc Feeley
    throw new dao.CompileTypeError(@)

    fun = compiler.new_var(new il.ConstLocalVar('fun'))
    vars = (compiler.new_var(new il.ConstLocalVar('a'+i)) for i in range(args.length))
    body = new il.Apply(fun, [cont]+vars)
    for var1, item in reversed(zip(vars, args))
      body = item.cps(compiler, il.clamda(var1, body))
      v = compiler.new_var(new il.ConstLocalVar('v'))
      macro_args1 = (il.ExpressionWithCode(arg, new il.Lamda([], arg.cps(compiler, il.clamda(v, v))))  for arg in args)
      macro_args2 = il.macro_args macro_args1
    @cps(compiler, il.clamda(fun,
                             new il.If(il.IsMacro(fun),
                                       new il.If(il.IsMacroRules(fun),
                                                 new il.Apply(fun, [cont, macro_args2]),
                                                 new il.Apply(fun, [cont]+macro_args1)),
                                       body)))

  interlang: ( ) ->  new il.Var(@name)
  free_vars: ( ) ->  set([@])
  to_code: (compiler) -> "DaoVar('#{@name}')"
  equal: (x, y) ->  classeq(x, y) and x.name==y.name
  hash: ( ) ->  hash(@name)
  toString: ( ) ->  "#{@constructor.name}('#{@name}')"

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

  equal: (x, y) -> x.constructor is y.constructor and x.name==y.name
  __hash__: () ->  hash(@name)
  toString: () ->  "%s"%@name

class dao.DummyVar extends dao.LogicVar
  deref: (bindings) -> @

class dao.Const extends dao.Var
  interlang: ( ) ->  new il.ConstLocalVar(@name)

class dao.LamdaVar extends dao.Var
  cps_call:(compiler, cont, args) ->
    #fun = compiler.new_var(new il.ConstLocalVar('fun'))
    fun = @interlang()
    vars = (compiler.new_var(new il.ConstLocalVar('a'+i))  for i in [0...args.length])
    body = new il.Apply(fun, [cont]+vars)
    for var1, item in reversed(zip(vars, args))
      body = item.cps(compiler, il.clamda(var1, body))
    v = compiler.new_var(new il.ConstLocalVar('v'))
    return @cps(compiler, il.clamda(fun,body))

class dao.MacroVar extends dao.Var
  cps_call:(compiler, cont, args) ->
    fun = @interlang()
    k = compiler.new_var(new il.ConstLocalVar('cont'))
    v = compiler.new_var(new il.ConstLocalVar('v'))
    #macro_args = (il.Lamda((), arg.cps(compiler, il.clamda(v, v)))
    #for arg in args)
    macro_args = (il.Lamda([k], arg.cps(compiler, k)) for arg in args)
    @cps(compiler, il.clamda(fun, new il.Apply(fun, [cont]+macro_args)))

class dao.ConstLamdaVar extends dao.LamdaVar #, Const)
  interlang: ( ) ->  new il.ConstLocalVar(@name)

class dao.ConstMacroVar extends dao.MacroVar #, Const):
  interlang: ( ) ->  new il.ConstLocalVar(@name)

class dao.RecursiveFunctionVar extends dao.ConstLamdaVar
  interlang: ( ) ->  new il.RecursiveVar(@name)

class dao.RecursiveMacroVar extends dao.ConstMacroVar
  interlang: ( ) ->  new il.RecursiveVar(@name)

class dao.LogicVar extends dao.Var
  alpha: (env, compiler) -> @
  interlang: ( ) ->  new il.LogicVar(@name)
  cps: (compiler, cont) -> cont.callOn(il.LogicVar(@name))
  to_code: (compiler) -> "dao.LogicVar('#{@name}')"
  equal: (x, y) ->  classeq(x, y) and x.name==y.name
  toString: ( ) ->  "dao.LogicVar('#{@name}')"

class dao.DummyVar extends dao.LogicVar
  interlang: ( ) ->  new il.DummyVar(@name)
  cps: (compiler, cont) -> cont.callOn(il.Deref(il.DummyVar(@name)))
  to_code: (compiler) -> "DaoDummyVar('#{@name}')"
  cons: (head, tail) -> Cons(element(head), element(tail))

class dao.Cons extends dao.Element
  constructor: (@head, @tail) ->

  alpha: (env, compiler) -> Cons(@head.alpha(env, compiler),  @tail.alpha(env, compiler))
  cps: (compiler, cont) -> cont.callOn(@interlang())
  interlang: ( ) ->  new il.Cons(@head.interlang(), @tail.interlang())
  cps_convert_unify: (x, y, compiler, cont) -> cps_convert_unify(x, y, compiler, cont)

  unify_rule_head: (other, env, subst) ->
    if @constructor isnt  other.constructor then return
    for _ in unify_rule_head(@head, other.head, env, subst)
      for _ in unify_rule_head(@tail, other.tail, env, subst)
        pyield true

  copy_rule_head: (env) ->
    head = copy_rule_head(@head, env)
    tail = copy_rule_head(@tail, env)
    if head==@head and tail==@tail then return @
    Cons(head, tail)

  getvalue: (env) ->
    head = getvalue(@head, env)
    tail = getvalue(@tail, env)
    if head is @head and tail is @tail then @
    else Cons(head, tail)

  copy: (memo) -> Cons(copy(@head, memo), copy(@tail, memo))
  equal: (other) -> @constructor is other.constructor and @head==other.head and @tail==other.tail

  __iter__: ( ) ->
    tail = @
    while 1
      pyield tail.head
      if tail.tail is nil then return
      else if isinstance(tail.tail, Cons)
        tail = tail.tail
      else
        pyield tail.tail
        return

  length: ( ) ->  (e for e in @).length
  toString: ( ) ->  "L(#{join(' ', [e for e in @])})"

class dao.Nil extends dao.Element
  alpha: (env, compiler) -> @
  interlang: ( ) ->  il.nil
  length: ( ) ->  0
  __iter__: ( ) -> if 0 then pyield
  toString: ( ) ->  'nil'

dao.nil = new dao.Nil()

dao.conslist = (elements...) ->
  result = nil
  for term in reversed(elements)
    result = Cons(element(term), result)
  return result

dao.cons2tuple = (item) ->
  if not isinstance(item, Cons) and not isinstance(item, Array)
    item
  cons2tuple(x) for x in item

cps_convert_unify_two_var = (x, y, compiler, cont) ->
  x = x.interlang()
  y = y.interlang()
  x1 = compiler.new_var(new il.ConstLocalVar(x.name))
  y1 = compiler.new_var(new il.ConstLocalVar(y.name))
  il.begin(
            new il.Assign(x1, new il.Deref(x)), #for LogicVar, could be optimized when generate code.
            new il.Assign(y1, new il.Deref(y)),
            new il.If(il.IsLogicVar(x1),
                      il.begin(il.SetBinding(x1, y1),
                               il.append_failcont.callOn(compiler, new il.DelBinding(x1)),
                               cont.callOn(il.TRUE)),
                      il.begin(
                                il.If(il.IsLogicVar(y1),
                                      il.begin(il.SetBinding(y1, x1),
                                               il.append_failcont.callOn(compiler, new il.DelBinding(y1)),
                                               cont.callOn(il.TRUE)),
                                      new il.If(il.Unify(x1, y1), cont.callOn(il.TRUE), il.failcont.callOn(il.TRUE))))))

cps_convert_unify_one_var = (x, y, compiler, cont) ->
  x = x.interlang()
  y = y.interlang()
  x1 = compiler.new_var(new il.ConstLocalVar(x.name))
  return il.begin(
                   new il.Assign(x1, new il.Deref(x)), #for LogicVar, could be optimized when generate code.
                   new il.If(il.IsLogicVar(x1),
                             il.begin(il.SetBinding(x1, y),
                                      il.append_failcont.callOn(compiler, new il.DelBinding(x1)),
                                      cont.callOn(il.TRUE)),
                             new il.If(new il.Unify(x1, y), cont.callOn(il.TRUE), il.failcont.callOn(il.TRUE))))

cps_convert_unify = (x, y, compiler, cont) ->
  if isinstance(x, Var)
    if isinstance(y , Var)
      return cps_convert_unify_two_var(x, y, compiler, cont)
    else
      return cps_convert_unify_one_var(x, y, compiler, cont)
  else
    if isinstance(y , Var)
      return cps_convert_unify_two_var(y, x, compiler, cont)
    else
      if isinstance(x , Cons) and isinstance(y , Cons)
        v = compiler.new_var(new il.ConstLocalVar('v'))
        return cps_convert_unify(x.head, y.head, compiler, il.clamda(v,
                                                                     cps_convert_unify(x.tail, y.tail, compiler, cont)))
      else
        if x==y then cont.callOn(il.TRUE)
        else il.failcont.callOn(il.FALSE)

class dao.Apply extends dao.Element
  constructor: (@caller, @args) ->
  alpha: (env, compiler) ->  new @constructor(@caller.alpha(env, compiler),  (arg.alpha(env, compiler) for arg in @args))
  # see The 90 minute Scheme to C compiler by Marc Feeley
  cps: (compiler, cont) ->  @caller.cps_call(compiler, cont, @args)
  subst: (bindings) -> new @constructor(@caller.subst(bindings),
                                        (arg.subst(bindings) for arg in @args))
  toString: ( ) ->  "#{@caller}(#{join(', ', [x for x in @args])})"

class dao.Command extends dao.Element
  constructor: (@fun, @args) ->
  subst: (bindings) -> new @constructor(@fun,  (arg.subst(bindings) for arg in @args))

  quasiquote:(compiler, cont) ->
    result = compiler.new_var(il.LocalVar('result'))
    vars = (compiler.new_var(new il.ConstLocalVar('a'+i)) for i in [0...@args])
    t = [new il.If(il.Isinstance(var1, new il.Klass('UnquoteSplice')),
                   new il.AddAssign(result, new il.Call(il.Symbol('list'), new il.Attr(var1, new il.Symbol('item')))),
                   new il.ListAppend(result, var1) ) for var1 in vars+[cont.callOn(il.Call(il.Klass(@constructor.name), new il.QuoteItem(@fun), new il.MakeTuple(result)))]]
    body = il.Assign(result, il.empty_list)+t
    fun = il.begin(body...)
    for var1, arg in reversed(zip(vars, @args))
      fun = arg.quasiquote(compiler, il.clamda(var1, fun))
    fun

  equal: (x, y) ->  classeq(x, y) and x.fun==y.fun and x.args==y.args
  toString: ( ) ->  "#{@fun}(#{join( ', ', [x for x in @args])})"

dao.special = (name, fun) ->
  (args...) -> new dao.Special(name, fun, dao.element x for x in args)

class dao.Special extends dao.Command
  constructor: (@name, @fun, @args) ->
  alpha: (env, compiler) -> new @constructor(@name, @fun, (arg.alpha(env, compiler) for arg in @args))
  cps: (compiler, cont) -> @fun(compiler, cont, @args...)
  to_code: (compiler) -> "#{@name}(#{join(', ', [x.to_code(compiler) for x in @args])})"
  free_vars: ( ) -> set.mergeAt( arg.free_vars() for arg in @args)
  toString: ( ) ->  "#{@name}(#{join(', ', (x for x in @args))})"

class dao.BuiltinFunction extends dao.Command
  constructor: (@name, @fun, @args) ->
  alpha:(env, compiler) -> new @constructor(@name, @fun, (arg.alpha(env, compiler) for arg in @args))

  cps:(compiler, cont) ->
    #see The 90 minute Scheme to C compiler by Marc Feeley
    args = @args
    vars = (compiler.new_var(new il.ConstLocalVar('a'+i)) for i in [0...args])
    fun = cont.callOn(@fun.fun(vars...))
    for var1, arg in reversed(zip(vars, args))
      fun = arg.cps(compiler, new il.Clamda(var1, fun))
    fun

# unquote to interlang level
  analyse: (compiler) ->
  optimize: (env, compiler) -> @
  interlang: ( ) ->  @
  free_vars: ( ) -> set.mergeAt( arg.free_vars() for arg in @args)
  javascriptize: (env, compiler) -> [@]
  to_code: (compiler) -> "#{@fun.name}(#{join(', ', [x.to_code(compiler) for x in @args])})"
  toString: ( ) ->  "#{@fun.name}(#{join(', ', [x.to_code(compiler) for x in @args])})"

dao.assign = (var1, exp) -> new dao.Assign(var1, element(exp))

class dao.MultiAssignToConstError
  constructor: (@const) ->
  toString: ( ) ->  @const.toString()

class dao.Assign extends dao.Command
  constructor: (@var1, @exp) ->
  subst: (bindings) -> Assign(@var1, @exp.subst(bindings))
  alpha: (env, compiler) ->
    try var1 = env[@var1]
    catch VariableNotBound
      env[@var1] = var1 = compiler.new_var(@var1)
      if isinstance(var1, Const)
        var1.assigned = true
        return Assign(var1, @exp.alpha(env, compiler))
    if isinstance(var1, Const) and var1.assigned
      throw new dao.MultiAssignToConstError(var1)
      dao.Assign(var1, @exp.alpha(env, compiler))

  cps: (compiler, cont) ->
    v = compiler.new_var(new il.ConstLocalVar('v'))
    @exp.cps(compiler, il.clamda(v, new il.Assign(@var1.interlang(), v), cont.callOn(v)))

  equal: (x, y) ->  classeq(x, y) and x.var1==y.var1 and x.exp==y.exp
  to_code: (compiler) ->  @.toString()
  toString: ( ) ->  "assign#{@var1}, #{@exp})"
  direct_interlang: (exps...) ->  DirectInterlang(il.begin(exps...))

class dao.DirectInterlang extends dao.Element
  constructor: (@body) ->
  alpha: (env, compiler) ->  @
  cps: (compiler, cont) ->  cont.callOn(@body)

  expression_with_code: (compiler, cont, exp) ->
    v = compiler.new_var(new il.ConstLocalVar('v'))
    cont.callOn(il.ExpressionWithCode(exp, new il.Lamda([], exp.cps(compiler, il.clamda(v, v)))))

dao.lamda = (params, body...) -> new dao.Lamda(params, dao.begin((element(x) for x in body)...))

class dao.Lamda extends dao.Element
  constructor: (@params, @body) ->
  equal: (x, y) -> classeq(x, y) and x.params==y.params and x.body==y.body
  toString: () -> "Lamda((#{', '.join(x for x in @params)}), #{@body}"
  make_new: (params, body) ->  new @constructor(params, body)
  callOn: (args...) -> dao.Apply((element(arg) for arg in args))

  alpha: (env, compiler) ->
    new_env = env.extend()
    for p in @params then new_env.bindings[p] = compiler.new_var(p)
    @params = (new_env[p] for p in @params)
    @body = @body.alpha(new_env, compiler)
    @variables = new_env.bindings.values()
    @

  has_cut: () -> has_cut(@body)

  cps: (compiler, cont)->
    k = compiler.new_var(new il.ConstLocalVar('cont'))
    params = (x.interlang() for x in @params)
    if @has_cut() then body = wrap_cut(@body).cps(compiler, k)
    else  body = @body.cps(compiler, k)
    cont(il.Lamda([k]+params, body))

  cps_call: (compiler, cont, args) ->
    # see The 90 minute Scheme to C compiler by Marc Feeley
    if @has_cut() then fun = wrap_cut(@body).cps(compiler, cont)
    else fun = @body.cps(compiler, cont)
    params = (x.interlang() for x in @params)
    for vari, arg in reversed(zip(params, args))
      fun = arg.cps(compiler, il.Clamda(vari, fun))
    fun

  interlang: () -> il.Lamda((x.interlang() for x in @params), @body.interlang())

dao.macro = (params, body...) -> dao.Macro(params, begin((element(x) for x in body)...))

#@special
dao.eval_macro_args = (compiler, cont, exp)->
  v = compiler.new_var(new il.ConstLocalVar('v'))
  il.Call(exp.interlang(), cont)
#return cont(il.Call(exp.interlang()))

class dao.Macro extends dao.Element
  constructor: (@arams, @body) ->
  equal: (x, y) -> classeq(x, y) and x.params==y.params and x.body==y.body
  toString: () ->  "Macro((#{join(', ', [x for x in @params])}), #{@body})"
  make_new: (params, body) ->  new @constructor(params, body)
  callOn: (args...) -> dao.Apply(element(arg) for arg in args)

  alpha: (env, compiler) ->
    new_env = env.extend()
    for p in @params
      new_env.bindings[p] = compiler.new_var(p)
    @params = new_env[p] for p in @params
    for vari, new_var in new_env.bindings.items()
      new_env.bindings[vari] = eval_macro_args(new_var)
    @body = @body.alpha(new_env, compiler)
    @

  has_cut: () -> has_cut(@body)

  cps: (compiler, cont) ->
    k = compiler.new_var(new il.ConstLocalVar('cont'))
    params = (x.interlang() for x in @params)
    if @has_cut()
      body = wrap_cut(@body).cps(compiler, k)
    else body = @body.cps(compiler, k)
    cont(il.Lamda([k]+params, body))

  cps_call: (compiler, cont, args) ->
    # see The 90 minute Scheme to C compiler by Marc Feeley
    if @has_cut()
      fun = wrap_cut(@body).cps(compiler, cont)
    else fun = @body.cps(compiler, cont)
    params = (x.interlang() for x in @params)
    for vari, arg in reversed(zip(params, args))
      k = compiler.new_var(new il.ConstLocalVar('cont'))
      fun = direct_interlang(il.Lamda([k], arg.cps(compiler, k))).cps(compiler, il.Clamda(vari, fun))
    return fun

  interlang: ()-> new il.Lamda((x.interlang() for x in @params), @body.interlang())

dao.let_ = (bindings, body...) ->
  bindings = [vari, element(value)] for vari, value in bindings
  new dao.Let(bindings, begin(body...))

class dao.Let extends dao.Element
  constructor: (@bindings, @body) ->

  alpha: (env, compiler) ->
    new_env = env.extend()
    for vari, value in @bindings
      if isinstance(value, Rules)
        if not isinstance(vari, Const)
          new_var = compiler.new_var(LamdaVar(vari.name))
        else new_var = compiler.new_var(ConstLamdaVar(vari.name))
      else if isinstance(value, Lamda)
        if not isinstance(vari, Const)
          new_var = compiler.new_var(LamdaVar(vari.name))
        else new_var = compiler.new_var(ConstLamdaVar(vari.name))
      else if isinstance(value, MacroRules)
        if not isinstance(vari, Const)
          new_var = compiler.new_var(MacroVar(vari.name))
        else new_var = compiler.new_var(ConstMacroVar(vari.name))
      else new_var = compiler.new_var(vari)
      if isinstance(vari, Const)
        new_var.assigned = false
      env[vari ]  = new_var
    alphaed_body = @body.alpha(new_env, compiler)
    assign_bindings = Assign(new_env[vari], value.alpha(env, compiler)) for vari, value in @bindings
    return begin(assign_bindings+[alphaed_body]...)

  subst:(bindings) ->
    bindings = [vari.subst(bindings), value.subst(bindings)] for vari, value in @bindings
    body = @body.subst(bindings)
    new dao.Let(bindings, body)

  toString: () -> "Let(#{@bindings}, #{@body})"

dao.letrec = (bindings, body...) ->
  new dao.Letrec(([element(vari), element(value)] for vari, value in bindings), begin((element(exp) for exp in body))...)

class dao.Letrec extends dao.Element
  constructor: (@bindings, @body) ->

  alpha: (env, compiler) ->
    new_env = env.extend()
    for vari, value in @bindings
      if isinstance(value, Rules)
        new_var = compiler.new_var(RecursiveFunctionVar(vari.name))
      else if isinstance(value, Lamda)
        new_var = compiler.new_var(RecursiveFunctionVar(vari.name))
      else if isinstance(value, Macro)
        new_var = compiler.new_var(RecursiveMacroVar(vari.name))
      else if isinstance(value, MacroRules)
        new_var = compiler.new_var(RecursiveMacroVar(vari.name))
      else new_var = compiler.new_var(vari)
      if isinstance(new_var, Const)
        new_var.assigned = false
      new_env.bindings[vari] = new_var
    return begin((Assign(new_env[vari], value.alpha(new_env, compiler))  for vari, value in @bindings+[@body.alpha(new_env, compiler)])...)

  toString: () -> "Letrec(#{@bindings}, #{@body})"

get_tuple_vars : (exps) ->  set().mergeAt(x.vars() for x in exps)

dao.rules = (rules...)->
  result = []
  for rule in rules
    head = (element(x) for x in rule[0])
    body = begin((element(x) for x in rule[1...])...)
    result.push([head, body])
  return Rules(result)

#@special
dao.wrap_cut = (compiler, cont, exp) ->
  cut_cont = new il.ConstLocalVar('cut_cont')
  v = new il.ConstLocalVar('v')
  v1 = compiler.new_var(new il.ConstLocalVar('v'))
  v2 = compiler.new_var(new il.ConstLocalVar('v'))
  parse_state = compiler.new_var(new il.ConstLocalVar('parse_state'))
  bindings = compiler.new_var(il.LocalVar('bindings'))
  fc = compiler.new_var(new il.ConstLocalVar('old_failcont'))
  return il.begin(
                   il.Assign(cut_cont, il.cut_cont),
                   il.Assign(parse_state, il.parse_state),
                   il.Assign(bindings, il.Copy(il.bindings)),
                   il.Assign(fc, il.failcont),
                   il.SetCutCont(il.clamda(v2,
                                           il.Assign(il.parse_state, parse_state),
                                           il.SetBindings(bindings),
                                           fc(il.FALSE))),
                   il.SetFailCont(il.clamda(v1,
                                            il.SetFailCont(fc),
                                            il.Assign(il.cut_cont, cut_cont),
                                            fc(il.FALSE))),
                   exp.cps(compiler, il.clamda(v,
                                               il.Assign(il.cut_cont, cut_cont),
                                               cont(v))))

class dao.Rules  extends dao.Lamda
  constructor: (@rules) -> @arity = rules[0][0].length
  callOn: (args...) -> new dao.Apply((element(arg) for arg in args))

  alpha: (env, compiler) ->
    rules = []
    for head, body in @rules
      [head, new_env] = alpha_rule_head(head, env, compiler)
      body = body.alpha(new_env, compiler)
      rules.push([head, body])
    new dao.Rules(rules)

  has_cut: () ->
    for head, body in @rules
      if has_cut(body) then return false
    return false

  cps_call: (compiler, cont, args) ->
    if args.length != @arity then throw new dao.ArityError
    clauses = []
    for head, body in @rules
      clauses.push(begin(unify_rule_head(args, head), body))
    if @has_cut()
      return wrap_cut(or_(clauses...)).cps(compiler, cont)
    else
      return or_(clauses...).cps(compiler, cont)

  cps: (compiler, cont) ->
    k = compiler.new_var(new il.ConstLocalVar('cont'))
    params = ([compiler.new_var(Const('arg')) for x in range(@arity)])
    clauses = []
    for head, body in @rules
      head_exps = begin((unify_head_item2(param, head_item) for param, head_item in zip(params, head)) ...)
      clauses.push(begin(head_exps, body))
    if @has_cut()
      body = wrap_cut(or_(clauses...)).cps(compiler, k)
    else body = or_(clauses...).cps(compiler, k)
    params = (param.interlang() for param in params)
    cont(il.Lamda([k]+params, body))

  toString: () -> "rules(#{@rules})"

alpha_rule_head = (head, env, compiler) ->
  new_env = env.extend()
  head2 = []
  for item in head
    head2.push(alpha_rule_head_item(item, new_env, compiler))
  [head2, new_env]

alpha_rule_head_item = (item, env, compiler) ->
  if isinstance(item, Var)
    if isinstance(item, Const)
      env.bindings[item] = result = compiler.new_var(Const(item.name))
    else
      env.bindings[item] = result = compiler.new_var(Var(item.name))
    return result
  else
    if isinstance(item, Cons)
      return Cons(alpha_rule_head_item(item.head, env, compiler),
                  alpha_rule_head_item(item.tail, env, compiler))
    else item

unify_rule_head = (args, head) ->
  il.begin((unify_head_item1(arg, head_item)  for [arg, head_item] in zip(args, head))...)

unify_head_item1 = (arg, head_item) ->
  # for direct call
  if isinstance(head_item, Var)
    if not isinstance(head_item, LogicVar)
      return Assign(head_item, arg)
    else throw new dao.CompileTypeError(head_item)
  else
    if isinstance(head_item, Cons)
      throw new dao.CompileTypeError(head_item)
    else return unify(arg, head_item)

do_unify_head_item2 = (arg, head_item, compiler, cont) ->
  if not isinstance(head_item, Var)
    # arg should be Var or il.ConsHead
    if isinstance(head_item, Cons)
      arg1 = compiler.new_var(new il.ConstLocalVar('arg'))
      return il.begin(il.Assign(arg1, il.Deref(arg)),
                      do_unify_head_item2(il.ConsHead(arg1), head_item.head, compiler,
                                          do_unify_head_item2(il.ConsTail(arg), head_item.tail, compiler, cont)))
    else
      head_item = head_item.interlang()
      arg = arg.interlang()
      arg1 = compiler.new_var(new il.ConstLocalVar('arg'))
      return il.begin(
                       il.Assign(arg1, il.Deref(arg)),
                       il.If(il.IsLogicVar(arg1),
                             il.begin(il.SetBinding(arg1, head_item),
                                      il.append_failcont(compiler, il.DelBinding(arg1)),
                                      cont(il.TRUE)),
                             il.If(il.Eq(arg1, head_item), cont(TRUE), il.failcont(TRUE))))
  else
    if not isinstance(head_item, LogicVar)
      arg = arg.interlang()
      return il.begin(
                       il.Assign(head_item.interlang(), arg),
                       cont(il.TRUE))
    else throw new dao.CompileTypeError

#@special
unify_head_item2: (compiler, cont, arg, head_item) ->
  # for call with rules variable.
  arg = arg.interlang()
  if not isinstance(head_item, Var)
    # arg should be Var
    if isinstance(head_item, Cons)
      v = compiler.new_var(new il.ConstLocalVar('v'))
      return do_unify_head_item2(il.ConsHead(arg), head_item.head, compiler,
                                 il.clamda(v,
                                           do_unify_head_item2(il.ConsTail(arg), head_item.tail,
                                                               compiler, cont)))
    else
      head_item = head_item.interlang()
      arg1 = compiler.new_var(new il.ConstLocalVar('arg'))
      return il.begin(
                       il.Assign(arg1, il.Deref(arg)),
                       il.If(il.IsLogicVar(arg1),
                             il.begin(il.SetBinding(arg1, head_item),
                                      il.append_failcont(compiler, il.DelBinding(arg1)),
                                      cont(il.TRUE)),
                             il.If(il.Eq(arg1, head_item), cont(TRUE), il.failcont(TRUE))))
  else
    if not isinstance(head_item, LogicVar)
      return il.begin(
                       il.Assign(head_item.interlang(), arg),
                       cont(il.TRUE))
    else throw new dao.CompileTypeError

macrorules = (rules...) ->
  result = []
  for rule in rules
    head = (element(x) for x in rule[0])
    body = begin((element(x) for x in rule[1...])...)
    result.push([head, body])
  MacroRules(result)

class dao.MacroRules extends dao.Element
  constructor: (rules) ->
    @rules = rules
    @arity = rules[0][0].length

  callOn: (args...) ->
    return Apply((element(arg) for arg in args))

  alpha: (env, compiler) ->
    result = []
    for head, body in @rules
      [head, new_env] = alpha_rule_head(head, env, compiler)
      for vari, new_var in new_env.bindings.items()
        new_env.bindings[vari] = eval_macro_args(new_var)
      body = body.alpha(new_env, compiler)
      result.push([head, body])
    return MacroRules(result)

  has_cut: () ->
    for head, body in @rules
      if has_cut(body) then false
    false

  cps_call: (compiler, cont, args) ->
    if @arity!=args.length then throw
    clauses = []
    for head, body in @rules
      clauses.push(begin(unify_macro_head(compiler, cont, args, head), body))
    if @has_cut()
      return wrap_cut(or_(clauses...)).cps(compiler, cont)
    else or_(clauses...).cps(compiler, cont)

  cps: (compiler, cont) ->
    k = compiler.new_var(new il.ConstLocalVar('cont'))
    params = compiler.new_var(new il.ConstLocalVar('arg')) for x in range(@arity)
    clauses = []
    for head, body in @rules
      head_exps = begin((unify_macro_head_item2(param, head_item)  for param, head_item in zip(params, head))...)
      clauses.push(begin(head_exps, body))
    if @has_cut()
      body = wrap_cut(or_(clauses...)).cps(compiler, k)
    else
      body = or_(clauses...).cps(compiler, k)
    cont(il.Lamda([k]+params, body))

  toString: () -> "macrorules(#{@rules})"

# for direct call
unify_macro_head = (compiler, cont, args, head) ->
  begin((unify_macro_head_item1(compiler, cont, arg, head_item)  for arg, head_item in zip(args, head))...)

# for direct call
unify_macro_head_item1 = (compiler, cont, arg, head_item) ->
  if isinstance(head_item, Var) and not isinstance(head_item, LogicVar)
    k = compiler.new_var(new il.ConstLocalVar('cont'))
    return Assign(head_item, direct_interlang(il.Lamda([k], arg.cps(compiler, k))))
  else unify(arg, head_item)

#@special
unify_macro_head_item2 = (compiler, cont, arg, head_item) ->
  if isinstance(head_item, Var)
    if not isinstance(head_item, LogicVar)
      return il.begin(
                       il.Assign(head_item.interlang(), arg),
                       cont(il.TRUE))
    else
      v = compiler.new_var(new il.ConstLocalVar('v'))
      head_item = head_item.interlang()
      arg1 = compiler.new_var(new il.ConstLocalVar('arg'))
      head1 = compiler.new_var(new il.ConstLocalVar('head'))
      return il.begin(
                       il.Assign(arg1, il.Deref(arg)), #for LogicVar, could be optimized when generate code.
                       il.Assign(head1, il.Deref(head_item)),
                       il.If(il.IsLogicVar(arg1),
                             il.begin(il.SetBinding(arg1, head1),
                                      il.append_failcont(compiler, il.DelBinding(arg1)),
                                      cont(il.TRUE)),
                             il.begin(
                                       il.If(il.IsLogicVar(head1),
                                             il.begin(il.SetBinding(head1, arg1),
                                                      il.append_failcont(compiler, il.DelBinding(head1)),
                                                      cont(il.TRUE)),
                                             il.If(il.Eq(arg1, head1), cont(il.TRUE), il.failcont(il.FALSE))))))
  else
    arg1 = compiler.new_var(new il.ConstLocalVar('arg'))
    return il.begin(
                     il.Assign(arg1, il.Deref(arg)),
                     il.If(il.IsLogicVar(arg1),
                           il.begin(il.SetBinding(arg1, head_item),
                                    il.append_failcont(compiler, il.DelBinding(arg1)),
                                    cont(il.TRUE)),
                           il.If(il.Eq(arg1, head_item), cont(TRUE), il.failcont(TRUE))))

#@special
dao.quote = (compiler, cont, exp) -> cont(il.ExpressionWithCode(exp, il.Lamda([], exp.cps(compiler, il.equal_cont))))

#@special
eval_ = (compiler, cont, exp) ->
  v = compiler.new_var(new il.ConstLocalVar('v'))
  exp.cps(compiler, il.clamda(v, cont(il.EvalExpressionWithCode(v))))

dao.begin = (exps...) ->
  exps = (dao.element(e) for e in exps)
  if exps.length==1 then  exps[0]
  else
    result = []
    for exp in exps
      if (exp instanceof dao.Special) and exp.command is dao.Begin
        result.concat(exp.args)
      else result.push(exp)
    dao.Begin.callOn(result...)

Begin_fun = (compiler, cont, exps...) -> cps_convert_exps(compiler, exps, cont)

dao.Begin = dao.special('begin', Begin_fun)

if_fun = (compiler, cont, test, then_, else_) ->
  v = compiler.new_var(new il.ConstLocalVar('v'))
  test.cps(compiler,
           il.clamda(v, new il.If(v, then_.cps(compiler, cont),
                                  else_.cps(compiler, cont))))

dao.if_ = dao.special 'if', if_fun

cps_convert_exps = (compiler, exps, cont) ->
  v = compiler.new_var(new il.ConstLocalVar('v'))
  if not exps then il.PassStatement()
  if exps.length==1 then exps[0].cps(compiler, cont)
  else exps[0].cps(compiler, new il.Clamda(v, cps_convert_exps(compiler, exps[1...], cont)))

#@special
callcc = (compiler, cont, fun) ->
  body = fun.body.subst(dict(fun.params[0], LamdaVar(fun.params[0].name)))
  k = compiler.new_var(new il.ConstLocalVar('cont'))
  params = (x.interlang() for x in fun.params)
  function1 = il.Lamda([k]+params, body.cps(compiler, k))
  k1 = compiler.new_var(new il.ConstLocalVar('cont'))
  v = compiler.new_var(new il.ConstLocalVar('v'))
  function1(cont, il.Lamda([k1, v], cont(v)))

#@special
callfc = (compiler, cont, fun) ->
  Todo_callfc_need_tests
  fun(il.failcont)

dao.block = (label, exps...) -> new dao.Block(label, begin((element(x) for x in exps)...))

class dao.Block extends dao.Element
  constructor: (@label, @body) ->

  alpha: (env, compiler) ->
    label = compiler.new_var(@label)
    compiler.block_label_stack.push([@label, label])
    body = @body.alpha(env, compiler)
    compiler.block_label_stack.pop()
    return Block(label, body)

  subst: (bindings) -> new dao.Block(@label, @body.subst(bindings))

  cps: (compiler, cont) ->
    # use cfunction, continue_block means recursive call.
    # tail recursive cfunction can be used to transform to while 1/break/continue.
    v = compiler.new_var(new il.ConstLocalVar('v'))
    v1 = compiler.new_var(new il.ConstLocalVar('v'))
    v2 = compiler.new_var(new il.ConstLocalVar('v'))
    block_fun = compiler.new_var(new il.ConstLocalVar('block_'+@label.name))
    compiler.exit_block_cont_map[@label.name] = il.clamda(v1, cont(v1))
    compiler.continue_block_cont_map[@label.name] = il.clamda(v2, block_fun(v2))
    il.cfunction(block_fun, v, @body.cps(compiler, cont))(il.NONE)

  toString: () -> "Block(#{@label}, #{@body})"

dao.exit_block = (label=NONE, value=NONE) -> dao.ExitBlock(element(label), element(value))

class dao.ExitBlock extends dao.Element
  constructor: (@label=NONE, @value=NONE) ->

  alpha: (env, compiler) ->
    if @label==NONE then label = compiler.get_inner_block_label(NONE)
    else label = compiler.get_block_label(@label)
    ExitBlock(label, @value.alpha(env, compiler))

  cps: (compiler, cont) ->
    v = compiler.new_var(new il.ConstLocalVar('v'))
    return @value.cps(compiler,
                      il.clamda(v, compiler.protect_cont(NONE),
                                compiler.exit_block_cont_map[@label.name](v)))

  toString: () -> "exit_block(#{@label}, #{@value})"

dao.continue_block = (label=NONE) -> dao.ContinueBlock(element(label))

class dao.ContinueBlock extends dao.Element
  constructor: (@label=NONE) ->

  alpha: (env, compiler) ->
    if @label==NONE then label = compiler.get_inner_block_label(NONE)
    else label = compiler.get_block_label(@label)
    new dao.ContinueBlock(label)

  cps: (compiler, cont) -> il.begin(compiler.protect_cont(NONE), compiler.continue_block_cont_map[@label.name](il.NONE))

  toString: () -> "continue_block(#{@label})"

#@special
catch_ = (compiler, cont, tag, form...) ->
  v = compiler.new_var(new il.ConstLocalVar('v'))
  v2 = compiler.new_var(new il.ConstLocalVar('v'))
  k = compiler.new_var(il.LocalVar('cont'))
  tag.cps(compiler, il.clamda(v,
                              il.Assign(k, il.clamda(v2, cont(v2))),
                              il.PushCatchCont(v, k),
                              begin(form...).cps(compiler, cont)))

#@special
throw_ = (compiler, cont, tag, form) ->
  v = compiler.new_var(new il.ConstLocalVar('v'))
  v2 = compiler.new_var(new il.ConstLocalVar('v'))
  tag.cps(compiler,
          il.clamda(v,
                    form.cps(compiler,
                             il.clamda(v2,
                                       compiler.protect_cont(NONE),
                                       il.FindCatchCont(v)(v2)))))

#@special
unwind_protect = (compiler, cont, form, cleanup...) ->
  v = compiler.new_var(new il.ConstLocalVar('v'))
  v1 = compiler.new_var(new il.ConstLocalVar('v'))
  v2 = compiler.new_var(new il.ConstLocalVar('v'))
  old_protect_cont = compiler.protect_cont
  compiler.protect_cont = il.clamda(v, NONE)
  cleanup_protect = begin(cleanup...).cps(compiler, old_protect_cont)
  compiler.protect_cont.body = cleanup_protect
  cleanup_cont = il.clamda(v1, begin(cleanup...).cps(compiler, il.clamda(v2, cont(v1))))
  result = form.cps(compiler, cleanup_cont)
  compiler.protect_cont = old_protect_cont
  result

quasiquote_args: (args) ->
  if not args then pyield []
  else if args.length is 1
    for x in @quasiquote(args[0])
      try pyield x.unquote_splice
      catch e then pyield [x]
  else
    for x in @quasiquote(args[0])
      for y in @quasiquote_args(args[1..])
        try x = x.unquote_splice
        catch e then x = [x]
        pyield x+y

dao.type_map = dict( "number", dao.Number,   "string",dao.String,     "boolean",dao.Bool,
                     "Array",dao.List,      "dict", dao.Dict,    typeof(->), dao.PyFunction
                     typeof(undefined) , dao.Atom
                   )
dao.format = new dao.BuiltinFunction('format', il.Format)
