## daonode
Dao is a functional logic solver, unifying code with data, grammar with program, logic with functional, compiling with running.
Daonode is a porting, rewriting and upgrading from python to coffeecript(so just javscript) of the dao project.
What would happen when lisp meets prolog in javascript?

###what's new in 0.2.0
* now daonode can compile expression(similar to lisp's sexpression) to javascript.
* stuffs in /lib is for the compiler
* Currently no document is written for the comiler, please refer to the document for the interpreter.
* original stuffs for the solver is moved to /lib/interpreter, and they still work.
* all tests is moved /test
* add .travis.yml and use travis-ci.org for Continuous integration, see https://travis-ci.org/chaosim/daonode.

### Documentation
See <https://github.com/chaosim/daonode/wiki> for documents for daonode.
The annotated coffeescript source is in the daonode/doc.
See the tests, and you'll get some information about the api and use cases.
Some old documents is on http://pythonhosted.org/daot/ (out of date).

### Web sites
the project's repository is on github <https://github.com/chaosim/daonode>. 
some old information and related stuff can be reached at pypi distribution and document:
  http://pypi.python.org/pypi/daot>, http://pythonhosted.org/daot/, <http://code.google.com/p/daot>
dao groups on google: Group name: daot, Group home page: http://groups.google.com/group/daot,
Group email address: daot@googlegroups.com
google+ pages for news on dao: https://plus.google.com/112050694070234685790

### Testing
daonode uses the nodeunit test framework, see the folder "test"

### Bug reports
To report or search for bugs, please goto <https://github.com/chaosim/daonode>, or email to simeon.chaos@gmail.com

### Platform notes
daonode is developed and tested on Windows 7, node.js 0.10.0, coffeescript 1.6.2.

### License
MIT: see LICENSE

