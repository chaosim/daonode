exports.main = function() {
  var _, __slice, solve, parser, solvecore, SolverFinish, Solver, Trail, Var, DummyVar, solver, UArray, UObject, Cons;
  _ = require("underscore");
  __slice = [].slice;
  solve = require("./core").solve;
  parser = require("./parser");
  solvecore = require("./solve");
  SolverFinish = solvecore.SolverFinish;
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
    var state, daoutil, operator, atomic, binaryExpr, v3;
    state = solver.state;
    solver.state = ["3", 0];
    daoutil = require("./daoutil");
    operator = daoutil.operator;
    atomic = function() {
      var trail2, state3, fc2;
      trail2 = solver.trail;
      state3 = solver.state;
      fc2 = solver.failcont;
      solver.trail = new Trail();
      solver.failcont = function(v16) {
        var trail3, state4, fc3;
        solver.trail.undo();
        solver.trail = trail2;
        solver.state = state3;
        solver.failcont = fc2;
        trail3 = solver.trail;
        state4 = solver.state;
        fc3 = solver.failcont;
        solver.trail = new Trail();
        solver.failcont = function(v17) {
          solver.trail.undo();
          solver.trail = trail3;
          solver.state = state4;
          solver.failcont = fc3;
          return parser.number(solver)
        };
        return parser.quoteString(solver)
      };
      return parser.identifier(solver)
    };
    binaryExpr = function() {
      var x, trail, state2, fc, op, y;
      x = atomic();
      trail = solver.trail;
      state2 = solver.state;
      fc = solver.failcont;
      solver.trail = new Trail();
      solver.failcont = function(v9) {
        solver.trail.undo();
        solver.trail = trail;
        solver.state = state2;
        solver.failcont = fc;
        return x
      };
      op = operator(solver);
      y = atomic();
      return [op, x, y]
    };
    v3 = binaryExpr();
    solver.state = state;
    throw new SolverFinish(v3)
  })
}
exports.main();