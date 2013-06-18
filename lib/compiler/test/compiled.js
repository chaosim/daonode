solve = require('f:/daonode/lib/compiler/core.js').solve;
solveModule = require('f:/daonode/lib/compiler/solve.js');
solver = new solveModule.Solver()
exports.main = function(v) {
  return solver.failcont(false);
}
//exports.main();