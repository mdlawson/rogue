flour = require 'flour'
{exec} = require 'child_process'

# vars
files = ['gfx', 'assets', 'entity','physics','tiles', 'input', 'collision', 'rogue']
srcFiles = ("src/#{file}.coffee" for file in files)

task 'build:src', ->
  coffee = exec "coffee -j lib/rogue.js -c #{srcFiles.join(' ')}"
  minify 'lib/rogue.js','lib/rogue.min.js'

task 'build:test', ->
  test = exec "coffee -o test/specs -c test/src"

task 'build:doc', ->
  fs = require 'fs'
  dox = require '../dox'
  jade = require 'jade'
  fs.readFile 'doc/template.jade', 'utf-8', (err,tmpl) ->
    fn = jade.compile tmpl
    for file in files
      code = fs.readFileSync "src/#{file}.coffee", 'utf-8'
      dox.parseComments code, {highlight:true}, (json) ->
        html = fn({"dox":json,"file":file})
        fs.writeFileSync "doc/#{file}.html",html

task 'serve:test', ->
  test = require "./test/server"

task 'serve:doc', ->
  doc = require "./doc/server"

task 'watch', ->
  watch 'src/*.coffee', ->
    invoke 'build:src'
    invoke 'build:doc'
  watch 'doc/template.jade', -> invoke 'build:doc'
  watch 'test/src/*.coffee', -> invoke 'build:test'
  invoke 'serve:test'
  invoke 'serve:doc'

task 'build', ->
  invoke 'build:src'
  invoke 'build:doc'
  invoke 'build:test'