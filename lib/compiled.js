exports.main = function() {
  var _, __slice, solve, parser, solvecore, Solver, Trail, Var, DummyVar, solver, UArray, UObject, Cons, __, n, result, state, trail, state2, fc;
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
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v) {
    return v
  };
  solver.cutcont = solver.failcont;
  return (function() {
    __ = new DummyVar("__");
    n = new Var("n");
    result = new Var("result");
    state = solver.state;
    solver.state = ["a,b,c", 0];
    trail = solver.trail;
    state2 = solver.state;
    fc = solver.failcont;
    solver.trail = new Trail();
    solver.failcont = function(v12) {
      solver.trail.undo();
      solver.trail = trail;
      solver.state = state2;
      solver.failcont = fc;
      return (solver.trail.unify(n, 0)) ? (solver.trail.unify(result, [])) ? parser.char(solver, ",", function(v9) {
        return parser.char(solver, "b", function(v10) {
          return parser.char(solver, ",", function(v11) {
            return parser.char(solver, "c", function(v6) {
              var v7;
              v7 = v6;
              solver.state = state;
              return solver.trail.getvalue(result)
            })
          })
        })
      }) : solver.failcont(false) : solver.failcont(false)
    };
    return parser.char(solver, __, function(v15) {
      var anyCont;
      n2 = 1;
      result2 = [solver.trail.getvalue(__)];
      anyCont = function(v20) {
        var fc2, trail2, state3;
        fc2 = solver.failcont;
        trail2 = solver.trail;
        state3 = solver.state;
        solver.trail = new Trail();
        solver.failcont = function(v20) {
          var v21;
          v21 = v20;
          solver.trail.undo();
          solver.trail = trail2;
          solver.state = state3;
          solver.failcont = fc2;
          return (solver.trail.unify(n, n2)) ? (solver.trail.unify(result, result2)) ? parser.char(solver, ",", function(v9) {
            return parser.char(solver, "b", function(v10) {
              return parser.char(solver, ",", function(v11) {
                return parser.char(solver, "c", function(v6) {
                  var v7;
                  v7 = v6;
                  solver.state = state;
                  return solver.trail.getvalue(result)
                })
              })
            })
          }) : solver.failcont(false) : solver.failcont(false)
        };
        return parser.char(solver, ",", function(v22) {
          return parser.char(solver, __, function(v23) {
            var list2, value2, fc4, fc3;
            list2 = result2;
            value2 = solver.trail.getvalue(__);
            fc4 = solver.failcont;
            solver.failcont = function(v26) {
              list2.pop();
              return fc4(value2)
            };
            result2.push(value2);
            fc3 = solver.failcont;
            solver.failcont = function(v25) {
              --n2;
              return fc3(n2)
            };
            ++n2;
            return anyCont(n2)
          })
        })
      };
      return anyCont(null)
    })
  })()
}
//exports.main();