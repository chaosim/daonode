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
    x = new Var("x");
    new Var("x");
    result = new Var("result");
    new Var("result");
    return (function(fc) {
      solver.failcont = function(v) {
        if (solver.trail.unify("result", [])) return (fc)(v);
        else {
          solver.failcont = fc;
          v;
          v = [];
          throw new(SolverFinish)(v);
        }
      };
      ([]).push(solver.trail.getvalue("x"));
      return (solver.failcont)(undefined);
    })(solver.failcont);
  });
}
//exports.main();