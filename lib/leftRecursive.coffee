parentToChildren = {}
rules = undefined
originalRules = {}
exports.recursiveRules = recursiveRules = {}
memoRules = {}
recRules = {}
memoCallpath = {}
_memo = {}
text = ''
textLength = 0
cursor = 0
_memo = {}
_memo2 = {}

hasOwnProperty = Object.hasOwnProperty

exports.setRules = (rules1) ->
  rules = rules1

exports.parse = (data, root, grammar) ->
  if grammar then prepareGrammar(grammar)
  text = data
  textLength = text.length
  cursor = 0
  _memo = {}
  root(0)

exports.prepareGrammar = prepareGrammar = (grammar) ->
  originalRules = {}
  for symbol, rule of grammar
    if hasOwnProperty.call(grammar, symbol) then originalRules[symbol] = rule
  symbolToParentsMap = {}
  computeLeftRecursives(grammar)

exports.computeLeftRecursives = computeLeftRecursives = (grammar) ->
  `var currentLeftHand`
  for symbol of grammar
    if hasOwnProperty.call(grammar, symbol)
      do (symbol = symbol) ->
        grammar[symbol] = (start) ->
          if start!=0 then return
          else
            cursor++
            children = parentToChildren[currentLeftHand] ?= []
            if symbol not in children then children.push symbol
  for symbol of grammar
    currentLeftHand = symbol
    originalRules[symbol](0)
  addDescendents = (symbol, meetTable, descedents) ->
    if not (chidlren = parentToChildren[symbol]) then return
    for child in chidlren
      if child not in descedents then descedents.push child
      if not meetTable[child] then addDescendents(child, meetTable, descedents)
  symbolDescedentsMap = {}
  for symbol of grammar
    meetTable = {}; meetTable[symbol] = true
    descendents = symbolDescedentsMap[symbol] = []
    addDescendents(symbol, meetTable, descendents)
    if symbol in descendents
      grammar[symbol] = recursiveRules[symbol] = recursive(symbol)
      memoRules[symbol] = memo(symbol)
      recRules[symbol] = rec(symbol)
    else grammar[symbol] = originalRules[symbol]
  for symbol of grammar
    if not hasOwnProperty.call(recursiveRules, symbol)
      delete symbolDescedentsMap[symbol]
    else
      descendents = symbolDescedentsMap[symbol]
      symbolDescedentsMap[symbol] = (symbol for symbol in descendents if hasOwnProperty.call(recursiveRules, symbol))
  return symbolDescedentsMap

exports.setRecursiveSymbols = (rules1, symbols...) ->
  rules = rules1
  for symbol in symbols
    originalRules[symbol] = rules[symbol]
    rules[symbol] = recursiveRules[symbol] = recursive(symbol)

EXTENDING = true

exports.recursive = recursive = (symbol) ->
  baserule = originalRules[symbol]
  (start) ->
    hash = symbol+start
    for sym of parentToChildren[symbol]
      originalRules[sym] = rec(sym)
    memoState[hash] = EXTENDING
    # if multichildren is allowded, should record choices information in callpath?
    callpath = memoCallpath[start] ?= [symbol]
    m = _memo[hash] ?= [undefined, -1]
    if m[1]>=0 then cursor = m[1]; return m[0]
    m[0] = baserule(start); m[1] = cursor
    while 1
      hash = symbol+start
      m = _memo[hash] ?= [undefined, -1]
      baserule = originalRules[symbol]
      result = baserule(start)
      if symbol in callpath and not result
        cursor = m[1]; return m[0]
      if m[0] and not result then cursor = m[1]; return m[0]
      if result==m[0] and cursor==m[1]
        return result
      else
        m[0] = result; m[1] = cursor

rec = (symbol) ->
  rule = originalRules[symbol]
  (start) ->
    callpath = memoCallpath[start]
    hash = symbol+start
    m = _memo[hash]
    result = m[0]; cur = m[1]
    if status is EXTENDING
      if symbol in callpath
        if cur<0 then m[1] = start; undefined
        else return m[0]
      else
        result = rule(start)

        if cur<0 then undefined
        else return result
    else
      if status is EXTENDING
        callpath.push symbol
      else
        callpath.push symbol;
        rule(start)

exports.memo = memo = (symbol) -> (start) ->
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