(exports).main = function() {
  var state_$4, anyCont_$14, fc_$11, trail_$12, state_$13, v_$16, data_$8, pos_$9, v_$3;
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
    state_$4 = (solver).state;
    (solver).state = ["abc", 0];
    __ = new DummyVar("__");
    anyCont_$14 = function(v_$15) {
      fc_$11 = (solver).failcont;
      trail_$12 = (solver).trail;
      state_$13 = (solver).state;
      (solver).trail = new Trail();
      (solver).failcont = function(v_$15) {
        v_$16 = v_$15;
        (solver).trail.undo();
        (solver).trail = trail_$12;
        (solver).state = state_$13;
        (solver).failcont = fc_$11;
        parser.char(solver, "c");
        data_$8 = ((solver).state)[0];
        pos_$9 = ((solver).state)[1];
        if (pos_$9 >= (data_$8).length) {
          v_$3 = true;
          (solver).state = state_$4;
          throw new(SolverFinish)(v_$3);
        } else return ((solver).failcont)(false);
      };
      return (anyCont_$14)(parser.char(solver, __));
    };
    return (anyCont_$14)(null);
  });
}
//exports.main();