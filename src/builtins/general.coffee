solve = require "../../src/solve"
fun = solve.fun
special = solve.special

exports.print_ = fun('print_', (args...) -> console.log(args...))
exports.add = fun('add', (x, y) -> x+y)
exports.sub = fun('sub', (x, y) -> x-y)
exports.mul = fun('mul', (x, y) -> x*y)
exports.div = fun('div', (x, y) -> x/y)
exports.mod = fun('mod', (x, y) -> x%y)

exports.and_ = fun('and_', (x, y) -> x and y)
exports.or_ = fun('or_', (x, y) -> x or y)
exports.not_ = fun('not_', (x) -> not x)
exports.lshift = fun('lshift', (x, y) -> x<<y)
exports.rshift = fun('rshift', (x, y) -> x>>y)
exports.bitand = fun('bitand', (x, y) -> x&y)
exports.bitor = fun('bitor', (x, y) -> x|y)
exports.bitnot = fun('bitnot', (x) -> ~x)

#exports.eq = fun('eq', (x, y) -> x==y)
#exports.ne = fun('ne', (x, y) -> x!=y)
#exports.lt = fun('lt', (x, y) -> x<y)
#exports.le = fun('le', (x, y) -> x<=y)
#exports.ge = fun('ge', (x, y) -> x>=y)
#exports.gt = fun('gt', (x, y) -> x>y)

# more optimized version
exports.eq = special('eq', (solver, cont, x, y) ->
  solver.cont(x, (x1, solver) ->
    solver.cont(y, (y1, solver) -> cont(x1==y1, solver))(null, solver)))

exports.ne = special('ne', (solver, cont, x, y) ->
  solver.cont(x, (x1, solver) -> solver.cont(y, (y1, solver) -> cont(x1!=y1, solver))(null, solver)))

exports.lt = special('lt', (solver, cont, x, y) ->
  solver.cont(x, (x1, solver) ->
    solver.cont(y, (y1, solver) -> cont(x1<y1, solver))(null, solver)))

exports.le = special('le', (solver, cont, x, y) ->
  solver.cont(x, (x1, solver) -> solver.cont(y, (y1, solver) -> cont(x1<=y1, solver))(null, solver)))

exports.gt = special('gt', (solver, cont, x, y) ->
  solver.cont(x, (x1, solver) ->
    solver.cont(y, (y1, solver) -> cont(x1>y1, solver))(null, solver)))

exports.ge = special('ge', (solver, cont, x, y) ->
  solver.cont(x, (x1, solver) -> solver.cont(y, (y1, solver) -> cont(x1>=y1, solver))(null, solver)))

# Because not using vari.bind, these are not saved in solver.trail and so it can NOT be restored in solver.failcont
# EXCEPT the vari has been in solver.trail in the logic branch before.
exports.inc = special('inc', (solver, cont, vari) ->
  (v, solver) -> (vari.binding++; cont(vari.binding, solver)))

exports.inc2 = special('inc2', (solver, cont, vari) ->
  (v, solver) -> (vari.binding++; vari.binding++; cont(vari.binding, solver)))

exports.dec = special('dec', (solver, cont, vari) ->
  (v, solver) -> (vari.binding--; cont(vari.binding, solver)))

exports.dec2 = special('dec2', (solver, cont, vari) ->
  (v, solver) -> (vari.binding--; vari.binding--; cont(vari.binding, solver)))

###
exports.format = new exports.BuiltinFunction('format', il.Format)

@special
def between(compiler, cont, lower, upper, mid):
  lower1 = compiler.new_var(il.ConstLocalVar('lower'))
  upper1 = compiler.new_var(il.ConstLocalVar('upper'))
  mid1 = compiler.new_var(il.ConstLocalVar('mid'))
  fc = compiler.new_var(il.ConstLocalVar('fc'))
  i = compiler.new_var(il.Var('i'))
  v = compiler.new_var(il.ConstLocalVar('v'))
  return lower.cps(compiler, il.clamda(lower1,
    upper.cps(compiler, il.clamda(upper1,
    mid.cps(compiler, il.clamda(mid1,
        il.If(il.IsLogicVar(mid1),
          il.begin(
            il.Assign(i, lower1),
            il.Assign(fc, il.failcont),
            il.SetFailCont(il.clamda(v, 
              il.If(il.Eq(i, upper1),
                il.Begin((
                  il.Assign(il.failcont, fc),
                  fc(il.FALSE))),
                il.Begin((
                  il.AddAssign(i, il.Integer(1)),
                  il.SetBinding(mid1, i),
                  cont(il.TRUE)))))),                
            il.SetBinding(mid1, lower1),
            cont(il.TRUE)),
          il.If(il.Cle(lower1, mid1, upper1),
            cont(il.TRUE),
            il.failcont(il.FALSE)))))
    ))))    

'''
@binary('getattr', '.')
def getattr(x, y): return operator.getattr(x, y)  
@binary('getitem', '[ ]')
def getitem(x, y): return operator.getitem(x, y)

@set_type(type.Function(type.atom))
@binary('add', '+', is_global=True)
def add(x, y): return operator.add(x, y)  

@builtin.function('iter')
def iter(x): return operator.iter(x) 
@unary('neg', 'neg')
def neg(x): return operator.neg(x)  
@unary('pos', '+')
def pos(x): return operator.pos(x)  
@builtin.function('abs')
def abs(x): return operator.abs(x)  

format = BuiltinFunction('format', il.Format)
concat = BuiltinFunction('concat', il.Concat)

open_file = BuiltinFunction('open', il.OpenFile)
close_file = BuiltinFunction('close', il.CloseFile)
read = BuiltinFunction('read', il.ReadFile)
readline = BuiltinFunction('readline', il.Readline)
readlines = BuiltinFunction('readlines', il.Readlines)

@special
def prin_(compiler, cont, argument):
  v = compiler.new_var(il.ConstLocalVar('v'))
  return argument.cps(compiler, 
           il.clamda(v, il.Prin(v), cont(il.NONE)))

def prin(*args):
  return prin_(concat(*args))

@special
def println_(compiler, cont, argument):
  v = compiler.new_var(il.ConstLocalVar('v'))
  return argument.cps(compiler, 
           il.clamda(v, il.PrintLn(v), cont(il.NONE)))

def println(*args):
  return println_(concat(*args))

@special
def write_(compiler, cont, file, argument):
  v1 = compiler.new_var(il.ConstLocalVar('v'))
  v2 = compiler.new_var(il.ConstLocalVar('v'))
  return file.cps(compiler, 
    il.clamda(v1, argument.cps(compiler, 
           il.clamda(v2, il.WriteFile(v1, v2), cont(il.NONE)))))

def write(file, *args):
  return write_(file, concat(*args))
# analysing and construction sequences

@special
def contain(compiler, cont, container, member):
  container1 = compiler.new_var(il.ConstLocalVar('container'))
  container2 = compiler.new_var(il.ConstLocalVar('container'))
  member1 = compiler.new_var(il.ConstLocalVar('member'))
  member2 = compiler.new_var(il.ConstLocalVar('member'))
  return container.cps(compiler, il.clamda(container1,
    il.Assign(container2, il.GetValue(container1)), 
    member.cps(compiler, il.clamda(member1, 
      il.Assign(member2, il.GetValue(member1)),
      il.If(il.In(member2, container2),
            cont(il.TRUE),
          il.failcont(il.FALSE))))))
    
@special
def length(compiler, cont, sequence):
  return sequence.cps(compiler, il.clamda(sequence1, 
    cont(il.Len(il.GetValue(sequence1)))))

def starstwith(x, y):
  try: x_startswith = x.startswith
  except: return x[:len(y)]== y
  return x_startswith(y)

def endswith(x, y):
  try: x_endswith = x.endswith
  except: return x[len(x)-len(y):]== y
  return x_endswith(y)

@special
def concat(compiler, cont, sequence1, sequence2, result):
  sequence1 = getvalue(sequence1, solver.env, {})
  sequence2 = getvalue(sequence2, solver.env, {})
  result = getvalue(result, solver.env, {})
  if isinstance(sequence1, Var):
    index = 0
    if isinstance(sequence2, Var):
      cont = solver.scont
      old_fcont = solver.fcont
      index_list =  (index for index in range(1, len(result)))
      @mycont(cont)
      def concat_cont(value, solver):
        try: index = index_list.next()
        except StopIteration: 
          solver.scont = old_fcont
          return
        if sequence1.unify(result[:index], solver) and\
               sequence2.unify(result[index:], solver):
          solver.scont = cont
          return result
      solver.scont = solver.fcont = concat_cont
      return True
    else:
      if endswith(result, sequence2):
        return sequence1.unify(result[:len(sequence2)], solver)
  else:
    if isinstance(sequence2, Var):
      if startswith(result, sequence1):
        return sequence2.unify(result[len(sequence1):], solver)
    else:
      return unify(result, sequence1+sequence2, solver)

@special
def subsequence(compiler, cont, sequence, before, length, after, sub):
  # sequence should be grounded.
  assert not isinstance(sequence, Var)
  sequence = deref(sequence, solver.env)
  before = deref(before, solver.env)
  length = deref(length, solver.env)
  after = deref(after, solver.env)
  sub = deref(sub, solver.env)
  if not isinstance(before, Var):
    if before<0 or before>=len(sequence): 
      solver.scont = solver.fcont
      return
  if not isinstance(length, Var):  
    if length<=0 or length>len(sequence):
      solver.scont = solver.fcont
      return
  if not isinstance(after, Var):
    if after<0 or after>len(sequence):
      solver.scont = solver.fcont
      return
  cont = solver.scont
  old_fcont = solver.fcont
  if not isinstance(sub, Var):
    if isinstance(before, Var): startbefore, stopbefore = 0, len(sequence)+1
    else: startbefore, stopbefore = before, before+1
    if unify(length, len(sub), solver):
      start  = [startbefore]
      @mycont(cont)
      def fcont(value, solver):
        if start[0]<stopbefore:
          start[0] = sequence.find(sub, start[0])
          if start[0]<0: 
            solver.scont = old_fcont
            return
          start[0] += 1
          if unify(before, start[0]-1, solver) and\
               unify(after, start[0]-1+len(sub), solver):
            solver.scont = cont
            return length
        else:
          solver.scont = old_fcont
          return
      solver.scont = solver.fcont = fcont
      return start[0]
  else:
    if not isinstance(before, Var) \
       and not isinstance(length, Var)\
       and not isinstance(after, Var):
      if start+length!=after: 
        solver.scont = old_fcont
        return
      if sub.unify(sequence[before:after], solver):
        return sequence[before:after]
    elif not isinstance(before, Var) and  not isinstance(length, Var):
      if before+length>len(sequence): 
        solver.scont = old_fcont
        return
      if sub.unify(sequence[before:after], solver) and\
         after.unify(before+length, solver):
          return sequence[before:before+length]
    elif not isinstance(length, Var) and  not isinstance(after, Var):
      if after-length<0: 
        solver.scont = old_fcont
        return
      if sub.unify(sequence[after-length:after], solver) and\
         length.unify(length, solver):
        return sequence[after-length:after:after]
    elif not isinstance(before, Var) and  not isinstance(after, Var):
      if sub.unify(sequence[before:after], solver) and\
         length.unify(length, solver):
        return sequence[after-length:after:after]
    elif not isinstance(before, Var):
      leng_list = (leng for leng in range(1, len(sequence)-before+1))
      @mycont(old_fcont)
      def cont1(value, solver):
        try:
          leng = leng_list.next()
          if sub.unify(sequence[before:before+leng], solver) and\
             length.unify(leng, solver) and\
             after.unify(before+leng, solver):
            solver.scont = cont
            return sequence[before:before+leng]
        except StopIteration:
          solver.scont = old_fcont
      solver.scont = cont1
    elif not isinstance(after, Var):
      leng_list = (leng for leng in range(1, after))
      @mycont(old_fcont)
      def cont1(value, solver):
        try:
          leng = leng_list.next()
          if sub.unify(sequence[after-leng+1:after], solver) and\
           length.unify(leng, solver) and\
           before.unify(after-leng+1, solver):
            solver.scont = cont
            return sequence[before:after]
        except StopIteration:
          solver.scont = old_fcont
      solver.scont = cont1
    elif not isinstance(length, Var):
      start_list = (start for start in range(len(sequence)-length))
      @mycont(old_fcont)
      def cont1(value, solver):
        try:
          start = start_list.next()
          if sub.unify(sequence[start:start+length], solver) and\
             before.unify(start, solver) and\
             after.unify(start+length, solver):
            solver.scont = cont
            return sequence[start:start+length]
        except StopIteration:
          solver.scont = old_fcont
      solver.scont = cont1
    else:
      start_leng_list = ((start, leng) for start in range(len(sequence))
                                   for leng in range(1, len(sequence)-start+1))
      @mycont(old_fcont)
      def cont1(value, solver):
        try:
          start, leng = start_leng_list.next()
          if sub.unify(sequence[start:start+leng], solver) and\
             before.unify(start, solver) and\
             length.unify(leng, solver) and\
             after.unify(start+leng, solver):
            solver.scont = cont
            return sequence[start:start+leng]
        except StopIteration:
          solver.scont = old_fcont
      solver.scont = solver.fcont = cont1

@special
def conslist(*arguments): 
  return conslist(arguments)

@special
def pylist(*arguments): return list(arguments)

@special
def pytuple(*arguments): 
  return tuple(arguments)

@special
def head_list(head, tail): 
  if isinstance(tail, list): return [head]+tail
  else: return (head,)+tuple(tail)

@special
def list_tail(head, tail):
  if isinstance(head, list): return head+[tail]
  else: return head+(tail,)

@special
def index(sequence, index): 
  return sequence[index]

@special
def first(sequence): 
  return sequence[0]

@special
def left(sequence): 
  return sequence[1:]

@special
def second(sequence): 
  return sequence[1]

@special
def iter_next(iterator): 
  try: return iterator.next()
  except StopIteration:
##    iterator.close()
    raise exportsStopIteration

@special
def make_iter(iterator): 
  try: 
    iterator.next
    return iterator
  except AttributeError: 
    return iter(iterator)
  
@special
def to_list(item): 
  if isinstance(item, list) or isinstance(item, tuple): 
    return item
  return [item]

#items = BuiltinFunction('items', il.Items) #dict.items


  @special
  def unify(compiler, cont, x, y):
    return cps_convert_unify(x, y, compiler, cont)
  
  @special
  def notunify(compiler, cont, x, y):
    v = compiler.new_var(il.ConstLocalVar('v'))
    cont1 = il.clamda(v, il.failcont(il.FALSE))
    cont2 = il.clamda(v, cont(il.TRUE))
    return il.begin(il.SetFailCont(cont2),
                    cps_convert_unify(x, y, compiler, cont1))
  
  

  @special
  def derefence(compiler, cont, item):
    return cont(il.Deref(item.interlang()))
  
  @special
  def getvalue(compiler, cont, item):
    if isinstance(item, Var) or isinstance(item, Cons):
      return cont(il.GetValue(item.interlang()))
    else:
      return cont(item.interlang())
   
  @special
  def getvalue_default(compiler, cont, item, default=None):
    if default is None: default = NONE
    v = compiler.new_var(il.ConstLocalVar('v'))
    return il.begin(
      il.Assign(v, il.GetValue(item.interlang())),
      il.If(il.IsLogicVar(v),
            default.cps(compiler,cont),
            cont(v)))
  
  @special
  def isinteger(compiler, cont, item):
   return cont(il.Isinstance(item.interlang(), il.Symbol('int')))
  
  @special
  def isfloat(compiler, cont, item):
   return cont(il.Isinstance(item.interlang(), il.Symbol('float')))
  
  @special
  def isnumber(compiler, cont, item): 
    return cont(il.or_(il.Isinstance(item.interlang(), il.Symbol('int')),
                       il.Isinstance(item.interlang(), il.Symbol('float'))))
    
  @special
  def isstr(compiler, cont, item):
   return cont(il.Isinstance(item.interlang(), il.Symbol('str')))
  
  
  @special
  def istuple(compiler, cont, item):  
    return cont(il.Isinstance(item.interlang(), il.Symbol('tuple')))
  
  @special
  def islist(compiler, cont, item):
    return cont(il.Isinstance(item.interlang(), il.Symbol('list')))
    
  @special
  def isdict(compiler, cont, item): 
    return cont(il.Isinstance(item.interlang(), il.Symbol('dict')))
    
  '''
  def is_ground(term):
    if isinstance(term, Var): return False
    if isinstance(term, Cons): 
      if not is_ground(term.head): return False
      if not is_ground(term.tail): return False
    return True
    
  @builtin.macro('ground')
  def ground(solver, item):
    return is_ground(term.getvalue(item, solver.env, {}))
    
  @builtin.macro('ground_p', 'ground!')
  def ground_p(solver, item):
    if is_ground(term.getvalue(item, solver.env, {})): return True
    else: solver.scont = solver.fcont
    
  @builtin.macro()
  def setvalue(solver, var, value):
    # necessary to deref, see Colosure.deref for the reason
    if isinstance(var, ClosureVar): var = var.var 
    var = deref(var, solver.env)
    assert isinstance(var, Var)
    @mycont(cont)
    def setvalue_cont(value, solver):
      old = var.getvalue(solver.env, {})
      var.setvalue(value, solver.env)
      solver.scont = cont
      old_fcont = solver.fcont
      @mycont(old_fcont)
      def fcont(value, solver):
        var.setvalue(old, solver.env)
        solver.scont = old_fcont
      solver.fcont = fcont
      return True
    solver.scont = solver.cont(value, setvalue_cont)
    return True
  
  @builtin.macro('free')
  def free(solver, arg):
    return is_free(arg, solver.env)
  
  @builtin.macro('free_p', 'free!')
  def free_p(solver, arg):
    if is_free(arg, solver.env): return True
    else: solver.scont = solver.fcont
  
  @builtin.macro('bound')
  def bound(solver, var):
    assert(isinstance(var, Var))
    if isinstance(var, ClosureVar): var = var.var
    return solver.env[var] is not var
    
  @builtin.macro('bound_p', 'bound!')
  def bound_p(solver, var):
    assert(isinstance(var, Var))
    if isinstance(var, ClosureVar): var = var.var
    if solver.env[var] is not var: return True
    else: solver.scont = solver.fcont
      
  @builtin.macro('unbind')
  def unbind(solver, var):
    if isinstance(var, ClosureVar): var = var.var
    env = solver.env
    bindings = []
    while env is not solver.global_env:
      try: 
        bindings.append((env.bindings, env.bindings[var]))
      except: pass
      env = env.outer
    for b, _ in bindings:
      del b[var]
    old_fcont = solver.fcont
    @mycont(old_fcont)
    def fcont(value, solver):
      for b, v in bindings:
        b[var] = v
      solver.scont = old_fcont
    solver.fcont = fcont
    return True
    
  @builtin.macro('iscons_p', 'iscons!')
  def iscons_p(solver, arg):
    if isinstance(getvalue(arg, env, {}), Cons): return True
    else: solver.scont = solver.fcont
  
  @builtin.macro('iscons')
  def iscons2(solver, arg):
    return isinstance(arg, Cons)
  
  @builtin.function('cons_f', 'iscons?')
  def is_cons(x): return isinstance(x, Cons)
  
  @builtin.function('pycall')
  def pycall(fun, *args):  
    return fun(*args)
  
  @builtin.function('py_apply')
  def py_apply(fun, args):  
    return fun(*args)
  
  '''  
  
  from exports.term import deref, unify_list_rule_head, conslist, getvalue, match, Var
  from exports.term import rule_head_signatures
  from exports import builtin
  from exports.rule import Rule, RuleList
  from exports.special import UserFunction, UserMacro, make_rules
  
  # rule manipulation
  
  def remove_memo_arity(solver, rules, arity):
    removed = []
    for sign_state in solver.sign_state2cont:
      if sign_state[0][0]==rules and len(sign_state[0][1])==arity:
        removed.append(sign_state)
    for x in removed:
      del solver.sign_state2cont[x]
    removed = []
    for sign_state in solver.sign_state2results:
      if sign_state[0][0]==rules and len(sign_state[0][1])==arity:
        removed.append(sign_state)
    for x in removed:
      del solver.sign_state2results[x]
    
  @builtin.macro()
  def abolish(solver, rules, arity):
    rules = getvalue(rules, solver.env, {})
    if not isinstance(rules, UserFunction) and not isinstance(rules, UserMacro):
      raise ValueError(rules)
    arity = deref(arity, solver.cont)
    if arity not in rules.arity2rules:
      yield cont, rules.arity2rules
      return
    old_arity2rules = rules.arity2rules[arity]
    old_signature2rules = rules.signature2rules[arity]
    del rules.arity2rules[arity]
    del rules.signature2rules[arity]
    
    remove_memo_arity(solver, rules, arity)
    
    yield cont, rules.arity2rules
    rules.arity2rules[arity] = old_arity2rules
    rules.signature2rules[arity] = old_signature2rules
  
  @builtin.macro('assert')
  def assert_(solver, rules, head, body, klass=UserFunction):
    rules = getvalue(rules, solver.env, {})
    if not isinstance(rules, klass): raise ValueError(rules)
    arity = len(head)
    arity_rules = rules.arity2rules.setdefault(arity, [])
    index = len(arity_rules)
    arity_rules.append(Rule(head, body))
    for signature in rule_head_signatures(head):
      arity2signature = rules.signature2rules.setdefault(arity, {})
      arity2signature.setdefault(signature, set()).add(index)
    
    remove_memo_arity(solver, rules, arity)
    
    yield cont, arity_rules
    
    if index==0: 
      del rules.arity2rules[arity]
      del rules.signature2rules[arity]
    else:
      del arity_rules[-1]
      for signature in rule_head_signatures(head):
        arity2signature[signature].remove(index)
      if arity2signature[signature]==set(): del arity2signature[signature]
  
  @builtin.macro('asserta')
  def asserta(solver, rules, head, body, klass=UserFunction):
    rules = getvalue(rules, solver.env, {})
    if not isinstance(rules, klass): raise ValueError(rules)
    arity = len(head)
    arity_rules = rules.arity2rules.setdefault(arity, [])
    arity_signature = rules.signature2rules.setdefault(arity, {})
    arity_rules.insert(0, Rule(head, body))
    for sign in arity_signature:
      arity_signature[sign] = set([i+1 for i in arity_signature[sign]])
    for signature in rule_head_signatures(head):
      arity_signature.setdefault(signature, set()).add(0)
    
    remove_memo_arity(solver, rules, arity)
    
    yield cont, rules
    
    del arity_rules[0]
    if len(arity_rules)==1: 
      del rules.arity2rules[arity]
      del rules.signature2rules[arity]
    else:
      del arity_rules[0]
      for sign in arity_signature:
        arity_signature[sign] = set([i-1 for i in arity_signature[sign] if i!=0])
        if arity_signature[sign]==set(): del arity_signature[sign]
  
  def match_signatures(sign1, sign2):
    if sign1[0]!=sign2[0]: return False
    if len(sign1[1])!=len(sign2[1]): return False
    for s1, s2 in zip(sign1[1], sign2[1]):
      if s1[1]==Var or s2[1]==Var: continue
      if s1[1]!=s2[1]: return False
    return True
  
  def remove_memo_head(solver, rules, head):
    signatures = rule_head_signatures(head)
    removed = []
    for sign_state in solver.sign_state2cont:
      if match_signatures(sign_state[0], (rules, signatures)):
        removed.append(sign_state)
    for x in removed:
      del solver.sign_state2cont[x]
    removed = []
    for sign_state in solver.sign_state2results:
      if match_signatures(sign_state[0], (rules, signatures)):
        removed.append(sign_state)
    for x in removed:
      del solver.sign_state2results[x]
    
  @builtin.macro('append_def')
  def append_def(solver, rules, head, bodies, klass=UserFunction):
    rules = getvalue(rules, solver.env, {})
    if not isinstance(rules, klass): raise ValueError(rules)
    arity = len(head)
    arity_rules = rules.arity2rules.setdefault(arity, [])
    arity2signature = rules.signature2rules.setdefault(arity, {})
    index = length = len(arity_rules)
    arity_rules += [Rule(head, body) for body in bodies]
    new_indexes = set(range(length, length+len(bodies)))
    for signature in rule_head_signatures(head):
      indexes = arity2signature.setdefault(signature, set()) 
      indexes |= new_indexes
    
    remove_memo_head(solver, rules, head)
    
    yield cont, arity_rules
    
    if length==0: 
      del rules.arity2rules[arity]
      del rules.signature2rules[arity]
    else:
      del arity_rules[length:]
      for signature in rule_head_signatures(head):
        arity2signature[signature] -= new_indexes
        if arity2signature[signature]==set(): del arity2signature[signature]
  
  @builtin.macro('insert_def')
  def insert_def(solver, rules, head, bodies, klass=UserFunction):
    rules = getvalue(rules, solver.env, {})
    if not isinstance(rules, klass): raise ValueError(rules)
    arity = len(head)
    arity_rules = rules.arity2rules.setdefault(arity, [])
    arity2signature = rules.signature2rules.setdefault(arity, {})
    length = len(rules.arity2rules[arity])
    arity_rules = [Rule(head, body) for body in bodies]+rules.arity2rules[arity]
    bodies_length = len(bodies)
    new_indexes = set(range(bodies_length))
    for signature in rule_head_signatures(head):
      indexes = arity2signature.setdefault(signature, set())
      indexes |= new_indexes
        
    remove_memo_head(solver, rules, head)
    
    yield cont, arity_rules
    
    if length==0: 
      del rules.arity2rules[arity]
      del rules.signature2rules[arity]
    else:
      del arity_rules[:bodies_length]
      for signature in rule_head_signatures(head):
        arity2signature[signature] -= new_indexes
        if arity2signature[signature]==set(): del arity2signature[signature]
  
  def deepcopy(d):
    result = {}
    for k, v in d.items():
      result[k] = v.copy()
    return result
  
  # replace the rules which the head can match with.
  @builtin.macro('replace')
  def replace(solver, rules, head, body, klass=UserFunction):
    rules = getvalue(rules, solver.env, {})
    if not isinstance(rules, klass): raise ValueError(rules)
    arity = len(head)
    arity_rules = rules.arity2rules.setdefault(arity, [])
    old_arity_rules = None
    arity_signatures = rules.signature2rules.setdefault(arity, {})
    del_indexes = []
    index = 0
    while index<len(arity_rules):
      rule = arity_rules[index]
      if match(head, rule.head):
        if old_arity_rules is None:
          old_arity_rules = arity_rules[:]
          old_arity_signatures = deepcopy(arity_signatures)
          arity_rules[index] = Rule(head, body)
          for signature in rule_head_signatures(rule.head):
            arity_signatures[signature].remove(index)
          for signature in rule_head_signatures(head):
            arity_signatures.setdefault(signature, set()).add(index)
          index += 1
        else: 
          del arity_rules[index]
          del_indexes.append(index)
      else: index += 1 
        
    remove_memo_head(solver, rules, head)
    
    if old_arity_rules is not None:
      delta = 0
      modify_dict = {}
      for i in range(index):
        if i in del_indexes: delta += 1
        else: modify_dict[i] = i-delta
      for sign in arity_signatures:
        arity_signatures[sign] = set([modify_dict[i] for i in arity_signatures[sign] 
                                     if i not in del_indexes])
      
      yield cont, arity_rules
      
      # backtracking
      rules.arity2rules[arity] = old_arity_rules
      rules.arity2signatures[arity] = old_arity_signatures
    else: 
      yield cont, arity_rules
  
  # replace or define the rules which the head can match with.
  @builtin.macro('replace_def')
  def replace_def(solver, rules, head, bodies, klass=UserFunction):
    rules = getvalue(rules, solver.env, {})
    if isinstance(rules, Var):
      new_rules = [(head,)+tuple(body) for body in bodies]
      arity2rules, signature2rules = make_rules(new_rules)
      solver.env[rules] = klass(arity2rules, signature2rules, solver.env, False)
      yield cont, rules
      del solver.env.bindings[rules]
      return
    
    if not isinstance(rules, klass): raise ValueError
    
    arity = len(head)
    new_indexes = set(range(len(bodies)))
    if arity not in rules.arity2rules: 
      rules.arity2rules[arity] = [Rule(head, body) for body in bodies]
      rules.signature2rules[arity] = {}
      for signature in rule_head_signatures(head):
        rules.signature2rules[arity][signature] = new_indexes
      yield cont, rules.arity2rules[arity]
      del rules.arity2rules[arity]
      del rules.signature2rules[arity]
      return
    
    arity_rules = rules.arity2rules[arity]
    old_arity_rules = None
    index = 0
    arity_signatures = rules.signature2rules[arity]
    del_indexes = []
    while index<len(arity_rules):
      rule = arity_rules[index]
      if match(head, rule.head):
        if old_arity_rules is None:
          old_arity_rules = arity_rules[:]
          old_arity_signatures = deepcopy(arity_signatures)
          new_indexes_start = index
          new_indexes = set(range(index, index+len(bodies)))
          del arity_rules[index]
          for signature in rule_head_signatures(rule.head):
            arity_signatures[signature].remove(index)
          for body in bodies:
            arity_rules.insert(index, Rule(head, body))
          new_indexes_map = {}
          for signature in rule_head_signatures(head):
            new_indexes_map[signature] = new_indexes
          index += len(bodies)
        else: 
          del arity_rules[index]
          del_indexes.append(index)
      else: index += 1 
    
    if old_arity_rules is not None:
      delta = 0
      modify_dict = {}
      i = 0
      delta = 0
      while i < index:
        if i in del_indexes: delta -= 1
        elif i==new_indexes_start: delta += len(bodies)-1 
        else: modify_dict[i] = i+delta
        i += 1
      for sign in arity_signatures:
        arity_signatures[sign] = set([modify_dict[i] for i in arity_signatures[sign] 
                                     if i not in del_indexes])
        arity_signatures[sign] |= new_indexes_map.get(sign, set())
        
      remove_memo_head(solver, rules, head)
      
      yield cont, arity_rules
      
      # backtracking
      rules.arity2rules[arity] = old_arity_rules
      rules.signature2rules[arity] = old_arity_signatures
      
    else: yield cont, arity_rules
        
  # retract(+Term)                                                    [ISO]
  #   When  Term  is an  string  or a  term  it is  unified with  the  first
  #   unifying  fact or clause  in the database.   The  fact or clause  is
  #   removed from the database.
  @builtin.macro('retract')
  def retract(solver, rules, head):
    rules = getvalue(rules, solver.env, {})
    if not isinstance(rules, klass): raise ValueError(rules)
    arity = len(head)
    if arity not in rules.arity_rules: 
      yield cont, rules.arity_rules[arity]
      return
    arity_rules = rules.arity_rules[arity]
    index = 0
    while index<len(arity_rules):
      rule = arity_rules[index]
      caller_env = solver.env.extend({})
      callee_env = caller_env.extend({})
      for _ in unify_list_rule_head(head, rule.head, callee_env, caller_env, set()):
        rule = arity_rules[index]
        del arity_rules[index]
        arity_signature2rules = rules.signature2rules[arity]
        for signature in rule_head_signatures(rule.head):
          arity_signature2rules[signature].remove(index)
    
        remove_memo_head(solver, rules, head)
          
        yield cont, arity_rules
        
        arity_rules.insert(index, rule)
        for signature in rule_head_signatures(rule.head):
          arity_signature2rules[signature].add(index)
        return
    
    # head don't match any rule in rules
    yield cont, True
    #no changes happen before yield, so don't need restore
    
  # All  rules for  which head  unifies with head are removed.
  @builtin.macro('retractall')
  def retractall(solver, rules, head, klass=UserFunction):
    rules = getvalue(rules, solver.env, {})
    if not isinstance(rules, klass): raise ValueError
    arity = len(head)
    if arity not in rules.arity_rules: 
      yield cont, rules.arity_rules[arity]
      return
    arity_signature2rules = rules.signature2rules[arity]
    arity_rules = rules.arity_rules[arity]
    old_arity_rules = arity_rules[:]
    del_indexes = {}
    index = 0
    changed = False
    while index<len(arity_rules):
      caller_env = solver.env.extend({})
      callee_env = caller_env.extend({})
      unified = False
      for _ in unify_list_rule_head(head, rule.head, callee_env, caller_env, set()):
        unified = True
        changed = True
        rule = arity_rules[index]
        del arity_rules[index]
        for signature in rule_head_signatures(rule.head):
          arity_signature2rules[signature].remove(index)
          del_indexes.setdefault(signature, set()).add(index)
        del_indexes.append(index)
      if not unified: index += 1
      
    if changed:
      remove_memo_head(solver, rules, head)        
      
    yield cont, arity_rules
    
    if not changed:  return
    rules.signature2rules[arity] = old_arity_rules
    for signature, indexes in del_indexes.items():
      arity_signature2rules[signature] |= indexes
  
  # remove all rules which head matched with.
  @builtin.macro('remove')
  def remove(solver, rules, head, klass=UserFunction):
    rules = getvalue(rules, solver.env, {})
    if not isinstance(rules, klass): raise ValueError
    arity = len(head)
    if arity not in rules.arity2rules: 
      yield cont, rules.arity2rules[arity]
      return
    arity_signature2rules = rules.signature2rules[arity]
    arity_rules = rules.arity2rules[arity]
    old_arity_rules = arity_rules[:]
    del_arity_signature2rules = {}
    index = 0
    old_index = 0
    changed = False
    while index<len(arity_rules):
      if match(head, arity_rules[index].head):
        changed = True
        rule = arity_rules[index]
        del arity_rules[index]
        for signature in rule_head_signatures(rule.head):
          arity_signature2rules[signature].remove(old_index)
          del_arity_signature2rules.setdefault(signature, set()).add(old_index)
      else: index += 1
      old_index += 1
      
    if changed:
      remove_memo_head(solver, rules, head)        
      
    yield cont, arity_rules
    
    if not changed:  return
    rules.signature2rules[arity] = old_arity_rules
    for signature, indexes in del_arity_signature2rules.items():
      arity_signature2rules[signature] |= indexes
      
@special
def any(compiler, cont, item, template=None, result=None):
  if result is None:
    return any1(item).cps(compiler, cont)  
  else:
    _result  = compiler.new_var(Var('result'))
    return begin(any2(item, template, _result), 
                     unify(result, _result)).cps(compiler, cont)  
  
@special
def any1(compiler, cont, item):
  any_cont = compiler.new_var(il.ConstLocalVar('any_cont'))
  fc = compiler.new_var(il.ConstLocalVar('old_fail_cont'))
  v = compiler.new_var(il.ConstLocalVar('v'))
  return il.cfunction(any_cont, v,
                il.Assign(fc, il.failcont),
                il.SetFailCont(il.clamda(v, 
                  il.SetFailCont(fc),
                  cont(v))),
                item.cps(compiler, any_cont))(il.TRUE)

@special
def any2(compiler, cont, item, template, result):
  template = template.interlang()
  result = result.interlang()
  any_cont = compiler.new_var(il.ConstLocalVar('any_cont'))
  fc = compiler.new_var(il.ConstLocalVar('old_fail_cont'))
  v = compiler.new_var(il.ConstLocalVar('v'))
  v2 = compiler.new_var(il.ConstLocalVar('v'))
  v3 = compiler.new_var(il.ConstLocalVar('v'))
  return il.Begin((
    il.Assign(result, il.empty_list),
    il.cfunction(any_cont, v,
                il.Assign(fc, il.failcont),
                il.SetFailCont(il.clamda(v, 
                  il.SetFailCont(il.clamda(v3, 
                    il.if2(result, il.DelListItem(result, il.Integer(-1))),
                    fc(v3))),
                  cont(v))),
                item.cps(compiler, il.clamda(v2, 
                    il.ListAppend(result, il.GetValue(template)),
                    any_cont(v2))))(il.NONE)))

@special
def lazy_any(compiler, cont, item, template=None, result=None):
  if result is None:
    return lazy_any1(item).cps(compiler, cont)  
  else:
    _result  = compiler.new_var(Var('result'))
    return begin(lazy_any2(item, template, _result), 
                     unify(result, _result)).cps(compiler, cont)  

@special
def lazy_any1(compiler, cont, item):
  fc = compiler.new_var(il.ConstLocalVar('fc'))
  lazy_any_cont = compiler.new_var(il.ConstLocalVar('lazy_any_cont'))
  lazy_any_fcont = compiler.new_var(il.ConstLocalVar('lazy_any_fcont'))
  v = compiler.new_var(il.ConstLocalVar('v'))
  return  il.begin(
    il.Assign(fc, il.failcont),
    il.cfunction(lazy_any_fcont, v,
        il.SetFailCont(fc),
        item.cps(compiler, lazy_any_cont)),
    il.cfunction(lazy_any_cont, v,
        il.SetFailCont(lazy_any_fcont),
        cont(il.TRUE))
    (il.TRUE))
                             
@special
def lazy_any2(compiler, cont, item, template, result):
  template = template.interlang()
  result = result.interlang()
  fc = compiler.new_var(il.ConstLocalVar('fc'))
  lazy_any_cont = compiler.new_var(il.ConstLocalVar('lazy_any_cont'))
  lazy_any_fcont = compiler.new_var(il.ConstLocalVar('lazy_any_fcont'))
  v = compiler.new_var(il.ConstLocalVar('v'))
  v1 = compiler.new_var(il.ConstLocalVar('v'))
  v2 = compiler.new_var(il.ConstLocalVar('v'))
  return  il.begin(
    il.Assign(result, il.empty_list),
    il.Assign(fc, il.failcont),
    il.cfunction(lazy_any_fcont, v,
        il.SetFailCont(fc),
        item.cps(compiler, 
          il.clamda(v2, 
                    il.ListAppend(result, il.GetValue(template)),
                    lazy_any_cont(il.TRUE)))),
    il.cfunction(lazy_any_cont, v,
        il.SetFailCont(lazy_any_fcont),
        cont(il.TRUE))
    (il.TRUE))
                             
@special
def greedy_any(compiler, cont, item, template=None, result=None):
  if result is None:
    return greedy_any1(item).cps(compiler, cont)  
  else:
    _result  = compiler.new_var(Var('result'))
    return begin(greedy_any2(item, template, _result), 
                     unify(result, _result)).cps(compiler, cont)  
    
@special
def greedy_any1(compiler, cont, item):
  v = compiler.new_var(il.ConstLocalVar('v'))
  fc = compiler.new_var(il.ConstLocalVar('old_failcont'))
  greedy_any_fcont = compiler.new_var(il.ConstLocalVar('greedy_any_fcont'))
  greedy_any_cont = compiler.new_var(il.ConstLocalVar('greedy_any_cont'))
  return il.begin(
    il.Assign(fc, il.failcont),
    il.cfunction(greedy_any_fcont, v,
        il.SetFailCont(fc),
        cont(il.TRUE)),    
    il.cfunction(greedy_any_cont, v,
        il.SetFailCont(greedy_any_fcont),
        item.cps(compiler, greedy_any_cont))(il.TRUE))

@special
def greedy_any2(compiler, cont, item, template, result):
  template = template.interlang()
  result = result.interlang()
  item_matched = compiler.new_var(il.Var('item_matched'))
  v = compiler.new_var(il.ConstLocalVar('v'))
  v2 = compiler.new_var(il.ConstLocalVar('v'))
  fc = compiler.new_var(il.ConstLocalVar('old_failcont'))
  greedy_any_fcont = compiler.new_var(il.ConstLocalVar('greedy_any_fcont'))
  greedy_any_cont = compiler.new_var(il.ConstLocalVar('greedy_any_cont'))
  return il.begin(
    il.Assign(result, il.empty_list),
    il.Assign(fc, il.failcont),
    il.cfunction(greedy_any_fcont, v,
        il.SetFailCont(fc),
        cont(il.TRUE)),    
    il.cfunction(greedy_any_cont, v,
        il.SetFailCont(greedy_any_fcont),
        item.cps(compiler, 
                         il.clamda(v2, 
                                   il.ListAppend(result, il.GetValue(template)), 
                                   greedy_any_cont(il.TRUE))))(il.TRUE))


@special
def some(compiler, cont, item, template=None, result=None):
  if result is None:
    return some1(item).cps(compiler, cont)  
  else:
    _result  = compiler.new_var(Var('result'))
    return begin(some2(item, template, _result), 
                     unify(result, _result)).cps(compiler, cont)  
  
@special
def some1(compiler, cont, item):
  some_cont = compiler.new_var(il.ConstLocalVar('some_cont'))
  fc = compiler.new_var(il.ConstLocalVar('old_fail_cont'))
  v = compiler.new_var(il.ConstLocalVar('v'))
  some_cont = il.cfunction(some_cont, v,
                il.Assign(fc, il.failcont),
                il.SetFailCont(il.clamda(v, 
                  il.SetFailCont(fc),
                  cont(v))),
                item.cps(compiler, some_cont))
  return item.cps(compiler, some_cont)

@special
def some2(compiler, cont, item, template, result):
  template = template.interlang()
  result = result.interlang()
  some_cont = compiler.new_var(il.ConstLocalVar('some_cont'))
  fc = compiler.new_var(il.ConstLocalVar('old_failcont'))
  v = compiler.new_var(il.ConstLocalVar('v'))
  v2 = compiler.new_var(il.ConstLocalVar('v'))
  v3 = compiler.new_var(il.ConstLocalVar('v'))
  append_cont = il.clamda(v2, 
                    il.ListAppend(result, il.GetValue(template)),
                    some_cont(v2))
  return il.Begin((
    il.Assign(result, il.empty_list),
    il.cfunction(some_cont, v,
                 il.Assign(fc, il.failcont),
                il.SetFailCont(il.clamda(v, 
                  il.SetFailCont(il.clamda(v3, 
                    il.DelListItem(result, il.Integer(-1)),
                    fc(v3))),
                 cont(v))),
                item.cps(compiler, append_cont)),
    item.cps(compiler, append_cont)))

@special
def lazy_some(compiler, cont, item, template=None, result=None):
  if result is None:
    return lazy_some1(item).cps(compiler, cont)  
  else:
    _result  = compiler.new_var(Var('result'))
    return begin(lazy_some2(item, template, _result), 
                     unify(result, _result)).cps(compiler, cont)  

@special
def lazy_some1(compiler, cont, item):
  fc = compiler.new_var(il.ConstLocalVar('fc'))
  lazy_some_cont = compiler.new_var(il.ConstLocalVar('lazy_some_cont'))
  lazy_some_fcont = compiler.new_var(il.ConstLocalVar('lazy_some_fcont'))
  v = compiler.new_var(il.ConstLocalVar('v'))
  v2 = compiler.new_var(il.ConstLocalVar('v'))
  return  il.begin(
    il.Assign(fc, il.failcont),
    il.cfunction(lazy_some_fcont, v,
        il.SetFailCont(fc),
        lazy_some_cont(il.TRUE)),
    il.cfunction(lazy_some_cont, v,
        item.cps(compiler, il.clamda(v2,
          il.SetFailCont(lazy_some_fcont),
          cont(il.TRUE))))(il.TRUE))
                             
@special
def lazy_some2(compiler, cont, item, template, result):
  template = template.interlang()
  result = result.interlang()
  fc = compiler.new_var(il.ConstLocalVar('fc'))
  lazy_some_cont = compiler.new_var(il.ConstLocalVar('lazy_some_cont'))
  lazy_some_fcont = compiler.new_var(il.ConstLocalVar('lazy_some_fcont'))
  v = compiler.new_var(il.ConstLocalVar('v'))
  v1 = compiler.new_var(il.ConstLocalVar('v'))
  v2 = compiler.new_var(il.ConstLocalVar('v'))
  return  il.begin(
    il.Assign(result, il.empty_list),
    il.Assign(fc, il.failcont),
    il.cfunction(lazy_some_fcont, v,
        il.SetFailCont(fc),
        lazy_some_cont(il.TRUE)),
    il.cfunction(lazy_some_cont, v,
        item.cps(compiler, il.clamda(v2,
           il.SetFailCont(lazy_some_fcont),
           il.ListAppend(result, il.GetValue(template)),
           cont(il.TRUE))))(il.TRUE))
                             
@special
def greedy_some(compiler, cont, item, template=None, result=None):
  if result is None:
    return greedy_some1(item).cps(compiler, cont)  
  else:
    _result  = compiler.new_var(Var('result'))
    return begin(greedy_some2(item, template, _result), 
                     unify(result, _result)).cps(compiler, cont)  
    
@special
def greedy_some1(compiler, cont, item):
  v = compiler.new_var(il.ConstLocalVar('v'))
  fc = compiler.new_var(il.ConstLocalVar('old_failcont'))
  greedy_some_fcont = compiler.new_var(il.ConstLocalVar('greedy_some_fcont'))
  greedy_some_cont = compiler.new_var(il.ConstLocalVar('greedy_some_cont'))
  return il.begin(
    il.Assign(fc, il.failcont),
    il.cfunction(greedy_some_fcont, v,
        il.SetFailCont(fc),
        cont(il.TRUE)),    
    il.cfunction(greedy_some_cont, v,
        il.SetFailCont(greedy_some_fcont),
        item.cps(compiler, greedy_some_cont)),
  item.cps(compiler, greedy_some_cont))

@special
def greedy_some2(compiler, cont, item, template, result):
  template = template.interlang()
  result = result.interlang()
  item_matched = compiler.new_var(il.Var('item_matched'))
  v = compiler.new_var(il.ConstLocalVar('v'))
  v2 = compiler.new_var(il.ConstLocalVar('v'))
  fc = compiler.new_var(il.ConstLocalVar('old_failcont'))
  greedy_some_fcont = compiler.new_var(il.ConstLocalVar('greedy_some_fcont'))
  greedy_some_cont = compiler.new_var(il.ConstLocalVar('greedy_some_cont'))
  append_result_cont = il.clamda(v2, 
                                   il.ListAppend(result, il.GetValue(template)), 
                                   greedy_some_cont(il.TRUE))
  return il.begin(
    il.Assign(result, il.empty_list),
    il.Assign(fc, il.failcont),
    il.cfunction(greedy_some_fcont, v,
        il.SetFailCont(fc),
        cont(il.TRUE)),    
    il.cfunction(greedy_some_cont, v,
        il.SetFailCont(greedy_some_fcont),
        item.cps(compiler, 
                         append_result_cont)),
    item.cps(compiler, append_result_cont))

from term import getvalue, eval_unify
from exports.command import assign, direct_interlang
from arith import add

@special
def times(compiler, cont, item, expect_times, template=None, result=None):
  if result is None:
    expect_times1 = compiler.new_var(Const('expect_times'))
    return begin(assign(expect_times1, getvalue(expect_times)), 
                    times1(item, expect_times1)).cps(compiler, cont)
  else:
    expect_times1 = compiler.new_var(Const('expect_times'))
    result1  = compiler.new_var(il.ConstLocalVar('result'))
    result2  = compiler.new_var(Var('result'))
    result2_2  = result2.interlang()
    template1 = template.interlang()
    return begin(assign(expect_times1, getvalue(expect_times)), 
                 times2(item, expect_times1, template, result2),
                 unify(result, result2)
                 ).cps(compiler, cont)  

@special
def times1(compiler, cont, item, expect_times):
    expect_times = expect_times.interlang()
    i = compiler.new_var(il.Var('i'))
    times_cont = compiler.new_var(il.ConstLocalVar('times_cont'))
    v = compiler.new_var(il.ConstLocalVar('v'))
    return il.begin(
      il.Assert(il.And(il.Isinstance(expect_times, il.Int), il.Gt(expect_times, il.Integer(0)))),
      il.Assign(i, il.Integer(0)),
      il.cfunction(times_cont, v, 
        item.cps(compiler, il.clamda(v,
        il.AddAssign(i, il.Integer(1)),
        il.If(il.Eq(i, expect_times),
              cont(v),
            times_cont(il.TRUE)))))
      (il.TRUE))
  
@special
def times2(compiler, cont, item, expect_times, template, result):
    expect_times = expect_times.interlang()
    template = template.interlang()
    result = result.interlang()
    i = compiler.new_var(il.Var('i'))
    times_cont = compiler.new_var(il.ConstLocalVar('times_cont'))
    v = compiler.new_var(il.ConstLocalVar('v'))
    return il.begin(
      il.Assert(il.And(il.Isinstance(expect_times, il.Int), il.Gt(expect_times, il.Integer(0)))),
      il.Assign(result, il.empty_list),
      il.Assign(i, il.Integer(0)),
      il.cfunction(times_cont, v, 
        item.cps(compiler, il.clamda(v,
        il.AddAssign(i, il.Integer(1)),
        il.ListAppend(result, il.GetValue(template)),
        il.If(il.Eq(i, expect_times),
              cont(v),
            times_cont(il.TRUE)))))
      (il.TRUE))
          
@special
def seplist(compiler, cont, item, separator, template=None, result=None):
  if result is None:
    return begin(item, any1(begin(separator, item))
                 ).cps(compiler, cont)  
  else:
    result1  = compiler.new_var(il.ConstLocalVar('result'))
    result2  = compiler.new_var(Var('result'))
    result2_2  = result2.interlang()
    template1 = template.interlang()
    return begin(item, 
                 direct_interlang(il.Assign(result1, il.GetValue(template1))), 
                 any2(begin(separator, item), template, result2),
                 eval_unify(result, direct_interlang(il.add(il.MakeList(result1), result2_2)))
                 ).cps(compiler, cont)  
  
@special
def lazy_seplist(compiler, cont, item, separator, template=None, result=None):
  if result is None:
    return begin(item, lazy_any1(begin(separator, item))
                 ).cps(compiler, cont)  
  else:
    result1  = compiler.new_var(il.ConstLocalVar('result'))
    result2  = compiler.new_var(Var('result'))
    result2_2  = result2.interlang()
    template1 = template.interlang()
    return begin(item, 
                 direct_interlang(il.Assign(result1, il.GetValue(template1))), 
                 lazy_any2(begin(separator, item), template, result2),
                 eval_unify(result, direct_interlang(il.add(il.MakeList(result1), result2_2)))
                 ).cps(compiler, cont)  
  
@special
def greedy_seplist(compiler, cont, item, separator, template=None, result=None):
  if result is None:
    return begin(item, greedy_any1(begin(separator, item))
                 ).cps(compiler, cont)  
  else:
    result1  = compiler.new_var(il.ConstLocalVar('result'))
    result2  = compiler.new_var(Var('result'))
    result2_2  = result2.interlang()
    template1 = template.interlang()
    return begin(item, 
                 direct_interlang(il.Assign(result1, il.GetValue(template1))), 
                 greedy_any2(begin(separator, item), template, result2),
                 eval_unify(result, direct_interlang(il.add(il.MakeList(result1), result2_2)))
                 ).cps(compiler, cont)  
  
@special
def follow(compiler, cont, item):
  parse_state  = compiler.new_var(il.ConstLocalVar('parse_state'))
  v  = compiler.new_var(il.ConstLocalVar('v'))
  return il.begin(
    il.Assign(parse_state, il.parse_state),
    item.cps(compiler, il.clamda(v,
      il.SetParseState(parse_state), 
      cont(v))))

@matcher()
def lead_chars(solver, chars):
  chars = deref(chars, solver.env)
  assert isinstance(chars, str)
  if last_char_(solver.parse_state) not in chars: return
  yield cont,  True

@matcher()
def not_lead_chars(solver, chars):
  chars = deref(chars, solver.env)
  assert isinstance(chars, str)
  if last_char_(solver.parse_state) in chars: return
  yield cont,  True

@matcher()
def follow_chars(solver, chars):
  chars = deref(chars, solver.env)
  if eoi_(solver.parse_state) or\
     next_char_(solver.parse_state) not in chars: 
    return
  yield cont,  True

@matcher()
def follow_char(solver, char):
  char = deref(char, solver.env)
  if eoi_(solver.parse_state) or\
     next_char_(solver.parse_state)!=char: 
    return
  yield cont,  True

@matcher()
def not_follow_chars(solver, chars):
  chars = deref(chars, solver.env)
  if not eoi_(solver.parse_state) and next_char_(solver.parse_state) in chars: 
    return
  yield cont,  True

@matcher()
def not_follow_char(solver, char):
  char = deref(char, solver.env)
  if not eoi_(solver.parse_state) and next_char_(solver.parse_state)==char: 
    return
  yield cont,  True

def lead_string(solver, string):
  strArgument = deref(strArgument, solver.env)
  assert isinstance(strArgument, str)
  if not parsed_(solver.parse_state).endwith(strArgument):return
  yield cont,  True

@matcher()
def not_lead_string(solver, string):
  string = string.deref(solver.env)
  if parsed_(solver.parse_state).endwith(string): return
  solver.value = True  

def follow_string(solver, strArgument):
  strArgument = strArgument.deref(solver.env)
  assert isinstance(strArgument, String)
  if not left_(solver.parse_state).startswith(strArgument.name): raise UnifyFail
  solver.value = True

@matcher()
def not_follow_string(solver, string):
  string = string.deref(solver.env)
  if left_(solver.parse_state).startswith(string.name): return
  solver.value = True  

@matcher()
def any_chars_except(solver, except_chars):
  'any chars until meet except_chars'
  text, pos = solver.parse_state
  length = len(text)
  p = pos
  while 1:
    if p == length or text[p] in except_chars: 
      solver.parse_state = text, p
      yield cont, text[p]
      solver.parse_state = text, pos
    p += 1

@matcher()
def space(solver):
  'one space'
  text, pos = solver.parse_state
  if pos==len(text): return
  if text[pos]==' ': 
    solver.parse_state = text, pos+1
    yield cont, ' '
    solver.parse_state = text, pos
space = space()

@matcher()
def tab(solver):
  'one tab'
  text, pos = solver.parse_state
  if pos==len(text): return
  if text[pos]=='\t': 
    solver.parse_state = text, pos+1
    yield cont, '\t'
    solver.parse_state = text, pos
tab = tab()

@matcher()
def tabspace(solver):
  'one space or tab'
  text, pos = solver.parse_state
  if pos==len(text): return
  if text[pos]==' ' or text[pos]=='\t': 
    solver.parse_state = text, pos+1
    yield cont, text[pos]
    solver.parse_state = text, pos
tabspace = tabspace()

@matcher()
def whitespace(solver):
  'one space or tab'
  text, pos = solver.parse_state
  if pos==len(text): return
  if text[pos] in ' \t\r\n': 
    solver.parse_state = text, pos+1
    yield cont, text[pos]
    solver.parse_state = text, pos
whitespace = whitespace()

@matcher()
def newline(solver):
  'one newline'
  text, pos = solver.parse_state
  if pos==len(text): return
  if text[pos]=='\r' or text[pos]=='\n':
    if text[pos+1]=='\r' or text[pos+1]=='\n' and text[pos+1]!=text[pos]:
      solver.parse_state = text, pos+2
      yield cont,  text[pos:pos+2]
    else:
      solver.parse_state = text, pos+1
      yield cont,  text[pos:pos+1]
    solver.parse_state = text, pos
nl = newline = newline()

@matcher()
def spaces0(solver)
  '0 or more space'
  text, pos = solver.parse_state
  length = len(text)
  p = pos
  while p<length and text[p]==' ': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
spaces0 = spaces0()

@matcher()
def tabs0(solver):
  '0 or more tab'
  text, pos = solver.parse_state
  length = len(text)
  p = pos
  while p<length and text[p]=='\t': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
tabs0 = tabs0()

@matcher()
def _Tabspaces0(solver):
  '0 or more space or tab'
  text, pos = solver.parse_state
  length = len(text)
  p = pos
  while p<length and (text[p]==' ' or text[p]=='\t'): p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
tabspaces0 = _Tabspaces0()

@matcher()
def whitespaces0(solver):
  text, pos = solver.parse_state
  length = len(text)
  p = pos
  while p<length and text[p] in ' \t\r\n': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
whitespaces0 = whitespaces0()

@matcher()
def newlines0(solver):
  text, pos = solver.parse_state
  length = len(text)
  p = pos
  while p<length and text[p] in '\r\n': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
newlines0 = newlines0()

@matcher()
def spaces(solver):
  '1 or more space or tab'
  text, pos = solver.parse_state
  if pos==len(text): return
  if text[pos]!=' ': return
  p = pos+1
  while text[p]==' ': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
spaces = spaces()

@matcher()
def tabs(solver):
  '1 or more space or tab'
  text, pos = solver.parse_state
  if pos==len(text): return
  if text[pos]!='\t': return
  p = pos+1
  while text[p]=='\t': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
tabs = tabs()

@matcher()
def _Tabspaces(solver):
  '1 or more space or tab'
  text, pos = solver.parse_state
  if pos==len(text): return
  if text[pos]!=' ' and text[pos]!='\t': return
  p = pos+1
  while text[p]==' ' or text[p]=='\t': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
tabspaces = _Tabspaces()

@matcher()
def pad_tabspaces(solver):
  'if not leading space, 1 or more space or tab'
  text, pos = solver.parse_state
  if pos==len(text): return
  if text[pos]!=' ' and text[pos]!='\t': 
    if text[pos-1]!=' ' and text[pos]!='\t': return
    yield cont, text[pos]
    return
  p = pos+1
  while text[p]==' ' or text[p]=='\t': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
pad_tabspaces = pad_tabspaces()

@matcher()
def tabspaces_if_need(solver):
  '1 or more tabspace not before punctuation '",;:.{}[]()!?\r\n '
  text, pos = solver.parse_state
  if pos==len(text): 
    yield cont, ''
    return
  if text[pos] not in ' \t': 
    if pos+1==len(text) or text[pos+1] in '\'",;:.{}[]()!?\r\n':
      yield cont, text[pos]
    return
  p = pos+1
  while text[p] in '\r\n': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
tabspaces_if_need = tabspaces_if_need()

@matcher()
def tabspaces_unless(solver, chars):
  '1 or more tabspace if not before chars, else 0 or more tabspace '
  chars = deref(chars, solver.env)
  text, pos = solver.parse_state
  if pos==len(text): 
    yield cont, ''
    return
  if text[pos] not in ' \t': 
    if pos+1==len(text) or text[pos+1] in chars:
      yield cont, text[pos]
    return
  p = pos+1
  while text[p] in '\r\n': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
tabspaces_unless = tabspaces_unless()

@matcher()
def whitespaces(solver):
  '1 or more space or tab or newline'
  text, pos = solver.parse_state
  if pos==len(text): return
  if text[pos] not in ' \t\r\n': return
  p = pos+1
  while text[p] in ' \t\r\n': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
whitespaces = whitespaces()

@matcher()
def newlines(solver):
  ' 1 or more  newline'
  text, pos = solver.parse_state
  if pos==len(text): return
  if text[pos] not in '\r\n': return
  p = pos+1
  while text[p] in '\r\n': p += 1
  solver.parse_state = text, p
  yield cont, text[pos:p]
  solver.parse_state = text, pos
newlines = newlines()

from exports.term import DummyVar
from exports.builtins.control import and_p

def wrap_tabspaces0(item):
  _ = DummyVar('_')
  return and_p(tabspaces0, item, tabspaces0)

def wrap_tabspaces(item):
  _ = DummyVar('_')
  return and_p(tabspaces, item, tabspaces)
###