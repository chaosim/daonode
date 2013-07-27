{solve, special, vari, dummy, cons, vari, macro} = core = require("../../lib/interpreter/core")
{print_, getvalue, toString} = require("../../lib/interpreter/builtins/general")
{andp, orp, bind, is_} = require("../../lib/interpreter/builtins/logic")
{begin} = require("../../lib/interpreter/builtins/lisp")
{settext} = require("../../lib/interpreter/builtins/parser")
{expression, operator, atom} = require("../../samples/expression")

xexports = {}

exports.Test =
  "test operator": (test) ->
    x = vari('x')
    console.log  solve(begin(
                              settext('+'),
                              operator(x), x))
    test.equal(x.binding, '+');
    test.equal(core.status, core.SUCCESS);
    x.binding = x
    console.log  solve(begin(
                              settext('/'),
                              operator(x), x))
    test.equal(x.binding, '/');
    test.equal(core.status, core.SUCCESS);
    test.done()

xexports.Test =
  "test kleene": (test) ->
    x = vari('x')
    console.log  solve(begin(
      settext('ab'),
      kleene(x), flatString(getvalue(x))))
    test.equal(core.status, core.SUCCESS);
    test.done()
