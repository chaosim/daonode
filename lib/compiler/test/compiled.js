(exports).main = function() {
  var _, __slice, solve, parser, solvecore, SolverFinish, Solver, Trail, Var, DummyVar, solver;
  _ = require("underscore");
  __slice = ([]).slice;
  solve = (require("f:/daonode/lib/compiler/core.js")).solve;
  parser = require("f:/daonode/lib/compiler/parser.js");
  solvecore = require("f:/daonode/lib/compiler/solve.js");
  SolverFinish = (solvecore).SolverFinish;
  Solver = (solvecore).Solver;
  Trail = (solvecore).Trail;
  Var = (solvecore).Var;
  DummyVar = (solvecore).DummyVar;
  solver = new(Solver)();
  (solver).trail = new Trail();
  (solver).cutcont = (solver).failcont;
  return solver.run(function(v2) {
    var fc, trail, state, fc2;
    fc = (solver).failcont;
    trail = (solver).trail;
    state = (solver).state;
    fc2 = (solver).failcont;
    (solver).trail = new Trail();
    return ((solver).failcont)((console.log)(1));
  });
}
//exports.main();