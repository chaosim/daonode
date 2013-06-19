solve = require('f:/daonode/lib/compiler/core.js').solve;
solvecore = require('f:/daonode/lib/compiler/solve.js');
$pushCatch = solvecore.$pushCatch;
$popCatch = solvecore.$popCatch;
$findCatch = solvecore.$findCatch;
Trail = solvecore.Trail;
Var = solvecore.Var;

{
  $state = null;
  $catches = {};
  $trail = new Trail();
  $failcont = function(v) {
    return v;
  };
  $cutcont = $failcont;
  exports.main = function(v) {
    quasilist = ["vop_add"];
    quasilist = (quasilist).concat([1, 2]);
    return quasilist;
  }
}
//exports.main();