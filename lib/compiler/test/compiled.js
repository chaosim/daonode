solve = require('../solve');
exports.solver = new solve.Solver();
exports.main = function(v1) {
  solver = exports.solver;
  return solver.failcont(false);
}
// x = exports.solver.run(exports.main)[0];
//console.log(x)