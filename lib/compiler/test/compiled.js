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
    return (function(v) {
      x = v;
      return (function(v) {
        blocka = function(v) {
          return (function(a0) {
            return (function(a1) {
              return (function(v) {
                return (v) ? ((function(v) {
                      throw new(SolverFinish)(v);
                    })(x)) : ((function(v) {
                      return (function(v) {
                        return (blocka)(null);
                      })(++x);
                    })(undefined));
              })(a0 === a1);
            })(5);
          })(x);
        };
        return (blocka)(null);
      })(v);
    })(1);
  });
}
//exports.main();