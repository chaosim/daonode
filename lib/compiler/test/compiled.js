exports.main = function() {
  var _, __slice, solve, parser, solvecore, SolverFinish, Solver, Trail, Var, DummyVar, solver;
  _ = require("underscore");
  __slice = [].slice;
  solve = (require("f:/daonode/lib/compiler/core.js")).solve;
  parser = require("f:/daonode/lib/compiler/parser.js");
  solvecore = require("f:/daonode/lib/compiler/solve.js");
  SolverFinish = solvecore.SolverFinish;
  Solver = solvecore.Solver;
  Trail = solvecore.Trail;
  Var = solvecore.Var;
  DummyVar = solvecore.DummyVar;
  solver = new Solver();
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v) {
    throw new SolverFinish(v);
  };
  solver.cutcont = solver.failcont;
  return solver.run(function(v2) {
    __ = new DummyVar("__");
    state = solver.state;
    solver.state = ["abc", 0];
    fc = solver.failcont;
    solver.failcont = function(v6) {
      v7 = v6;
      solver.failcont = fc;
      v5 = v7;
      solver.state = state;
      throw new SolverFinish(v5);
    };
    anyCont = function(v8) {
      trail = solver.trail;
      solver.trail = new Trail();
      solver.failcont = anyFcont;
      return (solver.failcont)(null);
    };
    anyFcont = function(v8) {
      (solver.trail).undo();
      solver.trail = trail;
      solver.failcont = fc2;
      parser.char(solver, __);
      return anyCont((console.log)(solver.trail.getvalue(__)));
    };
    fc2 = solver.failcont;
    trail = solver.trail;
    solver.trail = new Trail();
    solver.failcont = function(v8) {
      (solver.trail).undo();
      solver.trail = trail;
      solver.failcont = fc2;
      parser.char(solver, __);
      return anyCont((console.log)(solver.trail.getvalue(__)));
    };
    return (solver.failcont)(null);
  });
}
//exports.main();