{Trail, Var,  ExpressionError, TypeError} = require "./solve"
{ADD, SUB, MUL, DIV, MOD, LSFHIFT, RSHIFT,
AND, OR, NOT, BITAND, BITOR, BITNOT} = util = require "./util"

index = 0
exports.tokenInfoList = tokenInfoList = []
newToken = (text) ->
  i = text.indexOf(': ')
  names = text.slice(0, i).split(' ')
  symbol = text.slice(i+2)
  for name in names then tokenNames[name] = global[name] = index
  tokenInfoList.push([symbol, index]);
  index++

exports.tokenNames = tokenNames = {}

newToken(x) for x in [
  'TKNLINECOMMENTBEGIN TKNSHARP: #', 'TKNSHARP2: ##', 'TKNSHARP3: ###',
  "TKNQUOTE: '", "TKNQUOTE2: ''", "TKNQUOTE3: '''",
  'TKNDOUBLEQUOTE1: "', 'TKNDOUBLEQUOTE2: ""', 'TKNDOUBLEQUOTE3: """',
  'TKNBACKQUOTE: `', 'TKNBACKQUOTE2: ``', 'TKNBACKQUOTE3: ```',
  'TKNLPAREN: (', 'TKNRPAREN: )', 'TKNLBRACKET: [', 'TKNRBRACKET: ]', 'TKNLBRACE: {', 'TKNRBRACE: }',
  'TKNCOLON: :', 'TKNCOLON2: ::', 'TKNCOLON3: :::', 'TKNSEMICOLON: ;',
  'TKNDOT: .', 'TKNDOT2: ..', 'TKNDOT3: ...',
  'TKNEQ: =', 'TKNEQ2: ==', 'TKNEQ3: ===',
  'TKNGT: >', 'TKNGT2 TKNRSHIFT: >>', 'TKNGT3: >>>',
  'TKNLT: <', 'TKNLT2 TKNLSHIFT: <<', 'TKNLT3: <<<',
  'TKNNE: !=',  'TKNLTGT: <>',  'TKNGE: >=', 'TKNLE: <=',
  'TKNSUBARROW: ->', 'TKNEQARROW: =>', 'TKNCOLONEQ: :=', 'TKNCOLONSUB: :-',
  'TKNPOSITIVE TKNADD: +', 'TKNINC TKNADD2: ++', 'TKNADD3: +++',
  'TKNNEG TKNSUB: -', 'TKNDEC TKNSUB2: --', 'TKNSUB3: ---',
  'TKNMUL: *', 'TKNMUL2: **', 'TKNMUL3: ***',
  'TKNDIV: /', 'TKNDIV2: //', 'TKNDIV3: ///',
  'TKNMOD: %', 'TKNMOD2: %%', 'TKNMOD3: %%%',
  'TKNVLINE TKNBITOR: |', 'TKNVLINE2 TKNOR: ||', 'TKNVLINE3: |||'
  'TKNBITNOT: ~', 'TKNBITXOR: ^', 'TKNNOT: !',
  'TKNBITAND AMPERSAND1: &','TKNAND AMPERSAND2: &&','AMPERSAND3: &&&',
  'TKNRETURN: return', 'TKNPASS: pass',
  'TKNCONTINUE: continue', 'TKNBREAK: break',
  'TKNIF: if', 'TKNELSE: else', 'TKNELSEIF: elseif', 'TKNELIF: elif',
  'TKNSWITCH: switch', 'TKNDEFAULT: default',
  'TKNTRY: try', 'TKNCATCH: catch',   'TKNEXCEPT: except', 'TKNFINALLY: finally',
  'TKNTHROW: throw', 'TKNRAISE: raise', 'TKNERROR: error',
  'TKNWHILE: while', 'TKNUNTIL: until', 'TKNLOOP: loop',
  'TKNWHEN: when', 'TKNON: on', 'TKNLET: let', 'TKNWHERE: where', 'TKNCASE: case',
  'TKNVAR: var', 'TKNWITH: with', 'TKNDELETE: delete','TKNDEL: del',
  'TKNFUNCTION: function', 'TKNFUN: fun', 'TKNDEF: def',
  'TKNCLASS: class', 'TKNMACRO: macro',
  'TKNIN: in', 'TKNIS: is', 'TKNIS: unify', 'TKNINSTANCEOF: instanceof', 'TKNTYPEOF: typeof', 'TKNDOF: of',
  'TKNAND: and', 'TKNNOT: not', 'TKNOR: or'
  'TKNVOID: void', 'TKNNEW: new', 'TKNDEBUGGER: debugger', 'TKNTHIS: this',
]

exports.binaryOperator = (solver, cont) ->
  text = solver.parserdata; pos = solver.parsercursor
  length = text.length
  if pos>=length then return solver.failcont(pos)
  c = text[pos]
  switch c
    when '+' then solver.parsercursor = pos+1; cont(util.ADD)
    when '-' then solver.parsercursor = pos+1; cont(util.SUB)
    when '*' then solver.parsercursor = pos+1; cont(util.MUL)
    when '/' then solver.parsercursor = pos+1; cont(util.DIV)
    when '%' then solver.parsercursor = pos+1; cont(util.MOD)
    when '='
      c1 = text[pos+1]
      if c1=='=' then solver.parsercursor = pos+2; cont(util.EQ)
      else return solver.failcont(pos)
    when '!'
      c1 = text[pos+1]
      if c1=='=' then solver.parsercursor = pos+2; cont(util.NE)
      else return solver.failcont(pos)
    when '>'
      c1 = text[pos+1]
      if c1=='=' then solver.parsercursor = pos+2; cont(util.GE)
      else if c1=='>' then solver.parsercursor = pos+2; cont(util.RSHIFT)
      else solver.parsercursor = pos+1; cont(util.gt)
    when '<'
      c1 = text[pos+1]
      if c1=='=' then solver.parsercursor = pos+2; cont(util.le)
      else if c1=='<' then solver.parsercursor = pos+2; cont(util.LSHIFT)
      else solver.parsercursor = pos+1; cont(util.lt)
    else solver.failcont(pos)

exports.unaryOperator = (solver, cont) ->
  text = solver.parserdata; pos = solver.parsercursor
  length = text.length
  if pos>=length then return solver.failcont(pos)
  c = text[pos]
  switch c
    when '+'
      c1 = text[pos+1]
      if c1=='+' then solver.parsercursor = pos+2; cont(util.INC)
      else solver.parsercursor = pos+1; cont(util.pos)
    when '-'
      c1 = text[pos+1]
      if c1=='+' then solver.parsercursor = pos+2; cont(util.DEC)
      else solver.parsercursor = pos+1; cont(util.NEG)
    when '!' then solver.parsercursor = pos+1; cont(util.NOT)
    when '~' then solver.parsercursor = pos+1; cont(util.BITNOT)
    else solver.failcont(pos)

exports.suffixOperator = (solver, cont) ->
  text = solver.parserdata; pos = solver.parsercursor
  length = text.length
  if pos>=length then return solver.failcont(pos)
  c = text[pos]
  switch c
    when '+'
      c1 = text[pos+1]
      if c1=='+' then solver.parsercursor = pos+2; cont(util.INC)
      else solver.failcont(pos)
    when '-'
      c1 = text[pos+1]
      if c1=='+' then solver.parsercursor = pos+2; cont(util.DEC)
      else solver.failcont(pos)
    else solver.failcont(pos)

hasOwnProperty = Object.hasOwnProperty

exports.StateMachine = class StateMachine
  constructor: (items=[]) ->
    @index = 1
    @stateMap = {}
    @stateMap[0] = {}
    @tagMap = {}
    for item in items then @add(item[0], item[1])

  add: (word, tag) ->
    length = word.length
    state = 0
    i = 0
    while i<length-1
      c = word[i++]
      if hasOwnProperty.call(@stateMap[state], c)
        state = @stateMap[state][c]
        if state < 0 then state = -state
      else
        newState = @index++
        @stateMap[state][c] = newState
        @stateMap[newState] = {}
        state = newState
    c = word[i]
    if hasOwnProperty.call(@stateMap[state], c)
      s = @stateMap[state][c]
      if s>0
        @stateMap[state][c] = -s
        @tagMap[s] = tag
    else
      newState = @index++
      @stateMap[state][c] = -newState
      @stateMap[newState] = {}
      @tagMap[newState] = tag

  match: (text, i) ->
    state = 0
    length = text.length
    while i<length
      state = @stateMap[state][text[i++]]
      if state is undefined then i--; break
      else if state<0 then state = -state; succeedState = state; cursor = i
    if succeedState then return [@tagMap[succeedState], cursor]
    else return [null, i]

exports.readToken = readToken = (solver) ->
  tokenStateMachine = solver.tokenStateMachine
  text = solver.parserdata
  start = solver.parsercursor
  result = tokenStateMachine.match(text, start)
  value = result[0]; cursor = result[1]
  if value then solver.parsercursor = cursor; value
  else solver.parsercursor = start; null

binaryOperatorMap = {}
(binaryOperatorMap[pair[0]] = pair[1]) for pair in [
  [TKNADD, ADD], [TKNSUB, SUB], [TKNMUL, MUL], [TKNDIV, DIV], [TKNMOD, MOD],
  [TKNAND, AND], [TKNOR, OR],
  [TKNBITAND, BITAND], [TKNBITOR, BITOR], [TKNLSHIFT, LSHIFT], [TKNRSHIFT, RSHIFT],
  [TKNEQ, EQ], [TKNNE, NE], [TKNLT, LT], [TKNLE, LE], [TKNGE, GE], [TKNGT, GT]
]

exports.binaryOperator = (solver, cont) ->
  start = solver.parsercursor
  token =  readToken(solver)
  op = binaryOperatorMap[token]
  if op isnt undefined then cont(op)
  else solver.parsercursor = start; solver.failcont(null)

unaryOperatorMap = {}
(unaryOperatorMap[pair[0]] = pair[1]) for pair in [
  [TKNNOT, NOT], [TKNBITNOT, BITNOT], [TKNNEG, NEG], [TKNPOSITIVE, POSITIVE]
  [TKNINC, INC], [TKNDEC, DEC]
]

exports.unaryOperator = (solver, cont) ->
  start = solver.parsercursor
  token =  readToken(solver)
  op = unaryOperatorMap[token]
  if op isnt undefined then cont(op)
  else  solver.parsercursor = start; solver.failcont(null)

suffixOperatorMap = {}
(suffixOperatorMap[pair[0]] = pair[1]) for pair in [
  [TKNINC, INC], [TKNDEC, SUFFIXDEC]
]

exports.suffixOperator = (solver, cont) ->
  start = solver.parsercursor
  token =  readToken(solver)
  op = suffixOperatorMap[token]
  if op isnt undefined then cont(op)
  else  solver.parsercursor = start; solver.failcont(null)
