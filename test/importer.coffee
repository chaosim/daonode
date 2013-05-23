########################################################################################
###

Author   : Caoxingming
Email    : simeon.chaos@gmail.com
Homepage : https://github.com/chaosim
Source   : https://github.com/chaosim/nodejs_utils
License  : Simplified BSD License
Version  : 0.1.0

Copyright 2013 Caoxingming. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY CAOXINGMING 'AS IS' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL CAOXINGMING OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of Caoxingmingi.

###############################################################################
###
# usage: copy this file to your project and then:

# javascript:

I = require("imorter")

I.require_multiple("path/to/module1 path/to/module2")

I.use("underscore: isString, isArray")
I.at("underscore:first, underscore:last")
I.all("underscore and_other_module_path")

underscore = require("underscore")

I.with_(underscore, " isString some", function() {
    test.ok(isString(''));
    test.ok(some([3, 2], function(x) {
      return x > 1;
    }));
    test.throws(function() {
      return first([3, 2]);
    });
    return test.done();
  });

 I.with_(underscore, function() {
        test.ok(isString(''));
        test.ok(some([3, 2], function(x) {
          return x > 1;
        }));
        return test.equal(first([3, 2]), 3);
      });

I.set_global(obj, names)

# SEE test/test_importer.js for more information

# in coffeescript:

I = require("impporter")

I.use "underscore: isString, isArray"

I.at "underscore:first, underscore:last"

I.all "underscore and_other_module_path"

I.require_multiple "path/to/module1 path/to/module2"

underscore = require "underscore"

I.with_ underscore, " isString some",  ->
  test.ok(isString(''))
  test.ok some([3,2], (x) -> x>1)
  test.throws -> first [3,2]

I.with_ underscore, ->
  test.ok(isString(''))
  test.ok some([3,2], (x) -> x>1)
  test.equal (first [3,2]), 3

I.set_global obj, names

# SEE test/test_importer.coffee for more information
######################################################################################

exports.version = '0.1.0'

comman_space_splitter = reElements = /\s*,\s*|\s+/
path_namesSplit = /:[ \t]+/

exports.split = split = (str, sep) -> x for x in str.split(sep) when x

# all "path path"
exports.all = (path_list) ->
  for path in split path_list,  reElements
    modu = require(path)
    global[name] = value for name, value of modu

exports.require_multiple = (path_list) ->
  require(path) for path in split path_list,  reElements

# [Environment, Compiler] = from "compilebase", "Environment, Compiler"
exports.from  = (path_names) ->
  [path, names] = split(path_names, path_namesSplit)
  modu = require(path)
  modu[name] for name in split names, reElements

# use module/path, "name, name"
# use "compilebase", "Environment, Compiler"
exports.use = (path_names) ->
  [path, names] = split(path_names, path_namesSplit)
  modu = require(path)
  global[name] = modu[name] for name in split names, reElements

exports.at = (path_list) ->
  for path in split(path_list, /\s*,\s*/)
    [path, item] = path.split(/\s*:\s*/)
    global[item] = require(path)[item]

exports.with_  = (obj, fun, names) ->
  saved_global = {}
  if names
    [names, fun] = [fun, names]
    names = split names, reElements
  else names = (name for name of obj)
  for name in names
    if global[name] isnt undefined
      saved_global[name] = global[name]
    global[name] = obj[name]
  result = fun()
  for name, v of saved_global
    global[name] = v
  result

exports.set_global = (obj, names) ->
  saved_global = {}
  names = if names then (split names, reElements) else (name for name of obj)
  for name in names
    saved_global[name] = global[name]
    global[name] = obj[name]
  saved_global
