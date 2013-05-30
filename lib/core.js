// Generated by CoffeeScript 1.6.2
(function() {
  var ArgumentError, ArityError, BindingError, Command, Cons, DummyVar, Error, ExpressionError, Macro, Trail, TypeError, UArray, UObject, UnquoteSliceValue, Var, commandMaker, debug, dummy, nameToIndexMap, reElements, special, uarray, _, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __slice = [].slice;

  _ = require('underscore');

  exports.solve = function(exp, state) {
    exports.status = exports.UNKNOWN;
    return new exports.Solver(state).solve(exp);
  };

  exports.Solver = (function() {
    function Solver(state, trail, catches, exits, continues, purememo, memo) {
      var solver;

      this.state = state;
      this.trail = trail != null ? trail : new Trail;
      this.catches = catches != null ? catches : {};
      this.exits = exits != null ? exits : {};
      this.continues = continues != null ? continues : {};
      this.purememo = purememo != null ? purememo : {};
      this.memo = memo != null ? memo : {};
      this.finished = false;
      solver = this;
      this.done = function(value) {
        solver.finished = true;
        exports.status = exports.SUCCESS;
        return [null, value];
      };
      this.faildone = function(value) {
        solver.finished = true;
        exports.status = exports.SUCCESS;
        return [null, value];
      };
      this.failcont = this.faildone;
      this.cutCont = this.failcont;
    }

    Solver.prototype.fake = function() {
      var result, state;

      result = {};
      state = this.state;
      if (state != null) {
        state = (typeof state.slice === "function" ? state.slice(0) : void 0) || (typeof state.copy === "function" ? state.copy() : void 0) || (typeof state.clone === "function" ? state.clone() : void 0) || state;
      }
      result.state = state;
      result.trail = this.trail.copy();
      result.catches = _.extend({}, this.catches);
      result.exits = _.extend({}, this.exits);
      result.continues = _.extend({}, this.continues);
      result.purememo = _.extend({}, this.purememo);
      result.memo = _.extend({}, this.memo);
      result.done = this.done;
      result.faildone = this.faildone;
      result.failcont = this.failcont;
      result.cutCont = this.cutCont;
      return result;
    };

    Solver.prototype.restore = function(faked) {
      this.state = faked.state;
      this.trail = faked.trail;
      this.catches = faked.catches;
      this.exits = faked.exits;
      this.continues = faked.continues;
      this.purememo = faked.purememo;
      this.memo = faked.memo;
      this.done = faked.done;
      this.faildone = faked.faildone;
      this.failcont = faked.failcont;
      this.cutCont = faked.cutCont;
      return this.finished = false;
    };

    Solver.prototype.solve = function(exp, toCont) {
      var cont, fromCont, value, _ref;

      if (toCont == null) {
        toCont = this.done;
      }
      fromCont = this.cont(exp, toCont);
      _ref = this.run(null, fromCont), cont = _ref[0], value = _ref[1];
      return this.trail.getvalue(value);
    };

    Solver.prototype.run = function(value, cont) {
      var _ref;

      while (!this.finished) {
        _ref = cont(value), cont = _ref[0], value = _ref[1];
      }
      return [cont, value];
    };

    Solver.prototype.cont = function(exp, cont) {
      return (exp != null ? typeof exp.cont === "function" ? exp.cont(this, cont) : void 0 : void 0) || (function(v) {
        return cont(exp);
      });
    };

    Solver.prototype.expsCont = function(exps, cont) {
      var length;

      length = exps.length;
      if (length === 0) {
        throw exports.TypeError(exps);
      } else if (length === 1) {
        return this.cont(exps[0], cont);
      } else {
        return this.cont(exps[0], this.expsCont(exps.slice(1), cont));
      }
    };

    Solver.prototype.argsCont = function(args, cont) {
      var arg0, arg1, arg2, arg3, arg4, arg5, cont0, cont1, cont2, cont3, cont4, cont5, cont6, i, length, params, solver, _cont1, _cont2, _cont3, _cont4, _cont5, _cont6, _i, _ref;

      length = args.length;
      switch (length) {
        case 0:
          return function(v) {
            return cont([]);
          };
        case 1:
          cont0 = function(v) {
            return cont([v]);
          };
          return this.cont(args[0], cont0);
        case 2:
          arg0 = null;
          _cont1 = function(arg1) {
            return cont([arg0, arg1]);
          };
          cont1 = this.cont(args[1], _cont1);
          cont0 = function(v) {
            arg0 = v;
            return cont1(null);
          };
          return this.cont(args[0], cont0);
        case 3:
          arg0 = null;
          arg1 = null;
          _cont2 = function(arg2) {
            return cont([arg0, arg1, arg2]);
          };
          cont2 = this.cont(args[2], _cont2);
          _cont1 = function(v) {
            arg1 = v;
            return cont2(null);
          };
          cont1 = this.cont(args[1], _cont1);
          cont0 = function(v) {
            arg0 = v;
            return cont1(null);
          };
          return this.cont(args[0], cont0);
        case 4:
          arg0 = null;
          arg1 = null;
          arg2 = null;
          _cont3 = function(arg3) {
            return cont([arg0, arg1, arg2, arg3]);
          };
          cont3 = this.cont(args[3], _cont3);
          _cont2 = function(v) {
            arg2 = v;
            return cont3(null);
          };
          cont2 = this.cont(args[2], _cont2);
          _cont1 = function(v) {
            arg1 = v;
            return cont2(null);
          };
          cont1 = this.cont(args[1], _cont1);
          cont0 = function(v) {
            arg0 = v;
            return cont1(null);
          };
          return this.cont(args[0], cont0);
        case 5:
          arg0 = null;
          arg1 = null;
          arg2 = null;
          arg3 = null;
          _cont4 = function(arg4) {
            return cont([arg0, arg1, arg2, arg3, arg4]);
          };
          cont4 = this.cont(args[4], _cont4);
          _cont3 = function(v) {
            arg3 = v;
            return cont4(null);
          };
          cont3 = this.cont(args[3], _cont3);
          _cont2 = function(v) {
            arg2 = v;
            return cont3(null);
          };
          cont2 = this.cont(args[2], _cont2);
          _cont1 = function(v) {
            arg1 = v;
            return cont2(null);
          };
          cont1 = this.cont(args[1], _cont1);
          cont0 = function(v) {
            arg0 = v;
            return cont1(null);
          };
          return this.cont(args[0], cont0);
        case 6:
          arg0 = null;
          arg1 = null;
          arg2 = null;
          arg3 = null;
          arg4 = null;
          _cont5 = function(arg5) {
            return cont([arg0, arg1, arg2, arg3, arg4, arg5]);
          };
          cont5 = this.cont(args[5], _cont5);
          _cont4 = function(v) {
            arg4 = v;
            return cont5(null);
          };
          cont4 = this.cont(args[4], _cont4);
          _cont3 = function(v) {
            arg3 = v;
            return cont4(null);
          };
          cont3 = this.cont(args[3], _cont3);
          _cont2 = function(v) {
            arg2 = v;
            return cont3(null);
          };
          cont2 = this.cont(args[2], _cont2);
          _cont1 = function(v) {
            arg1 = v;
            return cont2(null);
          };
          cont1 = this.cont(args[1], _cont1);
          cont0 = function(v) {
            arg0 = v;
            return cont1(null);
          };
          return this.cont(args[0], cont0);
        case 7:
          arg0 = null;
          arg1 = null;
          arg2 = null;
          arg3 = null;
          arg4 = null;
          arg5 = null;
          _cont6 = function(arg6) {
            return cont([arg0, arg1, arg2, arg3, arg4, arg5, arg6]);
          };
          cont6 = this.cont(args[6], _cont6);
          _cont5 = function(v) {
            arg5 = v;
            return cont6(null);
          };
          cont5 = this.cont(args[5], _cont5);
          _cont4 = function(v) {
            arg4 = v;
            return cont5(null);
          };
          cont4 = this.cont(args[4], _cont4);
          _cont3 = function(v) {
            arg3 = v;
            return cont4(null);
          };
          cont3 = this.cont(args[3], _cont3);
          _cont2 = function(v) {
            arg2 = v;
            return cont3(null);
          };
          cont2 = this.cont(args[2], _cont2);
          _cont1 = function(v) {
            arg1 = v;
            return cont2(null);
          };
          cont1 = this.cont(args[1], _cont1);
          cont0 = function(v) {
            arg0 = v;
            return cont1(null);
          };
          return this.cont(args[0], cont0);
        default:
          params = [];
          solver = this;
          for (i = _i = _ref = length - 1; _i >= 0; i = _i += -1) {
            cont = (function(i, cont) {
              var _cont;

              _cont = function(argi) {
                params.push(argi);
                return cont(params);
              };
              return solver.cont(args[i], _cont);
            })(i, cont);
          }
          return cont;
      }
    };

    Solver.prototype.quasiquote = function(exp, cont) {
      return (exp != null ? typeof exp.quasiquote === "function" ? exp.quasiquote(this, cont) : void 0 : void 0) || (function(v) {
        return cont(exp);
      });
    };

    Solver.prototype.appendFailcont = function(fun) {
      var fc, state, trail;

      trail = this.trail;
      this.trail = new Trail;
      state = this.state;
      fc = this.failcont;
      return this.failcont = function(v) {
        this.trail.undo();
        this.trail = trail;
        this.state = state;
        this.failcont = fc;
        return fun(v);
      };
    };

    Solver.prototype.pushCatch = function(value, cont) {
      var catches, _base, _ref;

      catches = (_ref = (_base = this.catches)[value]) != null ? _ref : _base[value] = [];
      return catches.push(cont);
    };

    Solver.prototype.popCatch = function(value) {
      var catches;

      catches = this.catches[value];
      catches.pop();
      if (catches.length === 0) {
        return delete this.catches[value];
      }
    };

    Solver.prototype.findCatch = function(value) {
      var catches;

      catches = this.catches[value];
      if ((catches == null) || catches.length === 0) {
        throw new NotCatched;
      }
      return catches[catches.length - 1];
    };

    Solver.prototype.protect = function(fun) {
      return fun;
    };

    return Solver;

  })();

  Trail = exports.Trail = (function() {
    function Trail(data) {
      this.data = data != null ? data : {};
    }

    Trail.prototype.copy = function() {
      return new Trail(_.extend({}, this.data));
    };

    Trail.prototype.set = function(vari, value) {
      var data;

      data = this.data;
      if (!data.hasOwnProperty(vari.name)) {
        return data[vari.name] = [vari, value];
      }
    };

    Trail.prototype.undo = function() {
      var nam, pair, value, vari, _ref, _results;

      _ref = this.data;
      _results = [];
      for (nam in _ref) {
        pair = _ref[nam];
        vari = pair[0];
        value = pair[1];
        _results.push(vari.binding = value);
      }
      return _results;
    };

    Trail.prototype.deref = function(x) {
      return (x != null ? typeof x.deref === "function" ? x.deref(this) : void 0 : void 0) || x;
    };

    Trail.prototype.getvalue = function(x, memo) {
      var getvalue;

      if (memo == null) {
        memo = {};
      }
      getvalue = x != null ? x.getvalue : void 0;
      if (getvalue) {
        return getvalue.call(x, this, memo);
      } else {
        return x;
      }
    };

    Trail.prototype.unify = function(x, y) {
      x = this.deref(x);
      y = this.deref(y);
      if (x instanceof Var) {
        this.set(x, x.binding);
        x.binding = y;
        return true;
      } else if (y instanceof Var) {
        this.set(y, y.binding);
        y.binding = x;
        return true;
      } else {
        return (x != null ? typeof x.unify === "function" ? x.unify(y, this) : void 0 : void 0) || (y != null ? typeof y.unify === "function" ? y.unify(x, this) : void 0 : void 0) || (x === y);
      }
    };

    return Trail;

  })();

  Var = exports.Var = (function() {
    function Var(name, binding) {
      this.name = name;
      this.binding = binding != null ? binding : this;
    }

    Var.prototype.deref = function(trail) {
      var chains, i, length, next, v, x, _i, _j, _ref, _ref1;

      v = this;
      next = this.binding;
      if (next === this || !(next instanceof Var)) {
        return next;
      } else {
        chains = [v];
        length = 1;
        while (1) {
          chains.push(next);
          v = next;
          next = v.binding;
          length++;
          if (next === v) {
            for (i = _i = 0, _ref = chains.length - 2; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
              x = chains[i];
              x.binding = next;
              trail.set(x, chains[i + 1]);
            }
            return next;
          } else if (!(next instanceof Var)) {
            for (i = _j = 0, _ref1 = chains.length - 1; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
              x = chains[i];
              x.binding = next;
              trail.set(x, chains[i + 1]);
            }
            return next;
          }
        }
      }
    };

    Var.prototype.bind = function(value, trail) {
      trail.set(this, this.binding);
      return this.binding = trail.deref(value);
    };

    Var.prototype.getvalue = function(trail, memo) {
      var name, result;

      if (memo == null) {
        memo = {};
      }
      name = this.name;
      if (memo.hasOwnProperty(name)) {
        return memo[name];
      }
      result = this.deref(trail);
      if (result instanceof Var) {
        memo[name] = result;
        return result;
      } else {
        result = trail.getvalue(result, memo);
        memo[name] = result;
        return result;
      }
    };

    Var.prototype.cont = function(solver, cont) {
      var _this = this;

      return function(v) {
        return cont(_this.deref(solver.trail));
      };
    };

    Var.prototype.toString = function() {
      return "vari(" + this.name + ")";
    };

    return Var;

  })();

  reElements = /\s*,\s*|\s+/;

  nameToIndexMap = {};

  exports.vari = function(name) {
    var index;

    index = nameToIndexMap[name] || 1;
    nameToIndexMap[name] = index + 1;
    return new Var(name + index);
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

  exports.DummyVar = DummyVar = (function(_super) {
    __extends(DummyVar, _super);

    function DummyVar(name) {
      this.name = '_$' + name;
    }

    DummyVar.prototype.cont = function(solver, cont) {
      var _this = this;

      return function(v) {
        return cont(_this.binding);
      };
    };

    DummyVar.prototype.deref = function(trail) {
      return this;
    };

    DummyVar.prototype.getvalue = function(trail, memo) {
      var name, result;

      if (memo == null) {
        memo = {};
      }
      name = this.name;
      if (memo.hasOwnProperty(name)) {
        return memo[name];
      }
      result = this.binding;
      if (result === this) {
        memo[name] = result;
        return result;
      } else {
        result = trail.getvalue(result, memo);
        memo[name] = result;
        return result;
      }
    };

    return DummyVar;

  })(Var);

  exports.dummy = dummy = function(name) {
    var index;

    index = nameToIndexMap[name] || 1;
    nameToIndexMap[name] = index + 1;
    return new exports.DummyVar(name + index);
  };

  exports.dummies = function(names) {
    var name, _i, _len, _ref, _results;

    _ref = split(names, reElements);
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      name = _ref[_i];
      _results.push(new dummy(name));
    }
    return _results;
  };

  exports.Apply = (function() {
    function Apply(caller, args) {
      var arity, length, ok, x, _i, _len, _ref, _ref1;

      this.caller = caller;
      this.args = args;
      length = args.length;
      arity = this.caller.arity;
      ok = false;
      if (arity === null) {
        ok = true;
      }
      if (_.isArray(arity)) {
        if (__indexOf.call(arity, length) >= 0) {
          ok = true;
        }
      } else if (_.isNumber(arity)) {
        if ((arity >= 0 && length === arity) || (arity < 0 && length >= -arity)) {
          ok = true;
        }
      }
      if (!ok) {
        _ref = this.args;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          x = _ref[_i];
          if ((x != null ? (_ref1 = x.caller) != null ? _ref1.name : void 0 : void 0) === "unquoteSlice") {
            return;
          }
        }
        throw new ArityError(this);
      }
    }

    Apply.prototype.toString = function() {
      return "" + this.caller + "(" + (this.args.join(', ')) + ")";
    };

    Apply.prototype.cont = function(solver, cont) {
      return this.caller.applyCont(solver, cont, this.args);
    };

    Apply.prototype.quasiquote = function(solver, cont) {
      var args, i, params, _i, _ref,
        _this = this;

      if (this.caller.name === "unquote") {
        return solver.cont(this.args[0], function(v) {
          return cont(v);
        });
      } else if (this.caller.name === "unquoteSlice") {
        return solver.cont(this.args[0], function(v) {
          return cont(new UnquoteSliceValue(v));
        });
      }
      params = [];
      cont = (function(cont) {
        return function(v) {
          return [cont, new _this.constructor(_this.caller, params)];
        };
      })(cont);
      args = this.args;
      for (i = _i = _ref = args.length - 1; _i >= 0; i = _i += -1) {
        cont = (function(i, cont) {
          return solver.quasiquote(args[i], function(v) {
            var x, _j, _len, _ref1;

            if (v instanceof UnquoteSliceValue) {
              _ref1 = v.value;
              for (_j = 0, _len = _ref1.length; _j < _len; _j++) {
                x = _ref1[_j];
                params.push(x);
              }
            } else {
              params.push(v);
            }
            return cont(null);
          });
        })(i, cont);
      }
      return cont;
    };

    return Apply;

  })();

  UnquoteSliceValue = exports.UnquoteSliceValue = (function() {
    function UnquoteSliceValue(value) {
      this.value = value;
    }

    return UnquoteSliceValue;

  })();

  Command = exports.Command = (function() {
    Command.directRun = false;

    function Command(fun, name, arity) {
      var _this = this;

      this.fun = fun;
      this.name = name;
      this.arity = arity;
      this.callable = function() {
        var applied, args, result, solver;

        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        applied = new exports.Apply(_this, args);
        if (Command.directRun) {
          solver = Command.globalSolver;
          result = solver.solve(applied);
          solver.finished = false;
          return result;
        } else {
          return applied;
        }
      };
      this.callable.arity = this.arity;
    }

    Command.prototype.register = function(exports) {
      return exports[this.name] = this.callable;
    };

    Command.prototype.toString = function() {
      return this.name;
    };

    return Command;

  })();

  commandMaker = function(klass) {
    return function(arity, name, fun) {
      if ((name == null) && (fun == null)) {
        fun = arity;
        name = "noname";
        if (klass === exports.Special) {
          arity = fun.length - 2;
        } else {
          arity = fun.length;
        }
      } else if (fun == null) {
        fun = name;
        if (_.isString(arity)) {
          name = arity;
          if (klass === exports.Special) {
            arity = fun.length - 2;
          } else {
            arity = fun.length;
          }
        } else {
          if (!_.isNumber(arity) && arity !== null && !_.isArray(arity)) {
            throw new ArgumentError(arity);
          }
          name = "noname";
        }
      } else {
        if (!_.isNumber(arity) && arity !== null && !_.isArray(arity)) {
          throw new ArgumentError(arity);
        }
        if (!_.isString(name)) {
          throw new TypeError(name);
        }
      }
      return new klass(fun, name, arity).callable;
    };
  };

  exports.Special = (function(_super) {
    __extends(Special, _super);

    function Special() {
      _ref = Special.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Special.prototype.applyCont = function(solver, cont, args) {
      return this.fun.apply(this, [solver, cont].concat(__slice.call(args)));
    };

    return Special;

  })(exports.Command);

  exports.special = special = commandMaker(exports.Special);

  exports.call = special(-1, 'call', function() {
    var args, argsCont, cont, goal, goal1, solver;

    solver = arguments[0], cont = arguments[1], goal = arguments[2], args = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
    goal1 = null;
    argsCont = solver.argsCont(args, function(params, solver) {
      return solver.cont(goal1.apply(null, params), cont)(null);
    });
    return solver.cont(goal, function(v) {
      goal1 = goal;
      return argsCont(null);
    });
  });

  exports.apply = special(2, 'apply', function(solver, cont, goal, args) {
    var argsCont, goal1;

    goal1 = null;
    argsCont = solver.argsCont(args, function(params, solver) {
      return solver.cont(goal1.apply(null, params), cont)(null);
    });
    return solver.cont(goal, function(v) {
      goal1 = goal;
      return argsCont(null);
    });
  });

  exports.Fun = (function(_super) {
    __extends(Fun, _super);

    function Fun() {
      _ref1 = Fun.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    Fun.prototype.applyCont = function(solver, cont, args) {
      var _this = this;

      return solver.argsCont(args, function(params) {
        return [cont, _this.fun.apply(_this, params)];
      });
    };

    return Fun;

  })(exports.Command);

  exports.fun = commandMaker(exports.Fun);

  exports.Fun2 = (function(_super) {
    __extends(Fun2, _super);

    function Fun2() {
      _ref2 = Fun2.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    Fun2.prototype.applyCont = function(solver, cont, args) {
      var fun;

      fun = this.fun;
      return solver.argsCont(args, function(params) {
        return solver.cont(fun.apply(null, params), cont)(params);
      });
    };

    return Fun2;

  })(exports.Command);

  exports.fun2 = commandMaker(exports.Fun2);

  exports.Macro = Macro = (function(_super) {
    __extends(Macro, _super);

    Macro.idMap = {};

    Macro.id = 0;

    function Macro(fun, name, arity) {
      this.fun = fun;
      this.name = name;
      this.arity = arity;
      Macro.__super__.constructor.apply(this, arguments);
      this.id = (Macro.id++).toString();
    }

    Macro.prototype.applyCont = function(solver, cont, args) {
      var exp, id, idMap, result;

      exp = this.fun.apply(this, args);
      idMap = Macro.idMap;
      id = this.id;
      if (!idMap[id]) {
        idMap[id] = true;
        result = solver.cont(exp, cont);
        delete idMap[id];
        return result;
      } else {
        return function(v) {
          delete idMap[id];
          return solver.cont(exp, cont)(v);
        };
      }
    };

    return Macro;

  })(exports.Command);

  exports.macro = commandMaker(exports.Macro);

  exports.Proc = (function(_super) {
    __extends(Proc, _super);

    function Proc() {
      _ref3 = Proc.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    Proc.prototype.applyCont = function(solver, cont, args) {
      var _this = this;

      return function(v) {
        var result, savedSolver;

        Command.directRun = true;
        savedSolver = Command.globalSolver;
        Command.globalSolver = solver;
        result = _this.fun.apply(_this, args);
        Command.globalSolver = savedSolver;
        Command.directRun = false;
        return [cont, result, solver];
      };
    };

    return Proc;

  })(exports.Command);

  exports.proc = commandMaker(exports.Proc);

  exports.tofun = function(name, cmd) {
    if (cmd == null) {
      cmd = name;
      name = 'noname';
    }
    return special(cmd.arity, name, function() {
      var args, cont, solver;

      solver = arguments[0], cont = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      return solver.argsCont(args, function(params) {
        return [solver.cont(cmd.apply(null, params), cont), params];
      });
    });
  };

  exports.UObject = UObject = (function() {
    function UObject(data) {
      this.data = data;
    }

    UObject.prototype.getvalue = function(trail, memo) {
      var changed, key, result, v, value, _ref4;

      result = {};
      changed = false;
      _ref4 = this.data;
      for (key in _ref4) {
        value = _ref4[key];
        v = trail.getvalue(value, memo);
        if (v !== value) {
          changed = true;
        }
        result[key] = v;
      }
      if (changed) {
        return new UObject(result);
      } else {
        return this;
      }
    };

    UObject.prototype.unify = function(y, trail) {
      var index, key, xdata, ydata, ykeys;

      xdata = this.data;
      ydata = y.data;
      ykeys = Object.keys(y);
      for (key in xdata) {
        index = ykeys.indexOf(key);
        if (index === -1) {
          return false;
        }
        if (!trail.unify(xdata[key], ydata[key])) {
          return false;
        }
        ykeys.splice(index, 1);
      }
      if (ykeys.length !== 0) {
        return false;
      }
      return true;
    };

    return UObject;

  })();

  exports.uobject = function(x) {
    return new UObject(x);
  };

  exports.UArray = UArray = (function() {
    function UArray(data) {
      this.data = data;
    }

    UArray.prototype.getvalue = function(trail, memo) {
      var changed, result, v, x, _i, _len, _ref4;

      if (memo == null) {
        memo = {};
      }
      result = [];
      changed = false;
      _ref4 = this.data;
      for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
        x = _ref4[_i];
        v = trail.getvalue(x, memo);
        if (v !== x) {
          changed = true;
        }
        result.push(v);
      }
      if (changed) {
        return new UArray(result);
      } else {
        return this;
      }
    };

    UArray.prototype.unify = function(y, trail) {
      var i, length, xdata, ydata, _i;

      xdata = this.data;
      ydata = y.data;
      length = this.length;
      if (length !== y.length) {
        return false;
      }
      for (i = _i = 0; 0 <= length ? _i < length : _i > length; i = 0 <= length ? ++_i : --_i) {
        if (!trail.unify(xdata[i], ydata[i])) {
          return false;
        }
      }
      return true;
    };

    UArray.prototype.toString = function() {
      return this.data.toString();
    };

    return UArray;

  })();

  exports.uarray = uarray = function(x) {
    return new UArray(x);
  };

  exports.Cons = Cons = (function() {
    function Cons(head, tail) {
      this.head = head;
      this.tail = tail;
    }

    Cons.prototype.getvalue = function(trail, memo) {
      var head, head1, tail, tail1;

      if (memo == null) {
        memo = {};
      }
      head = this.head;
      tail = this.tail;
      head1 = trail.getvalue(head, memo);
      tail1 = trail.getvalue(tail, memo);
      if (head1 === head && tail1 === tail) {
        return this;
      } else {
        return new Cons(head1, tail1);
      }
    };

    Cons.prototype.unify = function(y, trail) {
      if (!(y instanceof Cons)) {
        return false;
      } else if (!trail.unify(this.head, y.head)) {
        return false;
      } else {
        return trail.unify(this.tail, y.tail);
      }
    };

    Cons.prototype.flatString = function() {
      var result, tail;

      result = "" + this.head;
      tail = this.tail;
      if (tail === null) {
        null;
      } else if (tail instanceof Cons) {
        result += ',';
        result += tail.flatString();
      } else {
        result += tail.toString();
      }
      return result;
    };

    Cons.prototype.toString = function() {
      return "cons(" + this.head + ", " + this.tail + ")";
    };

    return Cons;

  })();

  exports.cons = function(x, y) {
    return new Cons(x, y);
  };

  exports.conslist = function() {
    var args, i, result, _i, _ref4;

    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    result = null;
    for (i = _i = _ref4 = args.length - 1; _i >= 0; i = _i += -1) {
      result = new Cons([args[i], result]);
    }
    return result;
  };

  exports.unifiable = function(x) {
    if (_.isArray(x)) {
      return new UArray(x);
    } else if (_.isObject(x)) {
      return new UObject(x);
    } else {
      return x;
    }
  };

  exports.BindingError = Error = (function() {
    function Error(exp, message, stack) {
      this.exp = exp;
      this.message = message != null ? message : '';
      this.stack = stack != null ? stack : this;
    }

    Error.prototype.toString = function() {
      return "" + this.constructor.name + ": " + this.exp + " >>> " + this.message;
    };

    return Error;

  })();

  exports.BindingError = BindingError = (function(_super) {
    __extends(BindingError, _super);

    function BindingError() {
      _ref4 = BindingError.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    return BindingError;

  })(Error);

  exports.TypeError = TypeError = (function(_super) {
    __extends(TypeError, _super);

    function TypeError() {
      _ref5 = TypeError.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    return TypeError;

  })(Error);

  exports.ExpressionError = ExpressionError = (function(_super) {
    __extends(ExpressionError, _super);

    function ExpressionError() {
      _ref6 = ExpressionError.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    return ExpressionError;

  })(Error);

  exports.ArgumentError = ArgumentError = (function(_super) {
    __extends(ArgumentError, _super);

    function ArgumentError() {
      _ref7 = ArgumentError.__super__.constructor.apply(this, arguments);
      return _ref7;
    }

    return ArgumentError;

  })(Error);

  exports.ArityError = ArityError = (function(_super) {
    __extends(ArityError, _super);

    function ArityError() {
      _ref8 = ArityError.__super__.constructor.apply(this, arguments);
      return _ref8;
    }

    return ArityError;

  })(Error);

  exports.SUCCESS = 1;

  exports.UNKNOWN = 0;

  exports.FAIL = -1;

  exports.status = exports.UNKNOWN;

  exports.debug = debug = function() {
    var items, s, x;

    items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return console.log.apply(console, (function() {
      var _i, _len, _results;

      _results = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        x = items[_i];
        if (!(x instanceof Function)) {
          s = x.toString();
          if (s === '[object Object]') {
            _results.push(JSON.stringify(x));
          } else {
            _results.push(s);
          }
        } else {
          _results.push('[Function]');
        }
      }
      return _results;
    })());
  };

}).call(this);

/*
//@ sourceMappingURL=core.map
*/