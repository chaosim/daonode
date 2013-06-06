exports.vari = vari = (name) -> ["var", name]
exports.vars = (names) -> vari(name) for name in split names,  reElements

exports.quote = (exp) -> ["quote", exp]
exports.begin = (exps...) -> ["begin"].concat(exps)
exports.assign = (vari, exp) -> ["assign", vari, exp]
exports.if_ = (test, then_, else_) -> ["if", test, then_, else_]
exports.funcall = (caller, args...) -> ["funcall", caller].concat(args)
exports.macall = (caller, args...) -> ["macall", caller].concat(args)

exports.jsobject = (exp) -> ["jsobject", exp]
exports.jsfun = jsfun = (exp) -> ["jsfun", exp]
exports.lamda = lambda = (params, body...) -> ["lambda", params].concat(body)
exports.macro = macro = (params, body...) -> ["macro", params].concat(body)

exports.print_ = (exps...) -> ['funcall', jsfun(vari('console.log'))].concat(exps)

exports.vop = vop = (name, args...) -> ["vop_"+name].concat(args)

il = require("./interlang")

for name, _ of il
  if _ instanceof il.VirtualOperation
    do (name=name) -> exports[name] = (args...) -> vop(name, args...)
