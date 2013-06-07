solve = require('f:/daonode/lib/compiler/core.js').solve;
exports.main = function(v) {
  return (function(v) {
      x = v;
      return (function(v) {
          blockx = function(v) {
            return (function(v) {
                return (function(f) {
                    return (function(a0) {
                        return (f)(function(v) {
                            return (function(v) {
                                return (function(a0) {
                                    return (function(a1) {
                                        return (function(a0) {
                                            return (function(v) {
                                                if (v) return (blockx)(null);
                                                else return (function(v) {
                                                      return v;
                                                    })(undefined);;
                                              })(!(a0));
                                          })((a0) === (a1));
                                      })(5);
                                  })(x);
                              })(++(x));
                          }, a0);
                      })(x);
                  })(function() {
                    var args, cont;
                    cont = arguments[0], args = 2 <= arguments.length ? [].slice.call(arguments, 1) : [];
                    return cont(v.apply(this, args));
                  });
              })(console.log);
          };
          return (blockx)(null);
        })(v);
    })(1);
}
//exports.main();