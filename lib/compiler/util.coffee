_ = require('underscore')

exports.string = string = (s) -> ["string", s]
exports.vars = (names) -> vari(name) for name in split names,  reElements

exports.quote = (exp) -> ["quote", exp]
exports.eval_ = (exp, path) -> ["eval", exp, path]
exports.begin = (exps...) -> ["begin"].concat(exps)
exports.assign = (vari, exp) -> ["assign", vari, exp]
exports.if_ = if_ = (test, then_, else_) -> ["if", test, then_, else_]
exports.iff = iff = (clauses, else_) ->
  length =  clauses.length
  if length is 0 then throw new Error "iff clauses should have at least one clause."
  else
    [test, then_] = clauses[0]
    if length is 1 then if_(test, then_, else_)
    else if_(test, then_, iff(clauses[1...], else_))

exports.funcall = (caller, args...) -> ["funcall", caller].concat(args)
exports.macall = (caller, args...) -> ["macall", caller].concat(args)

exports.jsobject = (exp) -> ["jsobject", exp]
exports.jsfun = jsfun = (exp) -> ["jsfun", exp]
exports.lamda = lambda = (params, body...) -> ["lambda", params].concat(body)
exports.macro = macro = (params, body...) -> ["macro", params].concat(body)
exports.qq  = quasiquote = (exp) -> ["quasiquote", exp]
exports.uq  = unquote = (exp) -> ["unquote", exp]
exports.uqs  = unquoteSlice = (exp) -> ["unquote-slice", exp]

isLabel = (label) -> _.isArray(label) and label.length is 2 and label[0] is 'label'

exports.makeLabel = makeLabel = (label) -> ['label', label]

defaultLabel = ['label', '']

exports.block = block = (label, body...) ->
  if not isLabel(label) then label = makeLabel(''); body = [label].concat(body)
  ['block', label, body...]

exports.break_ = break_ = (label=defaultLabel, value=null) ->
  if value != null and not isLabel(label) then throw new TypeError([label, value])
  if value is null and not isLabel(label) then (value = label; label = makeLabel(''))
  ['break', label, value]

exports.continue_ = continue_ = (label=defaultLabel) -> ['continue',  label]

# loop
exports.loop_ = (label, body...) ->
  if not isLabel(label) then (label = defaultLabel; body = [label].concat body)
  block(label, body.concat([continue_(label)])...)

# while
exports.while_ = (label, test, body...) ->
  if not isLabel(label) then (label = defaultLabel; test = label; body = [test].concat body)
  block(label, [if_(not_(test), break_(label))].concat(body).concat([continue_(label)])...)

# until
exports.until_ = (label,body..., test) ->
  if not isLabel(label) then (label = defaultLabel; test = label; body = [test].concat body)
  body = body.concat([if_(not_(test), continue_(label))])
  block(label, body...)

exports.print_ = (exps...) -> ['funcall', jsfun('console.log')].concat(exps)

exports.vop = vop = (name, args...) -> ["vop_"+name].concat(args)

exports.inc = (item) -> ['inc', item]

exports.suffixinc = (item) -> ['suffixinc', item]

exports.dec = (item) -> ['dec', item]

exports.suffixdec = (item) -> ['suffixdec', item]

il = require("./interlang")

excludes = ['evalexpr', 'failcont', 'run', 'push', 'getvalue', 'fake', 'findCatch', 'popCatch', 'pushCatch', 'protect','suffixdec', 'suffixdec', 'dec', 'inc']

for name, _o of il
  if _o instanceof il.VirtualOperation and name not in excludes
    do (name=name) -> exports[name] = (args...) -> vop(name, args...)

not_ = exports.not_