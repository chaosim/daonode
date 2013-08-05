
cursor = 0
memoResult = {}
memoState = {}

solver = {}
memo = (name, alpha, beta, expr) -> ->
  start = cursor
  hash = name+state
  fc = solver.failcont
  state = memoState[hash]
  if state is undefined
    x = alpha()
    memoState[hash] = false
    memoResult[hash] = x
    solver.failcont = (v) ->
      solver.failcont = fc
      memoState[hash] = true
    beta();
  else if state is false
    beta()

b = () ->
  if str[cursor]=='b' then cursor++; true
  else failcont()
a = () ->
  if str[cursor] =='a' then true
  else failcont

e = memo('a', a, e)

str = 'abbb'

#e()

leftRecursive = (alpha, left) ->
  alpha(); left()
