_ = require('underscore');
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
    state = $state;
    $state = ["a", 0];
    data = ($state)[0];
    pos = ($state)[1];
    if (pos > (data).length) return ($failcont)("a");;
    x = "a";
    c = (data)[pos];
    if ((x) instanceof(Var)) {
      x.bind(c, $trail);
      $state = [data, pos + 1];
      $state = state;
      return pos + 1;
    } else if (x === c) {
      $state = [data, pos + 1];
      $state = state;
      return pos + 1;
    } else if (((_).isString)(x))
      if ((x).length === 1) return ($failcont)("a");
      else throw new(ExpressionError)(x);
      else throw new(TypeError)(x);
  }
}
//exports.main();