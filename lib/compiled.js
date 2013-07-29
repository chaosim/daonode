exports.main = function() {
  var _, __slice, solve, parser, solvecore, SolverFinish, SolverFail, Solver, Trail, Var, DummyVar, solver, UArray, UObject, Cons;
  _ = require("underscore");
  __slice = [].slice;
  solve = require("./core").solve;
  parser = require("./parser");
  solvecore = require("./solve");
  SolverFinish = solvecore.SolverFinish;
  SolverFail = solvecore.SolverFail;
  Solver = solvecore.Solver;
  Trail = solvecore.Trail;
  Var = solvecore.Var;
  DummyVar = solvecore.DummyVar;
  solver = new Solver();
  UArray = solvecore.UArray;
  UObject = solvecore.UObject;
  Cons = solvecore.Cons;
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v) {
    throw new SolverFinish(v)
  };
  solver.cutcont = solver.failcont;
  return solver.run(function() {
    var __, n, result, state, trail, state2, fc, n2, result2, anyCont;
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
        } else throw new SolverFail(false);
        else throw new SolverFail(false)
    };
    try {
      parser.char(solver, __);
      n2 = 1;
      result2 = [solver.trail.getvalue(__)];
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
          if (solver.trail.unify(n, n2))
            if (solver.trail.unify(result, result2)) {
              parser.char(solver, ",");
              parser.char(solver, "b");
              parser.char(solver, ",");
              v7 = parser.char(solver, "c");
              solver.state = state;
              throw new SolverFinish(solver.trail.getvalue(result))
            } else throw new SolverFail(false);
            else throw new SolverFail(false)
        };
        parser.char(solver, ",");
        parser.char(solver, __);
        list2 = result2;
        value2 = solver.trail.getvalue(__);
        fc4 = solver.failcont;
        solver.failcont = function(v30) {
          list2.pop();
          return fc4(value2)
        };
        result2.push(value2);
        fc3 = solver.failcont;
        solver.failcont = function(v29) {
          --n2;
          return fc3(n2)
        };
        ++n2;
        return anyCont(n2)
      };
      return anyCont(null)
    } catch (e) {
      if (e instanceof SolverFail) return solver.failcont(e.value);
      else throw e
    }
  })
}
//exports.main();