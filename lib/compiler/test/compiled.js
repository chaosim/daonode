(exports).main = function() {
  var _, __slice, solve, parser, solvecore, SolverFinish, Solver, Trail, Var, DummyVar, solver, __;
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
  (solver).state = null;
  (solver).catches = {};
  (solver).trail = new Trail();
  (solver).failcont = function(v_$1) {
    throw new(SolverFinish)(v_$1);
  };
  (solver).cutcont = (solver).failcont;
  return solver.run(function(v_$1) {
    var 7, state_$5, t, r, a, i, l, _, $, anyCont_$9, anyFcont_$10, fc_$6;
    __ = new DummyVar("__");
    state_$5 = (solver).state;
    (solver).state = ["a", 0];
    null;
    anyCont_$9 = function(v_$8) {
      var trail_$7, v_$4;
      trail_$7 = (solver).trail;
      (solver).trail = new Trail();
      (solver).failcont = anyFcont_$10;
      v_$4 = null;
      (solver).state = state_$5;
      throw new(SolverFinish)(v_$4);
    };
    anyFcont_$10 = function(v_$8) {
      (solver).trail.undo();
      (solver).trail = trail_$7;
      (solver).failcont = fc_$6;
      return (anyCont_$9)(parser.char(solver, __));
    };
    fc_$6 = (solver).failcont;
    return (anyCont_$9)(null);
  });
}
//exports.main();