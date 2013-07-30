##What's new in daonode

###what's new in 0.2.0
* now daonode can compile expression(similar to lisp's sexpression) to javascript.
* stuffs in /lib is for the compiler
* original stuffs for the solver is moved to /lib/interpreter, and they still work.
* all tests is moved /test
* add .travis.yml and use travis-ci.org for Continuous integration, see https://travis-ci.org/chaosim/daonode.

###what's new in 0.1.11
* memo and purememo in parser.coffee/.js
* refactor: remove parameter "solver" from continuation
* index.js becomes the main file in package.json

###what's new in 0.1.10
* other unifiable term: uobject, uarray, cons
* bug fix: avoid infinite macro extend when macro is recursive. see samples/kleene.coffee for demo.
* arity default to func.length(thanks to mscdex)
* samples: kleene.coffee/.js, expression.coffee/.js(not finished)
* annotated document with docco
* some document: overview, api(core, builtins) on https://github.com/chaosim/daonode/wiki
