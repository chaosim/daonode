exports.main = function() {
  var _, __slice, solve, parser, solvecore, Solver, Trail, Var, DummyVar, solver, UArray, UObject, Cons, x, y, z, cont;
  _ = require("underscore");
  __slice = [].slice;
  solve = require("./core").solve;
  parser = require("./parser");
  solvecore = require("./solve");
  Solver = solvecore.Solver;
  Trail = solvecore.Trail;
  Var = solvecore.Var;
  DummyVar = solvecore.DummyVar;
  solver = new Solver();
  UArray = solvecore.UArray;
  UObject = solvecore.UObject;
  Cons = solvecore.Cons;
  solver.parsercursor = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v) {
    return v
  };
  solver.cutcont = solver.failcont;
  return (function() {
    x = function() {
      return true
    };
    y = function() {
      return console.log(1)
    };
    z = function() {
      return console.log(2)
    };
    cont = function(v) {
      return v
    };
    return ((x()) ? cont(y()) : cont(z()))
  })()
}
//exports.main();