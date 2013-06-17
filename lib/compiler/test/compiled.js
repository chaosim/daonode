solve = require('f:/daonode/lib/compiler/core.js').solve;
solveModule = require('f:/daonode/lib/compiler/solve.js');
solver = new solveModule.Solver()
exports.main = function(v) {
  blockfoo = function(v) {
    return (function(v) {
      return (function(v) {
        return (function(f) {
          return (function(a0) {
              console.log("f a0")
            return (f)(function(v2) {
                console.log("f v2")
              return (function(v) {
                  console.log("inner", v)
                return v;
              })(v);
            }, a0);
          })(2);
        })(function() {
          var args, cont;
          cont = arguments[0], args = 2 <= arguments.length ? [].slice.call(arguments, 1) : [];
          return cont(v.apply(this, args));
        });
      })(console.log);
    })(1);
  };
  return (blockfoo)(null);
}
console.log(exports.main().toString())