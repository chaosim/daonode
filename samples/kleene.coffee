{solve, special, vari, dummy, cons, vari, macro} = require("../lib/dao")
{print_, getvalue, toString} = require("../lib/builtins/general")
{andp, orp, rule, bind, is_} = require("../lib/builtins/logic")
{begin} = require("../lib/builtins/lisp")
{settext, char, digits, spaces, eoi} = require("../lib/builtins/parser")

exports.flatString = flatString = special(1, 'flatString', (solver, cont, x) ->
  solver.cont(x, (v, solver) -> cont(v.flatString?() or 'null', solver)))

exports.kleene = kleene = rule(1, (x) ->
  x = vari('x');  y = vari('y')
  [ [cons(x, y)], andp(char(x), print_(x), kleene(y)),
    [null], print_('end')
  ])

exports.kleenePredicate = (pred) ->
  r = rule(1, (x) ->
    x = vari('x');  y = vari('y')
    [ [cons(x, y)], andp(pred(x)#, print_(x)
                        , r(y)),
      [null], print_('end')
    ])
  r

#dightsSpaces = macro(1, (x) -> andp(digits, print_('daf'), spaces, print_('adds')))

exports.dightsSpaces = macro(1, (x) ->
   andp(is_(x, digits)
#      print_('daf'),
      , orp(spaces, eoi)
#      , print_('adds')
   )
)

