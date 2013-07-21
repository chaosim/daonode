_ = require('underscore');
__slice = [].slice
solve = require('f:/daonode/lib/compiler/core.js').solve;
parser = require('f:/daonode/lib/compiler/parser.js');
solvecore = require('f:/daonode/lib/compiler/solve.js');
SolverFinish = solvecore.SolverFinish;
Solver = solvecore.Solver;
Trail = solvecore.Trail;
Var = solvecore.Var;
DummyVar = solvecore.DummyVar;

exports.main = function() {
  var f;
  f = function(n, a, b) {
    var a2;
    while (1) {
      if (n === 0) {
        return a
      } else {
        --n;
        a2 = b;
        b = a + b
      };
      a = a2
    }
  };
  return f(3, 0, 1)
}
//exports.main();