exports.main = function() {
  var _, __slice, solve, parser, solvecore, SolverFinish, Solver, Trail, Var, DummyVar, solver, UArray;
  _ = require("underscore");
  __slice = [].slice;
  solve = require("../core.js").solve;
  parser = require("../parser.js");
  solvecore = require("../solve.js");
  SolverFinish = solvecore.SolverFinish;
  Solver = solvecore.Solver;
  Trail = solvecore.Trail;
  Var = solvecore.Var;
  DummyVar = solvecore.DummyVar;
  solver = new Solver();
  UArray = solvecore.UArray;
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v) {
    throw new SolverFinish(v)
  };
  solver.cutcont = solver.failcont;
  return solver.run(function() {
    var result, result2, fc, fc2, trail, state, fc3, v8, v5;
    result = new Var("result");
    result2 = [];
    fc = solver.failcont;
    solver.failcont = function(v6) {
      var v5;
      v5 = v6;
      if (solver.trail.unify(result, result2)) {
        solver.failcont = fc;
        throw new SolverFinish(solver.trail.getvalue(result))
      } else return fc(v6)
    };
    fc2 = solver.failcont;
    trail = solver.trail;
    state = solver.state;
    fc3 = solver.failcont;
    solver.trail = new Trail();
    solver.failcont = function(v9) {
      var v8, v5;
      solver.trail.undo();
      solver.trail = trail;
      solver.state = state;
      solver.failcont = fc3;
      v8 = console.log(2);
      solver.failcont = fc2;
      v5 = v8;
      result2.push(solver.trail.getvalue(1));
      return solver.failcont(v8)
    };
    v8 = console.log(1);
    solver.failcont = fc2;
    v5 = v8;
    result2.push(solver.trail.getvalue(1));
    return solver.failcont(v8)
  })
}
//exports.main();