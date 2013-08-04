{solve} = core = require('./core')
{string, char, number, parsetext, quoteString, identifier
begin, nonlocal, direct, switch_
if_, eq, concat,
jsfun, lamda, funcall
andp, orp, assign,
array, headList
eoi} = util = require('./util')

{operator} = daoutil = require('./daoutil')

il = require('./interlang')

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
   direct(il.begin(
      il.assign(il.uservar('daoutil'), il.require('./daoutil')),
      il.assign(il.uservar('readToken'), il.attr(il.uservar('daoutil'), il.symbol('readToken'))),
      il.assign(il.uservar('binaryOperator'), il.attr(il.uservar('daoutil'), il.symbol('binaryOperator'))),
      il.assign(il.uservar('unaryOperator'), il.attr(il.uservar('daoutil'), il.symbol('unaryOperator'))),
      il.assign(il.uservar('assignOperator'), il.attr(il.uservar('daoutil'), il.symbol('assignOperator'))),
      il.assign(il.uservar('suffixOperator'), il.attr(il.uservar('daoutil'), il.symbol('suffixOperator'))))),
  assign($program, lamda([],
    orp(andp(eoi, null),
        andp(assign(body, funcall($programBody), headList('begin', body)))))),
  assign($statement, lamda([],
    assign(token, funcall(readToken)),
    switch_(token,
      [TOKEN_RETURN],
        begin(assign(exp, funcall($expression)), array(util.RETURN, exp)),
      [TOKEN_PASS],
        funcall($matchToEOL),
      [TOKEN_BLOCKCOMMENTBEGIN],
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
  assign($attrExpr, lamda([],  andp(orp(identifier(), funcall($parenExper), funcall($arrayLiteral), quoteString()),
                                    charDot, identifier()))),
  assign($indexExpr, lamda([],  andp(orp(identifier(), funcall($parenExpr)),
                                    charLeftBracket, funcall($expression), charRightBracket))),
  assign($binaryExpr, lamda([],
                            andp(assign(x, funcall($unaryExpr)),
                                 orp(andp(assign(op, funcall('binaryOperator', solver)),
                                          assign(y, funcall($unaryExpr)),
                                          array(op, x, y)),
                                     x)))),
  assign($unaryExpr, lamda([],
      orp(andp(assign(op, funcall('unaryOperator', solver)),
               assign(x, funcall($atomExpr)),
               array(op, x)),
          andp(assign(x, funcall($atomExpr)),
              orp(andp(assign(op, funcall('suffixOperator', solver)), array(op, x)),
                  x)))))
  assign($parenExpr, lamda([],
      andp(charLeftParen, assign(exp, funcall($binaryExpr)), charRightParen, exp))),
  assign($atomExpr, lamda([], orp(identifier(), array(util.STRING, quoteString()), number(), funcall($parenExpr)))),
  funcall($binaryExpr))


