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
    x = 1;
    x;
    blocka_$3 = function(v_$4) {
      if (x === 5) throw new(SolverFinish)(x);
      else undefined;
      ++x;
      return (blocka_$3)(null);
    };
    return (blocka_$3)(null);
  });
}
//exports.main();