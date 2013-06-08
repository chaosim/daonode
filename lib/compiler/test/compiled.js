solve = require('f:/daonode/lib/compiler/core.js').solve;
exports.main = function(v) {
  return (function() {
    var args, cont;
    cont = arguments[0], args = 2 <= arguments.length ? [].slice.call(arguments, 1) : [];
    return cont(console.log.apply(this, args));
  })(function(v) {
    return v;
  }, 1, 2);
}
//exports.main();