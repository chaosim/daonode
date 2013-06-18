solve = require('f:/daonode/lib/compiler/core.js').solve;
solveModule = require('f:/daonode/lib/compiler/solve.js');
solver = new solveModule.Solver()
exports.main = function(v) {
  blockfoo = function(v) {
    return (function(v3) {
      return (function(v) {
        return (function(f) {
          return (function(a0) {
            return (f)(function(v) {
              return (function(v) {
                return (function(f) {
                  return (function(a0) {
                    return (f)(function(v4) {
                      return (function(v) {
                        return v;
                      })(v3);
                    }, a0);
                  })(3);
                })(function() {
                  var args, cont;
                  cont = arguments[0], args = 2 <= arguments.length ? [].slice.call(arguments, 1) : [];
                  return cont(v.apply(this, args));
                });
              })(console.log);
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
//exports.main();