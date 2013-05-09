global._ =  require("underscore")
dao = require('../src/compile')

I = require("f:/node-utils/src/importer")

xexports = {}

xexports.Test1 =
  setUp: (callback) -> callback()
  tearDown:(callback) -> callback()

  "test 1": (test) ->
    dao.compileToJSFile dao.integer(1)
#    test.throws (-> new Error() ), Error
    test.equal 1, 1
    test.done()

xexports.Test2 =
  setUp: (callback) ->
    @global = I.set_global dao, "compileToJSFile integer begin, if"
    callback()

  tearDown:(callback) ->
    I.set_global  @global
    callback()

  test: (test) ->
    test.equal integer(1).toString(), "1"
    test.done()

  test: (test) ->
    compileToJSFile begin(integer(1), integer(2))
    compileToJSFile add(1, 2)
    test.done()

exports.Test3 =
  setUp: (callback) ->
    @global = I.set_global dao, "compileToJSFile integer begin, if_, add"
    callback()

  tearDown:(callback) ->
    I.set_global  @global
    callback()

  test: (test) ->
    compileToJSFile add(1, 2)
    test.done()
