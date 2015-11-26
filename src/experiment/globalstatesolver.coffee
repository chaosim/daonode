exports.solver = {}

solver.failcont = (v) -> v

orp = (args...) -> (cont) ->
  switch args.length
    when 1 then args[0](cont)
    when 2
      fc = solver.failcont
      solver.failcont = (v) ->
        failcont = fc
        args[1](cont)
      args[0](cont)
    else
      fc = failcont
      solver.failcont = (v) ->
        solver.failcont = fc
        orp(args[1...]...)(cont)
      args[0](cont)

andp = (args...) -> (cont) ->
  switch args.length
    when 1 then args[0](cont)
    when 2 then args[0](args[1](cont))
    else args[0](andp(args[1...]...)(cont))
