// Generated by CoffeeScript 1.6.2
(function() {
  var andp, begin, bind, char, cons, digits, dummy, eoi, flatString, getvalue, is_, kleene, leftkleene, macro, memo, orp, print_, rule, settext, solve, spaces, special, toString, vari, _ref, _ref1, _ref2, _ref3;

  _ref = require("../lib/dao"), solve = _ref.solve, special = _ref.special, vari = _ref.vari, dummy = _ref.dummy, cons = _ref.cons, vari = _ref.vari, macro = _ref.macro;

  _ref1 = require("../lib/builtins/general"), print_ = _ref1.print_, getvalue = _ref1.getvalue, toString = _ref1.toString;

  _ref2 = require("../lib/builtins/logic"), andp = _ref2.andp, orp = _ref2.orp, rule = _ref2.rule, bind = _ref2.bind, is_ = _ref2.is_;

  begin = require("../lib/builtins/lisp").begin;

  _ref3 = require("../lib/builtins/parser"), settext = _ref3.settext, char = _ref3.char, digits = _ref3.digits, spaces = _ref3.spaces, eoi = _ref3.eoi, memo = _ref3.memo;

  exports.flatString = flatString = special(1, 'flatString', function(solver, cont, x) {
    return solver.cont(x, function(v) {
      return cont((typeof v.flatString === "function" ? v.flatString() : void 0) || 'null');
    });
  });

  exports.kleene = kleene = rule(1, function(x) {
    var y;

    x = vari('x');
    y = vari('y');
    return [[cons(x, y)], andp(char(x), print_(x), kleene(y)), [null], print_('end')];
  });

  leftkleene = rule(0, function() {
    var x;

    x = vari('x');
    return [[], andp(leftkleene(), char(x), print_(x)), [], print_('end')];
  });

  exports.leftkleene = leftkleene = memo(leftkleene);

  exports.kleenePredicate = function(pred) {
    var r;

    r = rule(1, function(x) {
      var y;

      x = vari('x');
      y = vari('y');
      return [[cons(x, y)], andp(pred(x), r(y)), [null], print_('end')];
    });
    return r;
  };

  exports.dightsSpaces = macro(1, function(x) {
    return andp(is_(x, digits), orp(spaces, eoi));
  });

}).call(this);

/*
//@ sourceMappingURL=kleene.map
*/
