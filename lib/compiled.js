exports.main = function() {
  var _, __slice, solve, parser, solvecore, Solver, Trail, Var, DummyVar, solver, UArray, UObject, Cons, __, n, result, fc;
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
    __ = new DummyVar("__");
    n = new Var("n");
    result = new Var("result");
    solver.parserdata = "a,b,c";
    solver.parsercursor = 0;
    fc = solver.failcont;
    solver.failcont = function(v11) {
      solver.failcont = fc;
      return ((solver.trail.unify(n, 0)) ? ((solver.trail.unify(result, [])) ? parser.char(solver, ",", function(v8) {
              return parser.char(solver, "b", function(v9) {
                return parser.char(solver, ",", function(v10) {
                  return parser.char(solver, "c", function(v6) {
                    return solver.trail.getvalue(result)
                  })
                })
              })
            }) : solver.failcont(false)) : solver.failcont(false))
    };
    return parser.char(solver, __, function(v14) {
      var anyCont;
      n2 = 1;
      result2 = [solver.trail.getvalue(__)];
      anyCont = function(v19) {
        var fc2, trail, parsercursor;
        fc2 = solver.failcont;
        trail = solver.trail;
        parsercursor = solver.parsercursor;
        solver.trail = new Trail();
        solver.failcont = function(v19) {
          var v20;
          solver.trail.undo();
          solver.trail = trail;
          solver.parsercursor = parsercursor;
          solver.failcont = fc2;
          return ((solver.trail.unify(n, n2)) ? ((solver.trail.unify(result, result2)) ? parser.char(solver, ",", function(v8) {
                  return parser.char(solver, "b", function(v9) {
                    return parser.char(solver, ",", function(v10) {
                      return parser.char(solver, "c", function(v6) {
                        return solver.trail.getvalue(result)
                      })
                    })
                  })
                }) : solver.failcont(false)) : solver.failcont(false))
        };
        return parser.char(solver, ",", function(v21) {
          return parser.char(solver, __, function(v22) {
            var list2, value2, fc4, fc3;
            value2 = solver.trail.getvalue(__);
            fc4 = solver.failcont;
            solver.failcont = function(v25) {
              result2.pop();
              return fc4(value2)
            };
            result2.push(value2);
            fc3 = solver.failcont;
            solver.failcont = function(v24) {
              --n2;
              return fc3(n2)
            };
            return anyCont(++n2)
          })
        })
      };
      return anyCont(null)
    })
  })()
}
//exports.main();