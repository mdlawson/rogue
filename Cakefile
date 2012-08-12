flour = require 'flour'
{exec} = require 'child_process'
path = require 'path'

# vars
files = ['gfx', 'assets', 'entity','physics','tiles', 'input', 'collision', 'rogue']
srcFiles = ("src/#{file}.coffee" for file in files)
doc = 'doc/views/docs.jade'
home = 'doc/views/home.jade'
style = 'doc/style/style.styl'

task 'build:src', ->
  coffee = exec "coffee -j lib/rogue.js -c #{srcFiles.join(' ')}"
  minify 'lib/rogue.js','lib/rogue.min.js'

task 'build:test', ->
  test = exec "coffee -o test/specs -c test/src"

task 'build:doc', ->
  fs = require 'fs'
  dox = require '../dox'
  jade = require 'jade'
  stylus = require 'stylus'
  nib = require 'nib'
  fs.readFile doc, 'utf-8', (err,tmpl) ->
    fn = jade.compile tmpl, {filename:doc}
    for file in files
      code = fs.readFileSync "src/#{file}.coffee", 'utf-8'
      dox.parseComments code, {highlight:false}, (json) ->
        html = fn({"dox":json,"file":file,"title":file,"files":files})
        fs.writeFileSync "doc/#{file}.html",html

  fs.readFile style, 'utf-8', (err,styl) ->
    stylus(styl).set('filename',style).include(path.dirname(style)).use(nib()).import('nib').render (err,css) ->
      fs.writeFileSync path.dirname(style) + "/style.css",css


task 'serve:test', ->
  test = require "./test/server"

task 'serve:doc', ->
  doc = require "./doc/server"

task 'watch', ->
  watch 'src/*.coffee', ->
    invoke 'build:src'
    invoke 'build:doc'
  watch [doc,home,style], -> invoke 'build:doc'
  watch 'test/src/*.coffee', -> invoke 'build:test'
  invoke 'serve:test'
  invoke 'serve:doc'

task 'watch:src', ->
  watch 'src/*.coffee', ->
    invoke 'build:src'
  watch 'test/src/*.coffee', -> invoke 'build:test'
  invoke 'serve:test'

task 'build', ->
  invoke 'build:src'
  invoke 'build:doc'
  invoke 'build:test'