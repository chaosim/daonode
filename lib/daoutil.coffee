{Trail, Var,  ExpressionError, TypeError} = require "./solve"
util = require "./util"
[ TOKEN_BLOCKCOMMENTBEGIN, TOKEN_LINECOMMENTBEGIN,
  TOKEN_QUOTE, TOKEN_QUOTE2, TOKEN_QUOTE3,
  TOKEN_DOUBLEQUOTE, TOKEN_DOUBLEQUOTE2, TOKEN_DOUBLEQUOTE3,
  TOKEN_BACKQUOTE, TOKEN_BACKQUOTE2, TOKEN_BACKQUOTE3,
  TOKEN_LPAREN, TOKEN_RPAREN, TOKEN_LBRACKET, TOKEN_RPAREN, TOKEN_LBRACE, TOKEN_RBRACE,
  TOKEN_COLON, TOKEN_SEMICOLON, TOKEN_DOT, TOKEN_DOT2, TOKEN_DOT3, TOKEN_ARROW, # ->
  TOKEN_EQ, TOKEN_EQ2, TOKEN_EQ3, TOKEN_NE, TOKEN_GT, TOKEN_GE, TOKEN_LE, TOKEN_LT, TOKEN_COLONEQ,
  TOKEN_ADD, TOKEN_ADD2, TOKEN_SUB, TOKEN_SUB2, TOKEN_MUL, TOKEN_DIV, TOKEN_LSHIFT, TOKEN_RSHIFT, TOKEN_BITNOT, TOKEN_BITXOR, TOKEN_LOGICNOT, TOKEN_LOGICAND, TOKEN_LOGICOR,
  TOKEN_IF, TOKEN_ELSE, TOKEN_SWITCH, TOKEN_THIS, TOKEN_CLASS, TOKEN_RETURN, TOKEN_PASS, TOKEN_TRY, TOKEN_CATCH, TOKEN_FINALLY, TOKEN_WHILE, TOKEN_UNTIL, TOKEN_DO,
  TOKEN_WHEN, TOKEN_LET, TOKEN_CASE, TOKEN_DEBUGGER, TOKEN_DEFAULT, TOKEN_DELETE, TOKEN_IN,
  TOKEN_INSTANCEOF, TOKEN_NEW, TOKEN_THROW, TOKEN_FUNCTION, TOKEN_CONTINUE, TOKEN_VOID, TOKEN_VAR, TOKEN_WITH, TOKEN_TYPEOF, TOKEN_LOOP, TOKEN_AND, TOKEN_NOT, TOKEN_OR]  = [1..255]

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

exports.program = (solver, cont) ->
  text = solver.parserdata; pos = solver.parsercursor
  length = text.length
  if pos>=length then return cont(null)
  else programBody(solver, cont)

exports.programBody = (solver, cont) ->
  exps = []
  while 1
    stmt = statement(solver, cont)
    if stmt[0]==sexpression.COMMENT then continue
    [text, pos] = solver.state
    if pos==text.length then break
  if exps.length is 0 then null
  else exps.unshift sexpression.BEGIN; exps

exports.statement = (solver, cont) ->
  solver.token = token = readStartToken(solver, cont)
  switch token
    when SYM_RETURN then  exp = expression(solver, cont); [util.RETURN, exp]
    when SYM_PASS then passStatement(solver, cont); undefined
    when SYM_BLOCKCOMMENT then blockComment(solver, cont)
    when SYM_LINECOMMENT then lineComment(solver, cont)
    when SYM_IF
      orp(andp(testExpression(solver, cont)))
    else expression(solver, cont)

exports.expression = (solver, cont) ->
  assignExpr(solver, cont)

class StateMachine
  constructor = (items=[]) ->
    @index = 0
    @stateMap = {}
    @stateMap[0] = {}
    @tagMap = {}
    for item in items then @add(item[0], item[1])

  add = (word, tag) ->
    length = word.length
    for c in word[0...length-1]
      if c in @stateMap[state]
        state = Math.abs(@stateMap[state][c])
      else
        newState = @index++
        @stateMap[state][c] = newState
        @stateMap[newState] = {}
        state = newState
    c = word[-1]
    if c in @stateMap[state]
      if @stateMap[state][c]>0 then @stateMap[state][c] = -@stateMap[state][c]
    else
      newState = @new_state++
      @stateMap[state][c] = -newState
      @stateMap[newState] = {}
      @tagMap[newState] = tag

  match = (text, i) ->
    state = 0
    succeedState
    length = string.length
    while i<length
      c = text[i]
      state = @stateMap[state][c]
      if state is null
        if succeedState then return @tagMap[succeedState]
        else return null
      else if state<0
        i++
        state = -state
        succeedState = state