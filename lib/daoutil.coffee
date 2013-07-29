{Trail, Var,  ExpressionError, TypeError, SolverFail} = require "./solve"

exports.operator = (solver) ->
  [text, pos] = solver.state
  length = text.length
  if pos>=length then throw new SolverFail(pos)
  c = text[pos]
  switch c
    when '+' then solver.state = [text, pos+1]; 'vop_add'
    when '-' then solver.state = [text, pos+1]; 'vop_sub'
    when '*' then solver.state = [text, pos+1]; 'vop_mul'
    when '/' then solver.state = [text, pos+1]; 'vop_div'
    when '%' then solver.state = [text, pos+1]; 'vop_mod'
    when '='
      c1 = text[pos+1]
      if c1=='=' then solver.state = [text, pos+2]; 'vop_eq'
      else solver.failcont(pos)
    when '!'
      c1 = text[pos+1]
      if c1=='=' then solver.state = [text, pos+2]; 'vop_ne'
      else solver.failcont(pos)
    when '>'
      c1 = text[pos+1]
      if c1=='=' then solver.state = [text, pos+2]; 'vop_ge'
      else if c1=='>' then solver.state = [text, pos+2]; 'vop_rshift'
      else solver.state = [text, pos+1]; 'vop_gt'
    when '<'
      c1 = text[pos+1]
      if c1=='=' then solver.state = [text, pos+2]; 'vop_le'
      else if c1=='<' then solver.state = [text, pos+2]; 'vop_lshift'
      else solver.state = [text, pos+1]; 'vop_lt'