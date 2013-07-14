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
  f = function(x) {
    f = 0;
    while (1) {
      if (x === 0) {
        return f
      } else {
        --x
      }
    }
  };
  return f(3)
}
//exports.main();