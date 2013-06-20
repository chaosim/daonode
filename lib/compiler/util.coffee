_ = require('underscore')

exports.string = string = (s) -> ["string", s]
exports.vars = (names) -> vari(name) for name in split names,  reElements

exports.quote = (exp) -> ["quote", exp]
exports.eval_ = (exp, path) -> ["eval", exp, path]
exports.begin = (exps...) -> ["begin"].concat(exps)

exports.assign = (left, exp) -> ["assign", left, exp]
exports.augassign = (left, exp) -> ["augment-assign", op, left, exp]
exports.addassign = (left, exp) -> ["augment-assign", 'add', left, exp]
exports.subassign = (left, exp) -> ["augment-assign", 'sub', left, exp]
exports.mulassign = (left, exp) -> ["augment-assign", 'mul', left, exp]
exports.divassign = (left, exp) -> ["augment-assign", 'div', left, exp]
exports.modassign = (left, exp) -> ["augment-assign", 'mod', left, exp]
exports.andassign = (left, exp) -> ["augment-assign", 'and', left, exp]
exports.orassign = (left, exp) -> ["augment-assign", 'or', left, exp]
exports.bitandassign = (left, exp) -> ["augment-assign", 'bitand', left, exp]
exports.bitorassign = (left, exp) -> ["augment-assign", 'bitor', left, exp]
exports.bitxorassign = (left, exp) -> ["augment-assign", 'bitxor', left, exp]
exports.lshiftassign = (left, exp) -> ["augment-assign", 'lshift', left, exp]
exports.rshiftassign = (left, exp) -> ["augment-assign", 'rshift', left, exp]

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

exports.pure = io = (exp) -> ["pure", exp]
exports.effect = sideEffect = (exp) -> ["effect", exp]
exports.io = io = (exp) -> ["io", exp]

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

exports.catch_ =  (tag, forms...) -> ['catch', tag, forms...]
exports.throw_ = (tag, form) -> ['throw', tag, form]
exports.protect = (form, cleanup...) -> ['unwind-protect', form, cleanup...]
exports.callcc = (fun) -> ['callcc', fun]

exports.print_ = (exps...) -> ['funcall', io(jsfun('console.log'))].concat(exps)

exports.vop = vop = (name, args...) -> ["vop_"+name].concat(args)

exports.inc = (item) -> ['inc', item]

exports.suffixinc = (item) -> ['suffixinc', item]

exports.dec = (item) -> ['dec', item]

exports.suffixdec = (item) -> ['suffixdec', item]

il = require("./interlang")

for name, _o of il
  try instance = _o?()
  catch e then continue
  if instance instanceof il.VirtualOperation and name not in il.excludes
    do (name=name) -> exports[name] = (args...) -> vop(name, args...)

not_ = exports.not_

# logic

exports.logicvar = (name) -> ['logicvar', name]

exports.unify = (x, y) -> ['unify', x, y]
exports.notunify = (x, y) -> ['notunify', x, y]

exports.succeed = ['succeed']
exports.fail = ['fail']

exports.andp = exports.begin
exports.orp = orp = (exps...) ->
  length = exps.length
  if length is 0 then throw new ArgumentError(exps)
  else if length is 1 then exps[0]
  else if length is 2 then ['orp', exps...]
  else ['orp', exps[0], orp(exps[1...]...)]
exports.notp = (goal) -> ['notp', goal]
exports.repeat = ['repeat']
exports.cutable = (goal) -> ['cutable', goal]
exports.cut = ['cut']
exports.findall = (goal) -> ['findall', goal]
exports.is_ = (vari, exp) -> ['is_', vari, exp]
exports.bind = (vari, term) -> ['bind', vari, term]

# parser
exports.parse =  (exp, state) -> ['parse', exp, state]
exports.parsetext =  (exp, text) -> ['parsetext', exp, text]
exports.eoi = ['eoi']
exports.char = (x) -> ['char', x]
