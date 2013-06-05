exports.vari = (name) -> ["var", name]
exports.vars = (names) -> vari(name) for name in split names,  reElements

exports.quote = (exp) -> ["quote", exp]
exports.begin = (exps...) -> ["begin"].concat(exps)
exports.assign = (vari, exp) -> ["assign", vari, exp]

exports.jsobject = (exp) -> ["jsobject", exp]