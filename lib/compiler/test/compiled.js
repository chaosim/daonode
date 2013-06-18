solve = require('f:/daonode/lib/compiler/core.js').solve;
solveModule = require('f:/daonode/lib/compiler/solve.js');
solver = new solveModule.Solver()
exports.main = function(v) {
  (function(v) {
    return 3;
  })((function(k) {
        return k(null);
      })(function(v) {
        return 3;
      }));
  return 3;
}
//exports.main();