{solve, Error} = core = require('../core')
{string, begin, quote, assign, print_,
funcall, macall, lamda, macro, jsfun,
if_, add, eq, inc, suffixinc,
logicvar, dummy, andp, orp, findall, getvalue
getstate, gettext, getpos, eoi, boi, eol, bol, step, lefttext, subtext, nextchar
parsetext, char, settext, number, literal
may, greedymay, lazymay,
any, lazyany, greedyany
some, lazysome, greedysome
} = require('../util')

vari = (name) -> name

xexports = {}

exports.Test =
  "test low level primitives": (test) ->
    x = logicvar('x')
    test.deepEqual  solve(parsetext(getstate, string(''))), ['', 0]
    test.equal  solve(parsetext(gettext, string(''))), ''
    test.equal  solve(parsetext(getpos, string(''))), 0
    test.equal  solve(parsetext(eoi, string(''))), true
    test.equal  solve(parsetext(andp(step(2), eoi), string('we'))), true
    test.equal  solve(parsetext(andp(step(2), boi), string(''))), false
    test.equal  solve(parsetext(boi, string(''))), true
    test.equal  solve(parsetext(eol, string(''))), true
    test.equal  solve(parsetext(bol, string(''))), true
    test.equal  solve(parsetext(bol, string('\r'))), true
    test.equal  solve(parsetext(andp(step(1), bol), string('\r'))), true
    test.equal  solve(parsetext(andp(step(1), eol), string('\rasdf'))), false
    test.equal  solve(parsetext(andp(step(3), eol), string('\ras\ndf'))), true
    test.deepEqual  solve(parsetext(lefttext, string('\ras\ndf'))), '\ras\ndf'
    test.deepEqual  solve(parsetext(subtext(1, 3), string('\ras\ndf'))), '\n'
    test.done()

#xexports.Test =
  "test char": (test) ->
    x = logicvar('x')
    test.equal  solve(parsetext(1, string('a'))), 1
    test.equal  solve(parsetext(char(string('a')), string('a'))), 1
    test.equal  solve(parsetext(andp(char(string('a')), char(string('b'))), string('ab'))), 2
    test.equal  solve(parsetext(char(string('a')), string('b'))), 0
    test.equal  solve(begin(settext(string('a')), char(string('a')))), 1
    test.equal  solve(begin(settext(string('ab')), char(string('a')), char(string('b')))), 2
    test.done()

#exports.Test =
  "test number": (test) ->
    x = logicvar('x')
    test.equal  solve(parsetext(number(x), string('123'))), 3
    test.equal  solve(parsetext(number(x), string('123.4'))), 5
    test.equal  solve(parsetext(number(x), string('-123.4'))), 6
    test.equal  solve(parsetext(number(x), string('.123'))), 4
    test.equal  solve(parsetext(number(x), string('123.e-2'))), 7
    test.equal  solve(parsetext(number(x), string('123.e'))), 4
    test.equal  solve(parsetext(number(x), string('123.e+'))), 4
    test.done()

  "test literal": (test) ->
    test.equal  solve(parsetext(literal(string('daf')), string('daf'))), 3
    test.done()

#exports.Test =
  "test may char": (test) ->
    test.equal  solve(parsetext(may(char(string('a'))), string('a'))), 1
    test.equal  solve(parsetext(begin(may(char(string('a'))), eoi), string('a'))), true
    test.equal  solve(parsetext(begin(may(char(string('a'))), char(string('a')), eoi), string('a'))), true
    test.equal  solve(parsetext(begin(greedymay(char(string('a'))), char(string('a')), eoi), string('a'))), 1
    test.equal  solve(parsetext(begin(lazymay(char(string('a'))), char(string('a')), eoi), string('a'))), 1
    test.equal  solve(parsetext(may(char(string('a'))), string('b'))), 0
    test.done()

#exports.Test =
  "test greedyany": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(greedyany(char(_)), string('abc')))), 3
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), greedyany(char(_)), eoi), string('a'))), true
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), greedyany(char(_)), char(string('c')), eoi), string('ac'))), 2
    test.equal  solve(parsetext(findall(begin(assign(_, dummy('__')), greedyany(char(_)), char(string('c')), eoi)), string('abc'))), 3
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsetext(greedyany(char(_), result, _), string('a')), getvalue(result))), ['a']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                settext(string('ab')), greedyany(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.done()

#exports.Test =
  "test any": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(any(char(_)), string('a')))), 1
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(any(char(_)), string('ab')))), 2
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), any(char(_)), eoi), string('abc'))), true
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsetext(any(char(_), result, _), string('a')), getvalue(result))), ['a']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                settext(string('ab')), any(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), any(char(_)), char(string('c')), eoi), string('abc'))), true
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), any(char(string('a')))), string('b'))), 0
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), any(char(string('a'))), eoi), string('b'))), false
    test.done()

#exports.Test =
  "test lazyany": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(lazyany(char(_)), string('a')))), 'a'
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsetext(lazyany(char(_), result, _), string('a')), getvalue(result))), []
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                settext(string('ab')), lazyany(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), lazyany(char(_)), char(string('c')), eoi), string('abc'))), true
    test.equal  solve(parsetext(begin(lazyany(char(string('a'))), nextchar), string('b'))), 'b'
    test.equal  solve(parsetext(begin(lazyany(char(string('a'))), eoi), string('b'))), 0
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(lazyany(begin(char(_), print_(getvalue(_)))), string('abc')))), 'abc'
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(findall(lazyany(begin(char(_), print_(getvalue(_))))), string('abc')))), 3
    test.done()

#exports.Test =
  "test greedysome": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(greedysome(char(_)), string('abc')))), 3
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), greedysome(char(_)), eoi), string('a'))), true
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), greedysome(char(_)), char(string('c')), eoi), string('ac'))), 2
    test.equal  solve(parsetext(findall(begin(assign(_, dummy('__')), greedysome(char(_)), char(string('c')), eoi)), string('abc'))), 3
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsetext(greedysome(char(_), result, _), string('a')), getvalue(result))), ['a']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                settext(string('ab')), greedysome(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.equal  solve(parsetext(orp(begin(greedysome(char(_)), char('c'), eoi), 1), string('abc'))), 1
    test.done()

#exports.Test =
  "test some": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(some(char(_)), string('a')))), 1
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(some(char(_)), string('ab')))), 2
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), some(char(_)), eoi), string('abc'))), true
    test.equal core.status, core.SUCCESS
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsetext(some(char(_), result, _), string('a')), getvalue(result))), ['a']
    test.equal core.status, core.SUCCESS
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                settext(string('ab')), some(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.equal core.status, core.SUCCESS
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), some(char(_)), char(string('c')), eoi), string('abc'))), true
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), some(char(string('a')))), string('b'))), 0
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), some(char(string('a'))), eoi), string('b'))), false
    test.done()

#exports.Test =
  "test lazysome": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(lazysome(char(_)), string('a')))), 1
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsetext(lazysome(char(_), result, _), string('a')), getvalue(result))), ['a']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                settext(string('ab')), lazysome(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.equal  solve(parsetext(begin(assign(_, dummy('__')), lazysome(char(_)), char(string('c')), eoi), string('abc'))), true
    test.equal  solve(parsetext(begin(lazysome(char(string('a'))), nextchar), string('b'))), false
    test.equal  solve(parsetext(begin(lazysome(char(string('a'))), eoi), string('b'))), false
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(lazysome(begin(char(_), print_(getvalue(_)))), string('abc')))), null
    test.equal  solve(begin(assign(_, dummy('__')), parsetext(findall(lazysome(begin(char(_), print_(getvalue(_))))), string('abc')))), 3
    test.done()

xexports.Test =
  "test times": (test) ->
    _ = dummy('__')
    result = vari('result')
    n = vari('n')
    test.equal  solve(parsetext(times(char(_), 1), string('a'))), 1
    test.equal core.status, core.SUCCESS
    test.equal  solve(parsetext(times(char(_), 2), 'ab')), 2
    test.equal core.status, core.SUCCESS
    test.equal  solve(parsetext(times(char(_), 3), string('abc'))), 3
    test.equal core.status, core.SUCCESS
    test.deepEqual  solve(begin(settext(string('ab')), times(char(_), n), eoi)), true
    test.equal core.status, core.SUCCESS
    test.deepEqual  solve(begin(parsetext(times(char(_), 2, result, _), 'ab'), result)), ['a', 'b']
    test.equal core.status, core.SUCCESS
    test.deepEqual  solve(begin(parsetext(times(char(_), 3, result, _), string('abc')), result)), ['a', 'b', 'c']
    test.equal core.status, core.SUCCESS
    test.deepEqual  solve(begin(settext(string('ab')), times(char(_), n, result, _), eoi, n)), 2
    test.equal core.status, core.SUCCESS
    test.deepEqual  solve(begin(settext(string('ab')), times(char(_), n, result, _), eoi, result)), ['a', 'b']
    test.equal core.status, core.SUCCESS
    test.deepEqual  solve(begin(settext('aabb'), times(char(string('a')), n), times(char(string('b')), n), eoi, n)), 2
    test.equal core.status, core.SUCCESS
    n.binding = n
    test.deepEqual  solve(begin(settext(string('abc')), times(char(_), n, result, _), char('c'), eoi, result)), ['a', 'b']
    test.equal core.status, core.SUCCESS
    n.binding = n
    test.deepEqual  solve(begin(settext(string('abc')), times(char(_), n, result, _), char(string('b')), char('c'), eoi, result)), ['a']
    test.equal core.status, core.SUCCESS
    n.binding = n
    test.deepEqual  solve(begin(settext('aaabbb'), times(char(string('a')), n), times(char('b'), n), eoi, n)), 3
    test.equal core.status, core.SUCCESS
    test.deepEqual  solve(begin(settext('aaabbb'), times(char(string('a')), n, result, string('a')), times(char(string('b')), n), eoi, n)), 3
    test.equal core.status, core.SUCCESS
    test.deepEqual  solve(begin(settext('aaabbb'), times(char(string('a')), n, result, string('a')), times(char(string('b')), n, result, string('b')), eoi, result)), ['b', 'b', 'b']
    test.equal core.status, core.SUCCESS
    n.binding = n;
    test.deepEqual(solve(begin(settext(string('a')), times(char(_), n, result, _), char(string('a')), eoi, result)), []);
    test.equal(core.status, core.SUCCESS);
    test.done()

  "test seplist": (test) ->
    _ = dummy('__')
    result = vari('result')
    n = vari('n')
    test.equal  solve(parsetext(seplist(char(_)), string('a'))), 1
    test.equal(core.status, core.SUCCESS);
    test.equal  solve(parsetext(seplist(char(_)), 'a a')), 3
    test.equal(core.status, core.SUCCESS);
    test.equal  solve(parsetext(seplist(char(_), {sep:char(',')}), 'a,a')), 3
    test.equal(core.status, core.SUCCESS);
    test.equal  solve(parsetext(seplist(char(_), {sep:char(','), times:3}), 'a,a, a')), 5
    test.equal(core.status, core.SUCCESS);
    test.deepEqual  solve(begin(parsetext(seplist(char(_), {sep:char(','), times:3, result:result, template:string('a')}), 'a,a,a'), result)), ['a', 'a','a']
    test.equal(core.status, core.SUCCESS);
    test.deepEqual  solve(begin(parsetext(seplist(char(_), {sep:char(','), times:3, result:result, template:_}), 'a,b,c'), result)), ['a', 'b','c']
    test.equal(core.status, core.SUCCESS);
    n.binding = n;
    test.deepEqual  solve(begin(parsetext(seplist(char(_), {sep:char(','), times:n, result:result, template:_}), 'a,b,c'), result)), ['a', 'b','c']
    test.equal(core.status, core.SUCCESS);
    n.binding = n;
    test.deepEqual  solve(begin(parsetext(andp(seplist(char(_), {sep:char(','), times:n, result:result, template:_}), char(','), char('c')), 'a,b,c'), result)), ['a', 'b']
    test.equal(core.status, core.SUCCESS);
    n.binding = n;
    test.deepEqual  solve(begin(parsetext(andp(seplist(char(_), {sep:char(','), times:n, result:result, template:_}), char(','), char(string('b')), char(','), char('c')), 'a,b,c'), result)), ['a']
    test.equal(core.status, core.SUCCESS);
    test.done()

  "test purememo": (test) ->
    _ = dummy('__')
    result = vari('result')
    n = vari('n');
    f = (x) -> if x is 1 then console.log(1); 1 else x *f(x-1)
    factorial = fun(f)
    fac = purememo(factorial)
    test.equal solve(begin(fac(5), fac(5))), 120
    test.done()

  "test fun2 purememo": (test) ->
    factorial = fun2((x) -> if x is 1 then begin(print_(1), 1) else mul(x, factorial(sub(x, 1))))
    fac = purememo(factorial)
    test.equal solve(begin(fac(5), fac(5))), 120
#    test.equal solve(begin(fac(5))), 120
    test.done()
