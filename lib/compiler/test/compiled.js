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
    fc_$2 = solver.failcont;
    solver.failcont = function(v_$3) {
      solver.failcont = fc_$2;
      throw new(SolverFinish)(v_$3);
    };
    trail_$5 = solver.trail;
    state_$6 = solver.state;
    fc_$7 = solver.failcont;
    solver.trail = new Trail();
    solver.failcont = function(v_$4) {
      v_$4;
      solver.trail.undo();
      solver.trail = trail_$5;
      solver.state = state_$6;
      solver.failcont = fc_$7;
      trail_$9 = solver.trail;
      state_$10 = solver.state;
      fc_$11 = solver.failcont;
      solver.trail = new Trail();
      solver.failcont = function(v_$8) {
        v_$8;
        solver.trail.undo();
        solver.trail = trail_$9;
        solver.state = state_$10;
        solver.failcont = fc_$11;
        return (solver.failcont)((console.log)(3));
      };
      return (solver.failcont)((console.log)(2));
    };
    return (solver.failcont)((console.log)(1));
  });
}
//exports.main();