exports.main = function() {
  var _, __slice, solve, parser, solvecore, SolverFinish, Solver, Trail, Var, DummyVar, solver;
  _ = require("underscore");
  __slice = [].slice;
  solve = require("f:/daonode/lib/compiler/core.js").solve;
  parser = require("f:/daonode/lib/compiler/parser.js");
  solvecore = require("f:/daonode/lib/compiler/solve.js");
  SolverFinish = solvecore.SolverFinish;
  Solver = solvecore.Solver;
  Trail = solvecore.Trail;
  Var = solvecore.Var;
  DummyVar = solvecore.DummyVar;
  solver = new Solver();
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v) {
    throw new SolverFinish(v)
  };
  solver.cutcont = solver.failcont;
  return solver.run(function() {
    var __, n, result, state, trail, state2, fc, n_$058, result_$057, anyCont;
    __ = new DummyVar("__");
    n = new Var("n");
    result = new Var("result");
    state = solver.state;
    solver.state = ["a,b,c", 0];
    trail = solver.trail;
    state2 = solver.state;
    fc = solver.failcont;
    solver.trail = new Trail();
    solver.failcont = function(v16) {
      var v7;
      solver.trail.undo();
      solver.trail = trail;
      solver.state = state2;
      solver.failcont = fc;
      if (solver.trail.unify(n, 0))
        if (solver.trail.unify(result, [])) {
          parser.char(solver, ",");
          parser.char(solver, "b");
          parser.char(solver, ",");
          v7 = parser.char(solver, "c");
          solver.state = state;
          throw new SolverFinish(solver.trail.getvalue(result))
        } else return solver.failcont(false);
        else return solver.failcont(false)
    };
    parser.char(solver, __);
    n_$058 = 1;
    result_$057 = [solver.trail.getvalue(__)];
    anyCont = function(v24) {
      var fc2, trail2, state3, list2, value2, fc4, fc3;
      fc2 = solver.failcont;
      trail2 = solver.trail;
      state3 = solver.state;
      solver.trail = new Trail();
      solver.failcont = function(v24) {
        var v25, v7;
        v25 = v24;
        solver.trail.undo();
        solver.trail = trail2;
        solver.state = state3;
        solver.failcont = fc2;
        if (solver.trail.unify(n, n_$058))
          if (solver.trail.unify(result, result_$057)) {
            parser.char(solver, ",");
            parser.char(solver, "b");
            parser.char(solver, ",");
            v7 = parser.char(solver, "c");
            solver.state = state;
            throw new SolverFinish(solver.trail.getvalue(result))
          } else return solver.failcont(false);
          else return solver.failcont(false)
      };
      parser.char(solver, ",");
      parser.char(solver, __);
      list2 = result_$057;
      value2 = solver.trail.getvalue(__);
      fc4 = solver.failcont;
      solver.failcont = function(v30) {
        list2.pop();
        return fc4(value2)
      };
      result_$057.push(value2);
      fc3 = solver.failcont;
      solver.failcont = function(v29) {
        --n_$058;
        return fc3(n_$058)
      };
      ++n_$058;
      return anyCont(n_$058)
    };
    return anyCont(null)
  })
}
//exports.main();