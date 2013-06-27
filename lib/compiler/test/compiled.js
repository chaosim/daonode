_ = require('underscore');
__slice = [].slice
solve = require('f:/daonode/lib/compiler/core.js').solve;
parser = require('f:/daonode/lib/compiler/parser.js');
solvecore = require('f:/daonode/lib/compiler/solve.js');
SolverFinish = solvecore.SolverFinish;
Solver = solvecore.Solver;
Trail = solvecore.Trail;
Var = solvecore.Var;
DummyVar = solvecore.DummyVar;

exports.main = function(v) {
  solver = new(Solver)();
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v) {
    throw new(SolverFinish)(v);
  };
  solver.cutcont = solver.failcont;
  return solver.run(function(v) {
    blocka = function(v) {
      blockb = function(v) {
        return (function(v) {
          f = v;
          return (function(v) {
            return (function(f) {
              return (function(a0) {
                return (f)(function(v) {
                  return (function(v) {
                    return (function(v) {
                      throw new(SolverFinish)(v);
                    })(3);
                  })(1);
                }, a0);
              })(1);
            })(f);
          })(v);
        })(function(cont, x) {
          return (function(v) {
            return (function(v) {
              throw new(SolverFinish)(v);
            })(3);
          })(2);
        });
      };
      return (blockb)(null);
    };
    return (blocka)(null);
  });
}
//exports.main();