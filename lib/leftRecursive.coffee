symbolToParentsMap = {}
baseRules = {}
_memo = {}
text = ''
textLength = 0
cursor = 0
_memo = {}

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

exports.addParentChildrens = (parentChildrens...) ->
  map = symbolToParentsMap
  for parentChildren in parentChildrens
    for parent, children of parentChildren
      for name in children
        list = map[name] ?= []
        if parent isnt name and parent not in list then list.push parent

exports.addRecCircles = (recursiveCircles...) ->
  map = symbolToParentsMap
  for circle in recursiveCircles
    i = 0
    length = circle.length
    while i<length
      if i==length-1 then j = 0 else j = i+1
      name = circle[i]
      list = map[name] ?= []
      parent = circle[j]
      if parent isnt name and parent not in list then list.push parent
      i++

exports.setMemoRules= (rules) ->
  map = symbolToParentsMap
  for name of map
    baseRules[name] = rules[name]
    rules[name] = memoRule(name)

exports.memoRule = memoRule = (symbol) ->
  map = symbolToParentsMap
  agenda = []
  addParent = (parent) ->
    agenda.unshift(parent)
    parents =  map[parent]
    if parents then for parent in parents
      if parent not in agenda
        agenda.unshift(parent)
        addParent(parent)
  addParent(symbol)
  (start) ->
    memo = @_memo
    hash0 = symbol+start
    m = _memo[hash0]
    if m then cursor = m[1]; return m[0]
    while agenda.length
      symbol = agenda.pop()
      hash = symbol+start
      m = _memo[hash]
      if not m then m = _memo[hash] = [undefined, start]
      rule = baseRules[symbol]
      changed = false
      while 1
        if (result = rule(start)) and (result isnt m[0] or cursor isnt m[1])
          _memo[hash] = m = [result, cursor]
          changed = true
        else break
      if changed then for parent in map[symbol]
        if parent not in agenda then agenda.push parent
    m = _memo[hash0]
    cursor = m[1]
    m[0]

exports.memo= (symbol) -> (start) ->
  m = _memo[symbol+start]
  if m then cursor = m[1]; m[0]

exports.cur = () -> cursor