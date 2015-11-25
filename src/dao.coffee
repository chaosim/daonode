{solve} = core = require('./core')
{string, char, number, parsetext, quoteString, identifier,
begin, nonlocal, variable, direct, switch_
if_, eq, concat,
jsfun, lamda, funcall
andp, orp, assign,
array, headList
greedyany
eoi} = util = require('./util')

{operator, tokenInfoList, tokenNames} = daoutil = require('./daoutil')

hasOwnProperty = Object.hasOwnProperty

for name, value of tokenNames
  if hasOwnProperty.call(tokenNames, name)
    global[name] = value

il = require('./interlang')

repl = () ->

exports.compile = compile = (code) ->
  sexpr = core.solve(parsetext(grammar, string(exp)))
  path = process.cwd()+'/lib/compiled.js'
  core.compile(sexpr, path)

exports.solve = solve = (exp) ->
  sexpr = core.solve(parsetext(grammar, string(exp)))
#  core.solve(sexpr)

solver = 'solver'

x = 'x'; y = 'y'; z = 'z'
op = 'op'; left = 'left'
token = 'token'; readToken = 'readToken'
exp = 'exp'; body = 'body';

$program = '$program'; $programBody = '$programBody'
$statement = '$statement'; $expression = '$expression'; $exprList = '$exprList'
$ifExpr = '$ifExpr'; $forExpr = '$forExpr';  $switchExpr = '$switchExpr';
$tryExpr = '$tryExpr'; $throwExpr = '$throwExpr'
$assignExpr = '$assignExpr'; $leftValueExpr = '$leftValueExpr'
$attrExpr = '$attrExpr'; $indexExpr = '$indexExpr'
$operationExpr = '$operationExpr'; $binaryExpr = '$binaryExpr'; $unaryExpr = '$unaryExpr'; $atomExpr = '$atomExpr';
$parenExpr ='$parenExpr';
$valueExpr = '$valueExpr'; $invocationExpr = '$invocationExpr'; $code = '$code'
$parenExper = '$parenExper'; $arrayLiteral = '$arrayLiteral'
$linecomment = '$linecomment'
$blockcomment = '$blockcomment
'
$matchToEOL = '$matchToEOL'

charLeftParen = char(string('(')); charRightParen = char(string(')'))
charLeftBracket = char(string('[')); charRightBracket = char(string(']'))
charDot = char(string('.')); charComma = char(string(',')); charSemiConlon = char(string(';')); charConlon = char(string(':'))

grammar = begin(
direct(
il.begin(
    il.assign(il.uservar('daoutil'), il.require('./daoutil')),
    il.assign(il.uservar('readToken'), il.attr(il.uservar('daoutil'), il.symbol('readToken'))),
    il.assign(il.uservar('StateMachine'), il.attr(il.uservar('daoutil'), il.symbol('StateMachine'))),
    il.assign(il.uservar('tokenInfoList'), il.attr(il.uservar('daoutil'), il.symbol('tokenInfoList'))),
    il.assign(il.uservar('binaryOperator'), il.attr(il.uservar('daoutil'), il.symbol('binaryOperator'))),
    il.assign(il.uservar('unaryOperator'), il.attr(il.uservar('daoutil'), il.symbol('unaryOperator'))),
    il.assign(il.uservar('assignOperator'), il.attr(il.uservar('daoutil'), il.symbol('assignOperator'))),
    il.assign(il.uservar('suffixOperator'), il.attr(il.uservar('daoutil'), il.symbol('suffixOperator'))),
    il.assign(il.attr(il.uservar('solver'), il.uservar('tokenStateMachine')),
              il.new(il.uservar('StateMachine').call(il.uservar('tokenInfoList'))))
  )),

assign($nextToken, lamda([] )),
assign('parse', lamda([element],
switch_(element,
[Program], orp(
  andp(eoi, null),
    andp(assign(body, parse(ProgramBody)), eoi, headList('begin', body))),

[Statement], andp(
  nextToken,
  switch_(token,
    [TKNRETURN],
    begin(assign(exp, parse(Expression)), array(util.RETURN, exp)),
    [TKNTHROWN],
    begin(assign(exp, parse(Expression)), array(util.THROW, exp)),
    [TKNPASS],
      funcall($matchToEOL),
    [TKNCOMMENT],
      parse(blockcomment),
    #else
      parse(Expression))
  ),

[Expression],orp(
    parse(ValueExpr),
    parse(InvocationExpr),
    parse(Code),
    parse(OperationExpr),
    parse(AssignExpr),
    parse(ShifExpr),
    parse(TryExpr),
    parse(ForExpr),
    parse(SwitchExpr),
    parse(ThrowExpr)))),

[AssignExpr],andp(
  assign(left, parse(LeftValueExpr)),
  assign(op, funcall('assignOperator', solver)),
  assign(exp, parse(Expression)),
  if_(eq(op, util.ASSIGN), array(op, left, exp),
         concat(op, array(left, exp)))),

[LeftValueExpr],
    if_(eq(tokenId, TKNIDENTIFIER), tokenValue,
       orp(parse(AttrExpr),
         parse(IndexExpr))),

[ChainExpr], andp(
  parse(Expression),
  orp(
    andp(tokenWithSpace(TKNDOT), matchToken(TKNIDENTIFIER)),
    andp(tokenWithSpace(TKNLBRACKET), parse(Expression), tokenWithSpace(TKNRBRACKET)),
    andp(charLeftParen, assign(exp, array(FUNCALL, exp, parse(ExpressionList)), charRightParen) ),

[BinaryExp], andp(
  variable(x),
  assign(x, parse(unaryExpr)),
  while_(1,
    nextToken,
    switch_(tokenID,
      [TKNADD, TKNSUB],
        andp(assign(op, tokenValue),
             assign(y, parse(unaryExpr)),
             assign(x, array(op, x, y))),
      reuseToken, jsbreak_()))
  x),

[UnaryExpr], andp(
  nextToken,
  switch_(tokenID,
    [TKNNEG, TKNPOSITIVE, TKNINC, TKNDEC],
      andp(assign(op, tokenValue), assign(x, parse(atomExpr)), array(op,x))
    #else
      andp( reuseToken,
            assign(x, parse(atomExpr)),
            nextToken,
            switch_( tokenID,
              [TKNINC, TKNDEC] ,
                array(tokenValue, x)
              #else
                andp(reuseToken, x) )))),

[ParenExpr], andp(
  assign(exp, parse(BinaryExpr)), charRightParen, exp),

[AtomExpr], andp(
    nextToken,
    switch_(tokenID,
      TKNTRUE, true,
      TKNFALSE, false,
      TKNIDENTIFIER, tokenValue,
      TKNSTRING, tokenValue,
      TKNNUMBER, jseval(tokenValue),
      TKNLEFTBRACKET, parse(ArrayLiteral),
      TKNLEFTPAREN, parse(ParenExpr)
      reuseToken)),

funcall(parse, BinaryExpr)))


