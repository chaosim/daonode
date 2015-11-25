text = ''
textLength = 0
cursor = 0
rules = undefined
symbolDescedentsMap = {}
_memo = {}
originalRules = {}

hasOwnProperty = Object.hasOwnProperty

exports.parse = (data, grammar, start) ->
  start = start or grammar.rootSymbol
  text = data
  textLength = text.length
  cursor = 0
  _memo = {}
  rules = grammar
  grammar[start](0)

exports.addParentChildrens = (grammar, parentChildrens...) ->
  map = grammar.parentToChildren ?= {}
  for parentChildren in parentChildrens
    for parent, children of parentChildren
      list = map[parent] ?= []
      for name in children
        if name not in list then list.push name
  null

exports.addRecCircles = (grammar, recursiveCircles...) ->
  map = grammar.parentToChildren ?= {}
  for circle in recursiveCircles
    i = 0
    length = circle.length
    while i<length
      if i==length-1 then j = 0 else j = i+1
      name = circle[i]
      parent = circle[j]
      list = map[parent] ?= []
      if name not in list then list.push name
      i++
  null

exports.computeLeftRecursives = (grammar) ->
  parentToChildren = grammar.parentToChildren
  addDescendents = (symbol, meetTable, descedents) ->
    children =  parentToChildren[symbol]
    for child in children
      if child not in descedents then descedents.push child
      if not meetTable[child] then addDescendents(child, meetTable, descedents)
  symbolDescedentsMap = {}
  for symbol of parentToChildren
    meetTable = {}; meetTable[symbol] = true
    descendents = symbolDescedentsMap[symbol] = []
    addDescendents(symbol, meetTable, descendents)
    if symbol in descendents
      originalRules[symbol] = grammar[symbol]
      grammar[symbol] = recursive(symbol)
  symbolDescedentsMap

exports.recursive = recursive = (symbol) ->
  originalRule = originalRules[symbol]
  (start) ->
    for child in symbolDescedentsMap[symbol]
      if child isnt symbol then rules[child] = originalRules[child]
    hash = symbol+start
    m = _memo[hash] ?= [undefined, -1]
    if m[1]>=0 then cursor = m[1]; return m[0]
    while 1
      result = originalRule(start)
      if m[1]<0
        m[0] = result
        if result then  m[1] = cursor
        else m[1] = start
        continue
      else
        if m[1]==cursor then m[0] = result; return result
        else if cursor<m[1] then m[0] = result; cursor = m[1]; return result
        else m[0] = result; m[1] = cursor
    for child in symbolDescedentsMap[symbol]
      if child isnt symbol then rules[child] = recursive(child)
    result

exports.memo = memo = (symbol) ->
  (start) ->
    hash = symbol+start
    m = _memo[hash]
    if m then m[0]

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

exports.cur = () -> cursor