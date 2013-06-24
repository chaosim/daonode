_ = require('underscore');
__slice = [].slice
solve = require('f:/daonode/lib/compiler/core.js').solve;
parser = require('f:/daonode/lib/compiler/parser.js');
solvecore = require('f:/daonode/lib/compiler/solve.js');
Solver = solvecore.Solver;
Trail = solvecore.Trail;
Var = solvecore.Var;

exports.main = function(v) {
  solver = new(Solver)();
  solver.state = null;
  solver.catches = {};
  solver.trail = new Trail();
  solver.failcont = function(v) {
    return v;
  };
  solver.cutcont = solver.failcont;
  return (function(v) {
    state = solver.state;
    solver.state = [v, 0];
    text = (solver.state)[0];
    pos = (solver.state)[1];
    start = (3 !== null) ? (3) : (pos);
    length = (1 !== null) ? (1) : ((text).length);
    return (function(v) {
      solver.state = state;
      return (function(v) {
        return v;
      })(v);
    })(text.slice(start, start + length));
  })("\ras\ndf");
}
//exports.main();