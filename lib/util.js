// Generated by CoffeeScript 1.6.2
(function() {
  var andp, any, assign, begin, bind, block, break_, char, charIn, charWhen, continue_, defaultLabel, e, getvalue, greedyany, if_, iff, il, inc, incp, index, instance, io, isLabel, jsbreak, jscontinue, jsfun, lambda, lazyany, list, macro, makeLabel, name, not_, orp, push, pushp, quasiquote, sideEffect, string, stringIn, stringIn0, stringWhile, stringWhile0, times, unify, uniqueconst, uniquevar, unquote, unquoteSlice, vari, variable, vop, _, _o,
    __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  _ = require('underscore');

  vari = function(name) {
    return name;
  };

  exports.vars = function(names) {
    var name, _i, _len, _ref, _results;

    _ref = split(names, reElements);
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      name = _ref[_i];
      _results.push(vari(name));
    }
    return _results;
  };

  exports.nonlocal = function() {
    var names;

    names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return ['nonlocal'].concat(__slice.call(names));
  };

  exports.variable = variable = function() {
    var names;

    names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return ['variable'].concat(__slice.call(names));
  };

  exports.string = string = function(s) {
    return ["string", s];
  };

  exports.quote = function(exp) {
    return ["quote", exp];
  };

  exports.eval_ = function(exp, path) {
    return ["eval", exp, path];
  };

  exports.begin = begin = function() {
    var exps;

    exps = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return ["begin"].concat(exps);
  };

  exports.assign = assign = function(left, exp) {
    return ["assign", left, exp];
  };

  exports.addassign = function(left, exp) {
    return ["augment-assign", 'add', left, exp];
  };

  exports.subassign = function(left, exp) {
    return ["augment-assign", 'sub', left, exp];
  };

  exports.mulassign = function(left, exp) {
    return ["augment-assign", 'mul', left, exp];
  };

  exports.divassign = function(left, exp) {
    return ["augment-assign", 'div', left, exp];
  };

  exports.modassign = function(left, exp) {
    return ["augment-assign", 'mod', left, exp];
  };

  exports.andassign = function(left, exp) {
    return ["augment-assign", 'and_', left, exp];
  };

  exports.orassign = function(left, exp) {
    return ["augment-assign", 'or_', left, exp];
  };

  exports.bitandassign = function(left, exp) {
    return ["augment-assign", 'bitand', left, exp];
  };

  exports.bitorassign = function(left, exp) {
    return ["augment-assign", 'bitor', left, exp];
  };

  exports.bitxorassign = function(left, exp) {
    return ["augment-assign", 'bitxor', left, exp];
  };

  exports.lshiftassign = function(left, exp) {
    return ["augment-assign", 'lshift', left, exp];
  };

  exports.rshiftassign = function(left, exp) {
    return ["augment-assign", 'rshift', left, exp];
  };

  exports.if_ = if_ = function(test, then_, else_) {
    return ["if", test, then_, else_];
  };

  exports.iff = iff = function(clauses, else_) {
    var length, test, then_, _ref;

    length = clauses.length;
    if (length === 0) {
      throw new Error("iff clauses should have at least one clause.");
    } else {
      _ref = clauses[0], test = _ref[0], then_ = _ref[1];
      if (length === 1) {
        return if_(test, then_, else_);
      } else {
        return if_(test, then_, iff(clauses.slice(1), else_));
      }
    }
  };

  exports.switch_ = function(test, clauses, else_) {
    return ['switch', test, clauses, else_];
  };

  exports.array = function() {
    var args;

    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return ["array"].concat(__slice.call(args));
  };

  exports.uarray = function() {
    var args;

    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return ["uarray"].concat(__slice.call(args));
  };

  exports.cons = function(head, tail) {
    return ["cons", head, tail];
  };

  exports.makeobject = function() {
    var args;

    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return ["makeobject"].concat(__slice.call(args));
  };

  exports.uobject = function() {
    var args;

    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return ["uobject"].concat(__slice.call(args));
  };

  exports.funcall = function() {
    var args, caller;

    caller = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return ["funcall", caller].concat(__slice.call(args));
  };

  exports.macall = function() {
    var args, caller;

    caller = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return ["macall", caller].concat(__slice.call(args));
  };

  exports.jsobject = function(exp) {
    return ["jsobject", exp];
  };

  exports.jsfun = jsfun = function(exp) {
    return ["jsfun", exp];
  };

  exports.pure = io = function(exp) {
    return ["pure", exp];
  };

  exports.effect = sideEffect = function(exp) {
    return ["effect", exp];
  };

  exports.io = io = function(exp) {
    return ["io", exp];
  };

  exports.lamda = lambda = function() {
    var body, params;

    params = arguments[0], body = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return ["lambda", params].concat(body);
  };

  exports.macro = macro = function() {
    var body, params;

    params = arguments[0], body = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return ["macro", params].concat(body);
  };

  exports.qq = quasiquote = function(exp) {
    return ["quasiquote", exp];
  };

  exports.uq = unquote = function(exp) {
    return ["unquote", exp];
  };

  exports.uqs = unquoteSlice = function(exp) {
    return ["unquote-slice", exp];
  };

  isLabel = function(label) {
    return _.isArray(label) && label.length === 2 && label[0] === 'label';
  };

  exports.makeLabel = makeLabel = function(label) {
    return ['label', label];
  };

  defaultLabel = ['label', ''];

  exports.block = block = function() {
    var body, label;

    label = arguments[0], body = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if (!isLabel(label)) {
      label = makeLabel('');
      body = [label].concat(body);
    }
    return ['block', label].concat(__slice.call(body));
  };

  exports.break_ = break_ = function(label, value) {
    if (label == null) {
      label = defaultLabel;
    }
    if (value == null) {
      value = null;
    }
    if (value !== null && !isLabel(label)) {
      throw new TypeError([label, value]);
    }
    if (value === null && !isLabel(label)) {
      value = label;
      label = makeLabel('');
    }
    return ['break', label, value];
  };

  exports.continue_ = continue_ = function(label) {
    if (label == null) {
      label = defaultLabel;
    }
    return ['continue', label];
  };

  exports.jsbreak = jsbreak = function(label) {
    return ['jsbreak', label];
  };

  exports.jscontinue_ = jscontinue = function(label) {
    return ['jscontinue', label];
  };

  exports.loop_ = function() {
    var body, label;

    label = arguments[0], body = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if (!isLabel(label)) {
      label = defaultLabel;
      body = [label].concat(body);
    }
    return block.apply(null, [label].concat(__slice.call(body.concat([continue_(label)]))));
  };

  exports.while_ = function() {
    var body, label, test;

    label = arguments[0], test = arguments[1], body = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
    if (!isLabel(label)) {
      label = defaultLabel;
      test = label;
      body = [test].concat(body);
    }
    return block.apply(null, [label].concat(__slice.call([if_(not_(test), break_(label))].concat(body).concat([continue_(label)]))));
  };

  exports.until_ = function() {
    var body, label, test, _i;

    label = arguments[0], body = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), test = arguments[_i++];
    if (!isLabel(label)) {
      label = defaultLabel;
      test = label;
      body = [test].concat(body);
    }
    body = body.concat([if_(not_(test), continue_(label))]);
    return block.apply(null, [label].concat(__slice.call(body)));
  };

  exports.dowhile = function() {
    var body, label, test, _i;

    label = arguments[0], body = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), test = arguments[_i++];
    if (!isLabel(label)) {
      label = defaultLabel;
      test = label;
      body = [test].concat(body);
    }
    body = body.concat([if_(test, continue_(label))]);
    return block.apply(null, [label].concat(__slice.call(body)));
  };

  exports.for_ = function() {
    var body, init, step, test;

    init = arguments[0], test = arguments[1], step = arguments[2], body = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
    return ['for', init, test, step].concat(__slice.call(body));
  };

  exports.forin = function() {
    var body, container, vari;

    vari = arguments[0], container = arguments[1], body = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
    return ['forin', vari, container].concat(__slice.call(body));
  };

  exports.try_ = function(test, catches, final) {
    return ['try', test, catches, final];
  };

  exports.catch_ = function() {
    var forms, tag;

    tag = arguments[0], forms = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return ['catch', tag].concat(__slice.call(forms));
  };

  exports.throw_ = function(tag, form) {
    return ['throw', tag, form];
  };

  exports.protect = function() {
    var cleanup, form;

    form = arguments[0], cleanup = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return ['unwind-protect', form].concat(__slice.call(cleanup));
  };

  exports.callcc = function(fun) {
    return ['callcc', fun];
  };

  exports.print_ = function() {
    var exps;

    exps = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return ['funcall', io(jsfun('console.log'))].concat(exps);
  };

  exports.vop = vop = function() {
    var args, name;

    name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return ["vop_" + name].concat(args);
  };

  exports.inc = inc = function(item) {
    return ['inc', item];
  };

  exports.suffixinc = function(item) {
    return ['suffixinc', item];
  };

  exports.dec = function(item) {
    return ['dec', item];
  };

  exports.suffixdec = function(item) {
    return ['suffixdec', item];
  };

  exports.incp = incp = function(item) {
    return ['incp', item];
  };

  exports.suffixincp = function(item) {
    return ['suffixincp', item];
  };

  exports.decp = function(item) {
    return ['decp', item];
  };

  exports.suffixdecp = function(item) {
    return ['suffixdecp', item];
  };

  il = require("./interlang");

  for (name in il) {
    _o = il[name];
    try {
      instance = typeof _o === "function" ? _o() : void 0;
    } catch (_error) {
      e = _error;
      continue;
    }
    if (instance instanceof il.VirtualOperation && __indexOf.call(il.excludes, name) < 0) {
      (function(name) {
        return exports[name] = function() {
          var args;

          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return vop.apply(null, [name].concat(__slice.call(args)));
        };
      })(name);
    }
  }

  list = exports.list;

  push = exports.push;

  exports.pushp = pushp = function(list, value) {
    return ['pushp', list, value];
  };

  not_ = exports.not_;

  exports.logicvar = function(name) {
    return ['logicvar', name];
  };

  exports.dummy = function(name) {
    return ['dummy', name];
  };

  exports.unify = unify = function(x, y) {
    return ['unify', x, y];
  };

  exports.notunify = function(x, y) {
    return ['notunify', x, y];
  };

  exports.succeed = ['succeed'];

  exports.fail = ['fail'];

  exports.andp = andp = exports.begin;

  exports.orp = orp = function() {
    var exps, length;

    exps = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    length = exps.length;
    if (length === 0) {
      throw new ArgumentError(exps);
    } else if (length === 1) {
      return exps[0];
    } else if (length === 2) {
      return ['orp'].concat(__slice.call(exps));
    } else {
      return ['orp', exps[0], orp.apply(null, exps.slice(1))];
    }
  };

  exports.notp = function(goal) {
    return ['notp', goal];
  };

  exports.repeat = ['repeat'];

  exports.cutable = function(goal) {
    return ['cutable', goal];
  };

  exports.cut = ['cut'];

  exports.once = function(goal) {
    return ['once', goal];
  };

  exports.findall = function(goal, result, template) {
    return ['findall', goal, result, template];
  };

  exports.is_ = function(vari, exp) {
    return ['is_', vari, exp];
  };

  exports.bind = bind = function(vari, term) {
    return ['bind', vari, term];
  };

  exports.getvalue = getvalue = function(term) {
    return ['getvalue', term];
  };

  exports.parse = function(exp, state) {
    return ['parse', exp, state];
  };

  exports.parsetext = function(exp, text) {
    return ['parsetext', exp, text];
  };

  exports.settext = function(text) {
    return ['settext', text];
  };

  exports.setpos = function(pos) {
    return ['setpos', pos];
  };

  exports.setstate = function(state) {
    return ['setstate', state];
  };

  exports.getstate = ['getstate'];

  exports.gettext = ['gettext'];

  exports.getpos = ['getpos'];

  exports.eoi = ['eoi'];

  exports.boi = ['boi'];

  exports.eol = ['eol'];

  exports.bol = ['bol'];

  exports.step = function(n) {
    return ['step', n];
  };

  exports.lefttext = ['lefttext'];

  exports.subtext = function(length, start) {
    return ['subtext', length, start];
  };

  exports.nextchar = ['nextchar'];

  exports.may = function(exp) {
    return ['may', exp];
  };

  exports.lazymay = function(exp) {
    return ['lazymay', exp];
  };

  exports.greedymay = function(exp) {
    return ['greedymay', exp];
  };

  index = 1;

  exports.uniquevar = uniquevar = function(name) {
    return ['uniquevar', name, index++];
  };

  exports.uniqueconst = uniqueconst = function(name) {
    return ['uniqueconst', name, index++];
  };

  exports.any = any = function(exp, result, template) {
    var result1;

    if (result == null) {
      return ['any', exp];
    } else {
      result1 = uniqueconst('result');
      return begin(assign(result1, []), any(andp(exp, push(result1, getvalue(template)))), unify(result, result1));
    }
  };

  exports.lazyany = lazyany = function(exp, result, template) {
    var result1;

    if (result == null) {
      return ['lazyany', exp];
    } else {
      result1 = uniqueconst('result');
      return begin(assign(result1, []), lazyany(andp(exp, push(result1, getvalue(template)))), unify(result, result1));
    }
  };

  exports.greedyany = greedyany = function(exp, result, template) {
    var result1;

    if (result == null) {
      return ['greedyany', exp];
    } else {
      result1 = uniqueconst('result');
      return begin(assign(result1, []), greedyany(andp(exp, push(result1, getvalue(template)))), unify(result, result1));
    }
  };

  exports.some = function(exp, result, template) {
    var result1;

    if (result == null) {
      return andp(exp, ['any', exp]);
    } else {
      result1 = uniqueconst('result');
      return begin(['result'], assign(result1, []), exp, push(result1, getvalue(template)), any(andp(exp, push(result1, getvalue(template)))), unify(result, result1));
    }
  };

  exports.lazysome = function(exp, result, template) {
    var result1;

    if (result == null) {
      return andp(exp, ['lazyany', exp]);
    } else {
      result1 = uniqueconst('result');
      return begin(assign(result1, []), exp, push(result1, getvalue(template)), lazyany(andp(exp, push(result1, getvalue(template)))), unify(result, result1));
    }
  };

  exports.greedysome = function(exp, result, template) {
    var result1;

    if (result == null) {
      return andp(exp, ['greedyany', exp]);
    } else {
      result1 = uniqueconst('result');
      return begin(assign(result1, []), exp, push(result1, getvalue(template)), greedyany(andp(exp, push(result1, getvalue(template)))), unify(result, result1));
    }
  };

  exports.times = times = function(exp, expectTimes, result, template) {
    var n, result1;

    n = uniquevar('n');
    if (result == null) {
      return begin(variable(n), assign(n, 0), any(andp(exp, incp(n))), unify(expectTimes, n));
    } else {
      result1 = uniqueconst('result');
      return begin(variable(n), assign(n, 0), assign(result1, []), any(andp(exp, incp(n), pushp(result1, getvalue(template)))), unify(expectTimes, n), unify(result, result1));
    }
  };

  exports.seplist = function(exp, options) {
    var expectTimes, n, result, result1, sep, template;

    if (options == null) {
      options = {};
    }
    sep = options.sep || char(string(' '));
    expectTimes = options.times || null;
    result = options.result || null;
    template = options.template || null;
    if (result !== null) {
      result1 = uniqueconst('result');
    }
    if (expectTimes === null) {
      if (result === null) {
        return andp(exp, any(andp(sep, exp)));
      } else {
        return andp(assign(result1, []), exp, pushp(result1, getvalue(template)), any(andp(sep, exp, pushp(result1, getvalue(template)))), unify(result, result1));
      }
    } else if (_.isNumber(expectTimes)) {
      expectTimes = Math.floor(Math.max(0, expectTimes));
      if (result === null) {
        switch (expectTimes) {
          case 0:
            return succeed;
          case 1:
            return exp;
          default:
            return andp(exp, times(andp(sep, exp), expectTimes - 1));
        }
      } else {
        switch (expectTimes) {
          case 0:
            return unify(result, []);
          case 1:
            return andp(exp, unify(result, list(getvalue(template))));
          default:
            return andp(assign(result1, []), exp, pushp(result1, getvalue(template)), times(andp(sep, exp, pushp(result1, getvalue(template))), expectTimes - 1), unify(result, result1));
        }
      }
    } else {
      n = uniquevar('n');
      if (result === null) {
        return orp(andp(variable(n), exp, assign(n, 1), any(andp(sep, exp, incp(n))), unify(expectTimes, n)), unify(expectTimes, 0));
      } else {
        return orp(andp(variable(n), exp, assign(n, 1), assign(result1, list(getvalue(template))), any(andp(sep, exp, pushp(result1, getvalue(template)), incp(n))), unify(expectTimes, n), unify(result, result1)), andp(unify(expectTimes, 0), unify(result, [])));
      }
    }
  };

  exports.parallel = function(x, y) {
    return ['parallel', x, y];
  };

  exports.follow = function(x) {
    return ['follow', x];
  };

  exports.notfollow = function(x) {
    return ['notfollow', x];
  };

  exports.char = char = function(x) {
    return ['char', x];
  };

  exports.followChars = function(chars) {
    return ['followChars', chars];
  };

  exports.notFollowChars = function(chars) {
    return ['notFollowChars', chars];
  };

  exports.charWhen = charWhen = function(test) {
    return ['charWhen', test];
  };

  exports.charBetween = function(start, end) {
    return charWhen(function(c) {
      return (start < c && c < end);
    });
  };

  charIn = charIn = function(set) {
    return charWhen(function(c) {
      return __indexOf.call(set, c) >= 0;
    });
  };

  exports.digit = charWhen(function(c) {
    return ('0' <= c && c <= '9');
  });

  exports.digit1_9 = charWhen(function(c) {
    return ('1' <= c && c <= '9');
  });

  exports.lower = charWhen(function(c) {
    return ('a' <= c && c <= 'z');
  });

  exports.upper = charWhen(function(c) {
    return ('A' <= c && c <= 'Z');
  });

  exports.letter = charWhen(function(c) {
    return (('a' <= c && c <= 'z')) || (('A' <= c && c <= 'Z'));
  });

  exports.underlineLetter = charWhen(function(c) {
    return (c === '_') || (('a' <= c && c <= 'z')) || (('A' <= c && c <= 'Z'));
  });

  exports.underlineLetterDight = charWhen(function(c) {
    return (c === '_') || (('a' <= c && c <= 'z')) || (('A' <= c && c <= 'Z')) || (('0' <= c && c <= '9'));
  });

  exports.tabspace = charIn(' \t');

  exports.whitespace = charIn(' \t\r\n');

  exports.newline = charIn('\r\n');

  exports.spaces = ['spaces'];

  exports.spaces0 = ['spaces0'];

  exports.stringWhile = stringWhile = function(test) {
    return ['stringWhile', test];
  };

  exports.stringBetween = function(start, end) {
    return stringWhile(function(c) {
      return (start < c && c < end);
    });
  };

  exports.stringIn = stringIn = function(set) {
    return stringWhile(function(c) {
      return __indexOf.call(set, c) >= 0;
    });
  };

  exports.digits = stringWhile(function(c) {
    return ('0' <= c && c <= '9');
  });

  exports.digits1_9 = stringWhile(function(c) {
    return ('1' <= c && c <= '9');
  });

  exports.lowers = stringWhile(function(c) {
    return ('a' <= c && c <= 'z');
  });

  exports.uppers = stringWhile(function(c) {
    return ('A' <= c && c <= 'Z');
  });

  exports.letters = stringWhile(function(c) {
    return (('a' <= c && c <= 'z')) || (('A' <= c && c <= 'Z'));
  });

  exports.underlineLetters = stringWhile(function(c) {
    return (c === '_') || (('a' <= c && c <= 'z')) || (('A' <= c && c <= 'Z'));
  });

  exports.underlineLetterDights = stringWhile(function(c) {
    return (c === '_') || (('a' <= c && c <= 'z')) || (('A' <= c && c <= 'Z')) || (('0' <= c && c <= '9'));
  });

  exports.tabspaces = stringIn(' \t');

  exports.whitespaces = stringIn(' \t\r\n');

  exports.newlinespaces = stringIn('\r\n');

  exports.stringWhile0 = stringWhile0 = function(test) {
    return ['stringWhile0', test];
  };

  exports.stringBetween0 = function(start, end) {
    return stringWhile0(function(c) {
      return (start < c && c < end);
    });
  };

  exports.stringIn0 = stringIn0 = function(set) {
    return stringWhile0(function(c) {
      return __indexOf.call(set, c) >= 0;
    });
  };

  exports.digits0 = stringWhile0(function(c) {
    return ('0' <= c && c <= '9');
  });

  exports.digits1_90 = stringWhile0(function(c) {
    return ('1' <= c && c <= '9');
  });

  exports.lowers0 = stringWhile0(function(c) {
    return ('a' <= c && c <= 'z');
  });

  exports.uppers0 = stringWhile0(function(c) {
    return ('A' <= c && c <= 'Z');
  });

  exports.letters0 = stringWhile0(function(c) {
    return (('a' <= c && c <= 'z')) || (('A' <= c && c <= 'Z'));
  });

  exports.underlineLetters0 = stringWhile0(function(c) {
    return (c === '_') || (('a' <= c && c <= 'z')) || (('A' <= c && c <= 'Z'));
  });

  exports.underlineLetterDights0 = stringWhile0(function(c) {
    return (c === '_') || (('a' <= c && c <= 'z')) || (('A' <= c && c <= 'Z')) || (('0' <= c && c <= '9'));
  });

  exports.tabspaces0 = stringIn0(' \t');

  exports.whitespaces0 = stringIn0(' \t\r\n');

  exports.newlines0 = stringIn0('\r\n');

  exports.number = exports.float = function(arg) {
    return ['number', arg];
  };

  exports.literal = function(arg) {
    return ['literal', arg];
  };

  exports.followLiteral = function(arg) {
    return ['followLiteral', arg];
  };

  exports.notFollowLiteral = function(arg) {
    return ['notFollowLiteral', arg];
  };

  exports.quoteString = function(arg) {
    return ['quoteString', arg];
  };

  exports.dqstring = exports.quoteString('"');

  exports.sqstring = exports.quoteString("'");

}).call(this);

/*
//@ sourceMappingURL=util.map
*/