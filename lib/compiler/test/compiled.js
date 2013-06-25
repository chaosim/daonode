_ = require('underscore');
__slice = [].slice
solve = require('f:/daonode/lib/compiler/core.js').solve;
parser = require('f:/daonode/lib/compiler/parser.js');
solvecore = require('f:/daonode/lib/compiler/solve.js');
SolverFinish = solvecore.SolverFinish;
Solver = solvecore.Solver;
Trail = solvecore.Trail;
Var = solvecore.Var;
DummyVar = solvecore.DummyVar;

exports.main = function(v) {
  solver = new(Solver)();
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v) {
    throw new(SolverFinish)(v);
  };
  solver.cutcont = solver.failcont;
  return solver.run(function(v) {
    __ = new DummyVar("__");
    new DummyVar("__");
    n = new Var("n");
    new Var("n");
    result = new Var("result");
    new Var("result");
    solver.state = ["a", 0];
    "a";
    n_$$24 = 0;
    0;
    result_$$25 = [];
    v = [];
    anyCont = function(v) {
      trail = solver.trail;
      solver.trail = new Trail();
      solver.failcont = anyFcont;
      v;
      x = n;
      y = n_$$24;
      if (solver.trail.unify(x, y)) {
        x = result;
        y = result_$$25;
        if (solver.trail.unify(x, y)) {
          parser.char(solver, "a");
          data = (solver.state)[0];
          pos = (solver.state)[1];
          if (pos >= (data).length) {
            v = solver.trail.getvalue(result);
            throw new(SolverFinish)(v);
          } else return (solver.failcont)(false);
        } else return (solver.failcont)(false);
      } else return (solver.failcont)(false);
    };
    anyFcont = function(v) {
      solver.trail.undo();
      solver.trail = trail;
      solver.failcont = fc;
      v = __;
      parser.char(solver, v);
      ++n_$$24;
      a0 = result_$$25;
      a1 = solver.trail.getvalue(__);
      return (anyCont)((a0).push(a1));
    };
    fc = solver.failcont;
    return (anyCont)(v);
  });
}
//exports.main();