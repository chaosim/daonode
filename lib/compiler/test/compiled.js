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
(exports).main = function() {
  solver = new(Solver)();
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v_$1) {
    throw new(SolverFinish)(v_$1);
  };
  solver.cutcont = solver.failcont;
  return solver.run(function(v_$1) {
    __ = new DummyVar("__");
    __;
    state_$5 = solver.state;
    solver.state = ["abc", 0];
    fc_$6 = solver.failcont;
    solver.failcont = function(v_$7) {
      v_$8 = v_$7;
      solver.failcont = fc_$6;
      v_$4 = v_$8;
      solver.state = state_$5;
      throw new(SolverFinish)(v_$4);
    };
    parser.char(solver, __);
    (console.log)(solver.trail.getvalue(__));
    anyCont_$13 = function(v_$12) {
      trail_$11 = solver.trail;
      solver.trail = new Trail();
      solver.failcont = anyFcont_$14;
      return (solver.failcont)(null);
    };
    anyFcont_$14 = function(v_$12) {
      solver.trail.undo();
      solver.trail = trail_$11;
      solver.failcont = fc_$10;
      parser.char(solver, __);
      return (anyCont_$13)((console.log)(solver.trail.getvalue(__)));
    };
    fc_$10 = solver.failcont;
    return (anyCont_$13)(null);
  });
}
//exports.main();