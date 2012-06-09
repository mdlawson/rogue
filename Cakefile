{print} = require 'util'
{exec} = require 'child_process'

srcFiles = ("src/#{file}.coffee" for file in ['gfx', 'assets', 'entity', 'tiles', 'input', 'rogue']).join " "

task 'build', 'Build lib/rogue.js from src/', ->
  coffee = exec "coffee -j lib/rogue.js -c #{srcFiles}"
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

task 'watch', 'Watch src/ for changes', ->
  coffee = exec "coffee -j lib/rogue.js -cw #{srcFiles}"
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
