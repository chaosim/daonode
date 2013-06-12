solve = require('f:/daonode/lib/compiler/core.js').solve;
exports.main = function(v) {
  return (function(cont, x) {
    return (cont)(1);
  })(function(v) {
    return v;
  }, 1);
}
//exports.main();