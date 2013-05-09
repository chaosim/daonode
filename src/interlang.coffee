# stuffs for dao's inter langugage, aka interlang

il = exports

#true == 1
#false==0
il.unknown = -1

il.element = (exp) ->
  if (exp instanceof il.Element) then exp
  else
    maker = type_map[typeof(exp)]
    if maker? then maker(exp)
    else throw new dao.CompileTypeError(exp)

no_side_effects = (exp) ->
  exp.side_effects = ( ) ->  false
  exp

optimize_args = (args, env, compiler) ->
  result = []
  for arg in args
    arg = arg.optimize(env, compiler)
    if arg isnt undefined
      result.push(arg)
  (result)

javascriptize_args = (args, env, compiler) ->
  # used in Apply, Return, Yield, VirtualOpteration
  result_args = []
  exps = []
  for arg in args
    exps2 = arg.javascriptize(env, compiler)
    result_args.push(exps2[-1])
    exps += exps2[..-1]
    return [exps, result_args]

class il.Element
  tail_recursive_convert: ( ) ->  @
  find_assign_lefts: ( ) ->  set()
  replace_return_with_pyyield: ( ) ->  @
  interlang: ( ) ->  @
  __eq__: (x, y) ->  classeq(x, y)
  toString: ( ) ->  @constructor.name

class il.Atom extends il.Element
  constructor: (@item) ->
  find_assign_lefts: ( ) ->  set()
  analyse: (compiler) ->
  side_effects: ( ) ->  false
  subst: (bindings) ->  @
  optimize: (env, compiler) ->  @
  replace_assign: (compiler) ->  @
  tail_recursive_convert: ( ) ->  @
  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  javascriptize: (env, compiler) ->  [@]
  code_size: ( ) ->  1
  to_code: (compiler) ->  @item.toString()
  free_vars: ( ) ->  set()
  bool: ( ) -> if @item then true  else false
  __eq__: (x, y) ->  classeq(x, y) and x.item==y.item
  __hash__: ( ) ->  hash(@item)
  toString: ( ) ->  @item.toString()

class il.ConstAtom extends il.Atom

class il.Integer extends il.ConstAtom
  __eq__: (x, y) ->  ConstAtom.__eq__(x, y) or (isinstance(y, int) and x.item==y)

class il.Float extends il.ConstAtom
  __eq__: (x, y) ->  ConstAtom.__eq__(x, y) or (isinstance(y, float) and x.item==y)

class il.String extends il.ConstAtom
  __eq__: (x, y) ->  ConstAtom.__eq__(x, y) or (isinstance(y, str) and x.item==y)

class il.Bool extends il.ConstAtom
  __eq__: (x, y) ->  ConstAtom.__eq__(x, y) or (isinstance(y, bool) and x.item==y)

class il.Symbol extends il.ConstAtom
  to_code: (compiler) ->  @item

class il.Klass extends il.ConstAtom
  to_code: (compiler) ->  @item
  toString: ( ) ->  "il.Klass(#{@item})"

class il.PyFunction extends il.ConstAtom
  to_code: (compiler) ->  @item.func_name
  toString: ( ) ->  "il.PyFunction(#{@item})"


il.TRUE = new il.Bool(true)
il.FALSE = new il.Bool(false)
il.NULL = new il.Atom(null)

make_tuple = (item) ->  new il.Tuple((element(x) for x in item)...)

class il.Tuple extends il.ConstAtom
  constructor: (@item...) ->
  find_assign_lefts: ( ) ->  set()
  analyse: (compiler) ->
    for x in @item then x.analyse(compiler)
  side_effects: ( ) ->  false
  subst: (bindings) ->  Tuple((x.subst(bindings) for x in @item)...)
  code_size: ( ) ->  sum([x.code_size() for x in @item])
  optimize: (env, compiler) ->  Tuple((x.optimize(env, compiler) for x in @item)...)
  to_code: (compiler) ->
    if @item.length!=1 then  "(#{join(', ', [x.to_code(compiler) for x in @item])})"
    else  "(#{@item[0].to_code(compiler)}, )"
  __eq__: (x, y) ->  classeq(x, y) and x.item==y.item
  toString: ( ) ->  "il.#{@constructor.name}(#{@item})"

class il.MutableAtom extends il.Atom

class il.List extends il.MutableAtom
  __eq__: (x, y) ->  (classeq(x, y) and x.item==y.item) or ((isinstance(y, list) and x.item==y))

class il.Dict extends il.MutableAtom
  __eq__: (x, y) ->  Atom.__eq__(x, y) or (isinstance(y, dict) and x.item==y)
  macro_args: (item) ->  MacroArgs(item)

class il.MacroArgs extends il.Element
  constructor: (@item) ->
  find_assign_lefts: ( ) ->  set()
  analyse: (compiler) -> for x in @item then x.analyse(compiler)
  optimize: (env, compiler) ->  MacroArgs(optimize_args(@item, env, compiler))
  side_effects: ( ) ->  false
  free_vars: ( ) ->
    result = set()
    for x in @item then  result |= x.free_vars()
    return result

  subst: (bindings) ->  MacroArgs((x.subst(bindings) for x in @item))

  javascriptize: (env, compiler) ->
    exps = []
    args = []
    for arg in @item
      exps1 = arg.javascriptize(env, compiler)
      exps += exps1[..-1]
      args.push(exps1[-1])
      exps.push(MacroArgs((args)))
    return (exps)

  code_size: ( ) ->  sum([x.code_size() for x in @item])

  to_code: (compiler) ->
    if @item.length!=1
      return "(#{join(', ', [x.to_code(compiler) for x in @item])})"
    else return "(#{@item[0].to_code(compiler)}, )"

  __eq__: (x, y) ->  classeq(x, y) and x.item==y.item
  toString: ( ) ->  "il.#{@constructor.name}(#{@item})"

class il.Return extends il.Element
  constructor: (@args...) ->
  analyse: (compiler) ->  for arg in @args then  arg.analyse(compiler)
  code_size: ( ) ->  sum([code_size(x) for x in @args])
  side_effects: ( ) ->  false
  free_vars: ( ) ->
    result = set()
    for x in @args then  result |= x.free_vars()
    return result

  subst: (bindings) -> new @constructor((arg.subst(bindings) for arg in @args)...)

  optimize: (env, compiler) ->
    if @args.length==1 and isinstance(@args[0], Return)
      new @constructor(@args[0].args...)
    else
      for arg in @args
        if isinstance(arg, Return)  then throw new dao.CompileError
      new @constructor(optimize_args(@args, env, compiler)...)

  javascriptize: (env, compiler) ->
    if @args.length==1 and isinstance(@args[0], Begin)
      return Begin(@args[0].statements[..-1]+[Return(@args[0].statements[-1])]).javascriptize(env, compiler)
    else if @args.length==1 and isinstance(@args[0], If)
      return If(@args[0].test, Return(@args[0].then), Return(@args[0].else_)).javascriptize(env, compiler)
    [exps, args] = javascriptize_args(@args, env, compiler)
    exps+[new @constructor(args...)]

  to_code: (compiler) ->   "return #{join(', ', [x.to_code(compiler) for x in @args])}"
  insert_return_statement: ( ) ->  Return(@args...)
  replace_return_with_pyyield: ( ) ->  Begin([Yield(@args...), Return()])
  __eq__: (x, y) ->  classeq(x, y) and x.args==y.args
  toString: ( ) ->  "il.Return(#{join(',', x for x in @args)})"

class il.Yield extends il.Return
  to_code: (compiler) ->   "pyield #{join(', ', x.to_code(compiler) for x in @args)}"
  insert_return_statement: ( ) ->  @
  toString: ( ) ->  "il.Yield(#{join(', ', x for x in @args)})"

class il.Try extends il.Element
  constructor: (@test, @body) ->
  find_assign_lefts: ( ) ->  @body.find_assign_lefts()
  analyse: (compiler) ->
    @test.analyse(compiler)
    @body.analyse(compiler)

  code_size: ( ) ->  3 + @test.code_size() + @body.code_size()
  side_effects: ( ) ->  not @test.side_effects() and not @body.side_effects()
  subst: (bindings) ->  Try(@test.subst(bindings), @body.subst(bindings))
  optimize: (env, compiler) ->  Try(@test.optimize(env, compiler), @body.optimize(env, compiler))
  insert_return_statement: ( ) -> Try(@test, @body.insert_return_statement())

  replace_return_with_pyyield: ( ) -> Try(@test,  @body.replace_return_with_pyyield())

  javascriptize: (env, compiler) ->
    test = @test.javascriptize(env, compiler)
    body = @body.javascriptize(env, compiler)
    test[..-1]+[Try(test[-1], begin(body...))]

  to_code: (compiler) ->  "try\n#{compiler.indent(@test.to_code(compiler))}\ncatch e\n#{compiler.indent(@body.to_code(compiler))}\n"

  __eq__: (x, y) ->  classeq(x, y) and x.test==y.test and x.body==y.body
  toString: ( ) ->  "il.Try(#{@test}, #{ @body})"

il.begin = (exps...) ->
  result = []
  length = exps.length
  for e, i in exps
    if isinstance(e, il.Begin)
      result += e.statements
    else if _.isArray(e) and e.length is 0 then  continue
    else
      if e is il.NULL and i!=length-1 then continue
      else result.push(e)
  if result.length is 0 then return_statement
  else if result.length is 1 then result[0]
  else il.Begin(result)

class il.Begin extends il.Element
  constructor: (@statements) ->
  find_assign_lefts: ( ) ->
    result = set()
    for exp in @statements
      result |= exp.find_assign_lefts()
    return result

  side_effects: ( ) ->  true
  subst: (bindings) ->  Begin((x.subst(bindings) for x in @statements))

  free_vars: ( ) -> set().mergeAt(exp.free_vars() for exp in @statements)

  code_size: ( ) ->  1
  analyse: (compiler) -> for x in @statements then x.analyse(compiler)

  optimize: (env, compiler) ->
    result = []
    for arg in @statements
      arg1 = arg.optimize(env, compiler)
      if arg1 isnt undefined
        result.push(arg1)
      if result
        return begin(((x for x in result[..-1] if not isinstance(x, Atom))+[result[-1]])...)
      else return_statement

  remove: (exp) ->
    for i, stmt in enumerate(@statements)
      if stmt is exp then break
      else return @
    return begin((@statements[..i]+@statements[i+1..])...)

  insert_return_statement: ( ) ->
    inserted = @statements[-1].insert_return_statement()
    return begin((@statements[..-1]+[inserted])...)

  replace_return_with_pyyield: ( ) ->  Begin((exp.replace_return_with_pyyield() for exp in @statements))

  javascriptize: (env, compiler) ->
    result = []
    for exp in @statements
      exps2 = exp.javascriptize(env, compiler)
      result += exps2
    return result

  to_code: (compiler) ->   '\n'.join([x.to_code(compiler) for x in @statements])
  __eq__: (x, y) ->  classeq(x, y) and x.statements==y.statements
  toString: ( ) ->  "il.begin(#{'\n '.join(x for x in @statements)})"


class il.PassStatement extends il.Element
  constructor: ( ) ->
  code_size: ( ) ->  0
  side_effects: ( ) ->  false
  analyse: (compiler) ->
  optimize: (env, compiler) -> @
  javascriptize: (env, compiler) ->  [@]
  insert_return_statement: ( ) ->  @
  replace_return_with_pyyield: ( ) ->  @
  subst: (bindings) ->  @
  __eq__: (x, y) ->  classeq(x, y)
  to_code: (compiler) ->  'pass'
  toString: ( ) ->  'il.pass_statement'

il.pass_statement = new il.PassStatement()

class il.Nil extends il.Element
  constructor: ( ) ->
  code_size: ( ) ->  0
  side_effects: ( ) ->  false
  analyse: (compiler) ->
  optimize: (env, compiler) ->  nil
  javascriptize: (env, compiler) ->  [@]
  insert_return_statement: ( ) ->  @
  replace_return_with_pyyield: ( ) ->  @
  subst: (bindings) ->  @
  __eq__: (x, y) ->  classeq(x, y)
  to_code: (compiler) ->  'nil'
  toString: ( ) ->  'il.nil'

il.nil = new il.Nil()

type_map = dict("int", il.Integer,    "float", il.Float, "str",il.String, "unicode", il.String,
                "Array",il.List, "dict",il.Dict,
                "bool",il.Bool,
                (typeof undefined), il.Atom
               )

il.lamda = (params, body...) ->  new il.Lamda(params, begin(body...))

class il.Lamda extends il.Element
  constructor: (@params, @body) -> @has_javascriptized = false
  make_new: (params, body) ->  new il.Lamda(params, body)
  callOn: (args...) ->  Apply(args)
  find_assign_lefts: ( ) ->  @body.find_assign_lefts()
  analyse: (compiler) ->
    compiler.lamda_stack.push(@)
    @body.analyse(compiler)
    compiler.lamda_stack.pop()
  code_size: ( ) ->  @body.code_size()+@params.length+2
  side_effects: ( ) ->  false

  subst: (bindings) ->
    result = @make_make_new(@params, @body.subst(bindings))
    return result

  optimize: (env, compiler) ->
    env = env.extend()
    body = @body.optimize(env, compiler)
    result = @make_make_new(@params, body)
    return result

  optimize_apply: (env, compiler, args) ->
    #1. ((lambda () body))  =>  body
    if @params.length==0
      return @body.optimize(env, compiler)

    #2. (lamda x: ...x...)(y) => (lambda : ... y ...)()
    bindings = {}
    [new_params, new_args] = [[], []]
    for i, p in enumerate(@params)
      arg = args[i]
      if arg.side_effects()
        new_params += [p]
        new_args += [arg]
        continue
      else
        ref_count = compiler.ref_count.get(p, 0)
      if ref_count==0 then continue
      else if ref_count==1
        bindings[p] = arg
      else
        if arg.code_size()*ref_count>MAX_EXTEND_CODE_SIZE
          # a(...y...), and a is (lamda ...x...: ...x...),
          #then convert as above if code size is ok.
          new_params += [p]
          new_args += [arg]
        else
          bindings[p] = arg

    if new_params
      if bindings
        return Apply(@make_make_new(new_params, @body.subst(bindings).optimize(env, compiler)),
                     (arg.optimize(env, compiler) for arg in new_args))
      else
        if new_params.length!=@params.length
          Apply(@make_make_new(new_params, @body.subst(bindings).optimize(env, compiler)),
                (arg.optimize(env, compiler) for arg in new_args))
        else  Apply(@make_make_new(new_params, @body.optimize(env, compiler)),
                    optimize_args(new_args, env, compiler))
    else
      if bindings then @body.subst(bindings).optimize(env, compiler)
      else  @body.optimize(env, compiler)

  insert_return_statement: () ->  new il.Return(@)

  javascriptize: (env, compiler) ->
    if @has_javascriptized then return [@name]
    @has_javascriptized = true
    body_exps = @body.javascriptize(env, compiler)
    [@make_make_new(@params, il.begin(body_exps...))]

  to_code: (compiler) -> "function (#{join(', ', (x.to_code(compiler) for x in @params))}) { "  + @body.to_code(compiler)+";}"

  free_vars: ( ) ->  @body.free_vars()-set(@params)
  bool: ( ) ->  true
  __eq__: (x, y) ->  classeq(x, y) and x.params==y.params and x.body==y.body
  __hash__: ( ) ->  hash(id(@))
  toString: ( ) ->  "il.Lamda((#{join(', ', x for x in @params)}), \n#{@body})"

class il.RulesLamda extends il.Lamda
  constructor: (@params, @body) ->  @has_javascriptized = false
  callOn: (args...) ->  Apply((element(x) for x in args))

  optimize_apply: (env, compiler, args) ->  Lamda.optimize_apply(env, compiler, args)

  to_code: (compiler) -> "lambda #{@params[0].to_code(compiler)}, #{@params[1].to_code(compiler)}: " + @body.to_code(compiler)

il.clamda = (v, body...) -> new il. Clamda(v, il.begin(body...))

class il.Clamda extends il.Lamda
  constructor: (v, @body) ->
    @has_javascriptized = false
    @params = [v]
    @name = undefined

  make_new: (params, body) ->  new @constructor(params[0], body)

  optimize_apply: (env, compiler, args) ->
    [param, arg] = [@params[0], args[0]]
    if not arg.side_effects()
      body = @body.subst({param: arg}).optimize(env, compiler)
      return body
    else
      ref_count = compiler.ref_count.get(param, 0)
      if ref_count==0 then begin(arg, @body).optimize(env, compiler)
      else begin(Assign(param, arg), @body).optimize(env, compiler)

  callOn: (arg) ->
    if arg.side_effects() then begin(Assign(@params[0], arg), @body)
    else
      bindings = {}
      bindings[@params[0]] = arg
      @body.subst(bindings)

  toString: ( ) ->  "il.Clamda(#{@params[0]}, \n#{@body})"

class il.EqualCont
  callOn: (body) ->  body
  subst: (bindings) ->  @
  analyse: (compiler) ->
  code_size: ( ) ->  1
  side_effects: ( ) ->  false
  optimize:  (env, compiler) ->  @
  javascriptize: (env, compiler) ->  [@]
  to_code: (compiler) ->  'lambda v:v'
  toString: ( ) ->  'EqualCont'

il.equal_cont = new il.EqualCont()

class il.Done extends il.Clamda
  constructor: (param) ->
    @has_javascriptized = false
    @params = [param]
    @body = param

  make_new: (params, body) ->  new @constructor(@params[0])
  callOn: (args...) ->
    bindings = {}
    bindings[@params[0]] = args[0]
    @body.subst(bindings)
  replace_assign: (bindings) ->  @
  toString: ( ) ->  "il.Done(#{@params[0]}, #{@body})"

class il.Function extends il.Lamda
  constructor: (@name, @params, @body) ->

il.cfunction = (name, v, body...) ->  new il.CFunction(name, v, begin(body...))

class il.CFunction extends il.Function
  is_fun: true
  constructor: (name, v, body) ->
  make_new: (params, body) ->  new @constructor(@name, params[0], body)
  optimize_apply: (env, compiler, args) ->
    new_env = env.extend()
    bindings = {}
    bindings[@params[0]] = args[0]
    body = @body.subst(bindings)
    body = body.optimize(new_env, compiler)
    result = CFunction(@name, @params[0], body)(il.NULL)
    return result
  toString: ( ) ->  "il.CFunction(#{@name}, #{@params[0]}, \n#{@body})"

class il.RulesDict extends il.Element
  constructor: (arity_body_map) ->
    @arity_body_map = arity_body_map
    @to_coded = false

  analyse: (compiler) ->
    try @seen  catch e then  @seen = true
    compiler.occur_count[@] = compiler.occur_count.setdefault(0)+1
    for arity, body in @arity_body_map.items()
      body.analyse(compiler)

  subst: (bindings) ->
    @arity_body_maparity_body_map = {arity:body.subst(bindings) for arity, body in @arity_body_map.items()}
    return @

  side_effects: ( ) ->  false
  free_vars: ( ) ->
    result = set()
    for arity, body in @arity_body_map.items()
      result |= body.free_vars()
    return result

  optimize: (env, compiler) ->  @
  javascriptize: (env, compiler) ->  [@]
  bool: ( ) ->  true

  to_code: (compiler) ->
    if @to_coded then  return @name.to_code(compiler)
    else
      @to_coded = true
      ss = "#{arity}: #{funcname.to_code(compiler)}" for arity, funcname in @arity_body_map.items()
      return "{#{join(', ', ss)}}"

  toString: ( ) ->  "RulesDict(#{@arity_body_map})"

class il.Macro

class il.MacroLamda extends il.Lamda #, Macro):
  optimize_apply: (env, compiler, args) ->
    #args = (args[0], Tuple(*args[1:]))
    result = Lamda.optimize_apply(env, compiler, args)
    return result

  javascriptize: (env, compiler) ->
    body_exps = @body.javascriptize(env, compiler)
    global_vars = @find_assign_lefts()-set(@params)
    global_vars = set(x for x in global_vars when isinstance(x, Var)  and not isinstance(x, LocalVar)  and not isinstance(x, SolverVar))
    if global_vars
      body_exps = [GlobalDecl(global_vars)]+body_exps
      return [MacroFunction(Lamda(@params, begin(body_exps...)))]

  toString: ( ) ->  "il.MacroLamda((#{join(', ', x for x in @params)}), \n#{@body})"

class il.MacroRules extends il.Lamda #, Macro):
  optimize_apply: (env, compiler, args) ->
    result = Lamda.optimize_apply(env, compiler, args)
    return result

  javascriptize: (env, compiler) ->
    body_exps = @body.javascriptize(env, compiler)
    global_vars = @find_assign_lefts()-set(@params)
    global_vars = set()
    for x in global_vars
      if isinstance(x, Var) and not isinstance(x, LocalVar)  and not isinstance(x, SolverVar)
        global_vars.add(x)
    if global_vars
      body_exps = [GlobalDecl(global_vars)]+body_exps
    if not body_has_any_statemen
      return [MacroRulesFunction(@make_make_new(@params, begin(body_exps...)))]
    else
    name = compiler.new_var(LocalVar('fun'))
    body = begin(body_exps...).insert_return_statement()
    return [new il.Function(name, @params, body), MacroRulesFunction(name)]

class il.MacroFunction extends il.Element
  constructor: (@fun) ->
  to_code: (compiler) ->  "MacroFunction(#{@fun.to_code(compiler)})"
  toString: ( ) ->  "MacroFunction(#{@fun})"

class il.MacroRulesFunction extends il.Element
  constructor: (@fun) ->
  to_code: (compiler) ->  "MacroRules(#{@fun})"
  toString: ( ) ->  "MacroRulesFunction(#{@fun})"

class il.GlobalDecl extends il.Element
  constructor: (@args) ->
  side_effects: ( ) ->  false
  to_code: (compiler) ->  "global #{join(', ', x.to_code(compiler) for x in @args)}"
  toString: ( ) ->  "GlobalDecl(#{@args})"

class il.Apply extends il.Element
  constructor: (@caller, @args) ->
  find_assign_lefts: (exp) ->  set()

  analyse: (compiler) ->
    compiler.called_count[@caller] = compiler.called_count.setdefault(@caller, 0)+1
    @caller.analyse(compiler)
    for arg in @args
      arg.analyse(compiler)

  code_size: ( ) ->  @caller.code_size()+sum([x.code_size() for x in @args])

  side_effects: ( ) ->
    if isinstance(@caller, Lamda)
      if @caller.body.side_effects() then  return true
      else if isinstance(@caller, Var) then  return true
      else if @caller.has_side_effects() then return true
      else return false # after cps, all of value have been solved before called,
  # so have no side effects.

  subst: (bindings) ->  new @constructor(@caller.subst(bindings),
                                         (arg.subst(bindings) for arg in @args))

  free_vars: ( ) ->
    result = @caller.free_vars()
    for exp in @args
      result |= exp.free_vars()
    return result

  optimize: (env, compiler) ->
    args = optimize_args(@args, env, compiler)
    if isinstance(@caller, Var)
      if @caller not in compiler.recursive_call_path
        caller = @caller.optimize(env, compiler)
        if isinstance(caller, Lamda)
          compiler.recursive_call_path.push(@caller)
          result = caller.optimize_apply(env, compiler, args)
          compiler.recursive_call_path.pop()
          return result
        else
          return new @constructor(caller, args)
      else
        return new @constructor(@caller, args)
    else if isinstance(@caller, Lamda)
      return @caller.optimize_apply(env, compiler, args)
    else
      caller = @caller.optimize(env, compiler)
      if isinstance(caller, Lamda)
        return caller.optimize_apply(env, compiler, args)
      else
        return new @constructor(caller, args)

  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  javascriptize: (env, compiler) ->
    exps = @caller.javascriptize(env, compiler)
    caller = exps[-1]
    exps = exps[..-1]
    exps2 = javascriptize_args(@args, env, compiler)
    return exps+exps2+[new @constructor(caller,args)]

  to_code: (compiler) ->
    if isinstance(@caller, Lamda)
      "(#{@caller.to_code(compiler)})(#{join(', ', x.to_code(compiler) for x in @args)})"
    else
      @caller.to_code(compiler) + "(#{join(', ', [x.to_code(compiler) for x in @args])})"

  bool: ( ) ->  unknown
  __eq__: (x, y) ->  classeq(x, y) and x.caller==y.caller and x.args==y.args
  toString: ( ) ->  "#{@caller}(#{join(', ', x for x in @args)})"

class il.ExpressionWithCode extends il.Element
  constructor: (@exp, @fun) ->
  analyse: (compiler) -> @fun.analyse(compiler)
  side_effects: ( ) ->  false
  subst: (bindings) ->  ExpressionWithCode(@exp, @fun.subst(bindings))
  code_size: ( ) ->  1
  free_vars: ( ) ->  @fun.free_vars()
  optimize: (env, compiler) ->  ExpressionWithCode(@exp, @fun.optimize(env, compiler))

  javascriptize: (env, compiler) ->
    exps = @fun.javascriptize(env, compiler)
    [ExpressionWithCode(@exp, exps[0])]

  __eq__: (x, y) ->  classeq(x, y) and x.exp==y.exp
  to_code: (compiler) ->  "ExpressionWithCode((#{@exp.to_code(compiler)}), (#{ @fun.to_code(compiler)}))"
  toString: ( ) ->  "ExpressionWithCode(#{@exp}, #{@fun})"

class il.Var extends il.Element
  constructor: (@name) ->
  find_assign_lefts: ( ) ->  set()
  analyse: (compiler) -> compiler.ref_count[@] = compiler.ref_count.setdefault(0)+1
  code_size: ( ) ->  1
  side_effects: ( ) ->  false
  subst: (bindings) ->
    try bindings[@]
    catch e then @
  optimize: (env, compiler) ->
    try env[@]
    catch e then  @
  replace_assign: (compiler) ->
    try env[@]
    catch e then @
  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  javascriptize: (env, compiler) ->  [@]
  to_code: (compiler) ->  @name
  __eq__: (x, y) ->  classeq(x, y) and x.name==y.name
  callOn: (args...) ->  Apply(args)
  free_vars: ( ) ->  set([@])
  bool: ( ) ->  unknown
  __hash__: ( ) ->  hash(@name)
  toString: ( ) ->  @name

class il.RecursiveVar extends il.Var
class il.LocalVar extends il.Var
class il.ConstLocalVar extends il.LocalVar

class il.SolverVar extends il.Var
  constructor: (name) -> @name = 'solver.'+name
  toString: ( ) ->  "il.#{@name.split('.')[1]}"

class il.LogicVar extends il.Element
  constructor: (@name) ->
  find_assign_lefts: (exp) ->  set()
  analyse: (compiler) ->
  subst: (bindings) ->  @
  free_vars: ( ) ->  set()
  side_effects: ( ) ->  false
  optimize: (env, compiler) ->  @
  replace_assign: (compiler) ->  @
  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  javascriptize: (env, compiler) -> [@]

  deref: (bindings) ->
    # todo:
    # how to shorten the binding chain? need to change solver.fail_cont.
    # deref(solver) can help
    x = @
    while 1
      next = bindings[x]
      if not isinstance(next, LogicVar) or next==x
        return next
      else  x = next

  to_code: (compiler) ->   "LogicVar('#{@name}')"
  toString: ( ) ->  "LogicVar(%s)"%@name

class il.DummyVar extends il.LogicVar
  to_code: (compiler) ->   "DummyVar('#{@name}')"

class il.Assign extends il.Element
  constructor: (@var1, @exp) ->
  find_assign_lefts: ( ) ->  set([@var1])
  analyse: (compiler) -> @exp.analyse(compiler)
  insert_return_statement: ( ) ->  begin(Return(@var1))
  code_size: ( ) ->  code_size(@exp)+2
  side_effects: ( ) ->  true
  subst: (bindings) ->  Assign(@var1, @exp.subst(bindings))
  free_vars: ( ) ->  @exp.free_vars()
  right_value: ( ) ->  @exp

  optimize: (env, compiler) ->
    exp = @exp.optimize(env, compiler)
    result = Assign(@var1, exp)
    if isinstance(@var1, ConstLocalVar)
      if (exp instanceof ConstAtom) or (exp instanceof Cons) or (exp instanceof ExpressionWithCode) or (exp instanceof Lamda)
        env[@var1] = exp
        return None
      else if (exp instanceof RulesDict)
        env[@var1] = exp
        exp.name = @var1
        return result
    return result

  javascriptize: (env, compiler) ->
    if not @var1.name.startswith('solver.')
      if isinstance(@exp, Function)
        @exp.name = @var1
      fun = @exp
    else if isinstance(@exp, Lamda) and not isinstance(@exp, MacroLamda)
      fun = Function(@var1, @exp.params, @exp.body)
    else
      fun = None
    if fun isnt None
      result = fun.javascriptize(env, compiler)
      if isinstance(result[0][-1], Var)
        result = [result[0][..-1], result[1]]
      return result
    exps = @exp.javascriptize(env, compiler)
    [exps[..-1]+[Assign(@var1, exps[-1])], true]

  to_code: (compiler) ->
    if isinstance(@exp, RulesDict) and @exp.to_coded then ''
    else "#{@var1.to_code(compiler)} = #{@exp.to_code(compiler)}"

  __eq__: (x, y) ->  classeq(x, y) and x.var1==y.var1 and x.exp==y.exp

  toString: ( ) ->  "#il.Assign(#{@var1}, #{@exp})"

class il.AssignFromList extends il.Element
  constructor: (args...) ->
    @vars = args[..-1]
    @value = args[-1]

  side_effects: ( ) ->  true

  analyse: (compiler) ->
    for var1 in @vars
      var1.analyse(compiler)
    @value.analyse(compiler)

  subst: (bindings) ->  AssignFromList(((var1.subst(bindings) for var1 in @vars)+[@value.subst(bindings)])...)

  code_size: ( ) ->  1

  free_vars: ( ) ->
    result = set(@vars)
    result |= @value.free_vars()
    return result

  optimize: (env, compiler) ->
    value = @value.optimize(env, compiler)
    if isinstance(value, Tuple) or isinstance(value, List)
      if @value.item.length!=@vars.length
        throw new dao.CompileError
      else
        for var1, v in zip(@vars, value.item)
          if isinstance(var1, ConstLocalVar)
            env[var1] = v
          else
            assigns.push(Assign(var1, v))
        if assigns
          return begin((Assign(var1, v))...)
        else return None
      return AssignFromList((@vars+[value])...)

  find_assign_lefts: ( ) ->  set(@vars)

  javascriptize: (env, compiler) ->
    value_exps = @value.javascriptize(env, compiler)
    return value_exps[..-1]+[AssignFromList((@vars+[value_exps[-1]])...)]

  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  bool: ( ) ->  false

  to_code: (compiler) ->  "#{join(', ', [x.to_code(compiler) for x in @vars])} = #{@value.to_code(compiler)}"

  toString: ( ) ->  "il.AssignFromList(#{@vars}, #{@value})"

if_ = (test, then_, else_) -> new il.If(element(test), element(then_), element(else_))

class il.If extends il.Element
  constructor: (@test, @then_, @else_) ->

  find_assign_lefts: ( ) ->  @then_.find_assign_lefts() | @else_.find_assign_lefts()

  analyse: (compiler) ->
    @test.analyse(compiler)
    @then_.analyse(compiler)
    @else_.analyse(compiler)

  code_size: ( ) ->  3 + @test.code_size() + @then_.code_size() + @else_.code_size()

  side_effects: ( ) ->  not (@test.side_effects() or @then_.side_effects()  or  @else_.side_effects())

  subst: (bindings) ->  new il.If(@test.subst(bindings),  @then_.subst(bindings),  @else_.subst(bindings))

  free_vars: ( ) -> @test.free_vars().mergeAt(@then_.free_vars(), @else_.free_vars())

  optimize: (env, compiler) ->
    test = @test.optimize(env, compiler)
    test_bool = test.bool()
    if test_bool==true
      then_ = @then_.optimize(env, compiler)
    if isinstance(then_, il.If) and then_.test==test # (if a (if a b c) d)
      return then_.then_
    else if test_bool==false
      else_ = @else_.optimize(env, compiler)
    if isinstance(else_, il.If) and else_.test==test # (if a b (if a c d))
      return else_.else_
    then_ = @then_.optimize(env, compiler)
    else_ = @else_.optimize(env, compiler)
    if isinstance(then_, il.If) and then_.test==test # (if a (if a b c) d)
      then_ = then_.then_
    if isinstance(else_, il.If) and else_.test==test # (if a b (if a c d))
      else_ = else_.else_
    new il.If(test, then_, else_)

  insert_return_statement: ( ) ->  new il.If(@test,  @then_.insert_return_statement()  @else_.insert_return_statement())
  replace_return_with_pyyield: ( ) -> new il.If(@test, @then_.replace_return_with_pyyield(),  @else_.replace_return_with_pyyield())

  javascriptize: (env, compiler) ->
    test = @test.javascriptize(env, compiler)
    then_ = @then_.javascriptize(env, compiler)
    else_ = @else_.javascriptize(env, compiler)
    if_ = new il.If(test[test.length-1], il.begin(then_...), il.begin(else_...))
    test[...test.length-1].concat([if_])

  to_code: (compiler) ->
    result = "if #{@test.to_code(compiler)}: \n#{compiler.indent(@then_.to_code(compiler))}\n"
    if @else_ isnt il.pseudo_else
      result += "else\n#{compiler.indent(@else_.to_code(compiler))}\n"
    result
#        "(#{@then_.to_code(compiler)} if #{@test.to_code(compiler)} \nelse #{ @else_.to_code(compiler)})"
  __eq__: (x, y) ->  classeq(x, y) and x.test==y.test and x.then==y.then and x.else_==y.else_

  toString: ( ) ->
    if @else_!=il.pseudo_else then  "il.If(#{@test}, \n#{@then_}, \n#{@else_})"
    else  "il.If(#{@test}, \n#{@then_})"

il.if2 = (test, then_) ->  new il.If(test, then_, il.pseudo_else)

class il.PseudoElse extends il.ConstAtom
  constructor: ( ) ->
  code_size: ( ) ->  0
  insert_return_statement: ( ) ->  @
  replace_return_with_pyyield: ( ) ->  @
  to_code: (compiler) ->  ''
  __eq__: (x, y) ->  classeq(x, y)
  toString: ( ) ->  'il.pseudo_else'

il.pseudo_else = new il.PseudoElse()

class il.Cons extends il.ConstAtom
  constructor: (@head, @tail) ->
  code_size: ( ) ->  1
  insert_return_statement: ( ) ->  @
  replace_return_with_pyyield: ( ) ->  @
  to_code: (compiler) ->  "Cons(#{@head.to_code(compiler)}, #{@tail.to_code(compiler)})"
  __eq__: (x, y) ->  classeq(x, y) and x.head==y.head and x.tail==y.tail
  toString: ( ) ->  "il.Cons(#{@head}, #{@tail})"

il.while_ = (test, exps...) -> new il.While(test, begin([x for x in exps]...))

class il.While extends il.Element
  constructor: (@test, @body) ->
  find_assign_lefts: ( ) ->  @body.find_assign_lefts()
  analyse: (compiler) ->
    @test.analyse(compiler)
    @body.analyse(compiler)
  free_vars: ( ) ->  @test.free_vars() | @body.free_vars()
  code_size: ( ) ->  3 + @test.code_size() +@body.code_size()
  side_effects: ( ) ->  not @test.side_effects() and not @body.side_effects()
  subst: (bindings) ->  While(@test.subst(bindings), @body.subst(bindings))

  optimize: (env, compiler) ->
    free_vars = @free_vars()
    test = @test.optimize(env, compiler)
    body = @body.optimize(env, compiler)
    result = While(test,body)
    return result

  insert_return_statement: ( ) ->
    While(@test, @body.insert_return_statement())

  replace_return_with_pyyield: ( ) ->
    While(@test  @body.replace_return_with_pyyield())

  javascriptize: (env, compiler) ->
    test = @test.javascriptize(env, compiler)
    body = @body.javascriptize(env, compiler)
    test[..-1]+[While(test[-1], begin(body...))]

  to_code: (compiler) ->  "while #{@test.to_code(compiler)}:\n#{compiler.indent(@body.to_code(compiler))}\n"

  __eq__: (x, y) ->  classeq(x, y) and x.test==y.test and x.body==y.body
  toString: ( ) ->  "il.While(#{@test}, \n#{@body})"

il.for_ = (var1, range, exps...) -> new il.For(element(var1), element(range), begin([x for x in exps]...))

class il.For extends il.Element
  constructor: (@var1, @range, @body) ->
  find_assign_lefts: ( ) ->  @body.find_assign_lefts()
  analyse:(compiler) ->
    @var1.analyse(compiler)
    @range.analyse(compiler)
    @body.analyse(compiler)

  code_size: ( ) ->  3 + @var1.code_size() + @range.code_size() + @body.code_size()
  side_effects: ( ) ->  not @var1.side_effects() and not @range.side_effects() and not @body.side_effects()
  subst: (bindings) ->  For(@var1.subst(bindings), @range.subst(bindings), @body.subst(bindings))
  free_vars: ( ) ->  @var1.free_vars() | @range.free_vars() | @body.free_vars()
  optimize: (env, compiler) ->
    free_vars = @free_vars()
    assigns = []
    for var1 in free_vars
      value = env[var1]
      if value is undefined then continue
      assigns.push(Assign(var1, value))
      del env[var1]
    return begin(((assigns) + [For(@var1, @range.optimize(env, compiler), @body.optimize(env, compiler))])...)

  insert_return_statement: ( ) ->  For(@var1, @range, @body.insert_return_statement())
  replace_return_with_pyyield: ( ) ->  For(@var1, @range, @body.replace_return_with_pyyield())

  javascriptize: (env, compiler) ->
    var1 = @var1.javascriptize(env, compiler)
    range = @range.javascriptize(env, compiler)
    body = @body.javascriptize(env, compiler)
    return [For(var1[-1], range[-1], begin(body...))]

  to_code: (compiler) ->  "for #{@var1.to_code(compiler)} in #{@range.to_code(compiler)}:\n#{compiler.indent(@body.to_code(compiler))}\n"
  __eq__: (x, y) ->  classeq(x, y) and x.var1==y.var1 and x.range==y.range and x.body==y.body
  toString: ( ) ->  "il.For(#{@var1}, #{@range}, #{@body})"

class il.BinaryOperation extends il.Element
  constructor: (@name, @operator, @has_side_effects=true) ->
  analyse: (compiler) ->  @
  subst: (bindings) ->  @
  optimize: (env, compiler) ->  @
  code_size: ( ) ->  1
  javascriptize: (env, compiler) ->  [@]
  to_code: (compiler) ->  @operator
  callOn: (args...) ->  BinaryOperationApply(args)
  __eq__: (x, y) ->  classeq(x, y) and x.operator==y.operator
  __hash__: ( ) ->  hash(@operator)
  toString: ( ) ->  "il.#{@name}"

class il.BinaryOperationApply extends il.Apply
  constructor: (@caller, @args) ->

  analyse: (compiler) ->
    compiler.called_count[@caller] = compiler.called_count.setdefault(@caller, 0)+1
    @caller.analyse(compiler)
    arg.analyse(compiler) for arg in @args

  code_size: ( ) ->  @caller.code_size()+sum([x.code_size() for x in @args])

  side_effects: ( ) ->
    if isinstance(@caller, Var)  then true
    else if @caller.has_side_effects then return true
    else  return false # after cps, all of value have been solved before called,
  # so have no side effects.

  subst: (bindings) ->  new @constructor(@caller.subst(bindings), (arg.subst(bindings) for arg in @args))

  optimize: (env, compiler) ->
    caller = @caller
    args = optimize_args(@args, env, compiler)
    for arg in args
      if not isinstance(arg, Atom) then  break
      else element(caller.operator_fun((arg.item for arg in args))...)
    return new @constructor(caller, args)

  insert_return_statement: ( ) ->  new il.Return(@)

  javascriptize: (env, compiler) ->
    [exps, args] = javascriptize_args(@args, env, compiler)
    exps+[new @constructor(@caller, args)]

  free_vars: ( ) -> set().mergeAt(arg.free_vars() for arg in @args)

  to_code: (compiler) ->
    if not @caller.operator[0].isalpha()
      return "(#{@args[0].to_code(compiler)})#{ @caller.to_code(compiler)}(#{@args[1].to_code(compiler)})"
    else"(#{@args[0].to_code(compiler)}) #{@caller.to_code(compiler)} (#{ @args[1].to_code(compiler)})"

  toString: ( ) ->  "#{@caller}(#{join(', ', arg for arg in @args)})"

il.addop = new il.BinaryOperation('add', '+', false)
il.subop = new il.BinaryOperation('sub', '-', false)
il.mulop = new il.BinaryOperation('mul', '*', false)
il.divop = new il.BinaryOperation('div', '/', false)
il.isnotop = new il.BinaryOperation('isnot', 'isnt', false)
il.andop = new il.BinaryOperation('and', '&&', false)
il.orop = new il.BinaryOperation('or', '||', false)

il.ltop = new il.BinaryOperation('Lt', '<', false)
il.leop = new il.BinaryOperation('Le', '<=', false)
il.eqop = new il.BinaryOperation('Eq', '==', false)
il.neop = new il.BinaryOperation('Ne', '!=', false)
il.geop = new il.BinaryOperation('Ge', '>=', false)
il.gtop = new il.BinaryOperation('Gt', '>', false)

dao.add = (x, y) -> new dao.Apply(dao.builtinFuntion(il.addop), [x, y])
#    il.add = (x, y) -> new il.BinaryOperationApply(il.addop, [x,y])
#    il.sub = (x, y) -> new il.BinaryOperationApply(il.subop, [x,y])
#    il.mul = (x, y) -> new il.BinaryOperationApply(il.mulop, [x,y])
#    il.div = (x, y) -> new il.BinaryOperationApply(il.divop, [x,y])
#    il.isnot = (x, y) -> new il.BinaryOperationApply(il.isnotop, [x,y])
#    il.and_ = (x, y) -> new il.BinaryOperationApply(il.andop, [x,y])
#    il.or_ = (x, y) -> new il.BinaryOperationApply(il.orop, [x,y])
#
#    il.lt = (x, y) -> new il.BinaryOperationApply(il.ltop, [x,y])
#    il.le = (x, y) -> new il.BinaryOperationApply(il.leop, [x,y])
#    il.eq = (x, y) -> new il.BinaryOperationApply(il.eqop, [x,y])
#    il.ne = (x, y) -> new il.BinaryOperationApply(il.neop, [x,y])
#    il.ge = (x, y) -> new il.BinaryOperationApply(il.geop, [x,y])
#    il.gt = (x, y) -> new il.BinaryOperationApply(il.gtop, [x,y])

class il.VirtualOperation extends il.Element
  constructor: (args...) ->
    if @arity>=0
      assert args.length is @arity,  "#{@name} should have #{@arity} arguments."
    @args = args

  callOn: (args...) ->  Apply(args)
  find_assign_lefts: ( ) ->  set()
  side_effects: ( ) ->  true
  analyse: (compiler) -> for arg in @args then arg.analyse(compiler)
  subst: (bindings) ->  new @constructor((x.subst(bindings) for x in @args)...)
  code_size: ( ) ->  1
  optimize: (env, compiler) ->
    if @has_side_effects then  new @constructor(optimize_args(@args, env,compiler)...)

    args = optimize_args(@args, env,compiler)
    free_vars = set()
    for arg in args
      free_vars |= arg.free_vars()
    for var1 in free_vars
      try assign = env[var1]
      catch e
        if assign isnt undefined then assign.dont_remove()
        result = new @constructor(args...)
    result

  bool: ( ) ->  unknown
  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  javascriptize: (env, compiler) ->
    [exps, args] = javascriptize_args(@args, env, compiler)
    exps+new @constructor(args...)

  to_code: (compiler) ->
    if isinstance(@code_format, String)
      if @constructor.arity==0 then @code_format
      else if @constructor.arity!=-1
        @code_format % (x.to_code(compiler) for x in @args)
      else @code_format % (join(', ', [x.to_code(compiler) for x in @args]))
    else @code_format(compiler)

  __eq__: (x, y) ->  classeq(x, y) and x.args==y.args
  __hash__: ( ) ->  hash(@constructor.name)

  free_vars: ( ) -> set().mergeAt(arg.free_vars() for arg in @args)

  toString: ( ) ->
    try if @arity==0 then "il.#{@constructor.name}"
    catch e then "il.#{@constructor.name}(#{join(', ', x for x in @args)})"

class il.Deref extends il.Element
  constructor: (@item) ->
  side_effects: ( ) ->  false
  analyse: (compiler) -> @item.analyse(compiler)
  subst: (bindings) ->  Deref(@item.subst(bindings))
  code_size: ( ) ->  1
  free_vars: ( ) ->  @item.free_vars()
  optimize: (env, compiler) ->
    item = @item.optimize(env, compiler)
    if isinstance(item, Atom) or isinstance(item, Lamda) then item
    if isinstance(item, Deref) then return item
    return Deref(item)

  javascriptize: (env, compiler) ->
    exps = @item.javascriptize(env, compiler)
    return exps[..-1]+[new @constructor(exps[-1])]

  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  to_code: (compiler) ->   "deref(#{@item.to_code(compiler)}, solver.bindings)"
  toString: ( ) ->  "il.Deref(#{@item})"

class il.EvalExpressionWithCode extends il.Element
  constructor: (@item) ->
  side_effects: ( ) ->  true
  analyse: (compiler) -> @item.analyse(compiler)
  subst: (bindings) ->  EvalExpressionWithCode(@item.subst(bindings))
  code_size: ( ) ->  1
  free_vars: ( ) ->  @item.free_vars()
  optimize: (env, compiler) ->
    item = @item.optimize(env, compiler)
    if isinstance(item, Var)
      return EvalExpressionWithCode(item)
    else if isinstance(item, ExpressionWithCode)
      return item.fun.body.optimize(env, compiler)
    else return item

  javascriptize: (env, compiler) ->
    exps = @item.javascriptize(env, compiler)
    return exps[..-1]+[new @constructor(exps[-1])]

  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  to_code: (compiler) ->   "(#{@item.to_code(compiler)}).fun()"
  toString: ( ) ->  "il.EvalExpressionWithCode(#{@item})"

class il.Len extends il.Element
  constructor: (@item) ->
  side_effects: ( ) ->  false
  analyse: (compiler) -> @item.analyse(compiler)
  subst: (bindings) ->  new il.Len @item.subst(bindings)
  code_size: ( ) ->  1
  free_vars: ( ) ->  @item.free_vars()
  optimize: (env, compiler) ->
    item = @item.optimize(env, compiler)
    if isinstance(item, Atom) or isinstance(item, MacroArgs)
      return new il.Integer(item.item.length)
    new il.Len(item)

  javascriptize: (env, compiler) ->
    exps = @item.javascriptize(env, compiler)
    exps[..-1]+[new il.Len(exps[-1])]

  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  to_code: (compiler) ->   "#{@item.to_code(compiler)}.length"
  toString: ( ) ->  "il.Len(#{@item})"

class il.In extends il.Element
  constructor: (@item, @container) ->
  side_effects: ( ) ->  false
  analyse: (compiler) ->
    @item.analyse(compiler)
    @container.analyse(compiler)
  subst: (bindings) ->  In(@item.subst(bindings), @container.subst(bindings))
  code_size: ( ) ->  1
  free_vars: ( ) -> @item.free_vars().unionAt(@container.free_vars())
  optimize: (env, compiler) ->
    item = @item.optimize(env, compiler)
    container = @container.optimize(env, compiler)
    if isinstance(item, Atom)
      if isinstance(container, Atom)
        return Bool(item.value in container.value)
      else if isinstance(container, RulesDict)
        return Bool(item.item in container.arity_body_map)
    In(item, container)

  javascriptize: (env, compiler) ->
    exps1 = @item.javascriptize(env, compiler)
    exps2 = @container.javascriptize(env, compiler)
    exps1[..-1]+exps2[..-1]+[In(exps1[-1], exps2[-1])]

  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  bool: ( ) ->
    if isinstance(@item, Atom)
      if isinstance(@container, Atom)
        return @item.value in @container.value
      else if isinstance(@container, RulesDict)
        return [@item.value, @container.arity_body_map]
    il.unknown

  to_code: (compiler) ->   "(#{@item.to_code(compiler)}) in (#{@container.to_code(compiler)})"
  toString: ( ) ->  "il.In(#{@item}, #{@container})"

class il.GetItem extends il.Element
  constructor: (@container, @index) ->
  side_effects: ( ) ->  false
  analyse: (compiler) ->
    @index.analyse(compiler)
    @container.analyse(compiler)
  subst: (bindings) ->  GetItem(@container.subst(bindings), @index.subst(bindings))
  code_size: ( ) ->  1
  free_vars: ( ) -> @index.free_vars().unionAt(@container.free_vars())

  optimize: (env, compiler) ->
    index = @index.optimize(env, compiler)
    container = @container.optimize(env, compiler)
    if isinstance(index, Atom)
      if isinstance(container, Atom)
        return element(container.item[index.item])
    else if isinstance(container, RulesDict)
      return element(container.arity_body_map[index.item])
      #try
      #return element(container.arity_body_map[index.item])
      #catch e
      #return GetItem(container, index)
    else if isinstance(container, MacroArgs)
      return container.item[index.item]
    GetItem(container, index)

  javascriptize: (env, compiler) ->
    container_exps = @container.javascriptize(env, compiler)
    index_exps = @index.javascriptize(env, compiler)
    container_exps[..-1]+index_exps[..-1]+[GetItem(container_exps[-1], index_exps[-1])]

  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  bool: ( ) ->
    if isinstance(@index, Atom)
      if isinstance(@container, Atom)
        return Bool(bool(@container.value[@index.value]))
    else if isinstance(@container, RulesDict)
      return Bool(bool(@container.arity_body_map[@index.value]))
    il.unknown
  to_code: (compiler) ->   "(#{@container.to_code(compiler)})[#{@index.to_code(compiler)}]"
  toString: ( ) ->  "il.GetItem(#{@container}, #{@index})"

class il.ListAppend extends il.Element
  constructor: (@container, @value) ->
  side_effects: ( ) ->  true
  analyse: (compiler) ->
    @value.analyse(compiler)
    @container.analyse(compiler)
  subst: (bindings) ->  ListAppend(@container.subst(bindings), @value.subst(bindings))
  code_size: ( ) ->  1
  free_vars: ( ) -> @value.free_vars().unionAt(@container.free_vars())
  optimize: (env, compiler) ->
    value = @value.optimize(env, compiler)
    new il.ListAppend(@container, value)

  find_assign_lefts: ( ) ->  if isinstance(@container, Var) then set([@container]) else set()

  javascriptize: (env, compiler) ->
    container_exps = @container.javascriptize(env, compiler)
    value_exps = @value.javascriptize(env, compiler)
    container_exps[..-1]+value_exps[..-1]+[ListAppend(container_exps[-1], value_exps[-1])]

  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  bool: ( ) ->  false
  to_code: (compiler) ->   "#{@container.to_code(compiler)}.push(#{@value.to_code(compiler)})"
  toString: ( ) ->  "il.ListAppend(#{@container}, #{@value})"

il.catch_cont_map = new il.SolverVar('catch_cont_map')

class il.PushCatchCont extends il.Element
  constructor: (@tag, @cont) ->
  side_effects: ( ) ->  true

  analyse: (compiler) ->
    @tag.analyse(compiler)
    @cont.analyse(compiler)

  subst: (bindings) ->  PushCatchCont(@tag.subst(bindings), @cont.subst(bindings))
  code_size: ( ) ->  1
  free_vars: ( ) -> set([catch_cont_map]).unionAt(@tag.free_vars()).unionAt(@cont.free_vars())
  optimize: (env, compiler) ->
    tag = @tag.optimize(env, compiler)
    cont = @cont.optimize(env, compiler)
    PushCatchCont(tag, cont)

  javascriptize: (env, compiler) ->
    tag_exps = @tag.javascriptize(env, compiler)
    cont_exps = @cont.javascriptize(env, compiler)
    tag_exps[..-1]+cont_exps[..-1]+[PushCatchCont(tag_exps[-1], cont_exps[-1])]

  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  bool: ( ) ->  false
  to_code: (compiler) ->  "solver.catch_cont_map.setdefault(#{@tag}, []).push(#{@cont})"
  toString: ( ) ->  "il.PushCatchCont(#{@tag}, #{@cont})"

class il.SetBinding extends il.Element
  constructor: (@var1, @value) ->
  side_effects: ( ) ->  true

  analyse: (compiler) ->
    @var1.analyse(compiler)
    @value.analyse(compiler)

  subst: (bindings) ->  SetBinding(@var1.subst(bindings), @value.subst(bindings))
  code_size: ( ) ->  1
  free_vars: ( ) ->  @value.free_vars()

  optimize: (env, compiler) ->
    value = @value.optimize(env, compiler)
    SetBinding(@var1, value)

  javascriptize: (env, compiler) ->
    var1 = @var1.item if isinstance(@var1, Deref) else @var1
    var_exps = [var1]
    value_exps = @value.javascriptize(env, compiler)
    var_exps[..-1]+value_exps[..-1]+[SetBinding(var_exps[-1], value_exps[-1])]

  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  bool: ( ) ->  false
  to_code: (compiler) ->  "solver.bindings[#{@var1.to_code(compiler)}] = #{ @value.to_code(compiler)}"
  toString: ( ) ->  "il.SetBinding(#{@var1}, #{@value})"

class il.FindCatchCont extends il.Element
  constructor: (@tag) ->
  side_effects: ( ) ->  true
  callOn: (value) ->  Apply([value])
  analyse: (compiler) -> @tag.analyse(compiler)
  subst: (bindings) ->  FindCatchCont(@tag.subst(bindings))
  code_size: ( ) ->  1
  free_vars: ( ) -> set([catch_cont_map]).unionAt(@tag.free_vars())
  optimize: (env, compiler) -> tag = @tag.optimize(env, compiler);  FindCatchCont(tag)

  javascriptize: (env, compiler) ->
    tag_exps = @tag.javascriptize(env, compiler)
    tag_exps[..-1]+[FindCatchCont(tag_exps[-1])]

  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  bool: ( ) ->  false
  to_code: (compiler) ->  "solver.find_catch_cont.callOn(#{@tag})"
  toString: ( ) ->  "il.FindCatchCont(#{@tag})"
  AddAssign: (var1, value) ->  Assign(var1, BinaryOperationApply(add, [var1, value]))

class il.IsMacro extends il.Element
  constructor: (@item) ->
  side_effects: ( ) ->  false
  free_vars: ( ) ->  @item.free_vars()
  analyse: (compiler) -> @item.analyse(compiler)
  subst: (bindings) ->  new @constructor(@item.subst(bindings))
  code_size: ( ) ->  1
  optimize: (env, compiler) ->  new @constructor(@item.optimize(env, compiler))
  javascriptize: (env, compiler) ->
    exps = @item.javascriptize(env, compiler)
    return exps[..-1]+[new @constructor(exps[-1])]
  insert_return_statement: ( ) ->  Return(@)
  replace_return_with_pyyield: ( ) ->  @
  bool: ( ) ->
    if isinstance(@item, Macro) then true
    else if isinstance(@item, Lamda) then false
    else thenn unknown

  to_code: (compiler) ->   "isinstance(#{@item.to_code(compiler)}, Macro)"
  toString: ( ) ->  "il.IsMacro(#{@item})"

class il.IsMacroRules extends il.IsMacro
  bool: ( ) ->
    if isinstance(@item, MacroRules) then true
    else if isinstance(@item, Lamda) then false
    else unknown

  to_code: (compiler) ->   "isinstance(#{item.to_code(compiler)}, MacroRules)"
  toString: ( ) ->  "il.IsMacroRules(#{@item})"

il.vop = vop = (name, arity, code_format, has_side_effects) ->
  class Vop extends il.VirtualOperation
    name: name
    __name__: name
    arity: arity
    code_format: code_format
    has_side_effects: has_side_effects
  Vop

class il.VirtualOperation2 extends il.VirtualOperation
  insert_return_statement: ( ) ->  new il.Begin(new il.Return())
  replace_return_with_pyyield: ( ) ->  @

il.vop2 = vop2 = (name, arity, code_format, has_side_effects) ->
  class Vop extends il.VirtualOperation2
    __name__:name
    name: name
    arity: arity
    code_format: code_format
    has_side_effects: has_side_effects
  return Vop

class il.LogicOperation extends il.VirtualOperation
class il.BinaryLogicOperation extends il.VirtualOperation
class il.UnaryLogicOperation extends il.VirtualOperation

Call_to_code = (compiler) ->  "(#{@args[0].to_code(compiler)})(#{join(', ', [x.to_code(compiler) for x in @args[1..]])})"
il.Call = vop('Call', -1, Call_to_code, true)

il.Attr = vop('Attr', 2, '%s.%s', false)

AttrCall_to_code = (compiler) ->  "#{@args[0].to_code(compiler)}(#{join(', ', [x.to_code(compiler) for x in @args[1..]])})"
il.AttrCall = vop('AttrCall', -1, AttrCall_to_code, true)

il.SetItem = vop2('SetItem', 3, '(%s)[%s] = %s', true)
#  SetItem(item, key, value) ->  Assign(GetItem(item, key), value)

il.Slice2 = vop('Slice2', 2, '%s:%s', false)

il.Not = vop('Not', 1, "not %s", false)

il.Isinstance = vop('Isinstance', 2, "isinstance(%s, %s)", false)

empty_list = new il.List([])

empty_dict = new il.Dict({})

il.RaiseTypeError = vop2('RaiseTypeError', 1, 'throw new %s', true)

il.RaiseException = vop2('RaiseException', 1, 'throw new %s', true)

QuoteItem_to_code = (compiler) ->  "#{@args[0]}"
il.QuoteItem = vop('QuoteItem', 1, QuoteItem_to_code, false)

il.UnquoteSplice = vop('UnquoteSplice', 1, "UnquoteSplice(%s)", false)

il.MakeTuple = vop('MakeTuple', 1, '(%s)', false)

il.Cle = vop('Cle', 3, '(%s) <= (%s) <= (%s)', false)

il.Cge = vop('Cge', 3, '(%s) >= (%s) >= (%s)', false)

il.failcont = new il.SolverVar('fail_cont')

il.SetFailCont = (cont) ->  new il.Assign(failcont, cont)

append_failcont = (compiler, exps...) ->
  v =  compiler.new_var(ConstLocalVar('v'))
  fc = compiler.new_var(ConstLocalVar('fc'))
  return Begin(
                Assign(fc, failcont),
                SetFailCont(
                             clamda(v,
                                    SetFailCont(fc),
                                    begin(exps...),
                                    fc(v)))
              )

il.cut_cont = new il.SolverVar('cut_cont')

SetCutCont = (cont) ->  new il.Assign(cut_cont, cont)

il.cut_or_cont = new il.SolverVar('cut_or_cont')

il.SetCutOrCont = (cont) ->  new il.Assign(cut_or_cont, cont)

il.IsLogicVar = vop('IsLogicVar', 1, 'isinstance(%s, LogicVar)', false)

il.DelBinding = vop2('DelBinding', 1, 'del solver.bindings[%s]', true)
il.DelItem = vop2('DelItem', 2, 'del %s[%s]', true)


il.GetValue = vop('GetValue', 1, 'get_value(%s, {}, solver.bindings)', false)

il.parse_state = new il.SolverVar('parse_state')
SetParseState = (state) ->  new il.Assign(parse_state, state)

il.Unify = vop('Unify', 2, 'solver.unify(%s, %s)', false)
il.Nil = vop('Nil', 0, 'nil', false)
il.nil = new il.Nil()


il.bindings = new il.SolverVar('bindings')
SetBindings = (bindings1) ->  new il.Assign(bindings, bindings1)

il.ConsHead = vop('ConsHead', 1, '(%s).head', false)
il.ConsTail = vop('ConsTail', 1, '(%s).tail', false)

il.Optargs = vop('Optargs', 1, '*%s', false)

il.Continue = vop('Continue', 0, "continue\n", false)
continue_ = new il.Continue()

il.Prin = vop2('Prin', 1, "print %s,", true)
il.PrintLn = vop2('PrintLn', 1, "print %s", true)

il.DelListItem = vop2('DelListItem', 2, 'del %s[%s]', true)

il.MakeList = vop('MakeList', 1, '[%s]', false)


il.Copy = vop('Copy', 1, '(%s).copy()', false)

il.Assert = vop('Assert', 1, 'assert %s', false)
il.Int = new il.Symbol('int')

Format_to_code = (compiler) ->  "#{@args[0].to_code(compiler)}%#{join(', ', x.to_code(compiler) for x in @args[1..])}"
il.Format = vop('Format', -1,Format_to_code, false)

Concat_to_code = (compiler) ->  '%s'%''.join([arg.to_code(compiler) for arg in @args])
il.Concat = vop('Concat', -1, Concat_to_code, false)

Format_to_code = (compiler) ->  "file(#{@args[0].to_code(compiler)}, #{join(', ', x.to_code(compiler) for x in @args[1...])})"

il.OpenFile = vop('OpenFile', -1, Format_to_code, true)

il.CloseFile = vop('CloseFile', 1, "%s.close()", true)
il.ReadFile = vop('ReadFile', 1, '%s.read()', true)
il.Readline = vop('ReadLine', 1, '%s.readline()', true)
il.Readlines = vop('Readlines', 1, '%s.readlines()', true)
il.WriteFile = vop('WriteFile', 2, '%s.write(%s)', true)
