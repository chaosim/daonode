exports.main = function() {
  var _, __slice, solve, parser, solvecore, Solver, Trail, Var, DummyVar, solver, UArray, UObject, Cons, daoutil, readToken, StateMachine, tokenInfoList, binaryOperator, unaryOperator, assignOperator, suffixOperator, $program, $statement, $expression, $assignExpr, $leftValueExpr, $attrExpr, $indexExpr, $binaryExpr, $unaryExpr, $parenExpr, $atomExpr;
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
    solver.parserdata = "(1+1)+1";
    solver.parsercursor = 0;
    daoutil = require("./daoutil");
    readToken = daoutil.readToken;
    StateMachine = daoutil.StateMachine;
    tokenInfoList = daoutil.tokenInfoList;
    binaryOperator = daoutil.binaryOperator;
    unaryOperator = daoutil.unaryOperator;
    assignOperator = daoutil.assignOperator;
    suffixOperator = daoutil.suffixOperator;
    solver.tokenStateMachine = new StateMachine(tokenInfoList);
    $program = function(cont12) {
      var fc23, body, data2, pos2;
      fc23 = solver.failcont;
      solver.failcont = function(v87) {
        var fc24;
        solver.failcont = fc23;
        fc24 = solver.failcont;
        solver.failcont = function(v88) {
          var data, pos;
          solver.failcont = fc24;
          data = solver.parserdata;
          pos = solver.parsercursor;
          return ((pos >= data.length) ? cont12(true) : solver.failcont(false))
        };
        return $programBody(function(v89) {
          return cont12(body = v89)
        })
      };
      data2 = solver.parserdata;
      pos2 = solver.parsercursor;
      return ((pos2 >= data2.length) ? cont12(null) : solver.failcont(false))
    };
    $statement = function(cont10) {
      var token;
      return readToken(function(v85) {
        var cont11;
        switch (v85) {
          case 66:
            return $expression(function(v84) {
              exp = v84;
              cont11([19, exp])
            });
          case 67:
            return $matchToEOL(cont11);
          case 0:
            return $blockcomment(cont11);
          default:
            $expression(cont10)
        }
      })
    };
    $expression = function(cont9) {
      var fc14;
      fc14 = solver.failcont;
      solver.failcont = function(v71) {
        var fc15;
        solver.failcont = fc14;
        fc15 = solver.failcont;
        solver.failcont = function(v72) {
          var fc16;
          solver.failcont = fc15;
          fc16 = solver.failcont;
          solver.failcont = function(v73) {
            var fc17;
            solver.failcont = fc16;
            fc17 = solver.failcont;
            solver.failcont = function(v74) {
              var fc18;
              solver.failcont = fc17;
              fc18 = solver.failcont;
              solver.failcont = function(v75) {
                var fc19;
                solver.failcont = fc18;
                fc19 = solver.failcont;
                solver.failcont = function(v76) {
                  var fc20;
                  solver.failcont = fc19;
                  fc20 = solver.failcont;
                  solver.failcont = function(v77) {
                    var fc21;
                    solver.failcont = fc20;
                    fc21 = solver.failcont;
                    solver.failcont = function(v78) {
                      var fc22;
                      solver.failcont = fc21;
                      fc22 = solver.failcont;
                      solver.failcont = function(v79) {
                        solver.failcont = fc22;
                        return $throwExpr(cont9)
                      };
                      return $switchExpr(cont9)
                    };
                    return $forExpr(cont9)
                  };
                  return $tryExpr(cont9)
                };
                return $ifExpr(cont9)
              };
              return $assignExpr(cont9)
            };
            return $operationExpr(cont9)
          };
          return $code(cont9)
        };
        return $invocationExpr(cont9)
      };
      return $valueExpr(cont9)
    };
    $assignExpr = function(cont8) {
      var left, op, exp2;
      return $leftValueExpr(function(v69) {
        return assignOperator(solver, function(v68) {
          return $expression(function(v67) {
            return ((v68 === 8) ? cont8([v68, v69, v67]) : cont8(concat(v68, [v69, v67])))
          })
        })
      })
    };
    $leftValueExpr = function(cont7) {
      var fc12;
      fc12 = solver.failcont;
      solver.failcont = function(v60) {
        var fc13;
        solver.failcont = fc12;
        fc13 = solver.failcont;
        solver.failcont = function(v61) {
          solver.failcont = fc13;
          return $indexExpr(cont7)
        };
        return $attrExpr(cont7)
      };
      return parser.identifier(solver, cont7)
    };
    $attrExpr = function(cont6) {
      var fc9;
      fc9 = solver.failcont;
      solver.failcont = function(v56) {
        var fc10;
        solver.failcont = fc9;
        fc10 = solver.failcont;
        solver.failcont = function(v57) {
          var fc11;
          solver.failcont = fc10;
          fc11 = solver.failcont;
          solver.failcont = function(v58) {
            solver.failcont = fc11;
            return parser.quoteString(solver, function(v54) {
              return parser.char(solver, ".", function(v55) {
                return parser.identifier(solver, cont6)
              })
            })
          };
          return $arrayLiteral(function(v54) {
            return parser.char(solver, ".", function(v55) {
              return parser.identifier(solver, cont6)
            })
          })
        };
        return $parenExper(function(v54) {
          return parser.char(solver, ".", function(v55) {
            return parser.identifier(solver, cont6)
          })
        })
      };
      return parser.identifier(solver, function(v54) {
        return parser.char(solver, ".", function(v55) {
          return parser.identifier(solver, cont6)
        })
      })
    };
    $indexExpr = function(cont5) {
      var fc8;
      fc8 = solver.failcont;
      solver.failcont = function(v52) {
        solver.failcont = fc8;
        return $parenExpr(function(v49) {
          return parser.char(solver, "[", function(v50) {
            return $expression(function(v51) {
              return parser.char(solver, "]", cont5)
            })
          })
        })
      };
      return parser.identifier(solver, function(v49) {
        return parser.char(solver, "[", function(v50) {
          return $expression(function(v51) {
            return parser.char(solver, "]", cont5)
          })
        })
      })
    };
    $binaryExpr = function(cont4) {
      var x, op2, y;
      return $unaryExpr(function(v47) {
        var fc6, anyCont, fc7;
        x = v47;
        fc6 = solver.failcont;
        solver.failcont = function(v38) {
          solver.failcont = fc6;
          return cont4(x)
        };
        anyCont = function(v40) {
          return binaryOperator(solver, function(v46) {
            return $unaryExpr(function(v45) {
              return anyCont(x = [v46, x, v45])
            })
          })
        };
        fc7 = solver.failcont;
        solver.failcont = function(v40) {
          var v41;
          solver.failcont = fc7;
          return cont4(x)
        };
        return anyCont(null)
      })
    };
    $unaryExpr = function(cont3) {
      var fc4, x2, op2;
      fc4 = solver.failcont;
      solver.failcont = function(v25) {
        solver.failcont = fc4;
        return $atomExpr(function(v30) {
          var fc5;
          fc5 = solver.failcont;
          solver.failcont = function(v27) {
            solver.failcont = fc5;
            return cont3(v30)
          };
          return suffixOperator(solver, function(v29) {
            return cont3([v29, v30])
          })
        })
      };
      return unaryOperator(solver, function(v34) {
        return $atomExpr(function(v33) {
          return cont3([v34, v33])
        })
      })
    };
    $parenExpr = function(cont2) {
      var exp2;
      return parser.char(solver, "(", function(v20) {
        return $binaryExpr(function(v23) {
          return parser.char(solver, ")", function(v22) {
            return cont2(v23)
          })
        })
      })
    };
    $atomExpr = function(cont) {
      var fc;
      fc = solver.failcont;
      solver.failcont = function(v16) {
        var fc2;
        solver.failcont = fc;
        fc2 = solver.failcont;
        solver.failcont = function(v17) {
          var fc3;
          solver.failcont = fc2;
          fc3 = solver.failcont;
          solver.failcont = function(v18) {
            solver.failcont = fc3;
            return $parenExpr(cont)
          };
          return parser.number(solver, cont)
        };
        return parser.quoteString(solver, function(x1) {
          return cont([2, x1])
        })
      };
      return parser.identifier(solver, cont)
    };
    return $binaryExpr(function(v2) {
      return v2
    })
  })()
}
//exports.main();