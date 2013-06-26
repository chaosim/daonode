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
    state = solver.state;
    solver.state = ["a,b,c", 0];
    trail = solver.trail;
    solver.trail = new Trail();
    state = solver.state;
    fc = solver.failcont;
    solver.failcont = function(v) {
      solver.trail.undo();
      solver.trail = trail;
      solver.state = state;
      solver.failcont = fc;
      x = n;
      if (solver.trail.unify(x, 0)) {
        x = result;
        if (solver.trail.unify(x, [])) {
          parser.char(solver, ",");
          parser.char(solver, "b");
          parser.char(solver, ",");
          v = parser.char(solver, "c");
          solver.state = state;
          v;
          v = solver.trail.getvalue(result);
          throw new(SolverFinish)(v);
        } else return (solver.failcont)(false);
      } else return (solver.failcont)(false);
    };
    v = __;
    parser.char(solver, v);
    n_$$58 = 1;
    1;
    a0 = solver.trail.getvalue(__);
    v = [a0];
    result_$$57 = v;
    v;
    anyCont = function(v) {
      return (function(fc, trail, state) {
        solver.trail = new Trail();
        solver.failcont = function(v) {
          solver.trail.undo();
          solver.trail = trail;
          solver.state = state;
          solver.failcont = fc;
          v;
          x = n;
          y = n_$$58;
          if (solver.trail.unify(x, y)) {
            x = result;
            y = result_$$57;
            if (solver.trail.unify(x, y)) {
              parser.char(solver, ",");
              parser.char(solver, "b");
              parser.char(solver, ",");
              v = parser.char(solver, "c");
              solver.state = state;
              v;
              v = solver.trail.getvalue(result);
              throw new(SolverFinish)(v);
            } else return (solver.failcont)(false);
          } else return (solver.failcont)(false);
        };
        parser.char(solver, ",");
        v = __;
        parser.char(solver, v);
        list = result_$$57;
        value = solver.trail.getvalue(__);
        return (function(fc) {
          solver.failcont = function(v) {
            (list).pop();
            return (fc)(v);
          };
          (list).push(value);
          value;
          return (function(fc) {
            solver.failcont = function(v) {
              --n_$$58;
              return (fc)(v);
            };
            return (anyCont)(++n_$$58);
          })(solver.failcont);
        })(solver.failcont);
      })(solver.failcont, solver.trail, solver.state);
    };
    return (anyCont)(null);
  });
}
//exports.main();