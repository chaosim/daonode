# #### lisp builtins
# lispt.coffee doesn't know trail, failcont, state and the like.
# lisp knows cont only.

_ = require('underscore')
core = require "../core"
il = require "../interlang"
general = require "./general"

special = core.special
macro = core.macro

debug = core.debug

# aka lisp's quote, like in lisp, 'x==x, quote(x) === x 
exports.quote = special(1, 'quote', (compiler, cont, exp) ->
  v = compiler.vari('v')
  il.clamda(v, il.return(il.array(cont, exp))))

# aka lisp's eval, solve(eval_(quote(x))) means solve(x),  
exports.eval_ = special(1, 'eval', (compiler, cont, exp) ->
  compiler.cont(exp, (v) -> [compiler.cont(v, cont), null]))

# vari.binding = exp 
exports.assign = special(2, 'assign', (compiler, cont, vari, exp) ->
  # different from is_ in logic.coffee: <br/>
  # Because not using vari.bind, this is not saved in compiler.trail  <br/>
  # and so it can NOT be restored in compiler.failcont <br/>
  # EXCEPT the vari has been in compiler.trail in the logic branch before.

  compiler.cont(exp, (v) ->
    if v instanceof core.Var
      new core.TypeError(v, "do NOT assign free logic var to var")
    vari.binding = v;
    cont(v)))

# vari.binding = 0 <br/>
#  provide this for reducing continuation, and make code running faster.
exports.zero = special(1, 'zero', (compiler, cont, vari, exp) ->
  (v) -> (vari.binding = 0; cont(v)))

# vari.binding = 1 <br/>
#  provide this for reducing continuation, and make code running faster.
exports.one = special(1, 'one', (compiler, cont, vari, exp) ->
 (v) -> (vari.binding = 1; cont(v)))

# aka lisp's begin, same as logic.andp 
exports.begin = special(null, 'begin', (compiler, cont, exps...) -> compiler.expsCont(exps, cont))

if_fun = (compiler, cont, test, then_, else_) ->
  then_cont = compiler.cont(then_, cont)
  if else_?
    else_cont = compiler.cont(else_, cont)
    action = (v) ->
      if (v) then then_cont(v)
      else else_cont(v)
    compiler.cont(test, action)
  else
    action =  (v) ->
      if (v) then then_cont(null)
      else cont(null)
    compiler.cont(test, action)

# lisp style if. <br/>
#  different from logic.ifp, when test fail, it do not run else_ clause.
exports.if_ = special([2,3], 'if_', if_fun)

iff_fun = (compiler, cont, clauses, else_) ->
  length = clauses.length
  if length is 0 then throw new exports.TypeError(clauses)
  else if length is 1
    [test, then_] = clauses[0]
    if_fun(compiler, cont, test, then_, else_)
  else
    [test, then_] = clauses[0]
    then_cont = compiler.cont(then_, cont)
    iff_else_cont = iff_fun(compiler, cont, clauses[1...], else_)
    action = (v) ->
      if (v) then [then_cont, v]
      else [iff_else_cont, v]
    compiler.cont(test, action)


#iff [ [test1, body1], <br/>
#      [test2, body2]  <br/>
#    ] <br/>
#    else_

exports.iff = special(-2, 'iff', iff_fun)

# lisp style block 
exports.block = block = special(null, 'block', (compiler, cont, label, body...) ->
  if not _.isString(label) then (label = ''; body = [label].concat(body))

  exits = compiler.exits[label] ?= []
  exits.push(cont)
  defaultExits = compiler.exits[''] ?= []  # if no label, go here
  defaultExits.push(cont)
  holder = [null]
  continues = compiler.continues[label] ?= []
  continues.push(holder)
  defaultContinues = compiler.continues[''] ?= []   # if no label, go here
  defaultContinues.push(holder)
  holder[0] = fun = compiler.expsCont(body, cont)
  exits.pop()
  if exits.length is 0 then delete compiler.exits[label]
  continues.pop()
  if continues.length is 0 then delete compiler.continues[label]
  defaultExits.pop()
  defaultContinues.pop()
  fun)

# break a block 
exports.break_ = break_ = special([0, 1,2], 'break_', (compiler, cont, label='', value=null) ->
  if value != null and not _.isString label then throw new TypeError([label, value])
  if value is null and not _.isString label then (value = label; label = '')
  exits = compiler.exits[label]
  if not exits or exits==[] then throw Error(label)
  exitCont = exits[exits.length-1]
  valCont = (v) -> compiler.protect(exitCont)(v)
  compiler.cont(value, valCont))

# continue a block 
exports.continue_ = continue_ = special([0,1], 'continue_', (compiler, cont, label='') ->
  continues = compiler.continues[label]
  if not continues or continues==[] then throw Error(label)
  continueCont = continues[continues.length-1]
  (v) -> [compiler.protect(continueCont[0]), v])

not_ = general.not_

# loop 
exports.loop_ = macro(null, 'loop', (label, body...) ->
  if not _.isString(label) then (label = ''; body = [label].concat body)
  block(label, body.concat([continue_(label)])...))

# while 
exports.while_ = macro(null, 'while_', (label, test, body...) ->
  if not _.isString(label) then (label = ''; test = label; body = [test].concat body)
  block(label, [if_(not_(test), break_(label))].concat(body).concat([continue_(label)])...))

# until 
exports.until_ = macro(null, 'until_', (label,body..., test) ->
   if not _.isString(label) then (label = ''; test = label; body = [test].concat body)
   body = body.concat([if_(not_(test), continue_(label))])
   block(label, body...))

# aka. lisp style catch/throw  
exports.catch_ = special(-1, 'catch_', (compiler, cont, tag, forms...) ->
  tagCont = (v) ->
    compiler.pushCatch(v, cont)
    formsCont = compiler.expsCont(forms, (v2) -> compiler.popCatch(v); [cont, v2])
    [formsCont, v]
  compiler.cont(tag, tagCont))

# aka lisp style throw 
exports.throw_ = special(2, 'throw_', (compiler, cont, tag, form) ->
  formCont =  (v) ->
    compiler.cont(form, (v2) ->
      compiler.protect(compiler.findCatch(v))(v2))(v)
  compiler.cont(tag, formCont))

# aka. lisp's unwind-protect 
exports.protect = special(-1, 'protect', (compiler, cont, form, cleanup...) ->
  oldprotect = compiler.protect
  compiler.protect = (fun) -> (v1) ->
                               compiler.expsCont(cleanup, (v2) ->
                                 compiler.protect = oldprotect;
                                 oldprotect(fun)(v1))(v1)
  cleanupCont = (v1) ->
    compiler.expsCont(cleanup, (v2) ->
                    compiler.protect = oldprotect
                    cont(v1))(v1)
  result = compiler.cont(form, cleanupCont)
  result)


# callcc(someFunction(kont) -> body) <br/>
#current continuation @cont can be captured in someFunction
exports.callcc = special(1, 'callcc', (compiler, cont, fun) -> (v) ->
  faked = compiler.fake()
  cc = (v) ->
    compiler.restore(faked)
    result = compiler.run(v, cont)
    compiler.trail.getvalue(result[1])
  cont(fun(cc)))

# callfc(someFunction(fc) -> body) <br/>
#current compiler.failcont can be captured in someFunction
exports.callfc = special(1, 'callfc', (compiler, cont, fun) -> (v) ->
  faked = compiler.fake()
  fc = (v) ->
    compiler.restore(faked)
    result = compiler.run(v,  compiler.failcont)
    compiler.trail.getvalue(result[1])
  cont(fun(fc)))

# 0.1.11 update
# callcs(someFunction(compiler, faked, kont) -> body) <br/>
#  the compiler, compiler's current content and current cont can be captured in someFunction
exports.callcs = special(1, 'callcs', (compiler, cont, fun) -> (v) ->
  cont(fun(compiler, compiler.fake(), cont)))

# lisp style quasiquote/unquote/unquote-slice "`", "," and ",@" 
exports.quasiquote = exports.qq = special(1, 'quasiquote', (compiler, cont, item) ->
  compiler.quasiquote?(item, cont))

exports.unquote = exports.uq = special(1, 'unquote', (compiler, cont, item) ->
  throw "unquote: too many unquote and unquoteSlice" )

exports.unquoteSlice = exports.uqs = special(1, 'unquoteSlice', (compiler, cont, item) ->
  throw "unquoteSlice: too many unquote and unquoteSlice")
