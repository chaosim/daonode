solve = require('f:/daonode/lib/compiler/core.js').solve;
exports.main = function(v) {
  blocka = function(v) {
    return (function(f) {
      return (function(a0) {
        return (function(v) {
          return (function(v) {
            return v;
          })(1);
        })((f)(a0));
      })(1);
    })(function(x) {
      return (function(v) {
        return v;
      })(2);
    });
  };
  return (blocka)(null);
}
//exports.main();