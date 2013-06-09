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
  il.return(cont.call(exp)))

# aka lisp's eval, solve(eval_(quote(x))) means solve(x),  
exports.eval_ = special(1, 'eval', (compiler, cont, exp) ->
  v = compiler.vari('v')
  compiler.cont(exp, il.clamda(v, compiler.cont(v, cont))))

exports.assign = special(2, 'assign', (compiler, cont, item, exp) ->
  v = compiler.vari('v')
  compiler.cont(exp, il.clamda(v, il.assign(item.interlang(), v), il.return(cont.call(v)))))

# aka lisp's begin, same as logic.andp 
exports.begin = special(null, 'begin', (compiler, cont, exps...) -> compiler.expsCont(exps, cont))

if_fun = (compiler, cont, test, then_, else_) ->
  v = compiler.vari('v')
  compiler.cont(test, il.clamda(v, il.if_(v, compiler.cont(then_, cont), compiler.cont(else_, cont))))

# lisp style if. <br/>
#  different from logic.ifp, when test fail, it do not run else_ clause.
exports.if_ = if_ = special([2,3], 'if_', if_fun)

iff_fun = (compiler, cont, clauses, else_) ->
  length = clauses.length
  if length is 0 then throw new exports.TypeError(clauses)
  else if length is 1
    [test, then_] = clauses[0]
    if_fun(compiler, cont, test, then_, else_)
  else
    [test, then_] = clauses[0]
    v = compiler.vari('v')
    compiler.cont(test, il.clamda(v, il.if_(v, compiler.cont(then_, cont),
                                     iff_fun(compiler, cont, clauses[1...], else_))))

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
  continues = compiler.continues[label] ?= []
  f = compiler.vari('block'+label)
  fun = il.clamda(compiler.vari('v'), null)
  continues.push(f)
  defaultContinues = compiler.continues[''] ?= []   # if no label, go here
  defaultContinues.push(f)
  fun.body = compiler.expsCont(body, cont)
  exits.pop()
  if exits.length is 0 then delete compiler.exits[label]
  continues.pop()
  if continues.length is 0 then delete compiler.continues[label]
  defaultExits.pop()
  defaultContinues.pop()
  il.begin(
    il.assign(f, fun),
    il.return(f.apply([null]))))

# break a block 
exports.break_ = break_ = special([0, 1,2], 'break_', (compiler, cont, label='', value=null) ->
  if value != null and not _.isString label then throw new TypeError([label, value])
  if value is null and not _.isString label then (value = label; label = '')
  exits = compiler.exits[label]
  if not exits or exits==[] then throw new  Error(label)
  exitCont = exits[exits.length-1]
  compiler.cont(value, compiler.protect(exitCont)))

# continue a block 
exports.continue_ = continue_ = special([0,1], 'continue_', (compiler, cont, label='') ->
  continues = compiler.continues[label]
  if not continues or continues==[] then throw new Error(label)
  continueCont = continues[continues.length-1]
  il.return(compiler.protect(continueCont).call(null)))

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
  v = compiler.vari('v'); v2 = compiler.vari('v')
  formsCont = compiler.expsCont(forms, il.clamda(v2
        il.popCatch.apply([v]),
        il.return(cont.call(v2))))
  compiler.cont(tag, il.clamda(v,
    il.pushCatch.apply([v, cont]),
    formsCont)))

# aka lisp style throw 
exports.throw_ = special(2, 'throw_', (compiler, cont, tag, form) ->
  v = compiler.vari('v'); v2 = compiler.vari('v')
  formCont =  il.clamda(v,
    compiler.cont(form, il.clamda(v2,
      il.return(compiler.protect(il.findCatch.apply([v])).call(v2)))))
  compiler.cont(tag, formCont))


# aka. lisp's unwind-protect 
exports.protect = special(-1, 'protect', (compiler, cont, form, cleanup...) ->
  oldprotect = compiler.protect
  v1 = compiler.vari('v'); v2 = compiler.vari('v')
  compiler.protect = (cont) -> il.clamda(v1,
                               compiler.expsCont(cleanup, il.clamda(v2,
                                il.return(oldprotect(cont).call(v1)))))
  result = compiler.cont(form,  il.clamda(v1,
                  compiler.expsCont(cleanup, il.clamda(v2,
                    il.return(cont.call(v1))))))
  compiler.protect = oldprotect
  result)

# callcc(someFunction(kont) -> body) <br/>
#current continuation @cont can be captured in someFunction
exports.callcc = special(1, 'callcc', (compiler, cont, fun) ->
  if not fun.toCode? then fun = il.fun(fun)
  faked = compiler.vari('faked');  result = compiler.vari('result'); v = compiler.vari('v')
  cc = il.clamda(v,
    il.restore.apply([faked]),
    il.assign(result, il.getvalue.apply([il.index.apply([il.run.apply([cont, v]), 1])])),
    il.code("solver.finished = false;"),
    il.return(result))
  il.begin(il.assign(faked, il.fake),
    il.return(cont.call(fun.apply([cc])))))

###
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
###