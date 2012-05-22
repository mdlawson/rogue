class GameLoop
  constructor: (@state) ->
    @fps = 0
    @paused = @stopped = false
    @averageFPS = new RollingAverage 20

  animate: window.requestAnimationFrame or 
       window.webkitRequestAnimationFrame or 
       window.mozRequestAnimationFrame or
       window.oRequestAnimationFrame or
       window.msRequestAnimationFrame
  start: ->
    firstTick = currentTick = lastTick = (new Date()).getTime()
    amimate @loop

  loop: ->
    @currentTick = (new Date()).getTime()
    @tickDuration = @currentTick - @lastTick
    @fps = @averageFPS.add(1000/@tickDuration)
    unless @stopped or @paused
      @state.update()
      @state.draw()
    unless @stopped
      animate @loop
    @lastTick = @currentTick


class RollingAverage
  constructor: (@size) ->
    @values = new Array @size
    @count = 0
  add: (value) ->
    @values = @values[1...@size]
    @values.push value
    if @count < @size then @count++
    return parseInt (@values.reduce (t, s) -> t+s)/@count



# Logging

Log =
  trace: true

  logPrefix: '(Rogue)'

  log: (args...) ->
    return unless @trace
    if @logPrefix then args.unshift(@logPrefix)
    console?.log?(args...)
    this

# Utilities

util =
  isArray: (value) ->
    Object::toString.call(value) is '[object Array]'

# Maths

math =
  round: (num) ->
    return (0.5 + num) | 0

# Globals

Rogue = @Rogue   = {}
module?.exports  = Rogue

Rogue.util      = util
Rogue.math      = math
Rogue.GameLoop  = GameLoop
