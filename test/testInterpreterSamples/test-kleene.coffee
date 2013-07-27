{solve, special, vari, dummy, cons, vari, macro} = core = require("../../lib/interpreter/core")
{print_, getvalue, toString} = require("../../lib/interpreter/builtins/general")
{andp, orp, bind, is_} = require("../../lib/interpreter/builtins/logic")
{begin} = require("../../lib/interpreter/builtins/lisp")
{settext, memo} = require("../../lib/interpreter/builtins/parser")
{kleene, leftkleene, kleenePredicate, dightsSpaces, flatString} = require("../../samples/interpreter/kleene")

xexports = {}

exports.Test =
  "test kleenePredicate": (test) ->
    x = vari('x')
    console.log  solve(begin(
      settext('123 456'),
      kleenePredicate(dightsSpaces)(x), flatString(getvalue(x))))
    test.done()

  "test kleene": (test) ->
    x = vari('x')
    console.log  solve(begin(
      settext('ab'),
      kleene(x), flatString(getvalue(x))))
    test.equal(core.status, core.SUCCESS);
    test.done()

xexports.Test =
  "test leftkleene": (test) ->
    # It doesn't work.
    console.log  solve(begin(
                              settext('ab'),
                              leftkleene()))
    test.equal(core.status, core.SUCCESS);
    test.done()
