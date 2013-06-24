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
    solver.state = ["b", 0];
    anyCont = function(v) {
      solver.failcont = anyFcont;
      v;
      text = (solver.state)[0];
      pos = (solver.state)[1];
      v = (text)[pos];
      solver.state = state;
      v = v;
      throw new(SolverFinish)(v);
    };
    anyFcont = function(v) {
      solver.failcont = fc;
      return (anyCont)(parser.char(solver, "a"));
    };
    fc = solver.failcont;
    return (anyCont)("b");
  });
}
//exports.main();