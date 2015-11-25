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

exports.readToken = readToken = (text, start) ->
  tokenStateMachine = solver.tokenStateMachine
  text = solver.parserdata
  start = solver.parsercursor
  result = tokenStateMachine.match(text, start)
  value = result[0]; cursor = result[1]
  if value then solver.parsercursor = cursor; [value, cursor]
  else solver.parsercursor = start; null

BinaryOperatorMap = {}
(BinaryOperatorMap[pair[0]] = pair[1]) for pair in [
  [TKNADD, ADD], [TKNSUB, SUB], [TKNMUL, MUL], [TKNDIV, DIV], [TKNMOD, MOD],
  [TKNAND, AND], [TKNOR, OR],
  [TKNBITAND, BITAND], [TKNBITOR, BITOR], [TKNLSHIFT, LSHIFT], [TKNRSHIFT, RSHIFT],
  [TKNEQ, EQ], [TKNNE, NE], [TKNLT, LT], [TKNLE, LE], [TKNGE, GE], [TKNGT, GT]
]

exports.BinaryOperator = (solver, cont) ->
  start = solver.parsercursor
  token =  readToken(solver)
  op = BinaryOperatorMap[token]
  if op isnt undefined then cont(op)
  else solver.parsercursor = start; solver.failcont(null)

UnaryOperatorMap = {}
(UnaryOperatorMap[pair[0]] = pair[1]) for pair in [
  [TKNNOT, NOT], [TKNBITNOT, BITNOT], [TKNNEG, NEG], [TKNPOSITIVE, POSITIVE]
  [TKNINC, INC], [TKNDEC, DEC]
]

exports.UnaryOperator = (solver, cont) ->
  start = solver.parsercursor
  token =  readToken(solver)
  op = UnaryOperatorMap[token]
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

nextToken = (solver, cont) ->
  text = solver.parserdata
  cursor = solver.parsercursor
  c = text[cursor]
  switch c
    when undefined then [EOI, cursor]
    when '0'
      c2 = cursor[1]
      switch c2
        when 'x', 'X', 'h', 'H' then hexadigit(text, cursor)
        when '1', '2', '3', '4','5','6','7' then octal(text, cursor)
    when '1', '2', '3', '4','5','6','7','8','9' then number(text, cursor)
    when '+','-'
      c2 = cursor[1]
      switch c
        when '0'
          c2 = cursor[1]
          switch c2
            when 'x', 'X', 'h', 'H' then hexadigit(text, cursor)
            when '1', '2', '3', '4','5','6','7' then octal(text, cursor)
        when '1', '2', '3', '4','5','6','7','8','9' then number(text, cursor)
    when 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y'
      result = keyword(text, cursor)
      if result[0] is undefined
        result2 = identifier(text, result[1])
      else
        c2 = text[result[1]]
        if isIdentifierCharacter(c2)
          result2 = identifier(text, result[1])
    when '_', '$','z', 'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'
      identifier(text, cursor)
    when ' ','\t'
      whitespace(text, cursor)
    when '"', "'"
      result = quoteString(text, cursor, c)
      if result[0] is undefined then [QUOTE, c]
    when '#'
      result = comment(text, cursor)
    when '\r','\n' #indent and unindent
      newlineIndent(text, cursor, solver)
    else symbolToken(text, cursor)

# on succeed any matcher should not return result is not null or undefined, except the root symbol.

orp = (exps) -> (start) ->
  length = exps.length
  i = 0
  while i<length
    x = exps(start)
    if x? then return x

andp = (exps) -> (start) ->
  length = exps.length
  i = 0
  cursor = start
  while i<length
    x = exps(cursor)
    if not x? then return
  return x

notp = (exp) -> (start) ->
  x = exp(start)
  if not x? then return true
  return

char = (c) -> (start) ->
  if text[start]==c then cursor = start+1; return true

literal = (string) -> (start) ->
  len = string.length
  if text.slice(start,  stop = start+len)==string then cursor = stop; return true

keyword = (string) -> (start) ->
  len = string.length
  if text.slice(start, stop = start+len)==string and not text[stop2= stop+1].match /^[A-Za-z]/
    cursor = stop2; return true

spaces = (start) ->
  len = 0
  cursor = start
  while 1
    switch text[cursor]
     when ' ' then len++
     when '\t' then len += tabWidth
     else break
  return len

spaces1 = (start) ->
  len = 0
  cursor = start
  while 1
    switch text[cursor]
      when ' ' then len++
      when '\t' then len += tabWidth
      else break
  if len then return len

exports.parse = (element, text, tabWidth=4) ->
  global.text = text
  global.cursor = 0
  global.tokens = []
  global.memo = {}
  global.indentList = []
  global.tabWidth = tabWidth
  rules[element](0)

rules = {
Root: (start) ->
  if start is textLength then null
  else rules.Body(start)

Body: (start) ->
  cursor = start
  exps = []
  while 1
    x = rules.Statement(start)
    if x instanceof Comment then continue
    else if cursor is textLength then return begin(exps...)
    else exps.push Statement()

Statement: #(start) ->
  orp(rules.Comment, rules.Return, rules.Expression)#(start)

Expression: #(start) ->
  orp(rules.If, rules.Try, rules.For, rules.While, rules.Throw, rules.Class, rules.Switch,
     rules.Value, rules.Invocation, rules.FunctionDef, rules.Operation)#(start)

#  Value  Invocation FunctionDef Operation Assign If Try While For Switch Class Throw

Block: #(start) ->
  andp(indent, rules.Body, dedent) #(start)

Literal: #(start) ->
  orp(rules.KeywordLiteral, rules.RawJS, rules.String, rules.Alpha, rules.Number, rules.JSRegex)#(start)

KeywordLiteral:(start) ->
  if text.slice(start, start+2) == 'true' then return new Literal(true)
  s = text.slice(start, start+4)
  if s == 'null' then return new Literal(null)
  if s == 'true' then return new Literal(true)
  s = text.slice(start, start+5)
  if s == 'false' then return new Literal(false)
  if text.slice(start, start+7) == 'debugger' then return new Literal('debugger')
  s = text.slice(start, start+9)
  if s == 'undefined' then return new Literal(undefined)

Assign: (start) ->
  left = rules.Assignable(start)
  if left is null then return
  if rules.wrapSpaces('=')(cursor) is null then return
  if newline(cursor) is null then exp = rules.Expression(cursor)
  else
    if indent() is null then return
    exp = rules.Expression(cursor)
    if dedent() is null then return
  return assign(left, exp)

AssignObj: #(start) ->
  orp(rules.Comment, AssignObjClause) #(start)

AssignObjClause: (start) ->
  left = rules.ObjAssignable(start)
  if left is null then return
  andp(spaces, char(':'), spaces)(cursor)
  if indent(cursor) is null then exp = rules.Expression(cursor)
  else
    if (exp = rules.Expression(cursor)) isnt null
      dedent(cursor)
  [left, exp]

ObjAssignable:
  orp(rules.Identifier, rules.Alpha, rules.Numberic, rules.ThisProperty)

Return: (start) ->
  if keyword('return')(start) and spaces(cursor)
    if exp=rules.Expression(cursor) then util.return_(exp)
    else util.return_()

Comment: (start) ->
  spaces(start); char('#')(cursor); string = matchToNewLine(cursor); return new Comment(string)

FunctionDef: (start) ->
  params = rules.Parameters(start)
  wrapped(rules.FuncGlyph)(cursor)
  body = Block(cursor)
  util.lamda(params, body)

FuncGlyph: (start) ->
  if literal('->')(start) then 'func'
  else if literal('=>')(start) then 'boundfunc'

Parameters: (start) ->
  x = wrap(ParamList, leftParen, rightParen)
  if x? then x else []

ParameterList: (start) ->
  result = []
  spaces(curosr)
  while 1
    exp = rules.Param(cursor)
    orp(wrapped(char(',')),
        andp(may(wrapped(char(','))), newline))(curosr) #todo indent ParamList
    if exp? then result.push(exp)
    else breaks
  return []

Param: (start) ->
  v = rules.ParamVar(start)
  if v
    if wrap('...')(cursor) then return new Param $1, null, on
    else
      if v2 = andp(wrap('='), rules.Expression)  then new Param $1, $3
  o 'ParamVar',                               -> new Param $1
  o 'ParamVar ...',                           -> new Param $1, null, on
  o 'ParamVar = Expression',                  -> new Param $1, $3

ParamVar: [
  o 'Identifier'
  o 'ThisProperty'
  o 'Array'
  o 'Object'
]
Splat: [
  o 'Expression ...',                         -> new Splat $1
]
SimpleAssignable: [
  o 'Identifier',                             -> new Value $1
  o 'Value Accessor',                         -> $1.add $2
  o 'Invocation Accessor',                    -> new Value $1, [].concat $2
  o 'ThisProperty'
]
Assignable: [
  o 'SimpleAssignable'
  o 'Array',                                  -> new Value $1
  o 'Object',                                 -> new Value $1
]
Value: [
  o 'Assignable'
  o 'Literal',                                -> new Value $1
  o 'Parenthetical',                          -> new Value $1
  o 'Range',                                  -> new Value $1
  o 'This'
]
Accessor: [
  o '.  Identifier',                          -> new Access $2
  o '?. Identifier',                          -> new Access $2, 'soak'
  o ':: Identifier',                          -> [LOC(1)(new Access new Literal('prototype')), LOC(2)(new Access $2)]
  o '?:: Identifier',                         -> [LOC(1)(new Access new Literal('prototype'), 'soak'), LOC(2)(new Access $2)]
  o '::',                                     -> new Access new Literal 'prototype'
  o 'Index'
]
Index: [
  o 'INDEX_START IndexValue INDEX_END',       -> $2
  o 'INDEX_SOAK  Index',                      -> extend $2, soak : yes
]
IndexValue: [
  o 'Expression',                             -> new Index $1
  o 'Slice',                                  -> new Slice $1
]
Object: [
  o '{ AssignList OptComma }',                -> new Obj $2, $1.generated
]
AssignList: [
  o '',                                                       -> []
  o 'AssignObj',                                              -> [$1]
  o 'AssignList , AssignObj',                                 -> $1.concat $3
  o 'AssignList OptComma TERMINATOR AssignObj',               -> $1.concat $4
  o 'AssignList OptComma INDENT AssignList OptComma OUTDENT', -> $1.concat $4
]
Class: [
  o 'CLASS',                                           -> new Class
  o 'CLASS Block',                                     -> new Class null, null, $2
  o 'CLASS EXTENDS Expression',                        -> new Class null, $3
  o 'CLASS EXTENDS Expression Block',                  -> new Class null, $3, $4
  o 'CLASS SimpleAssignable',                          -> new Class $2
  o 'CLASS SimpleAssignable Block',                    -> new Class $2, null, $3
  o 'CLASS SimpleAssignable EXTENDS Expression',       -> new Class $2, $4
  o 'CLASS SimpleAssignable EXTENDS Expression Block', -> new Class $2, $4, $5
]
Invocation: [
  o 'Value OptFuncExist Arguments',           -> new Call $1, $3, $2
  o 'Invocation OptFuncExist Arguments',      -> new Call $1, $3, $2
  o 'SUPER',                                  -> new Call 'super', [new Splat new Literal 'arguments']
  o 'SUPER Arguments',                        -> new Call 'super', $2
]
OptFuncExist: [
  o '',                                       -> no
  o 'FUNC_EXIST',                             -> yes
]
Arguments: [
  o 'CALL_START CALL_END',                    -> []
  o 'CALL_START ArgList OptComma CALL_END',   -> $2
]
This: [
  o 'THIS',                                   -> new Value new Literal 'this'
  o '@',                                      -> new Value new Literal 'this'
]
ThisProperty: [
  o '@ Identifier',                           -> new Value LOC(1)(new Literal('this')), [LOC(2)(new Access($2))], 'this'
]
Array: [
  o '[ ]',                                    -> new Arr []
  o '[ ArgList OptComma ]',                   -> new Arr $2
]
RangeDots: [
  o '..',                                     -> 'inclusive'
  o '...',                                    -> 'exclusive'
]
Range: [
  o '[ Expression RangeDots Expression ]',    -> new Range $2, $4, $3
]
Slice: [
  o 'Expression RangeDots Expression',        -> new Range $1, $3, $2
  o 'Expression RangeDots',                   -> new Range $1, null, $2
  o 'RangeDots Expression',                   -> new Range null, $2, $1
  o 'RangeDots',                              -> new Range null, null, $1
]
ArgList: [
  o 'Arg',                                              -> [$1]
  o 'ArgList , Arg',                                    -> $1.concat $3
  o 'ArgList OptComma TERMINATOR Arg',                  -> $1.concat $4
  o 'INDENT ArgList OptComma OUTDENT',                  -> $2
  o 'ArgList OptComma INDENT ArgList OptComma OUTDENT', -> $1.concat $4
]
Arg: [
  o 'Expression'
  o 'Splat'
]
SimpleArgs: [
  o 'Expression'
  o 'SimpleArgs , Expression',                -> [].concat $1, $3
]
Try: [
  o 'TRY Block',                              -> new Try $2
  o 'TRY Block Catch',                        -> new Try $2, $3[0], $3[1]
  o 'TRY Block FINALLY Block',                -> new Try $2, null, null, $4
  o 'TRY Block Catch FINALLY Block',          -> new Try $2, $3[0], $3[1], $5
]
Catch: [
  o 'CATCH Identifier Block',                 -> [$2, $3]
  o 'CATCH Object Block',                     -> [LOC(2)(new Value($2)), $3]
  o 'CATCH Block',                            -> [null, $2]
]
Throw: [
  o 'THROW Expression',                       -> new Throw $2
]
Parenthetical: [
  o '( Body )',                               -> new Parens $2
  o '( INDENT Body OUTDENT )',                -> new Parens $3
]
WhileSource: [
  o 'WHILE Expression',                       -> new While $2
  o 'WHILE Expression WHEN Expression',       -> new While $2, guard: $4
  o 'UNTIL Expression',                       -> new While $2, invert: true
  o 'UNTIL Expression WHEN Expression',       -> new While $2, invert: true, guard: $4
]
While: [
  o 'WhileSource Block',                      -> $1.addBody $2
  o 'Statement  WhileSource',                 -> $2.addBody LOC(1) Block.wrap([$1])
  o 'Expression WhileSource',                 -> $2.addBody LOC(1) Block.wrap([$1])
  o 'Loop',                                   -> $1
]
Loop: [
  o 'LOOP Block',                             -> new While(LOC(1) new Literal 'true').addBody $2
  o 'LOOP Expression',                        -> new While(LOC(1) new Literal 'true').addBody LOC(2) Block.wrap [$2]
]
For: [
  o 'Statement  ForBody',                     -> new For $1, $2
  o 'Expression ForBody',                     -> new For $1, $2
  o 'ForBody    Block',                       -> new For $2, $1
]
ForBody: [
  o 'FOR Range',                              -> source: LOC(2) new Value($2)
  o 'ForStart ForSource',                     -> $2.own = $1.own; $2.name = $1[0]; $2.index = $1[1]; $2
]
ForStart: [
  o 'FOR ForVariables',                       -> $2
  o 'FOR OWN ForVariables',                   -> $3.own = yes; $3
]
ForValue: [
  o 'Identifier'
  o 'ThisProperty'
  o 'Array',                                  -> new Value $1
  o 'Object',                                 -> new Value $1
]
ForVariables: [
  o 'ForValue',                               -> [$1]
  o 'ForValue , ForValue',                    -> [$1, $3]
]
ForSource: [
  o 'FORIN Expression',                               -> source: $2
  o 'FOROF Expression',                               -> source: $2, object: yes
  o 'FORIN Expression WHEN Expression',               -> source: $2, guard: $4
  o 'FOROF Expression WHEN Expression',               -> source: $2, guard: $4, object: yes
  o 'FORIN Expression BY Expression',                 -> source: $2, step:  $4
  o 'FORIN Expression WHEN Expression BY Expression', -> source: $2, guard: $4, step: $6
  o 'FORIN Expression BY Expression WHEN Expression', -> source: $2, step:  $4, guard: $6
]
Switch: [
  o 'SWITCH Expression INDENT Whens OUTDENT',            -> new Switch $2, $4
  o 'SWITCH Expression INDENT Whens ELSE Block OUTDENT', -> new Switch $2, $4, $6
  o 'SWITCH INDENT Whens OUTDENT',                       -> new Switch null, $3
  o 'SWITCH INDENT Whens ELSE Block OUTDENT',            -> new Switch null, $3, $5
]
Whens: [
  o 'When'
  o 'Whens When',                             -> $1.concat $2
]
When: [
  o 'LEADING_WHEN SimpleArgs Block',            -> [[$2, $3]]
  o 'LEADING_WHEN SimpleArgs Block TERMINATOR', -> [[$2, $3]]
]
IfBlock: [
  o 'IF Expression Block',                    -> new If $2, $3, type: $1
  o 'IfBlock ELSE IF Expression Block',       -> $1.addElse LOC(3,5) new If $4, $5, type: $3
]
If: [
  o 'IfBlock'
  o 'IfBlock ELSE Block',                     -> $1.addElse $3
  o 'Statement  POST_IF Expression',          -> new If $3, LOC(1)(Block.wrap [$1]), type: $2, statement: true
  o 'Expression POST_IF Expression',          -> new If $3, LOC(1)(Block.wrap [$1]), type: $2, statement: true
]
Operation: [
  o 'UNARY Expression',                       -> new Op $1 , $2
  o '-     Expression',                      (-> new Op '-', $2), prec: 'UNARY'
  o '+     Expression',                      (-> new Op '+', $2), prec: 'UNARY'

  o '-- SimpleAssignable',                    -> new Op '--', $2
  o '++ SimpleAssignable',                    -> new Op '++', $2
  o 'SimpleAssignable --',                    -> new Op '--', $1, null, true
  o 'SimpleAssignable ++',                    -> new Op '++', $1, null, true

  # [The existential operator](http://jashkenas.github.com/coffee-script/#existence).
  o 'Expression ?',                           -> new Existence $1

  o 'Expression +  Expression',               -> new Op '+' , $1, $3
  o 'Expression -  Expression',               -> new Op '-' , $1, $3

  o 'Expression MATH     Expression',         -> new Op $2, $1, $3
  o 'Expression SHIFT    Expression',         -> new Op $2, $1, $3
  o 'Expression COMPARE  Expression',         -> new Op $2, $1, $3
  o 'Expression LOGIC    Expression',         -> new Op $2, $1, $3
  o 'Expression RELATION Expression',         ->
    if $2.charAt(0) is '!'
      new Op($2[1..], $1, $3).invert()
    else
      new Op $2, $1, $3

  o 'SimpleAssignable COMPOUND_ASSIGN
                 Expression',                             -> new Assign $1, $3, $2
  o 'SimpleAssignable COMPOUND_ASSIGN
                 INDENT Expression OUTDENT',              -> new Assign $1, $4, $2
  o 'SimpleAssignable COMPOUND_ASSIGN TERMINATOR
                 Expression',                             -> new Assign $1, $4, $2
  o 'SimpleAssignable EXTENDS Expression',    -> new Extends $1, $3
]

Binary: (start) ->
  "Binary: Unary | Binary+Unary"
  hash = 'Binary'+start
  m = memo[hash]
  if m is null
    memo[hash] = rules.Unary(start)
    return rules.Binary(start)
  if text[cursor]!='+' then delete memo[hash]; return m
  cursor++
  a = rules.Unary(cursor)
  if a is null then delete memo[hash]; return m
  memo[hash] = m+a;
  return rules.Binary(start)

Unary: (start) ->
  "Unary: +Unary | -Unary | Atom | Atom++ | Atom--"
  c = text[cursor]
  switch c
    when '+'
      cursor++;
      if text[cursor]=='+' then cursor++; rules.Unary(cursor)+1;
      else rules.Unary(cursor)
    when '-'
      cursor++;
      if text[cursor]=='-' then cursor++; rules.Unary(cursor)-1
      else -rules.Unary(cursor)
    else
      x = rules.Atom(start)
      if text[cursor]=='+' and text[cursor+1]=='+' then cursor+=2; x+1
      else if text[cursor]=='-' and text[cursor+1]=='-' then cursor+=2; x-1
      else x

Atom: (start) ->
  "Atom: 1 | ( Binary )"
  switch text[cursor]
    when '1' then cursor++; 1
    when '(' then cursor++; exp = rules.Binary(cursor); match(')'); exp
    when '[' then cursor++; exp = rules.Expression(cursor); match(')'); exp

}