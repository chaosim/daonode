exports.BaseParser =  class
  constructor: () ->
    @symbolToParentsMap = {}
    @baseRules = {}

  parse: (code, options) ->
    @text = code
    @textLength = code.length
    @cursor = 0
    @tokens = []
    @_memo = {}
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

  addParentChildrens: (parentChildrens...) ->
    map = @symbolToParentsMap
    for parentChildren in parentChildrens
      for parent, children of parentChildren
        for name in children
          list = map[name] ?= []
          if parent isnt name and parent not in list then list.push parent

  addRecCircles: (recursiveCircles...) ->
    map = @symbolToParentsMap
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

  setMemoRules: () ->
    map = @symbolToParentsMap
    for name of map
      @baseRules[name] = @[name]
      @[name] = @memoRule(name)

  memoRule: (symbol) ->
    map = @symbolToParentsMap
    agenda = []
    addParent = (parent) ->
      agenda.unshift(parent)
      parents =  map[parent]
      if parents then for parent in parents
        if parent not in agenda
          agenda.unshift(parent)
          addParent(parent)
    addParent(symbol)
    (start) =>
      memo = @_memo
      hash0 = symbol+start
      m = memo[hash0]
      if m then @cursor = m[1]; return m[0]
      while agenda.length
        symbol = agenda.pop()
        hash = symbol+start
        m = memo[hash]
        if not m then m = memo[hash] = [undefined, start]
        rule = @baseRules[symbol]
        changed = false
        while 1
          if (result = rule(start)) and (result isnt m[0] or @cursor isnt m[1])
            memo[hash] = m = [result, @cursor]
            changed = true
          else break
        if changed then for parent in map[symbol]
          if parent not in agenda then agenda.push parent
      m = memo[hash0]
      @cursor = m[1]
      m[0]

  memo: (symbol) -> (start) =>
    m = @_memo[symbol+start]
    if m then @cursor = m[1]; m[0]



