solve = require('f:/daonode/lib/compiler/core.js').solve;
solveModule = require('f:/daonode/lib/compiler/solve.js');
solver = new solveModule.Solver()
Trail = solveModule.Trail
exports.main = function(v) {
  oldTrail = solver.trail;
  trail = new Trail();
  solver.trail = trail;
  state = solver.state;
  fc = solver.failcont;
  solver.failcont = function(v) {
    trail.undo();
    solver.trail = oldTrail;
    solver.state = state;
    solver.failcont = fc;
    return (function(v) {
      return v;
    })((console.log)(2));
  };
  return (function(v) {
    return v;
  })((console.log)(1));
}
//exports.main();