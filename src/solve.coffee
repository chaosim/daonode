''' some basic utilities for solve dao expression.'''

'''code for compilation:
-> alpha convert
-> cps convert
-> optimize
-> tail recursive convert
-> javascriptize
-> generate code
'''

'''
I = require 'utils'
I.at "solvebase.Solutions compile.compileToJSFile"
I.use "compilebase: Environment, Compiler"
I.at "command.element"
I.use "compilebase: CompileTypeError, VariableNotBound, import_names"
il = I.from "dao: interlang"
'''

utils = require "f:/node-utils/src/set"

set = utils.set

isinstance = (x, klass) -> (x instanceof klass)
assert = (arg,  message) -> unless arg then throw new Error(message or '')
len = (obj) -> obj.length
tuple = (obj) -> obj
join = (sep, list) -> list.join(sep)
repr = (x) -> x.toString()

prelude = '''
          # generated file from compiled daonode expression.
          from dao.builtins import *
          from dao.command import LogicVar as DaoLogicVar
          from dao.command import Var as DaoVar
          from dao.solvebase import Solver, NoSolution
          from dao.solvebase import deref, get_value, LogicVar, DummyVar
          from dao.solvebase import Cons, nil
          from dao.solvebase import UnquoteSplice, ExpressionWithCode
          from dao.solvebase import Macro, MacroFunction, MacroRules
          from dao.solve import eval as eval_exp
          from dao.command import BuiltinFunctionCall
          from dao import interlang as il
          '''

exports.dao = dao = {}

dao.compileToJSFile = (exp, env) ->
  code = compileToJavascript exp, env
  fs = require "fs"
  fs.writeSync fs.openSync('f:\\daonode\\test\\compiled.js', 'w'), code

compileToJavascript = (exp, env) ->
  '''assemble steps from dao expression to javascript code'''
  original_exp = exp
  compiler = new Compiler()
  exp = element(exp)
  exp = exp.alpha(env, compiler)
  exp = exp.cps(compiler, compiler.cont)
  exp.analyse(compiler)
  env = new Environment()
  exp = exp.optimize(env, compiler)
  #exp = exp.tail_recursive_convert()
  exp = il.begin(exp.javascriptize(env, compiler)[0])
  if isinstance(exp, il.Begin)
    exp = exp.statements[0]
  exp = new il.Lamda([], exp)
  exp.body = exp.body.replace_return_with_pyyield()
  exp = new il.Call(exp, new il.ConstLocalVar('this'))
  exp.to_code(compiler)
#  return prelude + result

solve = (exp, env) ->
  compileToJSFile exp, env
  compiled = require 'f:\\daonode\\test\\bin\\compiled.js'
  Solutions(exp, compiled.fun())

evald = (exp, env) ->  solve(exp, env).next()

class BaseCommand

class Exception

class DaoStopIteration extends Exception

class DaoUncaughtThrow  extends Exception
  constructor: (@tag) ->

class  DaoSyntaxError  extends Exception

class DaoError  extends Exception
  constructor: (@message) ->
  toString: () -> @message

class NoSolution
  constructor: (@exp) ->
  toString: () -> @exp.toString()

class Solutions
  constructor: (@exp, @solutions) ->
  next: () ->
    try @solutions.next()
    catch StopIteration
      throw new NoSolution(@exp)

class Bindings
  getitem:  (variable) ->
    try dict.getitem(variable)
    catch e then variable

  setitem: (variable, value) -> dict.setitem(variable, value)

  detitem: (variable) ->
    try dict.detitem(variable)
    catch e then KeyError ->

  copy: () -> Bindings(dict.copy())

  deref: (exp, bindings) ->
    try exp_deref = exp.deref
    catch e then return exp
    exp_deref(bindings)

  get_value: (exp, memo, bindings) ->
    try exp_getvalue = exp.getvalue
    catch e then return exp
    return exp_getvalue(memo, bindings)

class LogicVar
  constructor: (@name) ->

  deref: (bindings) ->
    # todo:
    # how to shorten the binding chain? need to change solver.fail_cont.
    # deref(solver) can help
    while 1
      next = bindings[@]
      if not isinstance(next, LogicVar) or next==@
        return next
      else result = next

  getvalue: (memo, bindings) ->
    try return memo[@]
    catch e
      result = LogicVar.deref(bindings)
      if isinstance(result, LogicVar)
        memo[@] = result
        return result
      try result_getvalue = result.getvalue
      catch e
        memo[@] = result
        return result
      return result_getvalue(memo, bindings)

  unify: (x, y, solver) ->
    solver.bindings[x] = y
    return true

  __eq__: (x, y) -> x.constructor is y.constructor and x.name==y.name
  __hash__: () ->  hash(@name)
  toString: () ->  "%s"%@name

class DummyVar extends LogicVar
  deref: (bindings) -> @

class Cons
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
    return Cons(head, tail)

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
  length: () ->  len([e for e in @])
  toString: () ->  "L(#{join(' ', [repr(e) for e in @])})"

cons = (head, tail) -> new Cons head, tail

class Nil
  alpha: (env, compiler) -> new il.Nil()
  length: () ->  0
  __iter__: () -> if 0 then pyyield
  toString: () ->  'nil'

nil = new Nil()

conslist = (elements...) ->
  result = nil
  for term in reversed(elements)
    result = new Cons(term, result)
  return result

cons2tuple:(item) ->
  if not isinstance(item, Cons) and not isinstance(item, list)  and not isinstance(item, tuple)
     item
  else tuple(cons2tuple(x) for x in item)

class UnquoteSplice
  constructor: (Qitem) ->
  toString: () ->  ',@%s'%@item

class ExpressionWithCode
  constructor: (@exp, @fun) ->
  __eq__: (x, y) ->  (x.constructor is y.constructor and x.exp==y.exp) or x.exp==y

  __iter__ = () ->  iter(@exp)

  toString: () -> repr(@exp)

class Macro

class MacroFunction extends Macro
  constructor: (@fun) ->
  callOn:(args...) ->  @fun(args...)

class MacroRules extends Macro
  constructor: (@fun) ->
  callOn: (args...) -> @fun(args...)
  default_end_cont: (v) -> throw new NoSolution(v)

class Solver
  constructor: () ->
    @bindings = new Bindings() # for logic variableiableiable, unify
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
    catch e then throw new DaoUncaughtThrow(tag)
    return cont_stack.pop()

class CompileError extends Exception

class CompileTypeError  extends CompileError
  constructor:(@exp) ->
  toString: () -> '%s'%repr(@exp)

class ArityError extends CompileError

class VariableNotBound extends CompileError
  constructor:(@variable) ->
  toString: () -> '%s'%repr(@variable)

class DaoNotImplemented extends CompileError
  constructor:(@message) ->
  toString: () -> @message

class Environment
    '''environment for compile, especilly for alpha convert, block/exit/continue'''
    constructor:(@outer) -> @bindings = {}
    extend: () -> Environment()

    getitem: (variable) ->
      try  return @bindings[variable]
      catch e
        result = @outer
        while result isnt undefined
          try return @bindings[variable]
          catch e then result = @outer
        throw new VariableNotBound(variable)

    setitem: (variable, value) ->  @bindings[variable] = value

    toString: () ->
      result = ''
      while x isnt undefined
        result += repr(@bindings)
        x = @outer
      return result

class Compiler
  constructor: (env = new Environment(), options) ->
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
    @ref_count = {} # variable's reference count
    @called_count = {} # lambda's reference count
    @occur_count = {}
    @recursive_call_path = []

    @lamda_stack = []
    @recusive_variables_stack = [set()]


  new_var: (variable) ->
    try
      suffix = str(@newvar_map[variable.name])
      @newvar_map[variable.name] += 1
      return variable.constructor(variable.name+suffix)
    catch e
      @newvar_map[variable.name] = 1
      return variable

  get_inner_block_label: () ->
    if @block_label_stack
      return @block_label_stack[-1][1]
    else
      throw new make_new  BlockError("should not escape from top level outside of all block.")

  get_block_label: (old_label) ->
    for i in range(len(@block_label_stack))
      if old_label==@block_label_stack[-(i+1)][0]
        return @block_label_stack[-(i+1)][1]
      throw new BlockError("Block %s is not found."%old_label)

  indent: (code, level=1) ->
    '''javascript's famous indent'''
    lines = code.split('\n')
    lines = tuple(@indent_space*level + line for line in lines)
    return join('\n', lines)

MAX_EXTEND_CODE_SIZE = 10

import_names = []

register_fun = (name, fun) ->
  name = new_func_name(name)
  fun.func_name = name
  globals()[name] = fun
  import_names.append(name)
  return fun

new_func_name_map = {}

new_func_name = (name) ->
  try
    suffix = str(new_func_name_map[name])
    new_func_name_map[name] += 1
    return name+suffix
  catch e
    new_func_name_map[name] = 1
    return name

#from dao.compilebase import CompileTypeError, VariableNotBound

element = (exp)->
  if isinstance(exp, Element) then exp
  else
    try type_map[type(exp)](exp)
    catch e then throw new make_new CompileTypeError(exp)

class Element

class Atom extends Element
  constructor: (@item) ->
  alpha: (env, compiler) -> @
  cps: (compiler, cont) ->  cont.callOn(@interlang())
  quasiquote: (compiler, cont) -> cont.callOn(@interlang())
  subst: (bindings) -> @
  interlang: ( ) -> new il.Atom(@item)
  __eq__: (x, y) ->  x.constructor is y.constructor and x.item==y.item
  to_code: (compiler) -> "#{@constructor.__name__}(#{@item})"
  toString: ( ) ->  '%s'%@item

class Integer extends Atom
  __eq__: (x, y) -> Atom.__eq__(x, y) or (isinstance(y, int) and x.item==y)
  interlang: ( ) -> new il.Integer(@item)

dao.integer = (value) -> new Integer(1)

class Float extends Atom
  __eq__: (x, y) -> Atom.__eq__(x, y) or (isinstance(y, float) and x.item==y)
  interlang: ( ) ->  new il.Float(@item)

class String extends Atom
  __eq__: (x, y) ->  Atom.__eq__(x, y) or (isinstance(y, str) and x.item==y)
  interlang: ( ) ->  new il.String(@item)

class List extends Atom
  __eq__: (x, y) ->  Atom.__eq__(x, y) or (isinstance(y, list) and x.item==y)
  interlang: ( ) -> new il.List(@item)

class Dict extends Atom
  __eq__: (x, y) ->  Atom.__eq__(x, y) or (isinstance(y, dict) and x.item==y)
  interlang: ( ) ->  new il.Dict(@item)

class Bool extends Atom
  __eq__: (x, y) ->  Atom.__eq__(x, y) or (isinstance(y, bool) and x.item==y)
  interlang: ( ) ->  new il.Bool(@item)

class Symbol extends Atom
  __eq__: (x, y) ->  classeq(x, y) and x.item==y.item
  interlang: ( ) ->  new il.Symbol(@item)

class Klass extends Atom
  toString: ( ) ->  'Klass(%s)'%(@item)
  interlang: ( ) ->  new il.Klass(@item)

class PyFunction extends Atom
  toString: ( ) ->  'PyFunction(%s)'%(@item)
  interlang: ( ) ->  new il.PyFunction(@item)

TRUE = new Bool(true)
FALSE = new Bool(false)
NULL = new Atom(null)

make_tuple = (value) -> new Tuple(tuple(element(x) for x in value)...)

class Tuple extends Atom
  constructor: (items...)-> @item = items
  interlang: ( ) ->  new il.Tuple(tuple(x.interlang() for x in @item)...)
  to_code:  (compiler) -> "#{@constructor.__name__}(#{join(', ', [repr(x) for x in @item])})"
  __iter__: ( ) ->  iter(@item)
  toString: ( ) ->  "#{@constructor.__name__}(#{@item})"

class Var extends Element
  constructor: (@name) ->
  callOn: (args...) -> Apply(tuple(element(arg) for arg in args))
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
      x1 = compiler.new_var(new ConstLocalVar(x.name))
      return il.begin(
                       new il.Assign(x1, new il.Deref(x)), #for LogicVar, could be optimized when generate code.
                       new il.If(il.IsLogicVar(x1),
                             il.begin(il.SetBinding(x1, y),
                                      il.append_failcont.callOn(compiler, new il.DelBinding(x1)),
                                      cont.callOn(il.TRUE)),
                             new il.If(il.Eq(x1, y), cont.callOn(il.TRUE), il.failcont.callOn(il.TRUE))))
    x = x.interlang()
    y = y.interlang()
    x1 = compiler.new_var(new ConstLocalVar(x.name))
    y1 = compiler.new_var(new ConstLocalVar(y.name))
    return il.begin(
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
    throw new make_new CompileTypeError(@)

    fun = compiler.new_var(new ConstLocalVar('fun'))
    vars = tuple(compiler.new_var(new ConstLocalVar('a'+repr(i))) for i in range(len(args)))
    body = new il.Apply(fun, [cont]+vars)
    for var1, item in reversed(zip(vars, args))
      body = item.cps(compiler, il.clamda(var1, body))
      v = compiler.new_var(new ConstLocalVar('v'))
      macro_args1 = tuple(il.ExpressionWithCode(arg, new il.Lamda([], arg.cps(compiler, il.clamda(v, v))))  for arg in args)
      macro_args2 = il.macro_args macro_args1
    return @cps(compiler, il.clamda(fun,
                                    new il.If(il.IsMacro(fun),
                                          new il.If(il.IsMacroRules(fun),
                                                new il.Apply(fun, [cont, macro_args2]),
                                                new il.Apply(fun, [cont]+macro_args1)),
                                          body)))

  interlang: ( ) ->  new il.Var(@name)
  free_vars: ( ) ->  set([@])
  to_code: (compiler) -> "DaoVar('%s')"%@name
  __eq__: (x, y) ->  classeq(x, y) and x.name==y.name
  hash: ( ) ->  hash(@name)
  toString: ( ) ->  "#{@constructor.__name__}('#{@name}')"

class Const extends Var
  interlang: ( ) ->  new ConstLocalVar(@name)

class LamdaVar extends Var
  cps_call:(compiler, cont, args) ->
    #fun = compiler.new_var(new ConstLocalVar('fun'))
    fun = @interlang()
    vars = tuple(compiler.new_var(new ConstLocalVar('a'+repr(i)))  for i in range(len(args)))
    body = new il.Apply(fun, [cont]+vars)
    for var1, item in reversed(zip(vars, args))
      body = item.cps(compiler, il.clamda(var1, body))
    v = compiler.new_var(make_new ConstLocalVar('v'))
    return @cps(compiler, il.clamda(fun,body))

class MacroVar extends Var
  cps_call:(compiler, cont, args) ->
    fun = @interlang()
    k = compiler.new_var(new ConstLocalVar('cont'))
    v = compiler.new_var(new ConstLocalVar('v'))
    #macro_args = tuple(il.Lamda((), arg.cps(compiler, il.clamda(v, v)))
    #for arg in args)
    macro_args = tuple(il.Lamda([k], arg.cps(compiler, k)) for arg in args)
    return @cps(compiler, il.clamda(fun, new il.Apply(fun, [cont]+macro_args)))

class ConstLamdaVar extends LamdaVar #, Const)
  interlang: ( ) ->  new ConstLocalVar(@name)

class ConstMacroVar extends MacroVar #, Const):
  interlang: ( ) ->  new ConstLocalVar(@name)

class RecursiveFunctionVar extends ConstLamdaVar
  interlang: ( ) ->  new il.RecursiveVar(@name)

class RecursiveMacroVar extends ConstMacroVar
  interlang: ( ) ->  new il.RecursiveVar(@name)

class LogicVar extends Var
  alpha: (env, compiler) -> @
  interlang: ( ) ->  new il.LogicVar(@name)
  cps: (compiler, cont) -> cont.callOn(il.LogicVar(@name))
  to_code: (compiler) -> "DaoLogicVar('%s')"%@name
  __eq__: (x, y) ->  classeq(x, y) and x.name==y.name
  toString: ( ) ->  "DaoLogicVar('%s')"%@name

class DummyVar extends LogicVar
  interlang: ( ) ->  new il.DummyVar(@name)
  cps: (compiler, cont) -> cont.callOn(il.Deref(il.DummyVar(@name)))
  to_code: (compiler) -> "DaoDummyVar('%s')"%@name
  cons: (head, tail) -> Cons(element(head), element(tail))

class Cons extends Element
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
    return Cons(head, tail)

  getvalue: (env) ->
    head = getvalue(@head, env)
    tail = getvalue(@tail, env)
    if head is @head and tail is @tail then @
    else Cons(head, tail)

  copy: (memo) -> Cons(copy(@head, memo), copy(@tail, memo))
  __eq__: (other) -> @constructor is other.constructor and @head==other.head and @tail==other.tail

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

  length: ( ) ->  len([e for e in @])
  toString: ( ) ->  "L(#{join(' ', [repr(e) for e in @])})"

class Nil extends Element
  alpha: (env, compiler) -> @
  interlang: ( ) ->  il.nil
  length: ( ) ->  0
  __iter__: ( ) -> if 0 then pyield
  toString: ( ) ->  'nil'

nil = new Nil()

conslist = (elements...) ->
  result = nil
  for term in reversed(elements)
    result = Cons(element(term), result)
  return result

cons2tuple = (item) ->
  if not isinstance(item, Cons) and not isinstance(item, list)  and not isinstance(item, tuple)
    return item
  return tuple(cons2tuple(x) for x in item)

cps_convert_unify_two_var = (x, y, compiler, cont) ->
  x = x.interlang()
  y = y.interlang()
  x1 = compiler.new_var(new ConstLocalVar(x.name))
  y1 = compiler.new_var(new ConstLocalVar(y.name))
  return il.begin(
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
  x1 = compiler.new_var(new ConstLocalVar(x.name))
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
        v = compiler.new_var(new ConstLocalVar('v'))
        return cps_convert_unify(x.head, y.head, compiler, il.clamda(v,
                                                                     cps_convert_unify(x.tail, y.tail, compiler, cont)))
      else
        if x==y then cont.callOn(il.TRUE)
        else il.failcont.callOn(il.FALSE)

class Apply extends Element
  constructor: (@caller, @args) ->
  alpha: (env, compiler) ->  @constructor(@caller.alpha(env, compiler),  tuple(arg.alpha(env, compiler) for arg in @args))
  # see The 90 minute Scheme to C compiler by Marc Feeley
  cps: (compiler, cont) ->  @caller.cps_call(compiler, cont, @args)
  subst: (bindings) -> @constructor(@caller.subst(bindings),
                                tuple(arg.subst(bindings) for arg in @args))
  toString: ( ) ->  "#{@caller}(#{join(', ', [repr(x) for x in @args])})"

class Command extends Element

class CommandCall extends Element
  constructor: (@fun, @args) ->
  subst: (bindings) -> @constructor(@fun,  tuple(arg.subst(bindings) for arg in @args))

  quasiquote:(compiler, cont) ->
    result = compiler.new_var(il.LocalVar('result'))
    vars = tuple(compiler.new_var(new ConstLocalVar('a'+repr(i))) for i in range(len(@args)))
    t = tuple(
               new il.If(il.Isinstance(var1, new il.Klass('UnquoteSplice')),
                     new il.AddAssign(result, new il.Call(il.Symbol('list'), new il.Attr(var1, new il.Symbol('item')))),
                     new il.ListAppend(result, var1)
                    ) for var1 in vars+[cont.callOn(il.Call(il.Klass(@constructor.__name__), new il.QuoteItem(@fun), new il.MakeTuple(result)))]
    body = [il.Assign(result, il.empty_list)]+t)
    fun = il.begin(body...)
    for var1, arg in reversed(zip(vars, @args))
      fun = arg.quasiquote(compiler, il.clamda(var1, fun))
    return fun

  __eq__: (x, y) ->  classeq(x, y) and x.fun==y.fun and x.args==y.args
  toString: ( ) ->  "#{@fun}(#{join( ', ', [repr(x) for x in @args])})"

class Special extends Command
  constructor: (@fun) ->
  callOn: (args...) ->
    args = tuple(element(arg) for arg in args)
    return SpecialCall(args)
  toString: ( ) ->  @fun.__name__

special = Special

quasiquote_args: (args) ->
  if not args then pyield []
  else if len(args)==1
    for x in @quasiquote(args[0])
      try pyield x.unquote_splice
      catch e then pyield [x]
  else
    for x in @quasiquote(args[0])
      for y in @quasiquote_args(args[1..])
        try x = x.unquote_splice
        catch e then x = [x]
        pyield x+y

class SpecialCall extends CommandCall
  constructor: (@command, @args) -> @fun = command.fun

  alpha: (env, compiler) -> @constructor(@command, tuple(arg.alpha(env, compiler) for arg in @args))

  cps: (compiler, cont) -> @fun(compiler, cont, @args...)
  to_code: (compiler) -> "#{@fun.__name__}(#{join(', ', [x.to_code(compiler) for x in @args])})"

  free_vars: ( ) ->
    result = set()
    for arg in @args then  result |= arg.free_vars()
    return result

  toString: ( ) ->  "#{@fun.__name__}(#{join(', ', tuple(repr(x) for x in @args))})"

class BuiltinFunction extends Command
  constructor: (@name, @fun) ->

  callOn:(args...) ->
    args = tuple(element(arg) for arg in args)
    return BuiltinFunctionCall(args)

  cps: (compiler, cont) -> new il.Lamda((params), @fun.fun(params...))
  analyse: (compiler) -> @
  subst: (bindings) -> @
  optimize: (env, compiler) -> @
  javascriptize: (env, compiler) -> []
  toString: ( ) ->  @name

class BuiltinFunctionCall extends CommandCall
  alpha:(env, compiler) -> @constructor(@fun, tuple(arg.alpha(env, compiler) for arg in @args))

  cps:(compiler, cont) ->
    #see The 90 minute Scheme to C compiler by Marc Feeley
    args = @args
    vars = tuple(compiler.new_var(new ConstLocalVar('a'+repr(i))) for i in range(len(args)))
    fun = cont.callOn(@fun.fun(vars...))
    for var1, arg in reversed(zip(vars, args))
      fun = arg.cps(compiler, new il.Clamda(var1, fun))
    return fun

# unquote to interlang level
  analyse: (compiler) ->
  optimize: (env, compiler) -> @
  interlang: ( ) ->  @
  free_vars: ( ) ->
    result = set()
    for arg in @args then result |= arg.free_vars()
    return result

  javascriptize: (env, compiler) -> [@]
  to_code: (compiler) -> "#{@fun.name}(#{join(', ', [x.to_code(compiler) for x in @args])})"
  toString: ( ) ->  "#{@fun.name}(#{join(', ', [x.to_code(compiler) for x in @args])})"
  assign: (var1, exp) -> Assign(var1, element(exp))

class MultiAssignToConstError
  constructor: (@const) ->
  toString: ( ) ->  repr(@const)

class Assign extends CommandCall
  constructor: (@var1, @exp) ->
  subst: (bindings) -> Assign(@var1, @exp.subst(bindings))
  alpha: (env, compiler) ->
    try
      var1 = env[@var1]
    catch VariableNotBound
      env[@var1] = var1 = compiler.new_var(@var1)
      if isinstance(var1, Const)
        var1.assigned = true
        return Assign(var1, @exp.alpha(env, compiler))
    if isinstance(var1, Const) and var1.assigned
      throw new make_new MultiAssignToConstError(var1)
      return Assign(var1, @exp.alpha(env, compiler))

  cps: (compiler, cont) ->
    v = compiler.new_var(new ConstLocalVar('v'))
    return @exp.cps(compiler,
                    il.clamda(v, new il.Assign(@var1.interlang(), v), cont.callOn(v)))

  __eq__: (x, y) ->  classeq(x, y) and x.var1==y.var1 and x.exp==y.exp
  to_code: (compiler) ->  repr(@)
  toString: ( ) ->  "assign#{@var1}, #{@exp})"
  direct_interlang: (exps...) ->  DirectInterlang(il.begin(exps...))

class DirectInterlang extends Element
  constructor: (@body) ->
  alpha: (env, compiler) ->  @
  cps: (compiler, cont) ->  cont.callOn(@body)

  expression_with_code: (compiler, cont, exp) ->
    v = compiler.new_var(new ConstLocalVar('v'))
    return cont.callOn(il.ExpressionWithCode(exp, new il.Lamda([], exp.cps(compiler, il.clamda(v, v)))))

type_map = {int:Integer, float: Float, str:String, unicode: String
  tuple: make_tuple, list:List, dict:Dict,
  bool:Bool
} #type(lambda:1):PyFunction  type(undefined) : Atom

il = interlang = {}

do ->
    # interlang

    #true == 1
    #false==0
    il.unknown = -1

    il.element = (exp) ->
      if isinstance(exp, il.Element) then exp
      else
        try type_map[type(exp)](exp)
        catch e then throw new make_new CompileTypeError(exp)

    no_side_effects = (exp) ->
      fun: ( ) ->  false
      exp.side_effects = fun
      return exp

    optimize_args = (args, env, compiler) ->
      result = []
      for arg in args
        arg = arg.optimize(env, compiler)
        if arg isnt undefined
          result.append(arg)
      return tuple(result)

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
      toString: ( ) ->  @constructor.__name__

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
      to_code: (compiler) ->  repr(@item)
      free_vars: ( ) ->  set()
      bool: ( ) -> if @item then true  else false
      __eq__: (x, y) ->  classeq(x, y) and x.item==y.item
      __hash__: ( ) ->  hash(@item)
      toString: ( ) ->  '%s'%@item

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
      toString: ( ) ->  'il.Klass(%s)'%(@item)

    class il.PyFunction extends il.ConstAtom
      to_code: (compiler) ->  @item.func_name
      toString: ( ) ->  'il.PyFunction(%s)'%(@item)


    il.TRUE = new il.Bool(true)
    il.FALSE = new il.Bool(false)
    il.NULL = new il.Atom(null)

    make_tuple = (item) ->  new il.Tuple(tuple(element(x) for x in item)...)

    class il.Tuple extends il.ConstAtom
      constructor: (@item...) ->
      find_assign_lefts: ( ) ->  set()
      analyse: (compiler) ->
        for x in @item then x.analyse(compiler)
      side_effects: ( ) ->  false
      subst: (bindings) ->  Tuple(tuple(x.subst(bindings) for x in @item)...)
      code_size: ( ) ->  sum([x.code_size() for x in @item])
      optimize: (env, compiler) ->  Tuple(tuple(x.optimize(env, compiler) for x in @item)...)
      to_code: (compiler) ->
        if len(@item)!=1 then  "(#{join(', ', [x.to_code(compiler) for x in @item])})"
        else  "(#{@item[0].to_code(compiler)}, )"
      __eq__: (x, y) ->  classeq(x, y) and x.item==y.item
      toString: ( ) ->  "il.#{@constructor.__name__}(#{@item})"

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

      subst: (bindings) ->  MacroArgs(tuple(x.subst(bindings) for x in @item))

      javascriptize: (env, compiler) ->
        exps = []
        args = []
        for arg in @item
          exps1 = arg.javascriptize(env, compiler)
          exps += exps1[..-1]
          args.append(exps1[-1])
          exps.append(MacroArgs(tuple(args)))
        return tuple(exps)

      code_size: ( ) ->  sum([x.code_size() for x in @item])

      to_code: (compiler) ->
        if len(@item)!=1
          return '(%s)'% join(', ', [x.to_code(compiler) for x in @item])
        else return '(%s, )'%@item[0].to_code(compiler)

      __eq__: (x, y) ->  classeq(x, y) and x.item==y.item
      toString: ( ) ->  "il.#{@constructor.__name__}(#{@item})"

    class il.Return extends il.Element
      constructor: (@args...) ->
      analyse: (compiler) ->  for arg in @args then  arg.analyse(compiler)
      code_size: ( ) ->  sum([code_size(x) for x in @args])
      side_effects: ( ) ->  false
      free_vars: ( ) ->
        result = set()
        for x in @args then  result |= x.free_vars()
        return result

      subst: (bindings) -> @constructor(tuple(arg.subst(bindings) for arg in @args)...)

      optimize: (env, compiler) ->
        if len(@args)==1 and isinstance(@args[0], Return)
          return @constructor(@args[0].args...)
        else
          for arg in @args
            if isinstance(arg, Return)  then throw new make_new CompileError
          return @constructor(optimize_args(@args, env, compiler)...)

      javascriptize: (env, compiler) ->
        if len(@args)==1 and isinstance(@args[0], Begin)
          return Begin(@args[0].statements[..-1]+[Return(@args[0].statements[-1])]).javascriptize(env, compiler)
        else if len(@args)==1 and isinstance(@args[0], If)
          return If(@args[0].test, Return(@args[0].then), Return(@args[0].else_)).javascriptize(env, compiler)
        [exps, args] = javascriptize_args(@args, env, compiler)
        return [exps+[@constructor(args...)], true]

      to_code: (compiler) ->   "return #{join(', ', [x.to_code(compiler) for x in @args])}"
      insert_return_statement: ( ) ->  Return(@args...)
      replace_return_with_pyyield: ( ) ->  Begin([Yield(@args...), Return()])
      __eq__: (x, y) ->  classeq(x, y) and x.args==y.args
      toString: ( ) ->  "il.Return(#{','.join([repr(x) for x in @args])})"

    class il.Yield extends il.Return
      to_code: (compiler) ->   "pyield #{join(', ', [x.to_code(compiler) for x in @args])}"
      insert_return_statement: ( ) ->  @
      toString: ( ) ->  "il.Yield(#{join(', ', [repr(x) for x in @args])})"

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
          if e is NULL and i!=length-1 then continue
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
      subst: (bindings) ->  Begin(tuple(x.subst(bindings) for x in @statements))

      free_vars: ( ) -> set().merge(exp.free_vars() for exp in @statements)

      code_size: ( ) ->  1
      analyse: (compiler) -> for x in @statements then x.analyse(compiler)

      optimize: (env, compiler) ->
        result = []
        for arg in @statements
          arg1 = arg.optimize(env, compiler)
          if arg1 isnt undefined
            result.append(arg1)
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

      replace_return_with_pyyield: ( ) ->  Begin(tuple(exp.replace_return_with_pyyield() for exp in @statements))

      javascriptize: (env, compiler) ->
        result = []
        for exp in @statements
          exps2 = exp.javascriptize(env, compiler)
          result += exps2
        return result

      to_code: (compiler) ->   '\n'.join([x.to_code(compiler) for x in @statements])
      __eq__: (x, y) ->  classeq(x, y) and x.statements==y.statements
      toString: ( ) ->  'il.begin(%s)'%'\n '.join([repr(x) for x in @statements])


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

    il.nil = new Nil()

    type_map = {int:il.Integer, float: il.Float, str:il.String, unicode: il.String
      tuple: make_tuple, list:il.List, dict:il.Dict
      bool:il.Bool
    }
    type_map[typeof undefined] = il.Atom

    ########################################################
    #

    #from dao.base import classeq
    #
    #from dao.compilebase import MAX_EXTEND_CODE_SIZE
    #from dao.compilebase import VariableNotBound, CompileTypeError
    #
    #from element import javascriptize_args, optimize_args
    #from element import Element, begin, Return, Begin
    #from element import NULL, unknown, make_tuple, Tuple, ConstAtom, Tuple, List

    il.lamda = (params, body...) ->  new il.Lamda(params, begin(body...))

    class il.Lamda extends il.Element
      constructor: (@params, @body) -> @has_javascriptized = false
      make_new: (params, body) ->  new il.Lamda(params, body)
      callOn: (args...) ->  Apply(args)
      find_assign_lefts: ( ) ->  @body.find_assign_lefts()
      analyse: (compiler) ->
        compiler.lamda_stack.append(@)
        @body.analyse(compiler)
        compiler.lamda_stack.pop()
      code_size: ( ) ->  @body.code_size()+len(@params)+2
      side_effects: ( ) ->  false

      subst: (bindings) ->
        result = @make_new(@params, @body.subst(bindings))
        return result

      optimize: (env, compiler) ->
        env = env.extend()
        body = @body.optimize(env, compiler)
        result = @make_new(@params, body)
        return result

      optimize_apply: (env, compiler, args) ->
        #1. ((lambda () body))  =>  body
        if len(@params)==0
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
            return Apply(@make_new(new_params, @body.subst(bindings).optimize(env, compiler)),
                         tuple(arg.optimize(env, compiler) for arg in new_args))
          else
            if len(new_params)!=len(@params)
              Apply(@make_new(new_params, @body.subst(bindings).optimize(env, compiler)),
                    tuple(arg.optimize(env, compiler) for arg in new_args))
            else  Apply(@make_new(new_params, @body.optimize(env, compiler)),
                        optimize_args(new_args, env, compiler))
        else
          if bindings then @body.subst(bindings).optimize(env, compiler)
          else  @body.optimize(env, compiler)

      insert_return_statement: () ->  new il.Return(@)

      javascriptize: (env, compiler) ->
        if @has_javascriptized then return [@name]
        @has_javascriptized = true
        body_exps = @body.javascriptize(env, compiler)
        [@make_new(@params, il.begin(body_exps...))]

      to_code: (compiler) -> "function (#{join(', ', tuple(x.to_code(compiler) for x in @params))}) { "  + @body.to_code(compiler)+";}"

      free_vars: ( ) ->  @body.free_vars()-set(@params)
      bool: ( ) ->  true
      __eq__: (x, y) ->  classeq(x, y) and x.params==y.params and x.body==y.body
      __hash__: ( ) ->  hash(id(@))
      toString: ( ) ->  "il.Lamda((#{join(', ', [repr(x) for x in @params])}), \n#{repr(@body)})"

    class il.RulesLamda extends il.Lamda
      constructor: (@params, @body) ->  @has_javascriptized = false
      callOn: (args...) ->  Apply(tuple(element(x) for x in args))

      optimize_apply: (env, compiler, args) ->  Lamda.optimize_apply(env, compiler, args)

      to_code: (compiler) -> "lambda #{@params[0].to_code(compiler)}, #{@params[1].to_code(compiler)}: " + @body.to_code(compiler)

    clamda = (v, body...) -> new il. Clamda(v, begin(body...))

    class il.Clamda extends il.Lamda
      constructor: (v, @body) ->
        @has_javascriptized = false
        @params = [v]
        @name = undefined

      make_new: (params, body) ->  @constructor(params[0], body)

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

      toString: ( ) ->  "il.Clamda(#{@params[0]}, \n#{ repr(@body)})"

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

      make_new: (params, body) ->  @constructor(@params[0])
      callOn: (args...) ->
        bindings = {}
        bindings[@params[0]] = args[0]
        @body.subst(bindings)
      replace_assign: (bindings) ->  @
      toString: ( ) ->  "il.Done(#{@params[0]}, #{repr(@body)})"

    class il.Function extends il.Lamda
      constructor: (@name, @params, @body) ->

    il.cfunction = (name, v, body...) ->  new il.CFunction(name, v, begin(body...))

    class il.CFunction extends il.Function
      is_fun: true
      constructor: (name, v, body) ->
      make_new: (params, body) ->  @constructor(@name, params[0], body)
      optimize_apply: (env, compiler, args) ->
        new_env = env.extend()
        bindings = {}
        bindings[@params[0]] = args[0]
        body = @body.subst(bindings)
        body = body.optimize(new_env, compiler)
        result = CFunction(@name, @params[0], body)(NULL)
        return result
      toString: ( ) ->  "il.CFunction(#{@name}, #{@params[0]}, \n#{repr(@body)})"

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

      toString: ( ) ->  'RulesDict(%s)'%@arity_body_map

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

      toString: ( ) ->  "il.MacroLamda((#{join(', ', [repr(x) for x in @params])}), \n#{repr(@body)})"

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
          return [MacroRulesFunction(@make_new(@params, begin(body_exps...)))]
        else
        name = compiler.new_var(LocalVar('fun'))
        body = begin(body_exps...).insert_return_statement()
        return [new il.Function(name, @params, body), MacroRulesFunction(name)]

    class il.MacroFunction extends il.Element
      constructor: (@fun) ->
      to_code: (compiler) ->  'MacroFunction(%s)'%@fun.to_code(compiler)
      toString: ( ) ->  'MacroFunction(%s)'%@fun

    class il.MacroRulesFunction extends il.Element
      constructor: (@fun) ->
      to_code: (compiler) ->  'MacroRules(%s)'%@fun
      toString: ( ) ->  'MacroRulesFunction(%s)'%@fun

    class il.GlobalDecl extends il.Element
      constructor: (@args) ->
      side_effects: ( ) ->  false
      to_code: (compiler) ->  "global %s" % (join(', ', [x.to_code(compiler) for x in @args]))
      toString: ( ) ->  'GlobalDecl(%s)'%@args

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

      subst: (bindings) ->  @constructor(@caller.subst(bindings),
                                       tuple(arg.subst(bindings) for arg in @args))

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
              compiler.recursive_call_path.append(@caller)
              result = caller.optimize_apply(env, compiler, args)
              compiler.recursive_call_path.pop()
              return result
            else
              return @constructor(caller, args)
          else
            return @constructor(@caller, args)
        else if isinstance(@caller, Lamda)
          return @caller.optimize_apply(env, compiler, args)
        else
          caller = @caller.optimize(env, compiler)
          if isinstance(caller, Lamda)
            return caller.optimize_apply(env, compiler, args)
          else
            return @constructor(caller, args)

      insert_return_statement: ( ) ->  Return(@)
      replace_return_with_pyyield: ( ) ->  @
      javascriptize: (env, compiler) ->
        exps = @caller.javascriptize(env, compiler)
        caller = exps[-1]
        exps = exps[..-1]
        exps2 = javascriptize_args(@args, env, compiler)
        return exps+exps2+[@constructor(caller,args)]

      to_code: (compiler) ->
        if isinstance(@caller, Lamda)
          return "(%s)"%@caller.to_code(compiler) + '(%s)'%join(', ', [x.to_code(compiler) for x in @args])
        else
          return @caller.to_code(compiler) + '(%s)'%join(', ', [x.to_code(compiler) for x in @args])

      bool: ( ) ->  unknown
      __eq__: (x, y) ->  classeq(x, y) and x.caller==y.caller and x.args==y.args
      toString: ( ) ->  "#{@caller}(#{join(', ', [repr(x) for x in @args])})"

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
      toString: ( ) ->  'il.%s'%@name.split('.')[1]

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
        self = @
        while 1
          next = bindings[self]
          if not isinstance(next, LogicVar) or next==self
            return next
          else  self = next

      to_code: (compiler) ->   "LogicVar('%s')"%@name
      toString: ( ) ->  "LogicVar(%s)"%@name

    class il.DummyVar extends il.LogicVar
      to_code: (compiler) ->   "DummyVar('%s')"%@name

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
          if isinstance(exp, ConstAtom) or isinstance(exp, Cons) or isinstance(exp, ExpressionWithCode) or isinstance(exp, Lamda)
            env[@var1] = exp
            return None
          else if isinstance(exp, RulesDict)
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

      subst: (bindings) ->  AssignFromList((tuple(var1.subst(bindings) for var1 in @vars)+[@value.subst(bindings)])...)

      code_size: ( ) ->  1

      free_vars: ( ) ->
        result = set(@vars)
        result |= @value.free_vars()
        return result

      optimize: (env, compiler) ->
        value = @value.optimize(env, compiler)
        if isinstance(value, Tuple) or isinstance(value, List)
          if len(value.item)!=len(@vars)
            throw new make_new DaoCompileError
          else
            for var1, v in zip(@vars, value.item)
              if isinstance(var1, ConstLocalVar)
                env[var1] = v
              else
                assigns.append(Assign(var1, v))
            if assigns
              return begin(tuple(Assign(var1, v))...)
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

      subst: (bindings) ->  new If(@test.subst(bindings),  @then_.subst(bindings),  @else_.subst(bindings))

      free_vars: ( ) ->
        result = set()
        result |= @test.free_vars()
        result |= @then_.free_vars()
        result |= @else_.free_vars()
        return result

      optimize: (env, compiler) ->
        test = @test.optimize(env, compiler)
        test_bool = test.bool()
        if test_bool==true
          then_ = @then_.optimize(env, compiler)
        if isinstance(then_, If) and then_.test==test # (if a (if a b c) d)
          then_ = then_.then_
          return then_
        else if test_bool==false
          else_ = @else_.optimize(env, compiler)
        if isinstance(else_, If) and else_.test==test # (if a b (if a c d))
          else_ = else_.else_
          return else_
        then_ = @then_.optimize(env, compiler)
        else_ = @else_.optimize(env, compiler)
        if isinstance(then_, If) and then_.test==test # (if a (if a b c) d)
          then_ = then_.then_
        if isinstance(else_, If) and else_.test==test # (if a b (if a c d))
          else_ = else_.else_
          return If(test, then_, else_)

      insert_return_statement: ( ) ->  If(@test,  @then_.insert_return_statement()  @else_.insert_return_statement())


      replace_return_with_pyyield: ( ) ->
        If(@test, @then_.replace_return_with_pyyield(),  @else_.replace_return_with_pyyield())

      javascriptize: (env, compiler) ->
        test = @test.javascriptize(env, compiler)
        then_ = @then_.javascriptize(env, compiler)
        else_ = @else_.javascriptize(env, compiler)
        if_ = If(test[-1], begin(then_...), begin(else_...))
        test[..-1]+[if_]

      to_code: (compiler) ->
        if @is_statement
          result = "if #{@test.to_code(compiler)}: \n#{compiler.indent(@then_.to_code(compiler))}\n"
        if @else_!=pseudo_else
          result += 'else\n%s\n'% compiler.indent(@else_.to_code(compiler))
          return result
        else "(#{@then_.to_code(compiler)} if #{@test.to_code(compiler)} \nelse #{ @else_.to_code(compiler)})"
      __eq__: (x, y) ->  classeq(x, y) and x.test==y.test and x.then==y.then and x.else_==y.else_

      toString: ( ) ->
        if @else_!=pseudo_else then  "il.If(#{@test}, \n#{@then_}, \n#{else_})"
        else  "il.If(#{@test}, \n#{@then_})"

    il.if2 = (test, then_) ->  new il.If(test, then_, pseudo_else)

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

    for_ = (var1, range, exps...) -> new il.For(element(var1), element(range), begin([x for x in exps]...))

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
          assigns.append(Assign(var1, value))
          del env[var1]
        return begin((tuple(assigns) + [For(@var1, @range.optimize(env, compiler), @body.optimize(env, compiler))])...)

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
      constructor: (@name, @operator, @operator_fun, @has_side_effects=true) ->
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

# where is the things like the python'operator and python' operation overloading?
#    il.add = new il.BinaryOperation('add', '+', operator.add, false)
#    il.sub = new il.BinaryOperation('sub', '-', operator.sub, false)
#    il.mul = new il.BinaryOperation('mul', '*', operator.mul, false)
#    il.div = new il.BinaryOperation('div', '/', operator.div, false)
#    il.IsNot = new il.BinaryOperation('is_not', 'is not', operator.is_not, false)
#    il.anndop = new il.BinaryOperation('and', 'and', operator.and_, false)
#    il.orop = new il.BinaryOperation('or', 'or', operator.or_, false)
#
#    il.lt = new il.BinaryOperation('Lt', '<', operator.lt, false)
#    il.le = new il.BinaryOperation('Le', '<=', operator.le, false)
#    il.eq = new il.BinaryOperation('Eq', '==', operator.eq, false)
#    il.ne = new il.BinaryOperation('Ne', '!=', operator.ne, false)
#    il.ge = new il.BinaryOperation('Ge', '>=', operator.ge, false)
#    il.gt = new il.BinaryOperation('Gt', '>', operator.gt, false)

    il.and_ = (exps...) ->  if len(exps) is 2 then And(exps...)  else And(exps[0], and_(exps[1..]...))

    il.or_ = (exps...) ->  if len(exps) is 2 then Or(exps...)  else Or(exps[0], or_(exps[1...]))

    class il.BinaryOperationApply extends il.Apply
      constructor: (@caller, @args) ->

      analyse: (compiler) ->
        compiler.called_count[@caller] = compiler.called_count.setdefault(@caller, 0)+1
        @caller.analyse(compiler)
        for arg in @args
          arg.analyse(compiler)

      code_size: ( ) ->  @caller.code_size()+sum([x.code_size() for x in @args])

      side_effects: ( ) ->
        if isinstance(@caller, Var)  then true
        else if @caller.has_side_effects then return true
        else  return false # after cps, all of value have been solved before called,
      # so have no side effects.

      subst: (bindings) ->  @constructor(@caller.subst(bindings),
                                     tuple(arg.subst(bindings) for arg in @args))

      optimize: (env, compiler) ->
        caller = @caller
        args = optimize_args(@args, env, compiler)
        for arg in args
          if not isinstance(arg, Atom) then  break
          else element(caller.operator_fun(tuple(arg.item for arg in args))...)
        return @constructor(caller, args)

      insert_return_statement: ( ) ->  Return(@)

      javascriptize: (env, compiler) ->
        [exps, args] = javascriptize_args(@args, env, compiler)
        exps+[@constructor(@caller, args)]

      free_vars: ( ) ->
        result = set()
        for arg in @args
          result |= arg.free_vars()
        return result

      to_code: (compiler) ->
        if not @caller.operator[0].isalpha()
          return "(#{@args[0].to_code(compiler)})#{ @caller.to_code(compiler)}(#{@args[1].to_code(compiler)})"
        else"(#{@args[0].to_code(compiler)}) #{@caller.to_code(compiler)} (#{ @args[1].to_code(compiler)})"

      toString: ( ) ->  "#{@caller}(#{join(', ', [repr(arg) for arg in @args])})"

    class il.VirtualOperation extends il.Element
      constructor: (args...) ->
        if @arity>=0
          assert args.length is @arity,  "#{@name} should have #{@arity} arguments."
        @args = args

      callOn: (args...) ->  Apply(args)
      find_assign_lefts: ( ) ->  set()
      side_effects: ( ) ->  true
      analyse: (compiler) -> for arg in @args then arg.analyse(compiler)
      subst: (bindings) ->  @constructor(tuple(x.subst(bindings) for x in @args)...)
      code_size: ( ) ->  1
      optimize: (env, compiler) ->
        if @has_side_effects then  @constructor(optimize_args(@args, env,compiler)...)

        args = optimize_args(@args, env,compiler)
        free_vars = set()
        for arg in args
          free_vars |= arg.free_vars()
        for var1 in free_vars
          try assign = env[var1]
          catch e
            if assign isnt undefined then assign.dont_remove()
            result = @constructor(args...)
        return result

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
            @code_format % tuple(x.to_code(compiler) for x in @args)
          else
            @code_format % (join(', ', [x.to_code(compiler) for x in @args]))
        else
          @code_format(compiler)

      __eq__: (x, y) ->  classeq(x, y) and x.args==y.args
      __hash__: ( ) ->  hash(@constructor.__name__)

      free_vars: ( ) ->
        result = set()
        for arg in @args
          result |= arg.free_vars()
        return result

      toString: ( ) ->
        try if @arity==0 then "il.#{@constructor.__name__}"
        catch e then "il.#{@constructor.__name__}(#{join(', ', [repr(x) for x in @args])})"

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
        return exps[..-1]+[@constructor(exps[-1])]

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
        return exps[..-1]+[@constructor(exps[-1])]

      insert_return_statement: ( ) ->  Return(@)
      replace_return_with_pyyield: ( ) ->  @
      to_code: (compiler) ->   "(#{@item.to_code(compiler)}).fun()"
      toString: ( ) ->  "il.EvalExpressionWithCode(#{@item})"

    class il.Len extends il.Element
      constructor: (@item) ->
      side_effects: ( ) ->  false
      analyse: (compiler) -> @item.analyse(compiler)
      subst: (bindings) ->  Len(@item.subst(bindings))
      code_size: ( ) ->  1
      free_vars: ( ) ->  @item.free_vars()
      optimize: (env, compiler) ->
        item = @item.optimize(env, compiler)
        if isinstance(item, Atom) or isinstance(item, MacroArgs)
          return Integer(len(item.item))
        return Len(item)

      javascriptize: (env, compiler) ->
        exps = @item.javascriptize(env, compiler)
        return exps[..-1]+[Len(exps[-1])]

      insert_return_statement: ( ) ->  Return(@)
      replace_return_with_pyyield: ( ) ->  @
      to_code: (compiler) ->   'len(%s)'%@item.to_code(compiler)
      toString: ( ) ->  'il.Len(%s)'%@item

    class il.In extends il.Element
      constructor: (@item, @container) ->
      side_effects: ( ) ->  false
      analyse: (compiler) ->
        @item.analyse(compiler)
        @container.analyse(compiler)
      subst: (bindings) ->  In(@item.subst(bindings), @container.subst(bindings))
      code_size: ( ) ->  1
      free_vars: ( ) ->
        result = set()
        result |= @item.free_vars()
        result |= @container.free_vars()
        return result

      optimize: (env, compiler) ->
        item = @item.optimize(env, compiler)
        container = @container.optimize(env, compiler)
        if isinstance(item, Atom)
          if isinstance(container, Atom)
            return Bool(item.value in container.value)
          else if isinstance(container, RulesDict)
            return Bool(item.item in container.arity_body_map)
        return In(item, container)

      javascriptize: (env, compiler) ->
        exps1 = @item.javascriptize(env, compiler)
        exps2 = @container.javascriptize(env, compiler)
        return exps1[..-1]+exps2[..-1]+[In(exps1[-1], exps2[-1])]

      insert_return_statement: ( ) ->  Return(@)
      replace_return_with_pyyield: ( ) ->  @
      bool: ( ) ->
        if isinstance(@item, Atom)
          if isinstance(@container, Atom)
            return @item.value in @container.value
          else if isinstance(@container, RulesDict)
            return [@item.value, @container.arity_body_map]
        return unknown

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
      free_vars: ( ) ->
        result = set()
        result |= @index.free_vars()
        result |= @container.free_vars()
        return result

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
        return GetItem(container, index)

      javascriptize: (env, compiler) ->
        container_exps = @container.javascriptize(env, compiler)
        index_exps = @index.javascriptize(env, compiler)
        return container_exps[..-1]+index_exps[..-1]+[GetItem(container_exps[-1], index_exps[-1])]

      insert_return_statement: ( ) ->  Return(@)
      replace_return_with_pyyield: ( ) ->  @
      bool: ( ) ->
        if isinstance(@index, Atom)
          if isinstance(@container, Atom)
            return Bool(bool(@container.value[@index.value]))
        else if isinstance(@container, RulesDict)
          return Bool(bool(@container.arity_body_map[@index.value]))
        return unknown
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
      free_vars: ( ) ->
        result = set()
        result |= @value.free_vars()
        result |= @container.free_vars()
        return result
      optimize: (env, compiler) ->
        value = @value.optimize(env, compiler)
        return ListAppend(@container, value)

      find_assign_lefts: ( ) ->  if isinstance(@container, Var) then set([@container]) else set()

      javascriptize: (env, compiler) ->
        container_exps = @container.javascriptize(env, compiler)
        value_exps = @value.javascriptize(env, compiler)
        container_exps[..-1]+value_exps[..-1]+[ListAppend(container_exps[-1], value_exps[-1])]

      insert_return_statement: ( ) ->  Return(@)
      replace_return_with_pyyield: ( ) ->  @
      bool: ( ) ->  false
      to_code: (compiler) ->   "#{@container.to_code(compiler)}.append(#{@value.to_code(compiler)})"
      toString: ( ) ->  "il.ListAppend(#{@container}, #{@value})"

    catch_cont_map = new il.SolverVar('catch_cont_map')

    class il.PushCatchCont extends il.Element
      constructor: (@tag, @cont) ->
      side_effects: ( ) ->  true

      analyse: (compiler) ->
        @tag.analyse(compiler)
        @cont.analyse(compiler)

      subst: (bindings) ->  PushCatchCont(@tag.subst(bindings), @cont.subst(bindings))
      code_size: ( ) ->  1
      free_vars: ( ) ->
        result = set([catch_cont_map])
        result |= @tag.free_vars()
        result |= @cont.free_vars()
        return result

      optimize: (env, compiler) ->
        tag = @tag.optimize(env, compiler)
        cont = @cont.optimize(env, compiler)
        return PushCatchCont(tag, cont)

      javascriptize: (env, compiler) ->
        tag_exps = @tag.javascriptize(env, compiler)
        cont_exps = @cont.javascriptize(env, compiler)
        return [tag_exps[..-1]+cont_exps[..-1]+[PushCatchCont(tag_exps[-1], cont_exps[-1])], true]

      insert_return_statement: ( ) ->  Return(@)
      replace_return_with_pyyield: ( ) ->  @
      bool: ( ) ->  false
      to_code: (compiler) ->  "solver.catch_cont_map.setdefault(#{@tag}, []).append(#{@cont})"
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
        return SetBinding(@var1, value)

      javascriptize: (env, compiler) ->
        var1 = @var1.item if isinstance(@var1, Deref) else @var1
        var_exps = [var1]
        value_exps = @value.javascriptize(env, compiler)
        return var_exps[..-1]+value_exps[..-1]+[SetBinding(var_exps[-1], value_exps[-1])]

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
      free_vars: ( ) ->
        result = set([catch_cont_map])
        result |= @tag.free_vars()
        return result

      optimize: (env, compiler) ->
        tag = @tag.optimize(env, compiler)
        return FindCatchCont(tag)

      javascriptize: (env, compiler) ->
        tag_exps = @tag.javascriptize(env, compiler)
        return tag_exps[..-1]+[FindCatchCont(tag_exps[-1])]

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
      subst: (bindings) ->  @constructor(@item.subst(bindings))
      code_size: ( ) ->  1
      optimize: (env, compiler) ->  @constructor(@item.optimize(env, compiler))
      javascriptize: (env, compiler) ->
        exps = @item.javascriptize(env, compiler)
        return exps[..-1]+[@constructor(exps[-1])]
      insert_return_statement: ( ) ->  Return(@)
      replace_return_with_pyyield: ( ) ->  @
      bool: ( ) ->
        if isinstance(@item, Macro) then true
        else if isinstance(@item, Lamda) then false
        else thenn unknown

      to_code: (compiler) ->   "isinstance(#{@item.to_code(compiler)}, Macro)"%
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
      return Vop

    class il.VirtualOperation2 extends il.VirtualOperation
      insert_return_statement: ( ) ->  Begin((Return()))
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

    il.RaiseTypeError = vop2('RaiseTypeError', 1, 'throw new make_new %s', true)

    il.RaiseException = vop2('RaiseException', 1, 'throw new make_new %s', true)

    QuoteItem_to_code = (compiler) ->  '%s'%repr(@args[0])
    il.QuoteItem = vop('QuoteItem', 1, QuoteItem_to_code, false)

    il.UnquoteSplice = vop('UnquoteSplice', 1, "UnquoteSplice(%s)", false)

    il.MakeTuple = vop('MakeTuple', 1, 'tuple(%s)', false)

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

    ######################################
    # builtins