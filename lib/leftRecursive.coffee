exports.BaseParser =  class
  parse: (code, options) ->
    @text = code
    @textLength = code.length
    @cursor = 0
    @tokens = []
    @_memo = {}
    @memoState = {}
    @lookDepth = {}
    @indentList = []
    @tabWidth = 4
    @yy = @yy
    return  @Root(0)

  andp: (exps) -> (start) =>
    @cursor = start
    for exp in exps
      if not(result = exp(@cursor)) then return
    return result

  orp: (exps) -> (start) =>
    for exp in exps
      if result = exp(start) then return result
    return

  notp: (exp) -> (start) =>
    if exp(start) then return
    else return true

  char: (c) -> (start) =>
    if @text[start]==c then @cursor = start+1; return c

  literal: (string) -> (start) =>
    len = string.length
    if @text.slice(start,  stop = start+len)==string then @cursor = stop; return true

  spaces: (start) ->
    len = 0
    @cursor = start
    text = @text
    while 1
      switch text[@cursor]
        when ' ' then len++
        when '\t' then len += tabWidth
        else break
    return len

  spaces1: (start) ->
    len = 0
    cursor = start
    text = @text
    while 1
      switch text[cursor++]
        when ' ' then len++
        when '\t' then len += tabWidth
        else break
    if len then return @cursor = cursor; len

  wrap: (item, left=spaces, right=spaces) -> (start) ->
    if left(start) and result = item(@cursor) and right(@cursor)
      return result

  recursive: (symbol) ->
    rule = @[symbol]
    (start) =>
      hash = symbol+start
      memo = @_memo
      m = memo[hash]
      if not m then m = memo[hash] = [undefined, start]
      while 1
        if (result = rule(start)) and (result isnt m[0] or @cursor isnt m[1])
          memo[hash] = m = [result, @cursor]
        else
          return result

  look: (symbol) -> (start) =>
    rule = @[symbol]
    hash = symbol+start
    memo = @_memo
    m = memo[hash]
    memoState = @memoState
    while 1
      state = memoState[hash] = not memoState[hash]
      if state then rule(start)
      m1 = memo[hash]
      if m1 is m then return m[0]
      else m = m1

  memo: (symbol) -> (position) =>
    m = @_memo[symbol+position]
    if m then @cursor = m[1]; m[0]
