global._ =  require("underscore")
daonode = require('../src/solve')

I = require("f:/node-utils/src/importer")

xexports = {}

exports.Test1 =
  setUp: (callback) ->
    @global = I.set_global daonode.dao
    callback()

  tearDown:(callback) ->
    I.set_global  @global
    callback()

  "test 1": (test) ->
    compileToJSFile integer(1)
#    test.throws (-> new Error() ), Error
    test.equal 1, 1
    test.done()

exports.Test2 =
  setUp: (callback) ->
    @global = I.set_global daonode
    callback()

  tearDown:(callback) ->
    I.set_global  @global
    callback()

  test: (test) ->
    test.equal 1, 1
    test.done()
