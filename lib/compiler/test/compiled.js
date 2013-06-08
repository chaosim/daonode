solve = require('f:/daonode/lib/compiler/core.js').solve;
exports.main = function(v) {
  return solve(["funcall", ["jsfun", "console.log"], 1], "f:/daonode/lib/compiler/test/compiled2.js");
}
//exports.main();