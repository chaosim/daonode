symbolToParentsMap = {}
rules = undefined
baseRules = {}
recursiveRules = {}
memoCallpath = {}
_memo = {}
text = ''
textLength = 0
cursor = 0
_memo = {}
_memo2 = {}

exports.setRules = (rules1) ->
  rules = rules1

exports.clear = () ->
  baseRules = {}
  symbolToParentsMap = {}

exports.parse = (data, root) ->
  text = data
  textLength = text.length
  cursor = 0
  _memo = {}
  return  root(0)

exports.andp = (exps) -> (start) ->
  cursor = start
  for exp in exps
    if not(result = exp(cursor)) then return
  return result

exports.orp = (exps) -> (start) ->
  for exp in exps
    if result = exp(start) then return result
  return

exports.notp = (exp) -> (start) ->
  if exp(start) then return
  else return true

exports.char = (c) -> (start) ->
  if text[start]==c then cursor = start+1; return c

exports.literal = (string) -> (start) ->
  len = string.length
  if text.slice(start,  stop = start+len)==string then cursor = stop; return true

exports.spaces = (start) ->
  len = 0
  cursor = start
  text = text
  while 1
    switch text[cursor]
      when ' ' then len++
      when '\t' then len += tabWidth
      else break
  return len

exports.spaces1 = (start) ->
  len = 0
  cursor = start
  text = text
  while 1
    switch text[cursor++]
      when ' ' then len++
      when '\t' then len += tabWidth
      else break
  if len then return cursor = cursor; len

exports.wrap = (item, left=spaces, right=spaces) -> (start) ->
  if left(start) and result = item(cursor) and right(cursor)
    return result

exports.setRecursiveSymbols = (rules1, symbols...) ->
  rules = rules1
  for symbol in symbols
    baseRules[symbol] = rules[symbol]
    rules[symbol] = recursiveRules[symbol] = recursive(symbol)

exports.recursive = recursive = (symbol) ->
  baserule = baseRules[symbol]
  (start) ->
    hash = symbol+start
    callpath = memoCallpath[start] ?= [symbol]
    m = _memo[hash] ?= [undefined, -1]
    if m[1]>=0 then cursor = m[1]; return m[0]
    m[0] = baserule(start); m[1] = cursor
    while 1
      symbol = callpath.pop()
      hash = symbol+start
      m = _memo[hash] ?= [undefined, -1]
      baserule = baseRules[symbol]
      result = baserule(start)
      if symbol in callpath and not result
#        callpath.pop()
        cursor = m[1]; return m[0]
      if m[0] and not result then cursor = m[1]; return m[0]
      if result==m[0] and cursor==m[1]
#        callpath.pop()
        return result
      else
#        callpath.pop();
        m[0] = result; m[1] = cursor

exports.memo = memo = (symbol) -> (start) ->
  hash = symbol+start
  m = _memo[hash]
  if m then m[0]

exports.rec = rec = (symbol) -> (start) ->
  hash = symbol+start
  callpath = memoCallpath[start] ?= []
  callpath.push symbol
  m = _memo[hash]
  if m then m[0]

exports.cur = () -> cursor