solve = require('f:/daonode/lib/compiler/core.js').solve;
solveModule = require('f:/daonode/lib/compiler/solve.js');
solver = new solveModule.Solver()
Trail = solveModule.Trail
Var = solveModule.Var
exports.main = function(v) {
  a = new Var("a");
  trail = solver.trail;
  solver.trail = new Trail();
  state = solver.state;
  fc = solver.failcont;
  solver.failcont = function(v) {
    solver.trail.undo();
    solver.trail = trail;
    solver.state = state;
    solver.failcont = fc;
    return (solver.trail.unify(a, 2)) ? (true) : ((solver.failcont)(false));
  };
  return (solver.trail.unify(a, 1)) ? ((solver.trail.unify(a, 2)) ? (true) : ((solver.failcont)(false))) : ((solver.failcont)(false));
}
//exports.main();