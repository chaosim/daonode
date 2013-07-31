{Trail, Var,  ExpressionError, TypeError} = require "./solve"

exports.binaryOperator = (solver, cont) ->
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  c = text[pos]
  switch c
    when '+' then solver.state = [text, pos+1]; cont('vop_add')
    when '-' then solver.state = [text, pos+1]; cont('vop_sub')
    when '*' then solver.state = [text, pos+1]; cont('vop_mul')
    when '/' then solver.state = [text, pos+1]; cont('vop_div')
    when '%' then solver.state = [text, pos+1]; cont('vop_mod')
    when '='
      c1 = text[pos+1]
      if c1=='=' then solver.state = [text, pos+2]; cont('vop_eq')
      else return solver.failcont(pos)
    when '!'
      c1 = text[pos+1]
      if c1=='=' then solver.state = [text, pos+2]; cont('vop_ne')
      else return solver.failcont(pos)
    when '>'
      c1 = text[pos+1]
      if c1=='=' then solver.state = [text, pos+2]; cont('vop_ge')
      else if c1=='>' then solver.state = [text, pos+2]; cont('vop_rshift')
      else solver.state = [text, pos+1]; cont('vop_gt')
    when '<'
      c1 = text[pos+1]
      if c1=='=' then solver.state = [text, pos+2]; cont('vop_le')
      else if c1=='<' then solver.state = [text, pos+2]; cont('vop_lshift')
      else solver.state = [text, pos+1]; cont('vop_lt')

exports.unaryOperator = (solver, cont) ->
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  c = text[pos]
  switch c
    when '+'
      c1 = text[pos+1]
      if c1=='+' then solver.state = [text, pos+2]; cont('vop_inc')
      else solver.state = [text, pos+1]; cont('vop_pos')
    when '-'
      c1 = text[pos+1]
      if c1=='+' then solver.state = [text, pos+2]; cont('vop_dec')
      else solver.state = [text, pos+1]; cont('vop_neg')
    when '!' then solver.state = [text, pos+1]; cont('vop_not')
    when '~' then solver.state = [text, pos+1]; cont('vop_bitnot')
    else solver.failcont(pos)

exports.suffixOperator = (solver, cont) ->
  [text, pos] = solver.state
  length = text.length
  if pos>=length then return solver.failcont(pos)
  c = text[pos]
  switch c
    when '+'
      c1 = text[pos+1]
      if c1=='+' then solver.state = [text, pos+2]; cont('vop_inc')
      else solver.failcont(pos)
    when '-'
      c1 = text[pos+1]
      if c1=='+' then solver.state = [text, pos+2]; cont('vop_dec')
      else solver.failcont(pos)
    else solver.failcont(pos)

exports.program = (solver, cont) ->
  [text, pos] = solver.state
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
    when RETURN then  returnStatement(solver, cont)
    when PASS then passStatement(solver, cont)
    when BLOCKCOMMENT then blockComment(solver, cont)
    when LINECOMMENT then lineComment(solver, cont)
    else expression(solver, cont)

