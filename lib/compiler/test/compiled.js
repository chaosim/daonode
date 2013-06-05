exports.main = function(v) {
  return (function(x) {
      return (function(y) {
          return (function(v) {
              return v;
            })((x) + (y));
        })(1);
    })(1);
}