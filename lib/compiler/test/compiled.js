exports.main = function() {
  var _, __slice, solve, parser, solvecore, SolverFinish, Solver, Trail, Var, DummyVar, solver, UArray;
  _ = require("underscore");
  __slice = [].slice;
  solve = require("f:/daonode/lib/compiler/core.js").solve;
  parser = require("f:/daonode/lib/compiler/parser.js");
  solvecore = require("f:/daonode/lib/compiler/solve.js");
  SolverFinish = solvecore.SolverFinish;
  Solver = solvecore.Solver;
  Trail = solvecore.Trail;
  Var = solvecore.Var;
  DummyVar = solvecore.DummyVar;
  solver = new Solver();
  UArray = solvecore.UArray;
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v) {
    throw new SolverFinish(v)
  };
  solver.cutcont = solver.failcont;
  return solver.run(function() {
    var a, trail, state, fc;
    a = new Var("a");
    trail = solver.trail;
    state = solver.state;
    fc = solver.failcont;
    solver.trail = new Trail();
    solver.failcont = function(v3) {
      solver.trail.undo();
      solver.trail = trail;
      solver.state = state;
      solver.failcont = fc;
      if (solver.trail.unify(a, 2)) throw new SolverFinish(true);
      else return solver.failcont(false)
    };
    if (solver.trail.unify(new UArray([a]), [1]))
      if (solver.trail.unify(a, 2)) throw new SolverFinish(true);
      else return solver.failcont(false);
      else return solver.failcont(false)
  })
}
//exports.main();