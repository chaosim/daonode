{solve, Error} = core = require('../lib/core')
{string, begin, quote, assign, print_,
funcall, macall, lamda, macro, jsfun,
if_, add, eq, inc, suffixinc,
logicvar, dummy, andp, orp, findall, getvalue
getstate, getdata, getcursor, eoi, boi, eol, bol, step, leftdata, subdata, nextchar
parsedata, char, setdata, number, literal
may, greedymay, lazymay,
any, lazyany, greedyany
some, lazysome, greedysome, times, seplist
parallel, follow, notfollow
} = require('../lib/util')

vari = (name) -> name

xexports = {}

exports.Test =
  "test low level primitives": (test) ->
    x = logicvar('x')
    test.deepEqual  solve(parsedata(getstate, string(''))), ['', 0]
    test.equal  solve(parsedata(getdata, string(''))), ''
    test.equal  solve(parsedata(getcursor, string(''))), 0
    test.equal  solve(parsedata(eoi, string(''))), true
    test.equal  solve(parsedata(andp(step(2), eoi), string('we'))), true
    test.equal  solve(parsedata(andp(step(2), boi), string(''))), false
    test.equal  solve(parsedata(boi, string(''))), true
    test.equal  solve(parsedata(eol, string(''))), true
    test.equal  solve(parsedata(bol, string(''))), true
    test.equal  solve(parsedata(bol, string('\r'))), true
    test.equal  solve(parsedata(andp(step(1), bol), string('\r'))), true
    test.equal  solve(parsedata(andp(step(1), eol), string('\rasdf'))), false
    test.equal  solve(parsedata(andp(step(3), eol), string('\ras\ndf'))), true
    test.deepEqual  solve(parsedata(leftdata, string('\ras\ndf'))), '\ras\ndf'
    test.deepEqual  solve(parsedata(subdata(1, 3), string('\ras\ndf'))), '\n'
    test.done()

#exports.Test =
  "test char": (test) ->
    x = logicvar('x')
    test.equal  solve(parsedata(1, string('a'))), 1
    test.equal  solve(parsedata(char(string('a')), string('a'))), 1
    test.equal  solve(parsedata(andp(char(string('a')), char(string('b'))), string('ab'))), 2
    test.equal  solve(parsedata(char(string('a')), string('b'))), 0
    test.equal  solve(begin(setdata(string('a')), char(string('a')))), 1
    test.equal  solve(begin(setdata(string('ab')), char(string('a')), char(string('b')))), 2
    test.done()

#xexports.Test =
  "test number": (test) ->
    test.equal  solve(parsedata(number(), string('123'))), 123
    test.equal  solve(parsedata(number(), string('123.4'))), 123.4
    test.equal  solve(parsedata(number(), string('-123.4'))), -123.4
    test.equal  solve(parsedata(number(), string('.123'))),.123
    test.equal  solve(parsedata(number(), string('123.e-2'))), 123e-2
    test.equal  solve(parsedata(number(), string('123.e'))), 123
    test.equal  solve(parsedata(number(), string('123.e+'))), 123
    test.done()

#xexports.Test =
  "test literal": (test) ->
    test.equal  solve(parsedata(literal(string('daf')), string('daf'))), 3
    test.done()

#exports.Test =
  "test parallel": (test) ->
    test.equal  solve(begin(setdata(string('1')), parallel(char(string('1')), number()))), 1
    test.equal  solve(begin(setdata(string('12')), parallel(char(string('1')), number()))), 12
    test.equal  solve(begin(setdata(string('1')), parallel(char(string('1')),char(string('a'))))), false
    test.done()

#exports.Test =
  "test follow": (test) ->
    test.equal  solve(begin(setdata(string('1')), follow(char(string('1'))))), 1
    test.equal  solve(begin(setdata(string('1')), notfollow(char(string('1'))))), 1
    test.done()

#xexports.Test =
  "test may char": (test) ->
    test.equal  solve(parsedata(may(char(string('a'))), string('a'))), 1
    test.equal  solve(parsedata(begin(may(char(string('a'))), eoi), string('a'))), true
    test.equal  solve(parsedata(begin(may(char(string('a'))), char(string('a')), eoi), string('a'))), true
    test.equal  solve(parsedata(begin(greedymay(char(string('a'))), char(string('a')), eoi), string('a'))), 1
    test.equal  solve(parsedata(begin(lazymay(char(string('a'))), char(string('a')), eoi), string('a'))), 1
    test.equal  solve(parsedata(may(char(string('a'))), string('b'))), 0
    test.done()

#exports.Test =
  "test lazyany": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(lazyany(char(_)), string('a')))), null
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsedata(lazyany(char(_), result, _), string('a')), getvalue(result))), []
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                setdata(string('ab')), lazyany(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), lazyany(char(_)), char(string('c')), eoi), string('abc'))), true
    test.equal  solve(parsedata(begin(lazyany(char(string('a'))), nextchar), string('b'))), 'b'
    test.equal  solve(parsedata(begin(lazyany(char(string('a'))), eoi), string('b'))), 0
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(lazyany(begin(char(_), print_(getvalue(_)))), string('abc')))), null
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(findall(lazyany(begin(char(_), print_(getvalue(_))))), string('abc')))), 3
    test.done()

#xexports.Test =
  "test any": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(any(char(_)), string('a')))), 1
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(any(char(_)), string('ab')))), 2
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), any(char(_)), eoi), string('abc'))), true
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsedata(any(char(_), result, _), string('a')), getvalue(result))), ['a']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                setdata(string('ab')), any(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), any(char(_)), char(string('c')), eoi), string('abc'))), true
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), any(char(string('a')))), string('b'))), 0
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), any(char(string('a'))), eoi), string('b'))), false
    test.done()

#xexports.Test =
  "test greedyany": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(greedyany(char(_)), string('abc')))), 3
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), greedyany(char(_)), eoi), string('a'))), true
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), greedyany(char(_)), char(string('c')), eoi), string('ac'))), 2
#    test.equal  solve(parsedata(findall(begin(assign(_, dummy('__')), greedyany(char(_)), char(string('c')), eoi)), string('abc'))), 3
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsedata(greedyany(char(_), result, _), string('a')), getvalue(result))), ['a']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                setdata(string('ab')), greedyany(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.done()

#xexports.Test =
  "test lazysome": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(lazysome(char(_)), string('a')))), null
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsedata(lazysome(char(_), result, _), string('a')), getvalue(result))), ['a']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                setdata(string('ab')), lazysome(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), lazysome(char(_)), char(string('c')), eoi), string('abc'))), true
    test.equal  solve(parsedata(begin(lazysome(char(string('a'))), nextchar), string('b'))), false
    test.equal  solve(parsedata(begin(lazysome(char(string('a'))), eoi), string('b'))), false
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(lazysome(begin(char(_), print_(getvalue(_)))), string('abc')))), null
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(findall(lazysome(begin(char(_), print_(getvalue(_))))), string('abc')))), 3
    test.done()

#xexports.Test =
  "test greedysome": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(greedysome(char(_)), string('abc')))), 3
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), greedysome(char(_)), eoi), string('a'))), true
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), greedysome(char(_)), char(string('c')), eoi), string('ac'))), 2
    test.equal  solve(parsedata(findall(begin(assign(_, dummy('__')), greedysome(char(_)), char(string('c')), eoi)), string('abc'))), 3
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsedata(greedysome(char(_), result, _), string('a')), getvalue(result))), ['a']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                setdata(string('ab')), greedysome(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.equal  solve(parsedata(orp(begin(assign(_, dummy('__')), greedysome(char(_)), char(string('c')), eoi), 1), string('abc'))), 1
    test.done()

#xexports.Test =
  "test some": (test) ->
    _ = vari('__')
    result = vari('result')
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(some(char(_)), string('a')))), 1
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(some(char(_)), string('ab')))), 2
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), some(char(_)), eoi), string('abc'))), true
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsedata(some(char(_), result, _), string('a')), getvalue(result))), ['a']
    test.equal core.status, core.SUCCESS
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                setdata(string('ab')), some(char(_), result, _), eoi, getvalue(result))), ['a', 'b']
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), some(char(_)), char(string('c')), eoi), string('abc'))), true
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), some(char(string('a')))), string('b'))), 0
    test.equal  solve(parsedata(begin(assign(_, dummy('__')), some(char(string('a'))), eoi), string('b'))), false
    test.done()

#exports.Test =
  "test times": (test) ->
    _ = vari('__')
    result = vari('result')
    n = vari('n')
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(times(char(_), 1), string('a')))), true
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(times(char(_), 2), string('ab')))), true
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(times(char(_), 3), string('abc')))), true
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')),\
                                setdata(string('ab')), times(char(_), n), eoi)), true
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),\
                                parsedata(times(char(_), 2, result, _), string('ab')), getvalue(result))), ['a', 'b']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),\
                                parsedata(times(char(_), 3, result, _), string('abc')), getvalue(result))), ['a', 'b', 'c']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')), assign(result, logicvar('result')),\
                                setdata(string('ab')), times(char(_), n, result, _), eoi, getvalue(result))), ['a', 'b']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')),\
                                setdata(string('aabb')), times(char(string('a')), n), times(char(string('b')), n), eoi, getvalue(n))), 2
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')), assign(result, logicvar('result')),
                                setdata(string('ab')), times(char(_), n, result, _), eoi, getvalue(n))), 2
    test.deepEqual  solve(begin(setdata(string('aaabbb')), assign(n, logicvar('n')), assign(result, logicvar('result')),\
                                 times(char(string('a')), n, result, string('a')), times(char(string('b')), n), eoi, getvalue(n))), 3
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')), assign(result, logicvar('result')),\
                                setdata(string('abc')), times(char(_), n, result, _), char(string('c')), eoi, getvalue(result))), ['a', 'b']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')), assign(result, logicvar('result')),\
                                setdata(string('abc')), times(char(_), n, result, _), char(string('b')), char(string('c')), eoi, getvalue(result))), ['a']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')),\
                                setdata(string('aaabbb')), times(char(string('a')), n), times(char(string('b')), n), eoi, getvalue(n))), 3
    test.deepEqual(solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')), assign(result, logicvar('result')),\
                               setdata(string('a')), times(char(_), n, result, _),\
                               char(string('a')), eoi, getvalue(result))), []);
    test.deepEqual  solve(begin(setdata(string('aaabbb')), assign(n, logicvar('n')), assign(result, logicvar('result')),
                                times(char(string('a')), n, result, string('a')),
                                times(char(string('b')), n, result, string('b')), eoi, getvalue(result))), false
    test.deepEqual  solve(begin(setdata(string('aaabbb')), assign(n, logicvar('n')), assign(result, dummy('result')),
                                times(char(string('a')), n, result, string('a')),
                                times(char(string('b')), n, result, string('b')), eoi, getvalue(result))), ['b', 'b', 'b']
    test.done()

#xexports.Test =
  "test seplist": (test) ->
    _ = vari('__')
    result = vari('result')
    n = vari('n')
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(seplist(char(_)), string('a')))), 1
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(seplist(char(_)), string('a a')))), 3
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(seplist(char(_), {sep:char(string(','))}), string('a,a')))), 3
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(seplist(char(_), {sep:char(string(',')), times:3}),
                                                              string('a,a, a')))), true
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(seplist(char(_), {sep:char(string(',')), times:3}), string('a,a,b')))), true
    test.equal  solve(begin(assign(_, dummy('__')), parsedata(seplist(char(_), {sep:char(string(',')), times:3}), string('a,a,')))), false
    test.done()

#exports.Test =
  "test seplist2": (test) ->
    _ = vari('__')
    result = vari('result')
    n = vari('n')
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(result, logicvar('result')),
                                parsedata(seplist(char(_), {sep:char(string(',')), times:3, result:result, template:string('a')}),
                                          string('a,a,a')), getvalue(result))), ['a', 'a','a']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')), assign(result, logicvar('result')),
                                parsedata(seplist(char(_), {sep:char(string(',')), times:3, result:result, template:_}),
                                          string('a,b,c')), getvalue(result))), ['a', 'b','c']   #
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')), assign(result, logicvar('result')),
                                parsedata(seplist(char(_), {sep:char(string(',')), times:n, result:result, template:_}),
                                          string('a,b,c')), getvalue(result))), ['a', 'b','c']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')), assign(result, logicvar('result')),
                                parsedata(andp(seplist(char(_), {sep:char(string(',')), times:n, result:result, template:_}),
                                               char(string(',')), char(string('c'))), string('a,b,c')), getvalue(result))), ['a', 'b']
    test.deepEqual  solve(begin(assign(_, dummy('__')), assign(n, logicvar('n')), assign(result, logicvar('result')),
                                parsedata(andp(seplist(char(_), {sep:char(string(',')), times:n, result:result, template:_}),
                                               char(string(',')), char(string('b')),
                                               char(string(',')), char(string('c'))), string('a,b,c')), getvalue(result))), ['a']
    test.done()

xexports.Test =
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
