{solve, special, vari, dummy, cons, vari, macro} = dao = require("../../lib/dao")
{print_, getvalue, toString} = require("../../lib/builtins/general")
{andp, orp, bind, is_} = require("../../lib/builtins/logic")
{begin} = require("../../lib/builtins/lisp")
{settext} = require("../../lib/builtins/parser")
{kleene, kleenePredicate, dightsSpaces, flatString} = require("../kleene")

xexports = {}

exports.Test =
  "test kleenePredicate": (test) ->
    x = vari('x')
    console.log  solve(begin(
      settext('123 456'),
      kleenePredicate(dightsSpaces)(x), flatString(getvalue(x))))
    test.done()

exports.Test =
  "test kleenePredicate": (test) ->
    x = vari('x')
    console.log  solve(begin(
                              settext('ab'),
                              kleene(x), flatString(getvalue(x))))
    test.equal(dao.status, dao.SUCCESS);
    test.done()
