I = require "../test/importer"

base = "../src/"
I.use base+"solve: Trail, solve, fun, macro vari debug dummy"
I.use base+"builtins/lisp: begin"
I.use base+"builtins/logic: andp orp notp succeed fail unify findall once "
I.use base+"builtins/parser: char parsetext settext may any greedyany lazyany eoi"
I.use base+"builtins/general: getvalue print_"

dao = require base+"solve"

xexports = {}

xexports.Test =
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
    test.equal  solve(parsetext(begin(may(char('a')), eoi), 'ab')), null
    test.equal dao.status, dao.FAIL
    test.equal  solve(parsetext(may(char('a')), 'b')), null
    test.equal dao.status, dao.SUCCESS
    test.done()

exports.Test =
  "test greedyany": (test) ->
    _ = dummy('_')
    test.equal  solve(parsetext(greedyany(char(_)), 'a')), 1
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(greedyany(char(_)), 'ab')), 2
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(greedyany(char(_)), 'abc')), 3
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(greedyany(char(_)), eoi), 'a')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(greedyany(char(_)), char('c'), eoi), 'ac')), 2
    test.equal dao.status, dao.FAIL
    test.equal  solve(parsetext(findall(begin(greedyany(char(_)), char('c'), eoi)), 'abc')), 3
    test.equal dao.status, dao.SUCCESS
    debug("solve(parsetext(findall(greedyany(begin(char(_), print_(getvalue(_))))), 'abc'))")
    test.equal  solve(parsetext(findall(greedyany(begin(char(_), print_(getvalue(_))))), 'abc')), null
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(greedyany(char('a')), 'aa')), null
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(greedyany(char('a')), 'b')), null
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(orp(begin(greedyany(char(_)), char('c'), eoi), print_('a')), 'abc')), null
    test.equal dao.status, dao.SUCCESS
    test.done()

  "test any": (test) ->
    _ = dummy('_')
    test.equal  solve(parsetext(any(char(_)), 'a')), 1
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(any(char(_)), 'ab')), 2
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(any(char(_)), 'abc')), 3
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(any(char(_)), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(any(char(_)), char('c'), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(any(char('a')), 'a')), null
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(any(char('a')), 'aa')), null
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
    test.deepEqual  solve(begin(parsetext(lazyany(char(_), result, _), 'a'), result)), []
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(begin(parsetext(lazyany(char(_, result, _)), 'a'), result)), ['a']
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(lazyany(char(_)), 'abc')), null
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(lazyany(char(_)), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(begin(lazyany(char(_)), char('c'), eoi), 'abc')), true
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(lazyany(char('a')), 'a')), null
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(lazyany(char('a')), 'aa')), null
    test.equal dao.status, dao.SUCCESS
    test.equal  solve(parsetext(lazyany(char('a')), 'b')), null
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

  "test lazyany2": (test) ->
    _ = dummy('_')
    result = vari('result')
    test.deepEqual  solve(begin(parsetext(lazyany(char(_), result, _), 'a'), result)), []
    test.equal dao.status, dao.SUCCESS
    test.done()
