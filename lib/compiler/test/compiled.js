solve = require('f:/daonode/lib/compiler/core.js').solve;
exports.main = function(v) {
  x = 1;
  blockx = function(v) {
    (console.log)(x);
    ++(x);
    if (!((x) === (5))) return (blockx)(null);
    else return undefined;;
  };
  return (blockx)(null);
}
//exports.main();