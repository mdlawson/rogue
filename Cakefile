{print} = require 'util'
{exec} = require 'child_process'

files = ['gfx', 'assets', 'entity','physics','tiles', 'input', 'collision', 'rogue']
srcFiles = ("src/#{file}.coffee" for file in files)
srcString = srcFiles.join " "

task 'build', 'Build lib/rogue.js from src/', ->
  coffee = exec "coffee -j lib/rogue.js -c #{srcString}"
  min = exec "uglifyjs -o lib/rogue.min.js lib/rogue.js"
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

task 'watch', 'Watch src/ for changes', ->
  coffee = exec "coffee -j lib/rogue.js -cw #{srcString}"
  min = exec "uglifyjs -o lib/rogue.min.js  lib/rogue.js"
  serv = exec "node test/server"
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  test = exec "coffee -o test/specs -cw test/src"
  test.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  test.stdout.on 'data', (data) ->
    print data.toString()

task 'test', 'Build test specs', ->
  coffee = exec "coffee -o test/specs -c test/src"
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

task 'doc', 'Build docs', ->
  fs = require 'fs'
  dox = require '../dox'
  jade = require 'jade'
  fs.readFile 'doc/template.jade', 'utf-8', (err,tmpl) ->
    fn = jade.compile tmpl
    for file in files
      code =fs.readFileSync "src/#{file}.coffee", 'utf-8'
      json = dox.parseComments code
      html = fn({"dox":json,"file":file})
      fs.writeFileSync "doc/#{file}.html",html
