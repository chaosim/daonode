exports.main = function(v) {
  return (function(f) {
      return (function(a0) {
          return (function(a1) {
              return (function(a2) {
                  return (f)(function(v) {
                      return v;
                    }, a0, a1, a2);
                })(function() {
                  return (function(v) {
                      return (function(f) {
                          return (function(a0) {
                              return (f)(function(v) {
                                  return v;
                                }, a0);
                            })(2);
                        })(function() {
                          var args, cont;
                          cont = arguments[0], args = 2 <= arguments.length ? [].slice.call(arguments, 1) : [];
                          return cont(v.apply(this, args));
                        });
                    })(console.log);
                });
            })(function() {
              return (function(v) {
                  return (function(f) {
                      return (function(a0) {
                          return (f)(function(v) {
                              return v;
                            }, a0);
                        })(1);
                    })(function() {
                      var args, cont;
                      cont = arguments[0], args = 2 <= arguments.length ? [].slice.call(arguments, 1) : [];
                      return cont(v.apply(this, args));
                    });
                })(console.log);
            });
        })(function() {
          return (function(a0) {
              return (function(a1) {
                  return (function(v) {
                      return v;
                    })((a0) === (a1));
                })(1);
            })(1);
        });
    })(function(cont, x, y, z) {
      return (function(v) {
          if (v) return (cont)((y)(cont));
          else return (cont)((z)(cont));;
        })((x)(function(v) {
            if (v) return (cont)((y)(cont));
            else return (cont)((z)(cont));;
          }));
    });
}