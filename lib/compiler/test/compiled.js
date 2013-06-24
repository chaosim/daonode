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
      __ = new DummyVar("__");
      new DummyVar("__");
      anyCont = function(v) {
        v = __;
        return (anyCont)(parser.char(solver, v));
      };
      fc = solver.failcont;
      solver.failcont = function(v) {
        solver.failcont = fc;
        v;
        parser.char(solver, "c");
        data = (solver.state)[0];
        pos = (solver.state)[1];
        return (pos >= (data).length) ? ((solver.failcont)(true)) : ((solver.failcont)(false));
      };
      return (anyCont)(null);
    })(solver.failcont);
  });
}
//exports.main();