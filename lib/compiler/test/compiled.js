_ = require('underscore');
__slice = [].slice
solve = require('../core.js').solve;
parser = require('../parser.js');
solvecore = require('../solve.js');
SolverFinish = solvecore.SolverFinish;
Solver = solvecore.Solver;
Trail = solvecore.Trail;
Var = solvecore.Var;
DummyVar = solvecore.DummyVar;

exports.main = function() {
  var a;
  return function(n) {
    (n) ? (a = 2) : (a = 3);
    return 4
  }
}
//exports.main();