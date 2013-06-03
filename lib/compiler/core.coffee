# ##dao
# ###a functional logic solver, with builtin parser.
# continuation pass style, two continuations, one for succeed, one for fail and backtracking. <br/>

_ = require('underscore')
fs = require("fs")
il = require("./interlang")
solve = require('./solve')
beautify = require('js-beautify').js_beautify

exports.solve = (exp) ->
  path = compile(exp)
  solve.status = solve.UNKNOWN
  solver = new solve.Solver()
  delete require.cache[require.resolve(path)]
  module = require(path)
  solver.solveCompiled(module)

compile = (exp) ->
  compiler = new Compiler()
  code = compiler.compile(exp)
  code = beautify(code, { indent_size: 2})
  path = path or "f:/daonode/lib/compiler/test/compiled.js"
  fd = fs.openSync(path, 'w')
  fs.writeSync fd, code
  fs.closeSync fd
  path

# ####class Compiler
# the compiler for dao expression
exports.Compiler = class Compiler
  constructor: () ->
    @exits = {}
    @continues = {}
    @nameToVarIndex = {}
    # for lisp style unwind-protect, play with block/break/continue, catch/throw and lisp.protect
    @protect = (cont) -> cont

  # use this solver to solve exp, cont=done is the succeed continuation.
  compile: (exp) ->
    v = @vari('v')
    done = il.clamda(v, il.code('solver.finished = true; solve.status = solve.SUCCESS'), il.return(il.array(il.null, v)))
    fromCont = @cont(exp, done)
    f = il.clamda(@vari('v'), il.code('solver = exports.solver'), fromCont)
#    f = f.optimize(new Env(), @)
    result = "solve = require('../solve'); exports.solver = new solve.Solver(); exports.main = #{f.toCode(@)}"
    result += "\n// x = exports.solver.run(exports.main)[0];\n
    //console.log(x)"
    result

  # compile to continuation
  cont: (exp, cont) ->
    expCont = exp?.cont
    if expCont then expCont.call(exp, @, cont)
    else il.return(cont.call(exp))

  optimize: (exp, env) ->
    expOptimize = exp?.optimize
    if expOptimize then expOptimize.call(exp, env, @)
    else exp

  toCode: (exp) ->
    exptoCode = exp?.toCode
    if exptoCode then exptoCode.call(exp, @)
    else
      if exp is undefined then 'undefined'
      else if exp is null then 'null'
      else if _.isNumber(exp) then exp.toString()
      else if _.isString(exp) then JSON.stringify(exp)
      else if exp is true then "true"
      else if exp is false then "false"
      else throw new TypeError(exp)

  # used for lisp.begin, logic.andp, etc., to generate the continuation for an expression array
  expsCont: (exps, cont) ->
    length = exps.length
    if length is 0 then throw exports.TypeError(exps)
    else if length is 1 then @cont(exps[0], cont)
    else
      v = @vari('v')
      @cont(exps[0], il.clamda(v, @expsCont(exps[1...], cont)))

  argsCont: (args, cont) ->
    length = args.length
    params = @vari('a') for x in args
    cont = il.return(cont.call(params))
    compiler = @
    for i in [length-1..0] by -1
      cont = do (i=i, cont=cont) ->
        compiler.cont(args[i], il.clamda(params[i], cont))
    cont
  # used by lisp style quasiquote, unquote, unquoteSlice
  quasiquote: (exp, cont) -> exp?.quasiquote?(@, cont) or ((v) -> cont(exp))

  vari: (name) ->
    index = @nameToVarIndex[name] or 0
    @nameToVarIndex[name] = index+1
    new il.vari(name+(if index then index else ''))

class Env
  constructor: (@outer, @data={}) ->
  extend: (vari, value) -> data = {}; data[vari.name] = value; new Env(@, data)
  lookup: (vari) ->
    data = @data; name = vari.name;
    if data.hasOwnProperty(name) then return data[name]
    else
      outer = @outer
      if outer then outer.lookup(vari) else vari

# ####class Var
# Var for logic bindings, used in unify, lisp.assign, inc/dec, parser operation, etc.
exports.Var = class Var
  constructor: (@name) ->
  cont: (compiler, cont) -> il.return(cont.call(il.deref(@interlang())))
  interlang: () -> il.vari(@name)
  toString:() -> "vari(#{@name})"

reElements = /\s*,\s*|\s+/

# utilities for new variables
exports.vari = (name) ->  new Var(name)
exports.vars = (names) -> vari(name) for name in split names,  reElements

# ####class Apply
# Apply to some Command(special, fun, macro, proc, etc)
class exports.Apply
  constructor: (@caller, @args) ->
    # declare the command's arity when define the command. <br/>
    # see builtins/*.coffee for examples.<br/>
    # null: (...)<br/>
    # [2, 4]: (a, b), (a, b, c, d)<br/>
    # -1: (a, b...);   -2: (a, b, c...)<br/>
    # 1: (a);      3: (a, b, c)<br/>
    length = args.length; arity = @caller.arity
    ok = false
    if arity is null then ok = true
    if _.isArray(arity)
      if length in arity then ok = true
    else if _.isNumber(arity)
      if (arity>=0 and length is arity) or (arity<0 and length>=-arity) then ok = true
    if not ok
      for x in @args
        if x?.caller?.name is "unquoteSlice" then return
      throw new ArityError(@)
    # used in macro.applyCont, to prevent maximum recursive depth error

  toString: -> "#{@caller}(#{@args.join(', ')})"

  # get the continuation of an instance of Apply based on cont
  cont: (compiler, cont) -> @caller.applyCont(compiler, cont, @args)

  # play with lisp style quasiquote/unquote/unquoteSlice
  quasiquote:  (compiler, cont) ->
    if @caller.name is "unquote"
      return  compiler.cont(@args[0], (v) -> cont(v))
    else if @caller.name is "unquoteSlice"
      # use the flag class UnquoteSliceValue to find unquoteSlice expression
      return compiler.cont(@args[0], (v) -> cont(new UnquoteSliceValue(v)))
    params = []
    cont = do (cont=cont) => ((v) => [cont, new @constructor(@caller, params)])
    args = @args
    for i in [args.length-1..0] by -1
      cont = do (i=i, cont=cont) ->
        compiler.quasiquote(args[i], (v) ->
          if v instanceof UnquoteSliceValue
            for x in v.value then params.push x
          else params.push(v);
          cont(null))
    cont

# A flag class is used to process unquoteSlice
UnquoteSliceValue = class exports.UnquoteSliceValue
  constructor: (@value) ->

# #### class Command
# dao command that can be applied <br/>
#  Special, Fun, Macro, Proc is subclass of Command.
Command = class exports.Command
  @directRun = false
  constructor: (@fun, @name, @arity) ->
    @callable = (args...) =>
      applied = new exports.Apply(@, args)
      if Command.directRun
        solver = Command.globalSolver
        result = solver.solve(applied)
        solver.finished = false
        result
      else applied
    @callable.arity = @arity

  register: (exports) -> exports[@name] = @callable
  toString: () -> @name

# update when v0.1.10, according to mscdex <mscdex@gmail.com> advice.
commandMaker = (klass) -> (arity, name, fun) ->
  if not name? and not fun?
    fun = arity
    name = "noname"
    # bugfix(0.1.11): Special has special fun's signature (compiler, cont, args...)
    if klass is exports.Special then arity = fun.length - 2
    else arity = fun.length
  else if not fun?
    fun = name
    if _.isString(arity)
      name = arity;
      if klass is exports.Special then arity = fun.length - 2
      else arity = fun.length
    else
      if not _.isNumber(arity) and arity isnt null and not _.isArray(arity) then throw new ArgumentError(arity)
      name = "noname"
  else
    if not _.isNumber(arity) and arity isnt null and not _.isArray(arity) then throw new ArgumentError(arity)
    if not  _.isString(name) then throw new TypeError(name)
  new klass(fun, name, arity).callable

# Speical knows compiler and cont, with them the special function has full control of things.
class exports.Special extends exports.Command
  applyCont: (compiler, cont, args) -> @fun(compiler, cont, args...)

# generate an instance of Special from a function <br/>
#  example:<br/>
#  begin = special(null, 'begin', (compiler, cont, exps...) -> compiler.expsCont(exps, cont))  # coffeescript <br/>
#  exports.begin = special(null, 'begin', function() { # javascript <br/>
#    var cont, exps, compiler; <br/>
#    <br/>
#    compiler = arguments[0], cont = arguments[1], exps = 3 <= arguments.length ? __slice.call(arguments, 2) : [];<br/>
#    return compiler.expsCont(exps, cont);<br/>
#  });<br/>
#  exports.fail = special(0, 'fail', (compiler, cont) -> (v) -> compiler.failcont(v))() #coffescript <br/>
#  exports.fail = special(0, 'fail', function(compiler, cont) { # javascript <br/>
#    return function(v) { <br/>
#      return compiler.failcont(v);<br/>
#    }; <br/>
#  })();<br/>
#
exports.special = special = commandMaker(exports.Special)

class Recursive
  constructor: (@name, @func) ->

exports.recursive = (name, func) -> new Recursive(name, func)

# Fun evaluate its arguments, and return the result to fun(params...) to cont directly.
class exports.Fun extends exports.Command
  applyCont: (compiler, cont, args) ->
    length = args.length
    params = (compiler.vari('a') for x in args)
    fun = @fun
    if not fun.toCode?
      if fun instanceof Recursive
        f = il.vari(fun.name)
        cont = il.begin(
          il.assign(f, il.fun(fun.func))
          il.return(cont.call(f.apply(params))))
      else
        fun = il.fun(fun)
        cont = il.return(cont.call(fun.apply(params)))
    else
      cont = il.return(cont.call(fun.apply(params)))
    for i in [length-1..0] by -1
      cont = do (i=i, cont=cont) ->
        compiler.cont(args[i], il.clamda(params[i], cont))
    cont

exports.fun = commandMaker(exports.Fun)

# Fun2 evaluate its arguments, and evaluate the result of fun(params...) again
class exports.Fun2 extends exports.Command
  applyCont: (compiler, cont, args) ->
    length = args.length
    params = (compiler.vari('a') for x in args)
    fun = @fun
    if not fun.toCode?
      if fun instanceof Recursive
        f = il.vari(fun.name)
        exp = f.apply(params...)
        cont = il.begin(
                  il.assign(f, il.fun(fun.func))
                  compiler.cont(exp, cont))
      else
        fun = il.fun(fun)
        exp = fun.apply(params...)
        cont = compiler.cont(exp, cont)
    else
      exp = fun.apply(params...)
      cont = compiler.cont(exp, cont)
    for i in [length-1..0] by -1
      cont = do (i=i, cont=cont) ->
        compiler.cont(args[i], il.clamda(params[i], cont))
    cont

# generate an instance of Fun from a function <br/>
#  example:  <br/>
#  add = fun((x, y) -> x+y ) # coffeescript <br/>
#  add = fun(function(x,y){ return x+y; } # javascript <br/>
exports.fun2 = commandMaker(exports.Fun2)

# similar to lisp'macro, Macro does NOT evaluate its arguments, but evaluate the result to fun(args).
exports.Macro = class Macro extends exports.Command
  constructor: (@fun, @name, @arity) -> super
  applyCont: (compiler, cont, args) ->
    exp = @fun(args...)
    compiler.cont(exp, cont)

# generate a instance of Macro from a function <br/>
#  example:   <br/>
#  orpm = fun((x, y) -> orp(x,y ) # coffeescript<br/>
#  orpm = fun(function(x,y){  return orp(x,y ); } # javascript
exports.macro = commandMaker(exports.Macro)

exports.Error = class Error
  constructor: (@exp, @message='', @stack = @) ->  # @stack: to make webstorm nodeunit happy.
  toString: () -> "#{@constructor.name}: #{@exp} >>> #{@message}"

exports.TypeError = class TypeError extends Error
exports.ArgumentError = class ArgumentError extends Error
exports.ArityError = class ArityError extends Error
