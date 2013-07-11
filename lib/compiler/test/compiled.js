exports.main = function() {
  var _, __slice, solve, parser, solvecore, SolverFinish, Solver, Trail, Var, DummyVar, solver, x, y, z;
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
    return (function() {
      x = function() {
        return 1 === 1;
      };
      y = function() {
        return (console.log)(1);
      };
      z = function() {
        return (console.log)(2);
      };
      return (console.log)(1);
    })();
  });
}
//exports.main();