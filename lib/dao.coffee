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

  assign($program, lamda([],
    orp(andp(eoi, null),
        andp(assign(body, funcall($programBody), headList('begin', body)))))),
  assign($statement, lamda([],
    assign(token, funcall(readToken)),
    switch_(token,
      [TKNRETURN],
        begin(assign(exp, funcall($expression)), array(util.RETURN, exp)),
      [TKNPASS],
        funcall($matchToEOL),
      [TKNLINECOMMENTBEGIN],
        funcall($blockcomment),
      #else
       funcall($expression))
    )),
  assign($expression, lamda([],
    orp(funcall($valueExpr),
    funcall($invocationExpr),
    funcall($code),
    funcall($operationExpr),
    funcall($assignExpr),
    funcall($ifExpr),
    funcall($tryExpr),
    funcall($forExpr),
    funcall($switchExpr),
    funcall($throwExpr)))),
  assign($assignExpr, lamda([],
    assign(left, funcall($leftValueExpr)),
    assign(op, funcall('assignOperator', solver)),
    assign(exp, funcall($expression)),
    if_(eq(op, util.ASSIGN), array(op, left, exp),
           concat(op, array(left, exp))))),
  assign($leftValueExpr, lamda([],
    orp(identifier(),
       funcall($attrExpr),
       funcall($indexExpr)))),
  assign($attrExpr, lamda([],
    andp(orp(identifier(), funcall($parenExper), funcall($arrayLiteral), quoteString()),
         charDot,
         identifier()))),
  assign($indexExpr, lamda([],
    andp(orp(identifier(), funcall($parenExpr)),
         charLeftBracket,
         funcall($expression),
         charRightBracket))),
  assign($binaryExpr,lamda([],
      variable(x),
      assign(x, funcall($unaryExpr)),
      orp(andp(greedyany(
                  andp(assign(op, funcall('binaryOperator', solver)),
                    assign(y, funcall($unaryExpr)),
                    assign(x, array(op, x, y)))),
                  x),
         x))),
  assign($unaryExpr, lamda([],
      orp(andp(assign(op, funcall('unaryOperator', solver)),
               assign(x, funcall($atomExpr)),
               array(op, x)),
          andp(assign(x, funcall($atomExpr)),
              orp(andp(assign(op, funcall('suffixOperator', solver)), array(op, x)),
                  x)))))
  assign($parenExpr, lamda([],
      charLeftParen, assign(exp, funcall($binaryExpr)), charRightParen, exp)),
  assign($atomExpr, lamda([], orp(identifier(), array(util.STRING, quoteString()), number(), funcall($parenExpr)))),
  funcall($binaryExpr))


