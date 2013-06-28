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

exports.main = function(v_$1) {
  solver = new(Solver)();
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v_$1) {
    throw new(SolverFinish)(v_$1);
  };
  solver.cutcont = solver.failcont;
  return solver.run(function(v_$1) {
    return (function(v_$56) {
      __ = v_$56;
      return (function(v_$2) {
        return (function(v_$55) {
          n = v_$55;
          return (function(v_$3) {
            return (function(v_$54) {
              result = v_$54;
              return (function(v_$4) {
                return (function(v_$6) {
                  return (function(state_$7) {
                    solver.state = [v_$6, 0];
                    return (function(trail_$17, state_$18, fc_$19) {
                      solver.trail = new Trail();
                      solver.failcont = function(v_$16) {
                        solver.trail.undo();
                        solver.trail = trail_$17;
                        solver.state = state_$18;
                        solver.failcont = fc_$19;
                        return (function(x_$23) {
                          return (function(y_$24) {
                            return (solver.trail.unify(x_$23, y_$24)) ? ((function(v_$20) {
                                  return (function(x_$21) {
                                    return (function(y_$22) {
                                      return (solver.trail.unify(x_$21, y_$22)) ? ((function(v_$8) {
                                            return (function(v_$15) {
                                              return (function(v_$9) {
                                                return (function(v_$14) {
                                                  return (function(v_$10) {
                                                    return (function(v_$13) {
                                                      return (function(v_$11) {
                                                        return (function(v_$12) {
                                                          return (function(v_$6) {
                                                            solver.state = state_$7;
                                                            return (function(v_$5) {
                                                              return (function(v_$1) {
                                                                throw new(SolverFinish)(v_$1);
                                                              })(solver.trail.getvalue(result));
                                                            })(v_$6);
                                                          })(parser.char(solver, v_$12));
                                                        })("c");
                                                      })(parser.char(solver, v_$13));
                                                    })(",");
                                                  })(parser.char(solver, v_$14));
                                                })("b");
                                              })(parser.char(solver, v_$15));
                                            })(",");
                                          })(true)) : ((solver.failcont)(false));
                                    })([]);
                                  })(result);
                                })(true)) : ((solver.failcont)(false));
                          })(0);
                        })(n);
                      };
                      return (function(v_$53) {
                        return (function(v_$25) {
                          return (function(v_$52) {
                            n_$058 = v_$52;
                            return (function(v_$26) {
                              return (function(a0_$51) {
                                return (function(v_$50) {
                                  result_$057 = v_$50;
                                  return (function(v_$27) {
                                    anyCont_$37 = function(v_$38) {
                                      return (function(fc_$34, trail_$35, state_$36) {
                                        solver.trail = new Trail();
                                        solver.failcont = function(v_$38) {
                                          solver.trail.undo();
                                          solver.trail = trail_$35;
                                          solver.state = state_$36;
                                          solver.failcont = fc_$34;
                                          return (function(v_$28) {
                                            return (function(x_$32) {
                                              return (function(y_$33) {
                                                return (solver.trail.unify(x_$32, y_$33)) ? ((function(v_$29) {
                                                      return (function(x_$30) {
                                                        return (function(y_$31) {
                                                          return (solver.trail.unify(x_$30, y_$31)) ? ((function(v_$8) {
                                                                return (function(v_$15) {
                                                                  return (function(v_$9) {
                                                                    return (function(v_$14) {
                                                                      return (function(v_$10) {
                                                                        return (function(v_$13) {
                                                                          return (function(v_$11) {
                                                                            return (function(v_$12) {
                                                                              return (function(v_$6) {
                                                                                solver.state = state_$7;
                                                                                return (function(v_$5) {
                                                                                  return (function(v_$1) {
                                                                                    throw new(SolverFinish)(v_$1);
                                                                                  })(solver.trail.getvalue(result));
                                                                                })(v_$6);
                                                                              })(parser.char(solver, v_$12));
                                                                            })("c");
                                                                          })(parser.char(solver, v_$13));
                                                                        })(",");
                                                                      })(parser.char(solver, v_$14));
                                                                    })("b");
                                                                  })(parser.char(solver, v_$15));
                                                                })(",");
                                                              })(true)) : ((solver.failcont)(false));
                                                        })(result_$057);
                                                      })(result);
                                                    })(true)) : ((solver.failcont)(false));
                                              })(n_$058);
                                            })(n);
                                          })(v_$38);
                                        };
                                        return (function(v_$49) {
                                          return (function(v_$39) {
                                            return (function(v_$48) {
                                              return (function(v_$40) {
                                                return (function(list_$44) {
                                                  return (function(value_$45) {
                                                    return (function(fc_$46) {
                                                      solver.failcont = function(v_$47) {
                                                        (list_$44).pop();
                                                        return (fc_$46)(v_$47);
                                                      };
                                                      (list_$44).push(value_$45);
                                                      return (function(v_$41) {
                                                        return (function(fc_$43) {
                                                          solver.failcont = function(v_$42) {
                                                            --n_$058;
                                                            return (fc_$43)(v_$42);
                                                          };
                                                          return (anyCont_$37)(++n_$058);
                                                        })(solver.failcont);
                                                      })(value_$45);
                                                    })(solver.failcont);
                                                  })(solver.trail.getvalue(__));
                                                })(result_$057);
                                              })(parser.char(solver, v_$48));
                                            })(__);
                                          })(parser.char(solver, v_$49));
                                        })(",");
                                      })(solver.failcont, solver.trail, solver.state);
                                    };
                                    return (anyCont_$37)(null);
                                  })(v_$50);
                                })([a0_$51]);
                              })(solver.trail.getvalue(__));
                            })(v_$52);
                          })(1);
                        })(parser.char(solver, v_$53));
                      })(__);
                    })(solver.trail, solver.state, solver.failcont);
                  })(solver.state);
                })("a,b,c");
              })(v_$54);
            })(new Var("result"));
          })(v_$55);
        })(new Var("n"));
      })(v_$56);
    })(new DummyVar("__"));
  });
}
//exports.main();