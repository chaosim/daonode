# stuffs for dao's inter langugage, aka interlang

I = require "f:/node-utils/src/importer"
I.use "f:/node-utils/src/utils:   dict, assert"

il = interlang = exports
il.toString  = () -> 'interlang'

#true == 1
#false==0
il.unknown = -1

il.element  = (exp) ->
  if (exp instanceof il.Element) then exp
  else
    maker = type_map[typeof(exp)]
    if maker? then maker(exp)
    else throw new dao.CompileTypeError(exp)

no_side_effects  = (exp) ->
  exp.side_effects  = ( ) ->  false
  exp

optimize_args  = (args, env, compiler) ->
  result = []
  for arg in args
    arg = arg.optimize(env, compiler)
    if arg isnt undefined
      result.push(arg)
  (result)

javascriptize_args  = (args, env, compiler) ->
  # used in Apply, Return, Yield, VirtualOpteration
  result_args = []
  exps = []
  for arg in args
    exps2 = arg.javascriptize(env, compiler)
    result_args.push(exps2[-1])
    exps += exps2[..-1]
    return [exps, result_args]

class il.Element
class il.Atom extends il.Element
  constructor: (@item) ->
class il.ConstAtom extends il.Atom
class il.Integer extends il.ConstAtom
class il.Float extends il.ConstAtom
class il.String extends il.ConstAtom
class il.Bool extends il.ConstAtom
class il.Symbol extends il.ConstAtom
class il.Klass extends il.ConstAtom
class il.PyFunction extends il.ConstAtom
class il.Tuple extends il.ConstAtom
  constructor: (@item...) ->
class il.MutableAtom extends il.Atom
class il.List extends il.MutableAtom
class il.Dict extends il.MutableAtom
class il.MacroArgs extends il.Element
  constructor: (@item) ->
class il.Return extends il.Element
  constructor: (@args...) ->
class il.Yield extends il.Return
class il.Try extends il.Element
  constructor: (@test, @body) ->
class il.Begin extends il.Element
  constructor: (@statements) ->
class il.PassStatement extends il.Element
  constructor: ( ) ->
class il.Nil extends il.Element
  constructor: ( ) ->
class il.Lamda extends il.Element
  constructor: (@params, @body) -> @has_javascriptized = false
class il.RulesLamda extends il.Lamda
  constructor: (@params, @body) ->  @has_javascriptized = false
class il.Clamda extends il.Lamda
  constructor: (v, @body) ->
    @has_javascriptized = false
    @params = [v]
    @name = undefined
class il.EqualCont
class il.Done extends il.Clamda
  constructor: (param) ->
    @has_javascriptized = false
    @params = [param]
    @body = param
class il.Function extends il.Lamda
  constructor: (@name, @params, @body) ->
class il.CFunction extends il.Function
  is_fun: true
  constructor: (@name, v, @body) ->
class il.RulesDict extends il.Element
  constructor: (@arity_body_map) ->  @to_coded = false
class il.Macro
class il.MacroLamda extends il.Lamda #, Macro):
class il.MacroRules extends il.Lamda #, Macro):
class il.MacroFunction extends il.Element
  constructor: (@fun) ->
class il.MacroRulesFunction extends il.Element
  constructor: (@fun) ->
class il.GlobalDecl extends il.Element
  constructor: (@args) ->
class il.Apply extends il.Element
  constructor: (@caller, @args) ->
class il.ExpressionWithCode extends il.Element
  constructor: (@exp, @fun) ->
class il.Var extends il.Element
  constructor: (@name) ->
class il.RecursiveVar extends il.Var
class il.LocalVar extends il.Var
class il.ConstLocalVar extends il.LocalVar
class il.SolverVar extends il.Var
  constructor: (name) -> @name = 'solver.'+name
class il.LogicVar extends il.Element
  constructor: (@name) ->
class il.DummyVar extends il.LogicVar
class il.Assign extends il.Element
  constructor: (@var1, @exp) ->
class il.AssignFromList extends il.Element
  constructor: (args...) ->
    @vars = args[..-1]
    @value = args[-1]
class il.If extends il.Element
  constructor: (@test, @then_, @else_) ->
class il.PseudoElse extends il.ConstAtom
  constructor: ( ) ->
class il.Cons extends il.ConstAtom
  constructor: (@head, @tail) ->
class il.While extends il.Element
  constructor: (@test, @body) ->
class il.For extends il.Element
  constructor: (@var1, @range, @body) ->
class il.BinaryOperation extends il.Element
  constructor: (@name, @operator, @has_side_effects=true) ->
class il.BinaryOperationApply extends il.Apply
  constructor: (@caller, @args) ->
class il.VirtualOperation extends il.Element
  constructor: (@args...) ->
    if @arity>=0
      assert args.length is @arity,  "#{@name} should have #{@arity} arguments."
class il.Deref extends il.Element
  constructor: (@item) ->
class il.EvalExpressionWithCode extends il.Element
  constructor: (@item) ->
class il.Len extends il.Element
  constructor: (@item) ->
class il.In extends il.Element
  constructor: (@item, @container) ->
class il.GetItem extends il.Element
  constructor: (@container, @index) ->
class il.ListAppend extends il.Element
  constructor: (@container, @value) ->
class il.PushCatchCont extends il.Element
  constructor: (@tag, @cont) ->
class il.SetBinding extends il.Element
  constructor: (@var1, @value) ->
class il.FindCatchCont extends il.Element
  constructor: (@tag) ->
class il.IsMacro extends il.Element
  constructor: (@item) ->
class il.IsMacroRules extends il.IsMacro
class il.VirtualOperation2 extends il.VirtualOperation
class il.LogicOperation extends il.VirtualOperation
class il.BinaryLogicOperation extends il.VirtualOperation
class il.UnaryLogicOperation extends il.VirtualOperation

il.Element::tail_recursive_convert = ( ) ->  @
il.Atom::tail_recursive_convert = ( ) ->  @

il.Element::find_assign_lefts = ( ) ->  set()
il.Atom::find_assign_lefts = ( ) ->  set()
il.Tuple::find_assign_lefts = ( ) ->  set()
il.MacroArgs::find_assign_lefts = ( ) ->  set()
il.Try::find_assign_lefts = ( ) ->  @body.find_assign_lefts()
il.Begin::find_assign_lefts = ( ) -> set().mergeAt(exp.find_assign_lefts() for exp in @statements)
il.Lamda::find_assign_lefts = ( ) ->  @body.find_assign_lefts()
il.Apply::find_assign_lefts = (exp) ->  set()
il.Var::find_assign_lefts = ( ) ->  set()
il.LogicVar::find_assign_lefts = (exp) ->  set()
il.Assign::find_assign_lefts = ( ) ->  set([@var1])
il.AssignFromList::find_assign_lefts = ( ) ->  set(@vars)
il.If::find_assign_lefts = ( ) ->  @then_.find_assign_lefts() | @else_.find_assign_lefts()
il.While::find_assign_lefts = ( ) ->  @body.find_assign_lefts()
il.For::find_assign_lefts = ( ) ->  @body.find_assign_lefts()
il.VirtualOperation::find_assign_lefts = ( ) ->  set()
il.ListAppend::find_assign_lefts = ( ) ->  if isinstance(@container, Var) then set([@container]) else set()


il.Element::replace_return_with_pyyield = ( ) ->  @
il.Atom::replace_return_with_pyyield = ( ) ->  @
il.Return::replace_return_with_pyyield = ( ) ->  Begin([Yield(@args...), Return()])
il.Try::replace_return_with_pyyield = ( ) -> Try(@test,  @body.replace_return_with_pyyield())
il.Begin::replace_return_with_pyyield = ( ) ->  Begin((exp.replace_return_with_pyyield() for exp in @statements))
il.PassStatement::replace_return_with_pyyield = ( ) ->  @
il.Nil::replace_return_with_pyyield = ( ) ->  @
il.Apply::replace_return_with_pyyield = ( ) ->  @
il.Var::replace_return_with_pyyield = ( ) ->  @
il.LogicVar::replace_return_with_pyyield = ( ) ->  @
il.AssignFromList::replace_return_with_pyyield = ( ) ->  @
il.If::replace_return_with_pyyield = ( ) -> new il.If(@test, @then_.replace_return_with_pyyield(),  @else_.replace_return_with_pyyield())
il.PseudoElse::replace_return_with_pyyield = ( ) ->  @
il.Cons::replace_return_with_pyyield = ( ) ->  @
il.While::replace_return_with_pyyield = ( ) -> new il.While(@test  @body.replace_return_with_pyyield())
il.For::replace_return_with_pyyield = ( ) ->  For(@var1, @range, @body.replace_return_with_pyyield())
il.VirtualOperation::replace_return_with_pyyield = ( ) ->  @
il.Deref::replace_return_with_pyyield = ( ) ->  @
il.EvalExpressionWithCode::replace_return_with_pyyield = ( ) ->  @
il.Len::replace_return_with_pyyield = ( ) ->  @
il.In::replace_return_with_pyyield = ( ) ->  @
il.GetItem::replace_return_with_pyyield = ( ) ->  @
il.ListAppend::replace_return_with_pyyield = ( ) ->  @
il.PushCatchCont::replace_return_with_pyyield = ( ) ->  @
il.SetBinding::replace_return_with_pyyield = ( ) ->  @
il.FindCatchCont::replace_return_with_pyyield = ( ) ->  @
il.IsMacro::replace_return_with_pyyield = ( ) ->  @
il.VirtualOperation2::replace_return_with_pyyield = ( ) ->  @

il.Element::interlang = ( ) ->  @

il.Element::__eq__ = (x, y) ->  classeq(x, y)
il.Integer::__eq__ = (x, y) ->  ConstAtom.__eq__(x, y) or (isinstance(y, int) and x.item==y)
il.Float::__eq__ = (x, y) ->  ConstAtom.__eq__(x, y) or (isinstance(y, float) and x.item==y)
il.String::__eq__ = (x, y) ->  ConstAtom.__eq__(x, y) or (isinstance(y, str) and x.item==y)
il.Bool::__eq__ = (x, y) ->  ConstAtom.__eq__(x, y) or (isinstance(y, bool) and x.item==y)
il.Atom::__eq__ = (x, y) ->  classeq(x, y) and x.item==y.item
il.Tuple::__eq__ = (x, y) ->  classeq(x, y) and x.item==y.item
il.List::__eq__ = (x, y) ->  (classeq(x, y) and x.item==y.item) or ((isinstance(y, list) and x.item==y))
il.Dict::__eq__ = (x, y) ->  Atom.__eq__(x, y) or (isinstance(y, dict) and x.item==y)
il.MacroArgs::__eq__ = (x, y) ->  classeq(x, y) and x.item==y.item
il.Return::__eq__ = (x, y) ->  classeq(x, y) and x.args==y.args
il.Try::__eq__ = (x, y) ->  classeq(x, y) and x.test==y.test and x.body==y.body
il.Begin::__eq__ = (x, y) ->  classeq(x, y) and x.statements==y.statements
il.PassStatement::__eq__ = (x, y) ->  classeq(x, y)
il.Nil::__eq__ = (x, y) ->  classeq(x, y)
il.Lamda::__eq__ = (x, y) ->  classeq(x, y) and x.params==y.params and x.body==y.body
il.Apply::__eq__ = (x, y) ->  classeq(x, y) and x.caller==y.caller and x.args==y.args
il.ExpressionWithCode::__eq__ = (x, y) ->  classeq(x, y) and x.exp==y.exp
il.Var::__eq__ = (x, y) ->  classeq(x, y) and x.name==y.name
il.Assign::__eq__ = (x, y) ->  classeq(x, y) and x.var1==y.var1 and x.exp==y.exp
il.If::__eq__ = (x, y) ->  classeq(x, y) and x.test==y.test and x.then==y.then and x.else_==y.else_
il.PseudoElse::__eq__ = (x, y) ->  classeq(x, y)
il.Cons::__eq__ = (x, y) ->  classeq(x, y) and x.head==y.head and x.tail==y.tail
il.While::__eq__ = (x, y) ->  classeq(x, y) and x.test==y.test and x.body==y.body
il.For::__eq__ = (x, y) ->  classeq(x, y) and x.var1==y.var1 and x.range==y.range and x.body==y.body
il.BinaryOperation::__eq__ = (x, y) ->  classeq(x, y) and x.operator==y.operator
il.VirtualOperation::__eq__ = (x, y) ->  classeq(x, y) and x.args==y.args

il.Element::toString = ( ) ->  @constructor.name
il.Atom::toString = ( ) ->  @item.toString()
il.Klass::toString = ( ) ->  "il.Klass(#{@item})"
il.PyFunction::toString = ( ) ->  "il.PyFunction(#{@item})"
il.Tuple::toString = ( ) ->  "il.#{@constructor.name}(#{@item})"
il.MacroArgs::toString = ( ) ->  "il.#{@constructor.name}(#{@item})"
il.Return::toString = ( ) ->  "il.Return(#{join(',', x for x in @args)})"
il.Yield::toString = ( ) ->  "il.Yield(#{join(', ', x for x in @args)})"
il.Try::toString = ( ) ->  "il.Try(#{@test}, #{ @body})"
il.Begin::toString = ( ) ->  "il.begin(#{'\n '.join(x for x in @statements)})"
il.PassStatement::toString = ( ) ->  'il.pass_statement'
il.Nil::toString = ( ) ->  'il.nil'
il.Lamda::toString = ( ) ->  "il.Lamda((#{join(', ', x for x in @params)}), \n#{@body})"
il.Clamda::toString = ( ) ->  "il.Clamda(#{@params[0]}, \n#{@body})"
il.EqualCont::toString = ( ) ->  'EqualCont'
il.Done::toString = ( ) ->  "il.Done(#{@params[0]}, #{@body})"
il.CFunction::toString = ( ) ->  "il.CFunction(#{@name}, #{@params[0]}, \n#{@body})"
il.RulesDict::toString = ( ) ->  "RulesDict(#{@arity_body_map})"
il.MacroLamda::toString = ( ) ->  "il.MacroLamda((#{join(', ', x for x in @params)}), \n#{@body})"
il.MacroFunction::toString = ( ) ->  "MacroFunction(#{@fun})"
il.MacroFunction::toString = ( ) ->  "MacroRulesFunction(#{@fun})"
il.GlobalDecl::toString = ( ) ->  "GlobalDecl(#{@args})"
il.Apply::toString = ( ) ->  "#{@caller}(#{join(', ', x for x in @args)})"
il.ExpressionWithCode::toString = ( ) ->  "ExpressionWithCode(#{@exp}, #{@fun})"
il.Var::toString = ( ) ->  @name
il.SolverVar::toString = ( ) ->  "il.#{@name.split('.')[1]}"
il.LogicVar::toString = ( ) ->  "LogicVar(%s)"%@name
il.Assign::toString = ( ) ->  "#il.Assign(#{@var1}, #{@exp})"
il.AssignFromList::toString = ( ) ->  "il.AssignFromList(#{@vars}, #{@value})"
il.If::toString = ( ) ->
  if @else_!=il.pseudo_else then  "il.If(#{@test}, \n#{@then_}, \n#{@else_})"
  else  "il.If(#{@test}, \n#{@then_})"
il.PseudoElse::toString = ( ) ->  'il.pseudo_else'
il.Cons::toString = ( ) ->  "il.Cons(#{@head}, #{@tail})"
il.While::toString = ( ) ->  "il.While(#{@test}, \n#{@body})"
il.For::toString = ( ) ->  "il.For(#{@var1}, #{@range}, #{@body})"
il.BinaryOperation::toString = ( ) ->  "il.#{@name}"
il.BinaryOperationApply::toString = ( ) ->  "#{@caller}(#{join(', ', arg for arg in @args)})"
il.VirtualOperation::toString = ( ) ->
  try if @arity==0 then "il.#{@constructor.name}"
  catch e then "il.#{@constructor.name}(#{join(', ', x for x in @args)})"
il.Deref::toString = ( ) ->  "il.Deref(#{@item})"
il.EvalExpressionWithCode::toString = ( ) ->  "il.EvalExpressionWithCode(#{@item})"
il.Len::toString = ( ) ->  "il.Len(#{@item})"
il.In::toString = ( ) ->  "il.In(#{@item}, #{@container})"
il.GetItem::toString = ( ) ->  "il.GetItem(#{@container}, #{@index})"
il.ListAppend::toString = ( ) ->  "il.ListAppend(#{@container}, #{@value})"
il.PushCatchCont::toString = ( ) ->  "il.PushCatchCont(#{@tag}, #{@cont})"
il.SetBinding::toString = ( ) ->  "il.SetBinding(#{@var1}, #{@value})"
il.FindCatchCont::toString = ( ) ->  "il.FindCatchCont(#{@tag})"
il.IsMacro::toString = ( ) ->  "il.IsMacro(#{@item})"
il.IsMacroRules::toString = ( ) ->  "il.IsMacroRules(#{@item})"

il.Atom::analyse = (compiler) ->
il.Tuple::analyse = (compiler) ->  for x in @item then x.analyse(compiler)
il.MacroArgs::analyse = (compiler) -> for x in @item then x.analyse(compiler)
il.Return::analyse = (compiler) ->  for arg in @args then  arg.analyse(compiler)
il.Try::analyse = (compiler) ->
  @test.analyse(compiler)
  @body.analyse(compiler)
il.Begin::analyse = (compiler) -> for x in @statements then x.analyse(compiler)
il.PassStatement::analyse = (compiler) ->
il.Nil::analyse = (compiler) ->
il.Lamda::analyse = (compiler) ->
  compiler.lamda_stack.push(@)
  @body.analyse(compiler)
  compiler.lamda_stack.pop()
il.EqualCont::analyse = (compiler) ->
il.RulesDict::analyse = (compiler) ->
  try @seen  catch e then  @seen = true
  compiler.occur_count[@] = compiler.occur_count.setdefault(0)+1
  for arity, body in @arity_body_map.items()
    body.analyse(compiler)
il.Apply::analyse = (compiler) ->
  compiler.called_count[@caller] = compiler.called_count.setdefault(@caller, 0)+1
  @caller.analyse(compiler)
  for arg in @args
    arg.analyse(compiler)
il.ExpressionWithCode::analyse = (compiler) -> @fun.analyse(compiler)
il.Var::analyse = (compiler) -> compiler.ref_count[@] = compiler.ref_count.setdefault(0)+1
il.LogicVar::analyse = (compiler) ->
il.Assign::analyse = (compiler) -> @exp.analyse(compiler)
il.AssignFromList::analyse = (compiler) ->
  for var1 in @vars
    var1.analyse(compiler)
  @value.analyse(compiler)
il.If::analyse = (compiler) ->
  @test.analyse(compiler)
  @then_.analyse(compiler)
  @else_.analyse(compiler)
il.While::analyse = (compiler) ->
  @test.analyse(compiler)
  @body.analyse(compiler)
il.For::analyse = (compiler) ->
  @var1.analyse(compiler)
  @range.analyse(compiler)
  @body.analyse(compiler)
il.BinaryOperation::analyse = (compiler) ->  @
il.BinaryOperationApply::analyse = (compiler) ->
  compiler.called_count[@caller] = compiler.called_count.setdefault(@caller, 0)+1
  @caller.analyse(compiler)
  arg.analyse(compiler) for arg in @args
il.VirtualOperation::analyse = (compiler) -> for arg in @args then arg.analyse(compiler)
il.Deref::analyse = (compiler) -> @item.analyse(compiler)
il.EvalExpressionWithCode::analyse = (compiler) -> @item.analyse(compiler)
il.Len::analyse = (compiler) -> @item.analyse(compiler)
il.In::analyse = (compiler) ->
  @item.analyse(compiler)
  @container.analyse(compiler)
il.GetItem::analyse = (compiler) ->
  @index.analyse(compiler)
  @container.analyse(compiler)
il.ListAppend::analyse = (compiler) ->
  @value.analyse(compiler)
  @container.analyse(compiler)
il.PushCatchCont::analyse = (compiler) ->
  @tag.analyse(compiler)
  @cont.analyse(compiler)
il.SetBinding::analyse = (compiler) ->
  @var1.analyse(compiler)
  @value.analyse(compiler)
il.FindCatchCont::analyse = (compiler) -> @tag.analyse(compiler)
il.IsMacro::analyse = (compiler) -> @item.analyse(compiler)

il.Atom::side_effects = ( ) ->  false
il.Tuple::side_effects = ( ) ->  false
il.MacroArgs::side_effects = ( ) ->  false
il.Return::side_effects = ( ) ->  false
il.Try::side_effects = ( ) ->  not @test.side_effects() and not @body.side_effects()
il.Begin::side_effects = ( ) ->  true
il.PassStatement::side_effects = ( ) ->  false
il.Nil::side_effects = ( ) ->  false
il.Lamda::side_effects = ( ) ->  false
il.EqualCont::side_effects = ( ) ->  false
il.RulesDict::side_effects = ( ) ->  false
il.GlobalDecl::side_effects = ( ) ->  false
il.Apply::side_effects = ( ) ->
  if isinstance(@caller, Lamda)
    if @caller.body.side_effects() then  return true
    else if isinstance(@caller, Var) then  return true
    else if @caller.has_side_effects() then return true
    else return false # after cps, all of value have been solved before called,
# so have no side effects.
il.ExpressionWithCode::side_effects = ( ) ->  false
il.Var::side_effects = ( ) ->  false
il.LogicVar::side_effects = ( ) ->  false
il.Assign::side_effects = ( ) ->  true
il.AssignFromList::side_effects = ( ) ->  true
il.If::side_effects = ( ) ->  not (@test.side_effects() or @then_.side_effects()  or  @else_.side_effects())
il.While::side_effects = ( ) ->  not @test.side_effects() and not @body.side_effects()
il.For::side_effects = ( ) ->  not @var1.side_effects() and not @range.side_effects() and not @body.side_effects()
il.BinaryOperationApply::side_effects = ( ) ->
  if isinstance(@caller, Var)  then true
  else if @caller.has_side_effects then return true
  else  return false # after cps, all of value have been solved before called,
# so have no side effects.
il.VirtualOperation::side_effects = ( ) ->  true
il.Deref::side_effects = ( ) ->  false
il.EvalExpressionWithCode::side_effects = ( ) ->  true
il.Len::side_effects = ( ) ->  false
il.In::side_effects = ( ) ->  false
il.GetItem::side_effects = ( ) ->  false
il.ListAppend::side_effects = ( ) ->  true
il.PushCatchCont::side_effects = ( ) ->  true
il.SetBinding::side_effects = ( ) ->  true
il.FindCatchCont::side_effects = ( ) ->  true
il.IsMacro::side_effects = ( ) ->  false

il.Atom::subst = (bindings) ->  @
il.Tuple::subst = (bindings) ->  Tuple((x.subst(bindings) for x in @item)...)
il.MacroArgs::subst = (bindings) ->  MacroArgs((x.subst(bindings) for x in @item))
il.Return::subst = (bindings) -> new @constructor((arg.subst(bindings) for arg in @args)...)
il.Try::subst = (bindings) ->  Try(@test.subst(bindings), @body.subst(bindings))
il.Begin::subst = (bindings) ->  Begin((x.subst(bindings) for x in @statements))
il.Nil::subst = (bindings) ->  @
il.PassStatement::subst = (bindings) ->  @
il.Lamda::subst = (bindings) ->
  result = @make_make_new(@params, @body.subst(bindings))
  return result
il.EqualCont::subst = (bindings) ->  @
il.RulesDict::subst = (bindings) ->
  @arity_body_maparity_body_map = {arity:body.subst(bindings) for arity, body in @arity_body_map.items()}
  return @
il.Apply::subst = (bindings) ->  new @constructor(@caller.subst(bindings), (arg.subst(bindings) for arg in @args))
il.ExpressionWithCode::subst = (bindings) ->  ExpressionWithCode(@exp, @fun.subst(bindings))
il.Var::subst = (bindings) ->
  try bindings[@]
  catch e then @
il.LogicVar::subst = (bindings) ->  @
il.Assign::subst = (bindings) ->  Assign(@var1, @exp.subst(bindings))
il.AssignFromList::subst = (bindings) ->  AssignFromList(((var1.subst(bindings) for var1 in @vars)+[@value.subst(bindings)])...)
il.If::subst = (bindings) ->  new il.If(@test.subst(bindings),  @then_.subst(bindings),  @else_.subst(bindings))
il.While::subst = (bindings) ->  While(@test.subst(bindings), @body.subst(bindings))
il.For::subst = (bindings) ->  For(@var1.subst(bindings), @range.subst(bindings), @body.subst(bindings))
il.BinaryOperation::subst = (bindings) ->  @
il.BinaryOperationApply::subst = (bindings) ->  new @constructor(@caller.subst(bindings), (arg.subst(bindings) for arg in @args))
il.VirtualOperation::subst = (bindings) ->  new @constructor((x.subst(bindings) for x in @args)...)
il.Deref::subst = (bindings) ->  Deref(@item.subst(bindings))
il.EvalExpressionWithCode::subst = (bindings) ->  EvalExpressionWithCode(@item.subst(bindings))
il.Len::subst = (bindings) ->  new il.Len @item.subst(bindings)
il.In::subst = (bindings) ->  In(@item.subst(bindings), @container.subst(bindings))
il.GetItem::subst = (bindings) ->  GetItem(@container.subst(bindings), @index.subst(bindings))
il.ListAppend::subst = (bindings) ->  ListAppend(@container.subst(bindings), @value.subst(bindings))
il.PushCatchCont::subst = (bindings) ->  PushCatchCont(@tag.subst(bindings), @cont.subst(bindings))
il.SetBinding::subst = (bindings) ->  SetBinding(@var1.subst(bindings), @value.subst(bindings))
il.FindCatchCont::subst = (bindings) ->  FindCatchCont(@tag.subst(bindings))
il.IsMacro::subst = (bindings) ->  new @constructor(@item.subst(bindings))

il.Atom::optimize = (env, compiler) ->  @
il.Tuple::optimize = (env, compiler) ->  Tuple((x.optimize(env, compiler) for x in @item)...)
il.MacroArgs::optimize = (env, compiler) ->  MacroArgs(optimize_args(@item, env, compiler))
il.Return::optimize = (env, compiler) ->
  if @args.length==1 and isinstance(@args[0], Return)
    new @constructor(@args[0].args...)
  else
    for arg in @args
      if isinstance(arg, Return)  then throw new dao.CompileError
    new @constructor(optimize_args(@args, env, compiler)...)
il.Try::optimize = (env, compiler) ->  Try(@test.optimize(env, compiler), @body.optimize(env, compiler))
il.Begin::optimize = (env, compiler) ->
  result = []
  for arg in @statements
    arg1 = arg.optimize(env, compiler)
    if arg1 isnt undefined
      result.push(arg1)
    if result
      return begin(((x for x in result[..-1] if not isinstance(x, Atom))+[result[-1]])...)
    else return_statement
il.PassStatement::optimize = (env, compiler) -> @
il.Nil::optimize = (env, compiler) ->  nil
il.Lamda::optimize = (env, compiler) ->
  env = env.extend()
  body = @body.optimize(env, compiler)
  result = @make_make_new(@params, body)
  return result
il.EqualCont::optimize = (env, compiler) ->  @
il.RulesDict::optimize = (env, compiler) ->  @
il.Apply::optimize = (env, compiler) ->
  args = optimize_args(@args, env, compiler)
  if isinstance(@caller, Var)
    if @caller not in compiler.recursive_call_path
      caller = @caller.optimize(env, compiler)
      if isinstance(caller, Lamda)
        compiler.recursive_call_path.push(@caller)
        result = caller.optimize_apply(env, compiler, args)
        compiler.recursive_call_path.pop()
        return result
      else
        return new @constructor(caller, args)
    else
      return new @constructor(@caller, args)
  else if isinstance(@caller, Lamda)
    return @caller.optimize_apply(env, compiler, args)
  else
    caller = @caller.optimize(env, compiler)
    if isinstance(caller, Lamda)
      return caller.optimize_apply(env, compiler, args)
    else
      return new @constructor(caller, args)
il.ExpressionWithCode::optimize = (env, compiler) ->  ExpressionWithCode(@exp, @fun.optimize(env, compiler))
il.Var::optimize = (env, compiler) ->
  try env[@]
  catch e then  @
il.LogicVar::optimize = (env, compiler) ->  @
il.Assign::optimize = (env, compiler) ->
  exp = @exp.optimize(env, compiler)
  result = Assign(@var1, exp)
  if isinstance(@var1, ConstLocalVar)
    if (exp instanceof ConstAtom) or (exp instanceof Cons) or (exp instanceof ExpressionWithCode) or (exp instanceof Lamda)
      env[@var1] = exp
      return None
    else if (exp instanceof RulesDict)
      env[@var1] = exp
      exp.name = @var1
      return result
  return result
il.AssignFromList::optimize = (env, compiler) ->
  value = @value.optimize(env, compiler)
  if isinstance(value, Tuple) or isinstance(value, List)
    if @value.item.length!=@vars.length
      throw new dao.CompileError
    else
      for var1, v in zip(@vars, value.item)
        if isinstance(var1, ConstLocalVar)
          env[var1] = v
        else
          assigns.push(Assign(var1, v))
      if assigns
        return begin((Assign(var1, v))...)
      else return None
    return AssignFromList((@vars+[value])...)
il.If::optimize = (env, compiler) ->
  test = @test.optimize(env, compiler)
  test_bool = test.bool()
  if test_bool==true
    then_ = @then_.optimize(env, compiler)
  if isinstance(then_, il.If) and then_.test==test # (if a (if a b c) d)
    return then_.then_
  else if test_bool==false
    else_ = @else_.optimize(env, compiler)
  if isinstance(else_, il.If) and else_.test==test # (if a b (if a c d))
    return else_.else_
  then_ = @then_.optimize(env, compiler)
  else_ = @else_.optimize(env, compiler)
  if isinstance(then_, il.If) and then_.test==test # (if a (if a b c) d)
    then_ = then_.then_
  if isinstance(else_, il.If) and else_.test==test # (if a b (if a c d))
    else_ = else_.else_
  new il.If(test, then_, else_)
il.While::optimize = (env, compiler) ->
  free_vars = @free_vars()
  test = @test.optimize(env, compiler)
  body = @body.optimize(env, compiler)
  result = While(test,body)
  return result
il.For::optimize = (env, compiler) ->
  free_vars = @free_vars()
  assigns = []
  for var1 in free_vars
    value = env[var1]
    if value is undefined then continue
    assigns.push(Assign(var1, value))
    del env[var1]
  return begin(((assigns) + [For(@var1, @range.optimize(env, compiler), @body.optimize(env, compiler))])...)
il.BinaryOperation::optimize = (env, compiler) ->  @
il.BinaryOperationApply::optimize = (env, compiler) ->
  caller = @caller
  args = optimize_args(@args, env, compiler)
  for arg in args
    if not isinstance(arg, Atom) then  break
    else element(caller.operator_fun((arg.item for arg in args))...)
  return new @constructor(caller, args)
il.VirtualOperation::optimize = (env, compiler) ->
  if @has_side_effects then  new @constructor(optimize_args(@args, env,compiler)...)
  args = optimize_args(@args, env,compiler)
  free_vars = set()
  for arg in args
    free_vars |= arg.free_vars()
  for var1 in free_vars
    try assign = env[var1]
    catch e
      if assign isnt undefined then assign.dont_remove()
      result = new @constructor(args...)
  result
il.Deref::optimize = (env, compiler) ->
  item = @item.optimize(env, compiler)
  if isinstance(item, Atom) or isinstance(item, Lamda) then item
  if isinstance(item, Deref) then return item
  return Deref(item)
il.EvalExpressionWithCode::optimize = (env, compiler) ->
  item = @item.optimize(env, compiler)
  if isinstance(item, Var)
    EvalExpressionWithCode(item)
  else if isinstance(item, ExpressionWithCode)
    item.fun.body.optimize(env, compiler)
  else item
il.Len::optimize = (env, compiler) ->
  item = @item.optimize(env, compiler)
  if isinstance(item, Atom) or isinstance(item, MacroArgs)
    return new il.Integer(item.item.length)
  new il.Len(item)
il.In::optimize = (env, compiler) ->
  item = @item.optimize(env, compiler)
  container = @container.optimize(env, compiler)
  if isinstance(item, Atom)
    if isinstance(container, Atom)
      return Bool(item.value in container.value)
    else if isinstance(container, RulesDict)
      return Bool(item.item in container.arity_body_map)
  In(item, container)
il.GetItem::optimize = (env, compiler) ->
  index = @index.optimize(env, compiler)
  container = @container.optimize(env, compiler)
  if isinstance(index, Atom)
    if isinstance(container, Atom)
      return element(container.item[index.item])
  else if isinstance(container, RulesDict)
    return element(container.arity_body_map[index.item])
    #try
    #return element(container.arity_body_map[index.item])
    #catch e
    #return GetItem(container, index)
  else if isinstance(container, MacroArgs)
    return container.item[index.item]
  GetItem(container, index)
il.ListAppend::optimize = (env, compiler) ->
  value = @value.optimize(env, compiler)
  new il.ListAppend(@container, value)
il.PushCatchCont::optimize = (env, compiler) ->
  tag = @tag.optimize(env, compiler)
  cont = @cont.optimize(env, compiler)
  PushCatchCont(tag, cont)
il.SetBinding::optimize = (env, compiler) ->
  value = @value.optimize(env, compiler)
  SetBinding(@var1, value)
il.FindCatchCont::optimize = (env, compiler) -> tag = @tag.optimize(env, compiler);  FindCatchCont(tag)
il.IsMacro::optimize = (env, compiler) ->  new @constructor(@item.optimize(env, compiler))

il.Atom::replace_assign = (compiler) ->  @
il.Done::replace_assign = (bindings) ->  @
il.Var::replace_assign = (compiler) ->   env[@] or @
il.LogicVar::replace_assign = (compiler) ->  @

il.Atom::insert_return_statement = ( ) ->  Return(@)
il.Return::insert_return_statement = ( ) ->  Return(@args...)
il.Yield::insert_return_statement = ( ) ->  @
il.Try::insert_return_statement = ( ) -> Try(@test, @body.insert_return_statement())
il.Begin::insert_return_statement = ( ) ->
  inserted = @statements[-1].insert_return_statement()
  return begin((@statements[..-1]+[inserted])...)
il.PassStatement::insert_return_statement = ( ) ->  @
il.Nil::insert_return_statement = ( ) ->  @
il.Lamda::insert_return_statement = () ->  new il.Return(@)
il.Apply::insert_return_statement = ( ) ->  Return(@)
il.Var::insert_return_statement = ( ) ->  Return(@)
il.LogicVar::insert_return_statement = ( ) ->  Return(@)
il.Assign::insert_return_statement = ( ) ->  begin(Return(@var1))
il.AssignFromList::insert_return_statement = ( ) ->  Return(@)
il.If::insert_return_statement = ( ) ->  new il.If(@test,  @then_.insert_return_statement()  @else_.insert_return_statement())
il.PseudoElse::insert_return_statement = ( ) ->  @
il.Cons::insert_return_statement = ( ) ->  @
il.While::insert_return_statement = ( ) ->
  While(@test, @body.insert_return_statement())
il.For::insert_return_statement = ( ) ->  For(@var1, @range, @body.insert_return_statement())
il.BinaryOperationApply::insert_return_statement = ( ) ->  new il.Return(@)
il.VirtualOperation::insert_return_statement = ( ) ->  Return(@)
il.Deref::insert_return_statement = ( ) ->  Return(@)
il.EvalExpressionWithCode::insert_return_statement = ( ) ->  Return(@)
il.Len::insert_return_statement = ( ) ->  Return(@)
il.In::insert_return_statement = ( ) ->  Return(@)
il.GetItem::insert_return_statement = ( ) ->  Return(@)
il.ListAppend::insert_return_statement = ( ) ->  Return(@)
il.PushCatchCont::insert_return_statement = ( ) ->  Return(@)
il.SetBinding::insert_return_statement = ( ) ->  Return(@)
il.FindCatchCont::insert_return_statement = ( ) ->  Return(@)
il.IsMacro::insert_return_statement = ( ) ->  Return(@)
il.VirtualOperation2::insert_return_statement = ( ) ->  new il.Begin(new il.Return())

il.Atom::javascriptize = (env, compiler) ->  [@]
il.MacroArgs::javascriptize = (env, compiler) ->
  exps = []
  args = []
  for arg in @item
    exps1 = arg.javascriptize(env, compiler)
    exps += exps1[..-1]
    args.push(exps1[-1])
    exps.push(MacroArgs((args)))
  return (exps)
il.Return::javascriptize = (env, compiler) ->
  if @args.length==1 and isinstance(@args[0], Begin)
    return Begin(@args[0].statements[..-1]+[Return(@args[0].statements[-1])]).javascriptize(env, compiler)
  else if @args.length==1 and isinstance(@args[0], If)
    return If(@args[0].test, Return(@args[0].then), Return(@args[0].else_)).javascriptize(env, compiler)
  [exps, args] = javascriptize_args(@args, env, compiler)
  exps+[new @constructor(args...)]
il.Try::javascriptize = (env, compiler) ->
  test = @test.javascriptize(env, compiler)
  body = @body.javascriptize(env, compiler)
  test[..-1]+[Try(test[-1], begin(body...))]
il.Begin::javascriptize = (env, compiler) ->
  result = []
  for exp in @statements
    exps2 = exp.javascriptize(env, compiler)
    result += exps2
  return result
il.PassStatement::javascriptize = (env, compiler) ->  [@]
il.Nil::javascriptize = (env, compiler) ->  [@]
il.Lamda::javascriptize = (env, compiler) ->
  if @has_javascriptized then return [@name]
  @has_javascriptized = true
  body_exps = @body.javascriptize(env, compiler)
  [@make_make_new(@params, il.begin(body_exps...))]
il.EqualCont::javascriptize = (env, compiler) ->  [@]
il.RulesDict::javascriptize = (env, compiler) ->  [@]
il.MacroLamda::javascriptize = (env, compiler) ->
  body_exps = @body.javascriptize(env, compiler)
  global_vars = @find_assign_lefts()-set(@params)
  global_vars = set(x for x in global_vars when isinstance(x, Var)  and not isinstance(x, LocalVar)  and not isinstance(x, SolverVar))
  if global_vars
    body_exps = [GlobalDecl(global_vars)]+body_exps
    return [MacroFunction(Lamda(@params, begin(body_exps...)))]
il.MacroRules::javascriptize = (env, compiler) ->
  body_exps = @body.javascriptize(env, compiler)
  global_vars = @find_assign_lefts()-set(@params)
  global_vars = set()
  for x in global_vars
    if isinstance(x, Var) and not isinstance(x, LocalVar)  and not isinstance(x, SolverVar)
      global_vars.add(x)
  if global_vars
    body_exps = [GlobalDecl(global_vars)]+body_exps
  if not body_has_any_statemen
    return [MacroRulesFunction(@make_make_new(@params, begin(body_exps...)))]
  else
  name = compiler.new_var(LocalVar('fun'))
  body = begin(body_exps...).insert_return_statement()
  return [new il.Function(name, @params, body), MacroRulesFunction(name)]
il.Apply::javascriptize = (env, compiler) ->
  exps = @caller.javascriptize(env, compiler)
  caller = exps[-1]
  exps = exps[..-1]
  exps2 = javascriptize_args(@args, env, compiler)
  return exps+exps2+[new @constructor(caller,args)]
il.ExpressionWithCode::javascriptize = (env, compiler) ->
  exps = @fun.javascriptize(env, compiler)
  [ExpressionWithCode(@exp, exps[0])]
il.Var::javascriptize = (env, compiler) ->  [@]
il.LogicVar::javascriptize = (env, compiler) -> [@]
il.Assign::javascriptize = (env, compiler) ->
  if not @var1.name.startswith('solver.')
    if isinstance(@exp, Function)
      @exp.name = @var1
    fun = @exp
  else if isinstance(@exp, Lamda) and not isinstance(@exp, MacroLamda)
    fun = Function(@var1, @exp.params, @exp.body)
  else
    fun = None
  if fun isnt None
    result = fun.javascriptize(env, compiler)
    if isinstance(result[0][-1], Var)
      result = [result[0][..-1], result[1]]
    return result
  exps = @exp.javascriptize(env, compiler)
  [exps[..-1]+[Assign(@var1, exps[-1])], true]
il.AssignFromList::javascriptize = (env, compiler) ->
  value_exps = @value.javascriptize(env, compiler)
  return value_exps[..-1]+[AssignFromList((@vars+[value_exps[-1]])...)]
il.If::javascriptize = (env, compiler) ->
  test = @test.javascriptize(env, compiler)
  then_ = @then_.javascriptize(env, compiler)
  else_ = @else_.javascriptize(env, compiler)
  if_ = new il.If(test[test.length-1], il.begin(then_...), il.begin(else_...))
  test[...test.length-1].concat([if_])
il.While::javascriptize = (env, compiler) ->
  test = @test.javascriptize(env, compiler)
  body = @body.javascriptize(env, compiler)
  test[..-1]+[While(test[-1], begin(body...))]
il.For::javascriptize = (env, compiler) ->
  var1 = @var1.javascriptize(env, compiler)
  range = @range.javascriptize(env, compiler)
  body = @body.javascriptize(env, compiler)
  return [For(var1[-1], range[-1], begin(body...))]
il.BinaryOperation::javascriptize = (env, compiler) ->  [@]
il.BinaryOperationApply::javascriptize = (env, compiler) ->
  [exps, args] = javascriptize_args(@args, env, compiler)
  exps+[new @constructor(@caller, args)]
il.VirtualOperation::javascriptize = (env, compiler) ->
  [exps, args] = javascriptize_args(@args, env, compiler)
  exps+new @constructor(args...)
il.Deref::javascriptize = (env, compiler) ->
  exps = @item.javascriptize(env, compiler)
  exps[..-1]+[new @constructor(exps[-1])]
il.EvalExpressionWithCode::javascriptize = (env, compiler) ->
  exps = @item.javascriptize(env, compiler)
  return exps[..-1]+[new @constructor(exps[-1])]
il.Len::javascriptize = (env, compiler) ->
  exps = @item.javascriptize(env, compiler)
  exps[..-1]+[new il.Len(exps[-1])]
il.In::javascriptize = (env, compiler) ->
  exps1 = @item.javascriptize(env, compiler)
  exps2 = @container.javascriptize(env, compiler)
  exps1[..-1]+exps2[..-1]+[In(exps1[-1], exps2[-1])]
il.GetItem::javascriptize = (env, compiler) ->
  container_exps = @container.javascriptize(env, compiler)
  index_exps = @index.javascriptize(env, compiler)
  container_exps[..-1]+index_exps[..-1]+[GetItem(container_exps[-1], index_exps[-1])]
il.ListAppend::javascriptize = (env, compiler) ->
  container_exps = @container.javascriptize(env, compiler)
  value_exps = @value.javascriptize(env, compiler)
  container_exps[..-1]+value_exps[..-1]+[ListAppend(container_exps[-1], value_exps[-1])]
il.PushCatchCont::javascriptize = (env, compiler) ->
  tag_exps = @tag.javascriptize(env, compiler)
  cont_exps = @cont.javascriptize(env, compiler)
  tag_exps[..-1]+cont_exps[..-1]+[PushCatchCont(tag_exps[-1], cont_exps[-1])]
il.SetBinding::javascriptize = (env, compiler) ->
  var1 = @var1.item if isinstance(@var1, Deref) else @var1
  var_exps = [var1]
  value_exps = @value.javascriptize(env, compiler)
  var_exps[..-1]+value_exps[..-1]+[SetBinding(var_exps[-1], value_exps[-1])]
il.FindCatchCont::javascriptize = (env, compiler) ->
  tag_exps = @tag.javascriptize(env, compiler)
  tag_exps[..-1]+[FindCatchCont(tag_exps[-1])]
il.IsMacro::javascriptize = (env, compiler) ->
  exps = @item.javascriptize(env, compiler)
  exps[..-1]+[new @constructor(exps[-1])]

il.Atom::code_size = ( ) ->  1
il.Try::code_size = ( ) ->  3 + @test.code_size() + @body.code_size()
il.Tuple::code_size = ( ) ->  sum([x.code_size() for x in @item])
il.MacroArgs::code_size = ( ) ->  sum([x.code_size() for x in @item])
il.Return::code_size = ( ) ->  sum([code_size(x) for x in @args])
il.Begin::code_size = ( ) ->  1
il.PassStatement::code_size = ( ) ->  0
il.Nil::code_size = ( ) ->  0
il.Lamda::code_size = ( ) ->  @body.code_size()+@params.length+2
il.EqualCont::code_size = ( ) ->  1
il.Apply::code_size = ( ) ->  @caller.code_size()+sum([x.code_size() for x in @args])
il.ExpressionWithCode::code_size = ( ) ->  1
il.Var::code_size = ( ) ->  1
il.Assign::code_size = ( ) ->  code_size(@exp)+2
il.AssignFromList::code_size = ( ) ->  1
il.If::code_size = ( ) ->  3 + @test.code_size() + @then_.code_size() + @else_.code_size()
il.PseudoElse::code_size = ( ) ->  0
il.Cons::code_size = ( ) ->  1
il.While::code_size = ( ) ->  3 + @test.code_size() +@body.code_size()
il.For::code_size = ( ) ->  3 + @var1.code_size() + @range.code_size() + @body.code_size()
il.BinaryOperation::code_size = ( ) ->  1
il.BinaryOperationApply::code_size = ( ) ->  @caller.code_size()+sum([x.code_size() for x in @args])
il.VirtualOperation::code_size = ( ) ->  1
il.Deref::code_size = ( ) ->  1
il.EvalExpressionWithCode::code_size = ( ) ->  1
il.Len::code_size = ( ) ->  1
il.In::code_size = ( ) ->  1
il.GetItem::code_size = ( ) ->  1
il.ListAppend::code_size = ( ) ->  1
il.PushCatchCont::code_size = ( ) ->  1
il.SetBinding::code_size = ( ) ->  1
il.FindCatchCont::code_size = ( ) ->  1
il.IsMacro::code_size = ( ) ->  1

il.Atom::to_code = (compiler) ->  @item.toString()
il.Symbol::to_code = (compiler) ->  @item
il.Klass::to_code = (compiler) ->  @item
il.PyFunction::to_code = (compiler) ->  @item.func_name
il.Tuple::to_code = (compiler) ->
  if @item.length!=1 then  "(#{join(', ', [x.to_code(compiler) for x in @item])})"
  else  "(#{@item[0].to_code(compiler)}, )"
il.MacroArgs::to_code = (compiler) ->
  if @item.length!=1
    return "(#{join(', ', [x.to_code(compiler) for x in @item])})"
  else return "(#{@item[0].to_code(compiler)}, )"
il.Return::to_code = (compiler) ->   "return #{join(', ', [x.to_code(compiler) for x in @args])}"
il.Yield::to_code = (compiler) ->   "pyield #{join(', ', x.to_code(compiler) for x in @args)}"
il.Try::to_code = (compiler) ->  "try\n#{compiler.indent(@test.to_code(compiler))}\ncatch e\n#{compiler.indent(@body.to_code(compiler))}\n"
il.Begin::to_code = (compiler) ->   '\n'.join([x.to_code(compiler) for x in @statements])
il.PassStatement::to_code = (compiler) ->  'pass'
il.Nil::to_code = (compiler) ->  'nil'
il.Lamda::to_code = (compiler) -> "function (#{join(', ', (x.to_code(compiler) for x in @params))}) { "  + @body.to_code(compiler)+";}"
il.RulesLamda::to_code = (compiler) -> "lambda #{@params[0].to_code(compiler)}, #{@params[1].to_code(compiler)}: " + @body.to_code(compiler)
il.EqualCont::to_code = (compiler) ->  'lambda v:v'
il.RulesDict::to_code = (compiler) ->
  if @to_coded then  return @name.to_code(compiler)
  else
    @to_coded = true
    ss = "#{arity}: #{funcname.to_code(compiler)}" for arity, funcname in @arity_body_map.items()
    return "{#{join(', ', ss)}}"
il.MacroFunction::to_code = (compiler) ->  "MacroFunction(#{@fun.to_code(compiler)})"
il.MacroFunction::to_code = (compiler) ->  "MacroRules(#{@fun})"
il.GlobalDecl::to_code = (compiler) ->  "global #{join(', ', x.to_code(compiler) for x in @args)}"
il.Apply::to_code = (compiler) ->
  if isinstance(@caller, Lamda)
    "(#{@caller.to_code(compiler)})(#{join(', ', x.to_code(compiler) for x in @args)})"
  else
    @caller.to_code(compiler) + "(#{join(', ', [x.to_code(compiler) for x in @args])})"
il.ExpressionWithCode::to_code = (compiler) ->  "ExpressionWithCode((#{@exp.to_code(compiler)}), (#{ @fun.to_code(compiler)}))"
il.Var::to_code = (compiler) ->  @name
il.LogicVar::to_code = (compiler) ->   "LogicVar('#{@name}')"
il.DummyVar::to_code = (compiler) ->   "DummyVar('#{@name}')"
il.Assign::to_code = (compiler) ->
  if isinstance(@exp, RulesDict) and @exp.to_coded then ''
  else "#{@var1.to_code(compiler)} = #{@exp.to_code(compiler)}"
il.AssignFromList::to_code = (compiler) ->  "#{join(', ', [x.to_code(compiler) for x in @vars])} = #{@value.to_code(compiler)}"
il.If::to_code = (compiler) ->
  result = "if #{@test.to_code(compiler)}: \n#{compiler.indent(@then_.to_code(compiler))}\n"
  if @else_ isnt il.pseudo_else
    result += "else\n#{compiler.indent(@else_.to_code(compiler))}\n"
  result
#        "(#{@then_.to_code(compiler)} if #{@test.to_code(compiler)} \nelse #{ @else_.to_code(compiler)})"
il.PseudoElse::to_code = (compiler) ->  ''
il.Cons::to_code = (compiler) ->  "Cons(#{@head.to_code(compiler)}, #{@tail.to_code(compiler)})"
il.While::to_code = (compiler) ->  "while #{@test.to_code(compiler)}:\n#{compiler.indent(@body.to_code(compiler))}\n"
il.For::to_code = (compiler) ->  "for #{@var1.to_code(compiler)} in #{@range.to_code(compiler)}:\n#{compiler.indent(@body.to_code(compiler))}\n"
il.BinaryOperation::to_code = (compiler) ->  @operator
il.BinaryOperationApply::to_code = (compiler) ->
  if not @caller.operator[0].isalpha()
    return "(#{@args[0].to_code(compiler)})#{ @caller.to_code(compiler)}(#{@args[1].to_code(compiler)})"
  else"(#{@args[0].to_code(compiler)}) #{@caller.to_code(compiler)} (#{ @args[1].to_code(compiler)})"
il.VirtualOperation::to_code = (compiler) ->
  if isinstance(@code_format, String)
    if @constructor.arity==0 then @code_format
    else if @constructor.arity!=-1
      @code_format % (x.to_code(compiler) for x in @args)
    else @code_format % (join(', ', [x.to_code(compiler) for x in @args]))
  else @code_format(compiler)
il.Deref::to_code = (compiler) ->   "deref(#{@item.to_code(compiler)}, solver.bindings)"
il.EvalExpressionWithCode::to_code = (compiler) ->   "(#{@item.to_code(compiler)}).fun()"
il.Len::to_code = (compiler) ->   "#{@item.to_code(compiler)}.length"
il.In::to_code = (compiler) ->   "(#{@item.to_code(compiler)}) in (#{@container.to_code(compiler)})"
il.GetItem::to_code = (compiler) ->   "(#{@container.to_code(compiler)})[#{@index.to_code(compiler)}]"
il.ListAppend::to_code = (compiler) ->   "#{@container.to_code(compiler)}.push(#{@value.to_code(compiler)})"
il.PushCatchCont::to_code = (compiler) ->  "solver.catch_cont_map.setdefault(#{@tag}, []).push(#{@cont})"
il.SetBinding::to_code = (compiler) ->  "solver.bindings[#{@var1.to_code(compiler)}] = #{ @value.to_code(compiler)}"
il.FindCatchCont::to_code = (compiler) ->  "solver.find_catch_cont.callOn(#{@tag})"
il.IsMacro::to_code = (compiler) ->   "isinstance(#{@item.to_code(compiler)}, Macro)"
il.IsMacroRules::to_code = (compiler) ->   "isinstance(#{item.to_code(compiler)}, MacroRules)"

il.Atom::free_vars = ( ) ->  set()
il.MacroArgs::free_vars = ( ) ->
  result = set()
  for x in @item then  result |= x.free_vars()
  return result
il.Return::free_vars = ( ) ->
  result = set()
  for x in @args then  result |= x.free_vars()
  return result
il.Begin::free_vars = ( ) -> set().mergeAt(exp.free_vars() for exp in @statements)
il.Lamda::free_vars = ( ) ->  @body.free_vars()-set(@params)
il.RulesDict::free_vars = ( ) ->
  result = set()
  for arity, body in @arity_body_map.items()
    result |= body.free_vars()
  return result
il.Apply::free_vars = ( ) ->
  result = @caller.free_vars()
  for exp in @args
    result |= exp.free_vars()
  return result
il.ExpressionWithCode::free_vars = ( ) ->  @fun.free_vars()
il.Var::free_vars = ( ) ->  set([@])
il.LogicVar::free_vars = ( ) ->  set()
il.Assign::free_vars = ( ) ->  @exp.free_vars()
il.AssignFromList::free_vars = ( ) ->
  result = set(@vars)
  result |= @value.free_vars()
  return result
il.If::free_vars = ( ) -> @test.free_vars().mergeAt(@then_.free_vars(), @else_.free_vars())
il.While::free_vars = ( ) ->  @test.free_vars() | @body.free_vars()
il.For::free_vars = ( ) ->  @var1.free_vars() | @range.free_vars() | @body.free_vars()
il.BinaryOperationApply::free_vars = ( ) -> set().mergeAt(arg.free_vars() for arg in @args)
il.VirtualOperation::free_vars = ( ) -> set().mergeAt(arg.free_vars() for arg in @args)
il.Deref::free_vars = ( ) ->  @item.free_vars()
il.EvalExpressionWithCode::free_vars = ( ) ->  @item.free_vars()
il.Len::free_vars = ( ) ->  @item.free_vars()
il.In::free_vars = ( ) -> @item.free_vars().unionAt(@container.free_vars())
il.GetItem::free_vars = ( ) -> @index.free_vars().unionAt(@container.free_vars())
il.ListAppend::free_vars = ( ) -> @value.free_vars().unionAt(@container.free_vars())
il.PushCatchCont::free_vars = ( ) -> set([catch_cont_map]).unionAt(@tag.free_vars()).unionAt(@cont.free_vars())
il.SetBinding::free_vars = ( ) ->  @value.free_vars()
il.FindCatchCont::free_vars = ( ) -> set([catch_cont_map]).unionAt(@tag.free_vars())
il.IsMacro::free_vars = ( ) ->  @item.free_vars()

il.Atom::bool = ( ) -> if @item then true  else false
il.Lamda::bool = ( ) ->  true
il.RulesDict::bool = ( ) ->  true
il.Apply::bool = ( ) ->  unknown
il.Var::bool = ( ) ->  unknown
il.AssignFromList::bool = ( ) ->  false
il.VirtualOperation::bool = ( ) ->  unknown
il.In::bool = ( ) ->
  if isinstance(@item, Atom)
    if isinstance(@container, Atom)
      return @item.value in @container.value
    else if isinstance(@container, RulesDict)
      return [@item.value, @container.arity_body_map]
  il.unknown
il.GetItem::bool = ( ) ->
  if isinstance(@index, Atom)
    if isinstance(@container, Atom)
      return Bool(bool(@container.value[@index.value]))
  else if isinstance(@container, RulesDict)
    return Bool(bool(@container.arity_body_map[@index.value]))
  il.unknown
il.ListAppend::bool = ( ) ->  false
il.PushCatchCont::bool = ( ) ->  false
il.SetBinding::bool = ( ) ->  false
il.FindCatchCont::bool = ( ) ->  false
il.IsMacro::bool = ( ) ->
  if isinstance(@item, Macro) then true
  else if isinstance(@item, Lamda) then false
  else thenn unknown
il.IsMacroRules::bool = ( ) ->
  if isinstance(@item, MacroRules) then true
  else if isinstance(@item, Lamda) then false
  else unknown

il.Atom::__hash__ = ( ) ->  hash(@item)
il.Lamda::__hash__ = ( ) ->  hash(id(@))
il.Var::__hash__ = ( ) ->  hash(@name)
il.BinaryOperation::__hash__ = ( ) ->  hash(@operator)
il.VirtualOperation::__hash__ = ( ) ->  hash(@constructor.name)

il.TRUE = new il.Bool(true)
il.FALSE = new il.Bool(false)
il.NULL = new il.Atom(null)

make_tuple  = (item) ->  new il.Tuple((element(x) for x in item)...)

il.Dict::macro_args = (item) ->  MacroArgs(item)

il.begin  = (exps...) ->
  result = []
  length = exps.length
  for e, i in exps
    if isinstance(e, il.Begin)
      result += e.statements
    else if _.isArray(e) and e.length is 0 then  continue
    else
      if e is il.NULL and i!=length-1 then continue
      else result.push(e)
  if result.length is 0 then return_statement
  else if result.length is 1 then result[0]
  else il.Begin(result)

il.Begin::remove = (exp) ->
    for i, stmt in enumerate(@statements)
      if stmt is exp then break
      else return @
    return begin((@statements[..i]+@statements[i+1..])...)

il.Lamda::make_new = (params, body) ->  new il.Lamda(params, body)
il.Clamda::make_new = (params, body) ->  new @constructor(params[0], body)
il.Done::make_new = (params, body) ->  new @constructor(@params[0])
il.CFunction::make_new = (params, body) ->  new @constructor(@name, params[0], body)

il.Lamda::callOn = (args...) ->  Apply(args)
il.RulesLamda::callOn = (args...) ->  Apply((element(x) for x in args))
il.Clamda::callOn = (arg) ->
  if arg.side_effects() then begin(Assign(@params[0], arg), @body)
  else
    bindings = {}
    bindings[@params[0]] = arg
    @body.subst(bindings)

il.EqualCont::callOn = (body) ->  body
il.Done::callOn = (args...) ->
  bindings = {}
  bindings[@params[0]] = args[0]
  @body.subst(bindings)
il.Var::callOn = (args...) ->  Apply(args)
il.BinaryOperation::callOn = (args...) ->  BinaryOperationApply(args)
il.VirtualOperation::callOn = (args...) ->  Apply(args)
il.FindCatchCont::callOn = (value) ->  Apply([value])

il.Lamda::optimize_apply = (env, compiler, args) ->
  #1. ((lambda () body))  =>  body
  if @params.length==0
    return @body.optimize(env, compiler)

  #2. (lamda x: ...x...)(y) => (lambda : ... y ...)()
  bindings = {}
  [new_params, new_args] = [[], []]
  for i, p in enumerate(@params)
    arg = args[i]
    if arg.side_effects()
      new_params += [p]
      new_args += [arg]
      continue
    else
      ref_count = compiler.ref_count.get(p, 0)
    if ref_count==0 then continue
    else if ref_count==1
      bindings[p] = arg
    else
      if arg.code_size()*ref_count>MAX_EXTEND_CODE_SIZE
        # a(...y...), and a is (lamda ...x...: ...x...),
        #then convert as above if code size is ok.
        new_params += [p]
        new_args += [arg]
      else
        bindings[p] = arg

  if new_params
    if bindings
      return Apply(@make_make_new(new_params, @body.subst(bindings).optimize(env, compiler)),
                   (arg.optimize(env, compiler) for arg in new_args))
    else
      if new_params.length!=@params.length
        Apply(@make_make_new(new_params, @body.subst(bindings).optimize(env, compiler)),
              (arg.optimize(env, compiler) for arg in new_args))
      else  Apply(@make_make_new(new_params, @body.optimize(env, compiler)),
                  optimize_args(new_args, env, compiler))
  else
    if bindings then @body.subst(bindings).optimize(env, compiler)
    else  @body.optimize(env, compiler)

il.RulesLamda::optimize_apply = (env, compiler, args) ->  Lamda.optimize_apply(env, compiler, args)

il.CFunction::optimize_apply = (env, compiler, args) ->
  new_env = env.extend()
  bindings = {}
  bindings[@params[0]] = args[0]
  body = @body.subst(bindings)
  body = body.optimize(new_env, compiler)
  result = CFunction(@name, @params[0], body)(il.NULL)
  return result

il.MacroLamda::optimize_apply = (env, compiler, args) ->
  #args  = (args[0], Tuple(*args[1:]))
  result = Lamda.optimize_apply(env, compiler, args)
  return result

il.MacroRules::optimize_apply = (env, compiler, args) ->
  result = Lamda.optimize_apply(env, compiler, args)
  return result

il.Clamda::optimize_apply = (env, compiler, args) ->
  [param, arg] = [@params[0], args[0]]
  if not arg.side_effects()
    body = @body.subst({param: arg}).optimize(env, compiler)
    return body
  else
    ref_count = compiler.ref_count.get(param, 0)
    if ref_count==0 then begin(arg, @body).optimize(env, compiler)
    else begin(Assign(param, arg), @body).optimize(env, compiler)

il.LogicVar::deref = (bindings) ->
  # todo:
  # how to shorten the binding chain? need to change solver.fail_cont.
  # deref(solver) can help
  x = @
  while 1
    next = bindings[x]
    if not isinstance(next, LogicVar) or next==x
      return next
    else  x = next

il.Assign::right_value = ( ) ->  @exp

il.pass_statement = new il.PassStatement()
il.nil = new il.Nil()

il.lamda  = (params, body...) ->  new il.Lamda(params, begin(body...))
il.clamda  = (v, body...) -> new il. Clamda(v, il.begin(body...))
il.equal_cont = new il.EqualCont()
il.cfunction  = (name, v, body...) ->  new il.CFunction(name, v, begin(body...))
if_  = (test, then_, else_) -> new il.If(element(test), element(then_), element(else_))
il.if2  = (test, then_) ->  new il.If(test, then_, il.pseudo_else)
il.pseudo_else = new il.PseudoElse()
il.while_  = (test, exps...) -> new il.While(test, begin([x for x in exps]...))
il.for_  = (var1, range, exps...) -> new il.For(element(var1), element(range), begin([x for x in exps]...))

il.type_map = dict("int", il.Integer,    "float", il.Float, "str",il.String, "unicode", il.String,
                   "Array",il.List, "dict",il.Dict,
                   "bool",il.Bool,
                   (typeof undefined), il.Atom
                  )

il.addop = new il.BinaryOperation('add', '+', false)
il.subop = new il.BinaryOperation('sub', '-', false)
il.mulop = new il.BinaryOperation('mul', '*', false)
il.divop = new il.BinaryOperation('div', '/', false)
il.isnotop = new il.BinaryOperation('isnot', 'isnt', false)
il.andop = new il.BinaryOperation('and', '&&', false)
il.orop = new il.BinaryOperation('or', '||', false)

il.ltop = new il.BinaryOperation('Lt', '<', false)
il.leop = new il.BinaryOperation('Le', '<=', false)
il.eqop = new il.BinaryOperation('Eq', '==', false)
il.neop = new il.BinaryOperation('Ne', '!=', false)
il.geop = new il.BinaryOperation('Ge', '>=', false)
il.gtop = new il.BinaryOperation('Gt', '>', false)

il.catch_cont_map = new il.SolverVar('catch_cont_map')

il.vop = vop  = (name, arity, code_format, has_side_effects) ->
  class Vop extends il.VirtualOperation
    name: name
    __name__: name
    arity: arity
    code_format: code_format
    has_side_effects: has_side_effects
  Vop


il.vop2 = vop2  = (name, arity, code_format, has_side_effects) ->
  class Vop extends il.VirtualOperation2
    __name__:name
    name: name
    arity: arity
    code_format: code_format
    has_side_effects: has_side_effects
  return Vop

il.AddAssign = (var1, value) ->  Assign(var1, BinaryOperationApply(add, [var1, value]))

Call_to_code  = (compiler) ->  "(#{@args[0].to_code(compiler)})(#{join(', ', [x.to_code(compiler) for x in @args[1..]])})"
il.Call = vop('Call', -1, Call_to_code, true)

il.Attr = vop('Attr', 2, '%s.%s', false)

AttrCall_to_code  = (compiler) ->  "#{@args[0].to_code(compiler)}(#{join(', ', [x.to_code(compiler) for x in @args[1..]])})"
il.AttrCall = vop('AttrCall', -1, AttrCall_to_code, true)

il.SetItem = vop2('SetItem', 3, '(%s)[%s] = %s', true)
#  SetItem(item, key, value) ->  Assign(GetItem(item, key), value)

il.Slice2 = vop('Slice2', 2, '%s:%s', false)

il.Not = vop('Not', 1, "not %s", false)

il.Isinstance = vop('Isinstance', 2, "isinstance(%s, %s)", false)

empty_list = new il.List([])

empty_dict = new il.Dict({})

il.RaiseTypeError = vop2('RaiseTypeError', 1, 'throw new %s', true)

il.RaiseException = vop2('RaiseException', 1, 'throw new %s', true)

QuoteItem_to_code  = (compiler) ->  "#{@args[0]}"
il.QuoteItem = vop('QuoteItem', 1, QuoteItem_to_code, false)

il.UnquoteSplice = vop('UnquoteSplice', 1, "UnquoteSplice(%s)", false)

il.MakeTuple = vop('MakeTuple', 1, '(%s)', false)

il.Cle = vop('Cle', 3, '(%s) < = (%s) < = (%s)', false)

il.Cge = vop('Cge', 3, '(%s) > = (%s) > = (%s)', false)

il.failcont = new il.SolverVar('fail_cont')

il.SetFailCont  = (cont) ->  new il.Assign(failcont, cont)

append_failcont  = (compiler, exps...) ->
  v =  compiler.new_var(ConstLocalVar('v'))
  fc = compiler.new_var(ConstLocalVar('fc'))
  return Begin(
                Assign(fc, failcont),
                SetFailCont(
                             clamda(v,
                                    SetFailCont(fc),
                                    begin(exps...),
                                    fc(v)))
              )

il.cut_cont = new il.SolverVar('cut_cont')

SetCutCont  = (cont) ->  new il.Assign(cut_cont, cont)

il.cut_or_cont = new il.SolverVar('cut_or_cont')

il.SetCutOrCont  = (cont) ->  new il.Assign(cut_or_cont, cont)

il.IsLogicVar = vop('IsLogicVar', 1, 'isinstance(%s, LogicVar)', false)

il.DelBinding = vop2('DelBinding', 1, 'del solver.bindings[%s]', true)
il.DelItem = vop2('DelItem', 2, 'del %s[%s]', true)

il.GetValue = vop('GetValue', 1, 'get_value(%s, {}, solver.bindings)', false)

il.parse_state = new il.SolverVar('parse_state')
SetParseState  = (state) ->  new il.Assign(parse_state, state)

il.Unify = vop('Unify', 2, 'solver.unify(%s, %s)', false)
il.Nil = vop('Nil', 0, 'nil', false)
il.nil = new il.Nil()

il.bindings = new il.SolverVar('bindings')
SetBindings  = (bindings1) ->  new il.Assign(bindings, bindings1)

il.ConsHead = vop('ConsHead', 1, '(%s).head', false)
il.ConsTail = vop('ConsTail', 1, '(%s).tail', false)

il.Optargs = vop('Optargs', 1, '*%s', false)

il.Continue = vop('Continue', 0, "continue\n", false)
continue_ = new il.Continue()

il.Prin = vop2('Prin', 1, "print %s,", true)
il.PrintLn = vop2('PrintLn', 1, "print %s", true)

il.DelListItem = vop2('DelListItem', 2, 'del %s[%s]', true)

il.MakeList = vop('MakeList', 1, '[%s]', false)

il.Copy = vop('Copy', 1, '(%s).copy()', false)

il.Assert = vop('Assert', 1, 'assert %s', false)
il.Int = new il.Symbol('int')

Format_to_code  = (compiler) ->  "#{@args[0].to_code(compiler)}%#{join(', ', x.to_code(compiler) for x in @args[1..])}"
il.Format = vop('Format', -1,Format_to_code, false)

Concat_to_code  = (compiler) ->  '%s'%''.join([arg.to_code(compiler) for arg in @args])
il.Concat = vop('Concat', -1, Concat_to_code, false)

Format_to_code  = (compiler) ->  "file(#{@args[0].to_code(compiler)}, #{join(', ', x.to_code(compiler) for x in @args[1...])})"

il.OpenFile = vop('OpenFile', -1, Format_to_code, true)

il.CloseFile = vop('CloseFile', 1, "%s.close()", true)
il.ReadFile = vop('ReadFile', 1, '%s.read()', true)
il.Readline = vop('ReadLine', 1, '%s.readline()', true)
il.Readlines = vop('Readlines', 1, '%s.readlines()', true)
il.WriteFile = vop('WriteFile', 2, '%s.write(%s)', true)
