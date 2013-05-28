## daonode
Dao is a functional logic solver, unifying code with data, grammar with program, logic with functional, compiling with running.
Daonode is a porting, rewriting and upgrading from python to coffeecript(so just javscript) of the dao project.
What would happen when lisp meets prolog in javascript?
###what'new 0.1.10
* other unifiable term: uobject, uarray, cons
* bug fix: avoid infinite macro extend when macro is recursive. see samples/kleene.coffee for demo.
* arity default to func.length(thanks to mscdex)
* samples: kleene.coffee/.js, expression.coffee/.js(not finished)
* annotated document with docco
* some document: overview, api(core, builtins) on https://github.com/chaosim/daonode/wiki

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

