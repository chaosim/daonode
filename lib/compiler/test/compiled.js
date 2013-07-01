(exports).main = function() {
  _ = require("underscore");
  __slice = ([]).slice;
  solve = (require("f:/daonode/lib/compiler/core.js")).solve;
  parser = require("f:/daonode/lib/compiler/parser.js");
  solvecore = require("f:/daonode/lib/compiler/solve.js");
  SolverFinish = (solvecore).SolverFinish;
  Solver = (solvecore).Solver;
  Trail = (solvecore).Trail;
  Var = (solvecore).Var;
  DummyVar = (solvecore).DummyVar;
  solver = new(Solver)();
  (solver).state = null;
  (solver).catches = {};
  (solver).trail = new Trail();
  (solver).failcont = function(v_$1) {
    throw new(SolverFinish)(v_$1);
  };
  (solver).cutcont = (solver).failcont;
  return solver.run(function(v_$1) {
    var __, n, result, state_$8, trail_$18, state_$19, fc_$20, n_$058, result_$057, anyCont_$38;
    __ = new DummyVar("__");
    __;
    n = new Var("n");
    n;
    result = new Var("result");
    result;
    state_$8 = (solver).state;
    (solver).state = ["a,b,c", 0];
    trail_$18 = (solver).trail;
    state_$19 = (solver).state;
    fc_$20 = (solver).failcont;
    (solver).trail = new Trail();
    (solver).failcont = function(v_$17) {
      var v_$7;
      v_$17;
      (solver).trail.undo();
      (solver).trail = trail_$18;
      (solver).state = state_$19;
      (solver).failcont = fc_$20;
      if (solver.trail.unify(n, 0)) {
        true;
        if (solver.trail.unify(result, [])) {
          true;
          parser.char(solver, ",");
          parser.char(solver, "b");
          parser.char(solver, ",");
          v_$7 = parser.char(solver, "c");
          (solver).state = state_$8;
          v_$7;
          throw new(SolverFinish)(solver.trail.getvalue(result));
        } else return ((solver).failcont)(false);
      } else return ((solver).failcont)(false);
    };
    parser.char(solver, __);
    n_$058 = 1;
    n_$058;
    result_$057 = [solver.trail.getvalue(__)];
    result_$057;
    anyCont_$38 = function(v_$39) {
      var fc_$35, trail_$36, state_$37, list_$48, value_$49, fc_$50, fc_$45;
      fc_$35 = (solver).failcont;
      trail_$36 = (solver).trail;
      state_$37 = (solver).state;
      (solver).trail = new Trail();
      (solver).failcont = function(v_$39) {
        var v_$40, v_$7;
        v_$40 = v_$39;
        (solver).trail.undo();
        (solver).trail = trail_$36;
        (solver).state = state_$37;
        (solver).failcont = fc_$35;
        v_$40;
        if (solver.trail.unify(n, n_$058)) {
          true;
          if (solver.trail.unify(result, result_$057)) {
            true;
            parser.char(solver, ",");
            parser.char(solver, "b");
            parser.char(solver, ",");
            v_$7 = parser.char(solver, "c");
            (solver).state = state_$8;
            v_$7;
            throw new(SolverFinish)(solver.trail.getvalue(result));
          } else return ((solver).failcont)(false);
        } else return ((solver).failcont)(false);
      };
      parser.char(solver, ",");
      parser.char(solver, __);
      list_$48 = result_$057;
      value_$49 = solver.trail.getvalue(__);
      fc_$50 = (solver).failcont;
      (solver).failcont = function(v_$51) {
        v_$51;
        (list_$48).pop();
        return (fc_$50)(value_$49);
      };
      (list_$48).push(value_$49);
      value_$49;
      fc_$45 = (solver).failcont;
      (solver).failcont = function(v_$44) {
        --n_$058;
        return (fc_$45)(n_$058);
      };
      return (anyCont_$38)(++n_$058);
    };
    return (anyCont_$38)(null);
  });
}
//exports.main();