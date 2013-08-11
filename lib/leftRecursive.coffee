exports.BaseParser =  class
  parse: (code, options) ->
    oldText = global.text
    oldTextLength = global.textLength
    oldTokens = global.tokens
    oldMemo = global.memo
    oldMemoState = global.memoState
    oldIndentList = global.indentList
    oldyy = global.yy

    global.text = code
    global.textLength = code.length
    @cursor = 0
    global.tokens = []
    global.memo = {}
    global.memoState = {}
    global.indentList = []
    @tabWidth = 4
    global.yy = @yy
    result =  @Root(0)

    global.text = oldText
    global.textLength = oldTextLength
    global.tokens = oldTokens
    global.memo = oldMemo
    global.memoState = oldMemoState
    global.indentList = oldIndentList

    return result

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
    if text[start]==c then @cursor = start+1; return c

  literal: (string) -> (start) =>
    len = string.length
    if text.slice(start,  stop = start+len)==string then @cursor = stop; return true

  spaces: (start) ->
    len = 0
    @cursor = start
    while 1
      switch text[@cursor]
        when ' ' then len++
        when '\t' then len += tabWidth
        else break
    return len

  spaces1: (start) ->
    len = 0
    @cursor = start
    while 1
      switch text[@cursor]
        when ' ' then len++
        when '\t' then len += tabWidth
        else break
    if len then return len

  wrap: (item, left=spaces, right=spaces) -> (start) ->
    if left(start) and result = item(@cursor) and right(@cursor)
      return result

  recursive: (symbol) ->
    rule = @[symbol]
    rec = (start) =>
      hash = symbol+start
      memoState[hash] = state = memoState[hash] or 0
      switch state
        when 0 #enter
          memoState[hash]++
          memo[hash] = [undefined, start]
          if result = rule(start)
            memo[hash] = [result, @cursor]
            rec(start)
          else
            memoState[hash] = -1
            memo[hash] = [undefined, 0]
            undefined
        when 1 then memoState[hash]++; undefined #alpha
        when 2 #extend
          memoState[hash] = 3
          if result = rule(start)
            memo[hash] = [result, @cursor]
            memoState[hash] = 2
            rec(start)
          else
            memoState[hash] = -1
            m = memo[hash]
            @cursor = m[1]
            m[0]
        when 3 #reduce
          m = memo[hash]
          @cursor = m[1]
          m[0]
        when -1  #done
          m = memo[hash]
          @cursor = m[1]
          return m[0]

  getmemo: (symbol) -> (position) => memo[symbol+position][0]
  reduce: (symbol) -> (start) -> state = memoState[symbol+start]; state==REDUCE
  alpha: (symbol) -> (start) -> state = memoState[symbol+start]; state==2   #alpha
