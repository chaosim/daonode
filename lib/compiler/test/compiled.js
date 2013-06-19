solve = require('f:/daonode/lib/compiler/core.js').solve;
solveModule = require('f:/daonode/lib/compiler/solve.js');
solver = new solveModule.Solver()
Trail = solveModule.Trail
exports.main = function(v) {
  trail = solver.trail;
  solver.trail = new Trail();
  fc = solver.failcont;
  state = solver.state;
  solver.failcont = function(v) {
    solver.trail.undo();
    solver.trail = trail;
    solver.state = state;
    solver.failcont = fc;
    return v;
  };
  return (fc)((console.log)(1));
}
//exports.main();