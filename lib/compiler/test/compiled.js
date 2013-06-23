_ = require('underscore');
solve = require('f:/daonode/lib/compiler/core.js').solve;
parser = require('f:/daonode/lib/compiler/parser.js');
solvecore = require('f:/daonode/lib/compiler/solve.js');
Solver = solvecore.Solver;
Trail = solvecore.Trail;
Var = solvecore.Var;

exports.main = function(v) {
  solver = new(Solver)();
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v) {
    return v;
  };
  solver.cutcont = solver.failcont;
  state = solver.state;
  solver.state = ["ab", 0];
  parser.char(solver, "a");
  v = parser.char(solver, "b");
  solver.state = state;
  return v;
}
//exports.main();