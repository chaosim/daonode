trampoline = (f) ->
  (args...) ->
    result = f(args...)
    while result instanceof Function
      result = result()
    console.log result
    result

fib = (n) ->
  f = (n, a, b) ->
    if n>0 then -> f(n-1, b, a+b)
    else a
  trampoline(f)(n, 0, 1)

zero = trampoline(f = (n) ->
  if n is 0 then 0
  else -> f(n-1))

zero2 = (n) ->
  while 1
    if n is 0 then return 0
    else n = n-1

_odd = (n) ->
  if n is 0 then false
  else -> _even n-1

_even = (n) ->
  if n is 0 then true
  else -> _odd n-1

odd = trampoline(_odd)
even = trampoline(_even)

start = process.hrtime()

elapsed_time = (note) ->
  precision = 3
  elapsed = process.hrtime(start)
  console.log "#{note} -- #{elapsed[0]}s#{elapsed[1]/1000000}ms"
  start = process.hrtime()

xexports = {}

exports.Test =
  "test tailrecursive": (test) ->
    elapsed_time "start"
    test.equal  fib(100), 354224848179262000000
    elapsed_time "fib(100)"
    test.equal  zero(100), 0
    elapsed_time "zero(100)"
    test.equal  zero2(100), 0
    elapsed_time "zero2(100)"
    test.equal  odd(2), false
    elapsed_time "odd(2)"
    test.equal  even(2), true
    elapsed_time "even(2)"
    test.done()
