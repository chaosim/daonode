// Generated by CoffeeScript 1.6.2
(function() {
  var Error, add, addassign, assign, begin, core, eq, eval_, funcall, if_, inc, jsfun, jsobject, lamda, macall, macro, print_, qq, quote, solve, string, suffixinc, uq, uqs, vari, variable, xexports, _ref, _ref1;

  _ref = core = require('../lib/core'), solve = _ref.solve, Error = _ref.Error;

  _ref1 = require('../lib/util'), variable = _ref1.variable, string = _ref1.string, begin = _ref1.begin, quote = _ref1.quote, assign = _ref1.assign, addassign = _ref1.addassign, print_ = _ref1.print_, jsobject = _ref1.jsobject, funcall = _ref1.funcall, macall = _ref1.macall, lamda = _ref1.lamda, macro = _ref1.macro, jsfun = _ref1.jsfun, if_ = _ref1.if_, add = _ref1.add, eq = _ref1.eq, inc = _ref1.inc, suffixinc = _ref1.suffixinc, eval_ = _ref1.eval_, qq = _ref1.qq, uq = _ref1.uq, uqs = _ref1.uqs;

  vari = function(name) {
    return name;
  };

  xexports = {};

  exports.Test = {
    "test vari assign": function(test) {
      var x;

      x = 'x';
      test.equal(solve(begin(assign(x, 1))), 1);
      test.equal(solve(begin(assign(x, 1), x)), 1);
      test.equal(solve(begin(variable(x), assign(x, 1), addassign(x, 2), x)), 3);
      test.equal(solve(begin(variable(x), assign(x, 1), inc(x))), 2);
      test.equal(solve(begin(variable(x), assign(x, 1), suffixinc(x))), 1);
      return test.done();
    },
    "test 1": function(test) {
      test.equal(solve(1), 1);
      return test.done();
    },
    "test begin": function(test) {
      test.equal(solve(begin(1, 2)), 2);
      return test.done();
    },
    "test quote": function(test) {
      test.equal(solve(quote(1)), 1);
      return test.done();
    },
    "test js vari": function(test) {
      var console_log;

      console_log = 'console.log';
      test.equal(solve(console_log), console.log);
      return test.done();
    },
    "test jsfun": function(test) {
      var console_log, x;

      console_log = 'console.log';
      test.equal(solve(funcall(jsfun(console_log), 1)), null);
      test.equal(solve(print_(1, 2)), null);
      x = vari('x');
      test.equal(solve(begin(assign(x, 1), print_(x))), null);
      return test.done();
    },
    "test vop: add, eq": function(test) {
      test.equal(solve(add(1, 1)), 2);
      test.equal(solve(eq(1, 1)), true);
      test.equal(solve(begin(eq(1, 1), add(1, 1))), 2);
      return test.done();
    },
    "test eval_ quote": function(test) {
      test.equal(solve(eval_(quote(1), string('f:/daonode/lib/compiler/test/compiled2.js'))), 1);
      test.equal(solve(eval_(quote(print_(1)), string('f:/daonode/lib/compiler/test/compiled2.js'))), null);
      return test.done();
    },
    "test quasiquote": function(test) {
      var a;

      test.equal(solve(qq(1)), 1);
      a = add(1, 2);
      test.deepEqual(solve(qq(a)), a);
      test.deepEqual(solve(qq(uq(a))), 3);
      test.deepEqual(solve(qq(uqs([1, 2]))), [1, 2]);
      test.deepEqual(solve(qq(add(uqs([1, 2])))), a);
      test.throws((function() {
        return solve(qq(add(uqs(uqs([1, 2])))));
      }), Error);
      return test.done();
    },
    "test lambda": function(test) {
      var f, x, y;

      x = 'x';
      y = 'y';
      f = vari('f');
      test.equal(solve(funcall(lamda([x], x), 1)), 1);
      test.equal(solve(funcall(lamda([x, y], add(x, y)), 1, 1)), 2);
      test.equal(solve(begin(assign(f, lamda([], 1)), funcall(f))), 1);
      return test.done();
    },
    "test macro": function(test) {
      var x, y, z;

      x = 'x';
      y = 'y';
      z = 'z';
      test.equal(solve(macall(macro([x], 1), print_(1))), 1);
      test.equal(solve(macall(macro([x], x), print_(1))), null);
      return test.done();
    },
    "test macro2": function(test) {
      var x, y, z;

      x = 'x';
      y = 'y';
      z = 'z';
      test.equal(solve(macall(macro([x, y, z], if_(x, y, z)), eq(1, 1), print_(1), print_(2))), null);
      return test.done();
    }
  };

}).call(this);

/*
//@ sourceMappingURL=testCore.map
*/
