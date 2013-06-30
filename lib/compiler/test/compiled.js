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
    v_$1 = 1;
    throw new(SolverFinish)(v_$1);
  });
}
//exports.main();