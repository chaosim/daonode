exports.main = function() {
  var _, __slice, solve, parser, solvecore, SolverFinish, Solver, Trail, Var, DummyVar, solver, x;
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
    var blocka;
    x = 1;
    blocka = function(v4) {
      if (x === 10000) throw new SolverFinish(x);
      else {
        ++x;
        return blocka(null);
      }
    };
    return blocka(null);
  });
}
//exports.main();