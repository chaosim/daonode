solve = require('f:/daonode/lib/compiler/core.js').solve;
exports.main = function(v) {
  x = 1;
  blockx = function(v) {
    (console.log)(x);
    ++(x);
    return (!((x) === (5))) ? ((blockx)(null)) : (undefined);
  };
  return (blockx)(null);
}
//exports.main();