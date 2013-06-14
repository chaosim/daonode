solve = require('f:/daonode/lib/compiler/core.js').solve;
exports.main = function(v) {
  x = 1;
  blocka = function(v) {
    if ((x) === (5)) return x;
    else {
      ++(x);
      return (blocka)(null);
    };
  };
  return (blocka)(null);
}
//exports.main();