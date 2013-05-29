exports.core = core = require("./lib/dao")
exports.solve = core.solve
exports.solver = core.solver
exports.special = core.special
exports.fun = core.fun
exports.fun2 = core.fun2
exports.macro = core.macro
exports.proc = core.proc
exports.call = core.call
exports.apply = core.apply
exports.general = require('./lib/builtins/general')
exports.lisp = require('./lib/builtins/lisp')
exports.logic = require('./lib/builtins/logic')
exports.parser = require('./lib/builtins/parser')