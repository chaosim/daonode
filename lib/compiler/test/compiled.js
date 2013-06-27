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
    return (function(v) {
      __ = v;
      return (function(v) {
        return (function(v) {
          n = v;
          return (function(v) {
            return (function(v) {
              result = v;
              return (function(v) {
                return (function(v) {
                  state = solver.state;
                  solver.state = [v, 0];
                  return (function(trail, state, fc) {
                    solver.trail = new Trail();
                    solver.failcont = function(v) {
                      solver.trail.undo();
                      solver.trail = trail;
                      solver.state = state;
                      solver.failcont = fc;
                      return (function(x) {
                        return (function(y) {
                          return (solver.trail.unify(x, y)) ? ((function(v) {
                                return (function(x) {
                                  return (function(y) {
                                    return (solver.trail.unify(x, y)) ? ((function(v) {
                                          return (function(v) {
                                            return (function(v) {
                                              return (function(v) {
                                                return (function(v) {
                                                  return (function(v) {
                                                    return (function(v) {
                                                      return (function(v) {
                                                        return (function(v) {
                                                          solver.state = state;
                                                          return (function(v) {
                                                            return (function(v) {
                                                              throw new(SolverFinish)(v);
                                                            })(solver.trail.getvalue(result));
                                                          })(v);
                                                        })(parser.char(solver, v));
                                                      })("c");
                                                    })(parser.char(solver, v));
                                                  })(",");
                                                })(parser.char(solver, v));
                                              })("b");
                                            })(parser.char(solver, v));
                                          })(",");
                                        })(true)) : ((solver.failcont)(false));
                                  })([]);
                                })(result);
                              })(true)) : ((solver.failcont)(false));
                        })(0);
                      })(n);
                    };
                    return (function(v) {
                      return (function(v) {
                        return (function(v) {
                          n_$$58 = v;
                          return (function(v) {
                            return (function(a0) {
                              return (function(v) {
                                result_$$57 = v;
                                return (function(v) {
                                  anyCont = function(v) {
                                    return (function(fc, trail, state) {
                                      solver.trail = new Trail();
                                      solver.failcont = function(v) {
                                        solver.trail.undo();
                                        solver.trail = trail;
                                        solver.state = state;
                                        solver.failcont = fc;
                                        return (function(v) {
                                          return (function(x) {
                                            return (function(y) {
                                              return (solver.trail.unify(x, y)) ? ((function(v) {
                                                    return (function(x) {
                                                      return (function(y) {
                                                        return (solver.trail.unify(x, y)) ? ((function(v) {
                                                              return (function(v) {
                                                                return (function(v) {
                                                                  return (function(v) {
                                                                    return (function(v) {
                                                                      return (function(v) {
                                                                        return (function(v) {
                                                                          return (function(v) {
                                                                            return (function(v) {
                                                                              solver.state = state;
                                                                              return (function(v) {
                                                                                return (function(v) {
                                                                                  throw new(SolverFinish)(v);
                                                                                })(solver.trail.getvalue(result));
                                                                              })(v);
                                                                            })(parser.char(solver, v));
                                                                          })("c");
                                                                        })(parser.char(solver, v));
                                                                      })(",");
                                                                    })(parser.char(solver, v));
                                                                  })("b");
                                                                })(parser.char(solver, v));
                                                              })(",");
                                                            })(true)) : ((solver.failcont)(false));
                                                      })(result_$$57);
                                                    })(result);
                                                  })(true)) : ((solver.failcont)(false));
                                            })(n_$$58);
                                          })(n);
                                        })(v);
                                      };
                                      return (function(v) {
                                        return (function(v) {
                                          return (function(v) {
                                            return (function(v) {
                                              return (function(list) {
                                                return (function(value) {
                                                  return (function(fc) {
                                                    solver.failcont = function(v) {
                                                      (list).pop();
                                                      return (fc)(v);
                                                    };
                                                    (list).push(value);
                                                    return (function(v) {
                                                      return (function(fc) {
                                                        solver.failcont = function(v) {
                                                          --n_$$58;
                                                          return (fc)(v);
                                                        };
                                                        return (anyCont)(++n_$$58);
                                                      })(solver.failcont);
                                                    })(value);
                                                  })(solver.failcont);
                                                })(solver.trail.getvalue(__));
                                              })(result_$$57);
                                            })(parser.char(solver, v));
                                          })(__);
                                        })(parser.char(solver, v));
                                      })(",");
                                    })(solver.failcont, solver.trail, solver.state);
                                  };
                                  return (anyCont)(null);
                                })(v);
                              })([a0]);
                            })(solver.trail.getvalue(__));
                          })(v);
                        })(1);
                      })(parser.char(solver, v));
                    })(__);
                  })(solver.trail, solver.state, solver.failcont);
                })("a,b,c");
              })(v);
            })(new Var("result"));
          })(v);
        })(new Var("n"));
      })(v);
    })(new DummyVar("__"));
  });
}
//exports.main();