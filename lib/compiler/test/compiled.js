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
    __ = new DummyVar("__");
    new DummyVar("__");
    state = solver.state;
    solver.state = ["abc", 0];
    return (function(fc) {
      solver.failcont = function(v) {
        solver.failcont = fc;
        v = v;
        solver.state = state;
        v = v;
        throw new(SolverFinish)(v);
      };
      v = __;
      parser.char(solver, v);
      a0 = solver.trail.getvalue(__);
      v = (console.log)(a0);
      anyCont = function(v) {
        solver.failcont = anyFcont;
        return (solver.failcont)(v);
      };
      anyFcont = function(v) {
        solver.failcont = fc;
        v = __;
        parser.char(solver, v);
        a0 = solver.trail.getvalue(__);
        return (anyCont)((console.log)(a0));
      };
      fc = solver.failcont;
      return (anyCont)(v);
    })(solver.failcont);
  });
}
//exports.main();