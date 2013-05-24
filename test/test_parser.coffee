I = require "./importer"

base = "../lib/"
I.use base+"dao: Trail, solve, fun, macro vari debug dummy"
I.use base+"builtins/lisp: begin"
I.use base+"builtins/logic: andp orp notp succeed fail unify findall once "
I.use base+"""builtins/parser: char parsetext settext may greedymay
           any greedyany lazyany some greedysome lazysome eoi nextchar, times seplist"""
I.use base+"builtins/general: getvalue print_"

dao = require base+"dao"

xexports = {}

exports.Test =
  "test char": (test) ->
    test.equal  solve(parsetext(char('a'), 'a')), null
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(char('a'), 'b')), null
    test.equal dao.status, dao.FAIL
    test.equal  solve(begin(settext('a'), char('a'))), null
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(andp(char('a'), char('b')), 'ab')), null
    test.equal dao.status, dao.SUCCESS
    test.done()

  "test may char": (test) ->
    test.equal  solve(parsetext(may(char('a')), 'a')), null
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(may(char('a')), eoi), 'a')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(may(char('a')), char('a'), eoi), 'a')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(greedymay(char('a')), char('a'), eoi), 'a')), null
    test.equal dao.status, dao.FAIL
    test.equal  solve(parsetext(may(char('a')), 'b')), null
    test.equal dao.status, dao.SUCCESS
    test.done()

  "test greedyany": (test) ->
    _ = dummy('_')
    result = vari('result')
    test.equal  solve(parsetext(greedyany(char(_)), 'abc')), 3
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(greedyany(char(_)), eoi), 'a')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(greedyany(char(_)), char('c'), eoi), 'ac')), 2
    test.equal dao.status, dao.FAIL
    test.equal  solve(parsetext(findall(begin(greedyany(char(_)), char('c'), eoi)), 'abc')), 3
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(parsetext(greedyany(char(_), result, _), 'a'), result)), ['a']
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(settext('ab'), greedyany(char(_), result, _), eoi, result)), ['a', 'b']
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(orp(begin(greedyany(char(_)), char('c'), eoi), 1), 'abc')), 1
    test.equal dao.status, dao.SUCCESS
    test.done()

  "test any": (test) ->
    _ = dummy('_')
    result = vari('result')
    test.equal  solve(parsetext(any(char(_)), 'a')), 1
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(any(char(_)), 'ab')), 2
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(any(char(_)), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(parsetext(any(char(_), result, _), 'a'), result)), ['a']
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(settext('ab'), any(char(_), result, _), eoi, result)), ['a', 'b']
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(any(char(_)), char('c'), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(any(char('a')), 'b')), null
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(any(char('a')), eoi), 'b')), null
    test.equal dao.status, dao.FAIL
    test.equal  solve(parsetext(eoi, '')), true
    test.equal dao.status, dao.SUCCESS
    test.done()

  "test lazyany": (test) ->
    _ = dummy('_')
    result = vari('result')
    test.equal  solve(parsetext(lazyany(char(_)), 'a')), null
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(parsetext(lazyany(char(_), result, _), 'a'), result)), []
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(settext('ab'), lazyany(char(_), result, _), eoi, result)), ['a', 'b']
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(lazyany(char(_)), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(lazyany(char(_)), char('c'), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(lazyany(char('a')), nextchar), 'b')), 'b'
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(lazyany(char('a')), eoi), 'b')), null
    test.equal dao.status, dao.FAIL
    test.equal  solve(parsetext(eoi, '')), true
    test.equal dao.status, dao.SUCCESS
    debug("solve(parsetext(lazyany(begin(char(_), print_(getvalue(_)))), 'abc'))")
    test.equal  solve(parsetext(lazyany(begin(char(_), print_(getvalue(_)))), 'abc')), null
    test.equal dao.status, dao.SUCCESS
    debug("solve(parsetext(findall(lazyany(begin(char(_), print_(getvalue(_))))), 'abc'))")
    test.equal  solve(parsetext(findall(lazyany(begin(char(_), print_(getvalue(_))))), 'abc')), null
    test.equal dao.status, dao.SUCCESS
    test.done()

  "test greedysome": (test) ->
    _ = dummy('_')
    result = vari('result')
    test.equal  solve(parsetext(greedysome(char(_)), 'abc')), 3
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(greedysome(char(_)), eoi), 'a')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(greedysome(char(_)), char('c'), eoi), 'ac')), 2
    test.equal dao.status, dao.FAIL
    test.equal  solve(parsetext(findall(begin(greedysome(char(_)), char('c'), eoi)), 'abc')), 3
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(parsetext(greedysome(char(_), result, _), 'a'), result)), ['a']
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(settext('ab'), greedysome(char(_), result, _), eoi, result)), ['a', 'b']
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(orp(begin(greedysome(char(_)), char('c'), eoi), 1), 'abc')), 1
    test.equal dao.status, dao.SUCCESS
    test.done()

  "test some": (test) ->
    _ = dummy('_')
    result = vari('result')
    test.equal  solve(parsetext(some(char(_)), 'ab')), 2
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(some(char(_)), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(parsetext(some(char(_), result, _), 'ab'), result)), ['a', 'b']
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(parsetext(some(char(_), result, _), ''), result)), null
    test.equal dao.status, dao.FAIL
    test.deepEqual  solve(begin(settext('ab'), some(char(_), result, _), eoi, result)), ['a', 'b']
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(some(char(_)), char('c'), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(some(char('a')), 'b')), null
    test.equal dao.status, dao.FAIL
    test.equal  solve(parsetext(begin(some(char('a')), eoi), 'b')), null
    test.equal dao.status, dao.FAIL
    test.equal  solve(parsetext(eoi, '')), true
    test.equal dao.status, dao.SUCCESS
    test.done()

  "test lazysome": (test) ->
    _ = dummy('_')
    result = vari('result')
    test.equal  solve(parsetext(lazysome(char(_)), 'a')), 1
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(parsetext(lazysome(char(_), result, _), 'a'), result)), ['a']
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(settext('ab'), lazysome(char(_), result, _), eoi, result)), ['a', 'b']
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(lazysome(char(_)), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(lazysome(char(_)), char('c'), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(lazysome(char('a')), nextchar), 'b')), null
    test.equal dao.status, dao.FAIL
    test.equal  solve(parsetext(begin(lazysome(char('a')), eoi), 'b')), null
    test.equal dao.status, dao.FAIL
    test.equal  solve(parsetext(eoi, '')), true
    test.equal dao.status, dao.SUCCESS
    debug("solve(parsetext(lazysome(begin(char(_), print_(getvalue(_)))), 'abc'))")
    test.equal  solve(parsetext(lazysome(begin(char(_), print_(getvalue(_)))), 'abc')), null
    test.equal dao.status, dao.SUCCESS
    debug("solve(parsetext(findall(lazysome(begin(char(_), print_(getvalue(_))))), 'abc'))")
    test.equal  solve(parsetext(findall(lazysome(begin(char(_), print_(getvalue(_))))), 'abc')), null
    test.equal dao.status, dao.SUCCESS
    test.done()

  "test times": (test) ->
    _ = dummy('_')
    result = vari('result')
    n = vari('n')
    test.equal  solve(parsetext(times(char(_), 1), 'a')), 1
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(times(char(_), 2), 'ab')), 2
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(times(char(_), 3), 'abc')), 3
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(settext('ab'), times(char(_), n), eoi)), true
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(parsetext(times(char(_), 2, result, _), 'ab'), result)), ['a', 'b']
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(parsetext(times(char(_), 3, result, _), 'abc'), result)), ['a', 'b', 'c']
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(settext('ab'), times(char(_), n, result, _), eoi, n)), 2
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(settext('ab'), times(char(_), n, result, _), eoi, result)), ['a', 'b']
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(settext('aabb'), times(char('a'), n), times(char('b'), n), eoi, n)), 2
    test.equal dao.status, dao.SUCCESS
    n.binding = n
    test.deepEqual  solve(begin(settext('abc'), times(char(_), n, result, _), char('c'), eoi, result)), ['a', 'b']
    test.equal dao.status, dao.SUCCESS
    n.binding = n
    test.deepEqual  solve(begin(settext('abc'), times(char(_), n, result, _), char('b'), char('c'), eoi, result)), ['a']
    test.equal dao.status, dao.SUCCESS
    n.binding = n
    test.deepEqual  solve(begin(settext('aaabbb'), times(char('a'), n), times(char('b'), n), eoi, n)), 3
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(settext('aaabbb'), times(char('a'), n, result, 'a'), times(char('b'), n), eoi, n)), 3
    test.equal dao.status, dao.SUCCESS
    test.deepEqual  solve(begin(settext('aaabbb'), times(char('a'), n, result, 'a'), times(char('b'), n, result, 'b'), eoi, result)), ['b', 'b', 'b']
    test.equal dao.status, dao.SUCCESS
    n.binding = n;
    test.deepEqual(solve(begin(settext('a'), times(char(_), n, result, _), char('a'), eoi, result)), []);
    test.equal(dao.status, dao.SUCCESS);
    test.done()

  "test seplist": (test) ->
    _ = dummy('_')
    result = vari('result')
    n = vari('n')
    test.equal  solve(parsetext(seplist(char(_)), 'a')), 1
    test.equal(dao.status, dao.SUCCESS);
    test.equal  solve(parsetext(seplist(char(_)), 'a a')), 3
    test.equal(dao.status, dao.SUCCESS);
    test.equal  solve(parsetext(seplist(char(_), {sep:char(',')}), 'a,a')), 3
    test.equal(dao.status, dao.SUCCESS);
    test.equal  solve(parsetext(seplist(char(_), {sep:char(','), times:3}), 'a,a, a')), 5
    test.equal(dao.status, dao.SUCCESS);
    test.deepEqual  solve(begin(parsetext(seplist(char(_), {sep:char(','), times:3, result:result, template:'a'}), 'a,a,a'), result)), ['a', 'a','a']
    test.equal(dao.status, dao.SUCCESS);
    test.deepEqual  solve(begin(parsetext(seplist(char(_), {sep:char(','), times:3, result:result, template:_}), 'a,b,c'), result)), ['a', 'b','c']
    test.equal(dao.status, dao.SUCCESS);
    n.binding = n;
    test.deepEqual  solve(begin(parsetext(seplist(char(_), {sep:char(','), times:n, result:result, template:_}), 'a,b,c'), result)), ['a', 'b','c']
    test.equal(dao.status, dao.SUCCESS);
    n.binding = n;
    test.deepEqual  solve(begin(parsetext(andp(seplist(char(_), {sep:char(','), times:n, result:result, template:_}), char(','), char('c')), 'a,b,c'), result)), ['a', 'b']
    test.equal(dao.status, dao.SUCCESS);
    n.binding = n;
    test.deepEqual  solve(begin(parsetext(andp(seplist(char(_), {sep:char(','), times:n, result:result, template:_}), char(','), char('b'), char(','), char('c')), 'a,b,c'), result)), ['a']
    test.equal(dao.status, dao.SUCCESS);
    test.done()

xexports.Test =
  "test": (test) ->
    _ = dummy('_')
    result = vari('result')
    n = vari('n');
    test.deepEqual  solve(begin(parsetext(seplist(char(_), {sep:char(','), times:n, result:result, template:_}), 'a,b,c'), result)), ['a', 'b','c']
    test.equal(dao.status, dao.SUCCESS);
    test.deepEqual  solve(begin(parsetext(andp(seplist(char(_), {sep:char(','), times:n, result:result, template:_}), char(','), char('c')), 'a,b,c'), result)), ['a', 'b']
    test.equal(dao.status, dao.SUCCESS);
    test.done()
