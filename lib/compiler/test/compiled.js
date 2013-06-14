solve = require('f:/daonode/lib/compiler/core.js').solve;
exports.main = function(v) {
  a = 1;
  blockx = function(v) {
    if ((a) === (10)) return a;
    else {
      v = undefined;
      v = ++(a);
      return (blockx)(null);
    };
  };
  return (blockx)(null);
}
//exports.main();