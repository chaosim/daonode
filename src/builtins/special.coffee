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
