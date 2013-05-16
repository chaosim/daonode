// Generated by CoffeeScript 1.6.2
(function() {
  var Trail, solve, special;

  solve = require("../../src/solve");

  special = solve.special;

  Trail = solve.Trail;

  exports.succeed = special('succeed', function(solver, cont) {
    return cont;
  })();

  exports.fail = special('fail', function(solver, cont) {
    return solver.failcont;
  })();

  exports.andp = special('andp', function(solver, cont, x, y) {
    return solver.cont(x, solver.cont(y, cont));
  });

  exports.ifp = special('ifp', function(solver, cont, test, action) {
    return solver.cont(test, solver.cont(action, cont));
  });

  exports.cutable = special('cutable', function(solver, cont, x) {
    return function(v, solver) {
      var cc;

      cc = solver.cutCont;
      return solver.cont(x, function(v, solver) {
        solver.cutCont = cc;
        return [cont, v, solver];
      })(null, solver);
    };
  });

  exports.cut = special('cut', function(solver, cont) {
    return function(v, solver) {
      solver.failcont = solver.cutCont;
      return [cont, v, solver];
    };
  })();

  exports.orp = special('orp', function(solver, cont, x, y) {
    return function(v, solver) {
      var fc, state, trail, xcont, ycont;

      trail = new Trail;
      state = solver.state;
      fc = solver.failcont;
      xcont = solver.cont(x, cont);
      ycont = solver.cont(y, cont);
      solver.failcont = function(v, solver) {
        trail.undo();
        solver.state = state;
        solver.failcont = fc;
        return [ycont, v, solver];
      };
      solver.trail = trail;
      return [xcont, null, solver];
    };
  });

  exports.notp = special('notp', function(solver, cont, x) {
    return function(v, solver) {
      var fc, state, trail;

      trail = solver.trail;
      solver.trail = new Trail;
      fc = solver.failcont;
      state = solver.state;
      solver.failcont = function(v, solver) {
        solver.trail.undo();
        solver.trail = trail;
        solver.state = state;
        solver.failcont = fc;
        return [cont, v, solver];
      };
      return solver.cont(x, function(v, solver) {
        solver.failcont = fc;
        return [fc, v, solver];
      })(v, solver);
    };
  });

  exports.repeat = special('repeat', function(solver, cont) {
    return function(v, solver) {
      solver.failcont = cont;
      return [cont, null, solver];
    };
  })();

  exports.findall = special('findall', function(solver, cont, exp) {
    var findallcont;

    findallcont = solver.cont(exp, function(v, solver) {
      return [solver.failcont, v, solver];
    });
    return function(v, solver) {
      var fc;

      fc = solver.failcont;
      solver.failcont = function(v, solver) {
        solver.failcont = fc;
        return [cont, v, solver];
      };
      return [findallcont, v, solver];
    };
  });

  exports.xfindall = special('findall', function(solver, cont, exp) {
    var findallcont;

    findallcont = solver.cont(exp, solver.failcont);
    return function(v, solver) {
      var fc;

      fc = solver.failcont;
      solver.failcont = function(v, solver) {
        solver.failcont = fc;
        return [cont, v, solver];
      };
      return [findallcont, v, solver];
    };
  });

  exports.once = special('once', function(solver, cont, x) {
    return function(v, solver) {
      var fc;

      fc = solver.failcont;
      return [
        solver.cont(x, function(v, solver) {
          solver.failcont = fc;
          return [cont, v, solver];
        }), null, solver
      ];
    };
  });

  exports.unify = special('unify', function(solver, cont, x, y) {
    return function(v, solver) {
      if (solver.trail.unify(x, y)) {
        return [cont, true, solver];
      } else {
        return [solver.failcont, false, solver];
      }
    };
  });

  exports.is_ = special('is_', function(solver, cont, vari, exp) {
    return solver.cont(exp, function(v, solver) {
      vari.bind(v, solver.trail);
      return [cont, true, solver];
    });
  });

}).call(this);

/*
//@ sourceMappingURL=logic.map
*/
