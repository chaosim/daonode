{solve, vari, cons, newVar} = require("../lib/dao")
{andp, rule} = require("../lib/builtins/logic")
{begin} = require("../lib/builtins/lisp")
{settext, char} = require("../lib/builtins/parser")

list = rule(1, (x) ->
  y = newVar('y')
  [ [cons('a', y)], andp(char('a'), list(y)),
    [null], null,
  ])

x = vari('x')
console.log  solve(begin(
  settext('abc'),
  list(x)))