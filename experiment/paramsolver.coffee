exports.orp = (args...) ->  (cont) -> (failcont) ->
  switch args.length
    when 1 then args[0](cont)(failcont)
    when 2 then args[0](cont)(args[1](cont)(failcont))
    else args[0](cont)(orp(args[1...]...)(cont)(failcont))

exports.andp = (args...) ->  (cont) ->
  switch args.length
    when 1 then args[0]
    when 2 then args[0](args[1](cont))
    else args[0](andp(args[1...]...)(cont))

exports.succeed = (cont) -> cont
exports.fail = (cont) -> (failcont) -> failcont
exports.notp = (goal) -> (cont) -> (failcont) -> goal(failcont)(cont)

exports.cutable = (goal) -> (cont) -> (failcont) -> (cutcont) -> goal (cont) (failcont) (failcont)
exports.cut = (cont) -> (failcont) -> (cutcont) -> cont(cutcont)(cutcont)
exports.repeat = (cont) -> (failcont) -> cont(cont)

exports.findall = (goal) -> (cont) -> (failcont) ->
  goal(failcont)(cont(fc -> failcont()))

exports.may = (goal) -> (cont) -> (failcont) -> goal((fc) -> cont(failcont(fc)))((cc) -> cont(failcont)(cc))
exports.lazymay = (goal) -> (cont) -> (failcont) -> cont(goal(cont(failcont)))
#exports.greedymay = (goal) -> (cont) -> (failcont) -> goal(cont((sc) -> (fc ->))

exports.char = (x) -> (cont) -> (failcont) -> (cutcont) -> (bindings) -> (text) -> (cursor) -> (value) ->
  if cursor>=text.length then failcont (cutcont) (bindings) (text) (cursor) (value)
  cont (failcont) (cutcont) (bindings) (text) (cursor+1) (text[cursor])

exports.digit = (cont) -> (failcont) -> (cutcont) -> (bindings) -> (text) -> (cursor) -> (value) ->
  if cursor>=text.length then failcont (cutcont) (bindings) (text) (cursor) (value)
  if '0' <= text[cursor] <= '9' then cont (failcont) (cutcont) (bindings) (text) (cursor+1) (text[cursor])
  else failcont (cutcont) (bindings) (text) (cursor) (value)


