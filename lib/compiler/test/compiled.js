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
    var state_$5, fc_$6, trail_$10, anyCont_$12, anyFcont_$13, fc_$9;
    __ = new DummyVar("__");
    state_$5 = (solver).state;
    (solver).state = ["abc", 0];
    fc_$6 = (solver).failcont;
    (solver).failcont = function(v_$7) {
      var v_$8, v_$4;
      v_$8 = v_$7;
      (solver).failcont = fc_$6;
      v_$4 = v_$8;
      (solver).state = state_$5;
      throw new(SolverFinish)(v_$4);
    };
    anyCont_$12 = function(v_$11) {
      trail_$10 = (solver).trail;
      (solver).trail = new Trail();
      (solver).failcont = anyFcont_$13;
      return ((solver).failcont)(null);
    };
    anyFcont_$13 = function(v_$11) {
      (solver).trail.undo();
      (solver).trail = trail_$10;
      (solver).failcont = fc_$9;
      parser.char(solver, __);
      return (anyCont_$12)((console.log)(solver.trail.getvalue(__)));
    };
    fc_$9 = (solver).failcont;
    return (anyCont_$12)(null);
  });
}
//exports.main();