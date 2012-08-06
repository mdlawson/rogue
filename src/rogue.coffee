# Base class on which the game is build. Provides basic state management functionality.
# Instances of game have canvas, context, and loop, which is an instance of GameLoop, properties

class Game
  
  # @param [Object] options game setup options
  # @option options [String] canvas an ID of a canvas element provided, one will be created if not
  # @option options [Int] width width of canvas, defaults to 400
  # @option options [Int] height height of canvas, defaults to 300
  # @option options [Bool] showfps whether fps should be displayed
  #
  constructor: (@options={}) ->
    @canvas = document.getElementById(options.canvas) if @options.canvas?
    if not @canvas?
      @canvas = util.canvas()
      document.body.appendChild(@canvas)
    @canvas.tabIndex=0
    @canvas.style.outline="none"
    @width = @canvas.width = @options.width ? 400
    @height = @canvas.height = @options.height ? 300
    @showFPS = @options.fps ? false
    @canvas.x = @canvas.y = 0
    @context = @canvas.getContext('2d')

  # Starts the game with a state
  # @param [Object] state game state
  # @option state [Function] setup function to run when state is initialised
  # @option state [Function] update function to run every tick in which game logic is performed. is passed dt, the change in time since the last tick.
  # @option state [Function] draw function to run every tick in which the game graphics are drawn
  #
  start: (state) ->
    loading = @options.loadingScreen ? ->
    @switchState(state)

  # Switches the state to a new state, saving the old state in game.oldState
  # @param [Object] state state to switch to
  #
  switchState: (state) ->
    @e = []
    @loop and @loop.stop()
    @oldState = @state
    @state = state
    @state.setup.call(@state,@)
    @loop = new GameLoop @,@showFPS
    @loop.add [@state.update,@state.draw]
    @loop.start()


  # Clears the canvas, can be run at the end of each frame.
  # @todo automatic partial update system?
  #
  clear: ->
    @context.clearRect(0,0,@width,@height)

  # Finds entities with a given set of components that are children of the game
  # @param [Array] components array of components to match against
  # @param [Entity] ex an entity to exclude from the matching
  # @return [Array] array of matched entities
  #
  find: (components,ex) ->
    find.call(@,components,ex)

# Gameloop class, used internally by Game, gets bound to game.loop
#
class GameLoop
  constructor: (@parent,@showFPS) ->
    @fps = 0
    @averageFPS = new RollingAverage 20
    @call = []
  # Starts the loop, running each function in @call every tick
  start: ->
    @paused = @stopped = false
    firstTick = currentTick = lastTick = (new Date()).getTime()
    Rogue.ticker.call window, @loop
  # loop function that is called every tick
  loop: =>
    @currentTick = (new Date()).getTime()
    @dt = (@currentTick - @lastTick) or 17
    @fps = @averageFPS.add(1000/@dt)
    unless @stopped or @paused
      if @dt > 20 then @dt = 17
      func.call(@parent.state,@parent,@dt/1000) for func in @call
    unless @stopped
      Rogue.ticker.call window, @loop
    if @showFPS then @parent.context.fillText("fps:#{@fps} step:#{@dt}",10,10)
    @lastTick = @currentTick
  # Pauses the game loop, loop still runs, but no functions are called
  pause: -> 
    @paused = true
  # Stops the game loop
  stop: ->
    @stopped = true

  # adds a function or an array of functions to the loop
  add: (func) ->
    @call = @call.concat func

# A simple rolling average class, used internally for smoothing fps
#
class RollingAverage
  constructor: (@size) ->
    @values = new Array @size
    @count = 0

  add: (value) ->
    @values = @values[1...@size]
    @values.push value
    if @count < @size then @count++
    return ((@values.reduce (t, s) -> t+s)/@count) | 0

# Viewport class, most games will use this. Expands the game world to be larger than the canvas.
#
class ViewPort
  # @param [Object] options options for setting up the viewport
  # @option options [Game] parent the parent game instance to attach the viewport to
  # @option options [Canvas] canvas the canvas this viewport should render on, defaults to the parents canvas
  # @option options [Int] width the width of the viewport, defaults to the canvas width
  # @option options [Int] height the height of the viewport, defaults to the canvas height
  # @option options [Int] viewWidth the width of the viewable area, defaults to width
  # @option options [Int] viewHeight the height of the viewable area, defaults to height
  #
  constructor: (@options) ->
    @parent = @options.parent
    @canvas = @options.canvas or @parent.canvas or util.canvas()
    @context = @canvas.getContext('2d')
    @width = @options.width or @canvas.width
    @height = @options.height or @canvas.height
    @viewWidth = @options.viewWidth or @width
    @viewHeight = @options.viewHeight or @height
    @viewX = @options.viewX or 0
    @viewY = @options.viewY or 0
    @x = @options.x or 0
    @y = @options.y or 0
    @e = []
    @updates = []

  # Add an entity or an array of entities to the viewport, will be updated and rendered with the viewport, 
  # and position is drawn relative to the viewports position
  # @param [Entity] entity entity to add, alternitively an array of entities can be given.
  #
  add: (entity) ->
    if entity.forEach
      entity.forEach (obj) => @add obj
    else
      entity.parent = @
      @e.push(entity)
      @parent.e.push(entity)
      if entity.name? then @[entity.name] = entity

  # Updates all entities within the viewport. The viewport update function should be called from your states update function
  # @param [Float] dt dt, the time elapsed between ticks. all update functions should be passed dt if physics is needed.
  #
  update: (dt) ->
    for entity in @e
      if @close(entity) and entity.update?
        entity.update(dt)
    func.call(@,dt) for func in @updates when func?

  # Draws all entities within the viewport. The viewport draw function should be called from within your states draw function.
  #
  draw: ->
    @context.save()
    @context.translate(-@viewX, -@viewY)
    @context.beginPath()
    @context.rect(@x+@viewX, @y+@viewY, @width, @height)
    @context.clip()
    for entity in @e
      if @visible(entity) and entity.draw?
        entity.draw()
    @context.restore()

  # moves the view area by [x,y]
  # @param [Int] x 
  # @param [Int] y
  #
  move: (x,y) ->
    @viewX += x
    @viewY += y
    @keepInBounds()

  # moves the view area to [x,y]
  # @param [Int] x 
  # @param [Int] y
  #
  moveTo: (x,y) ->
    @viewX = x
    @viewY = y
    @keepInBounds()

  # Makes the view follow an entity, so that entity is always in the center
  # @param [Entity] entity the entity to follow
  #
  follow: (entity) ->
    @viewX = entity.x - math.round(@width/2)
    @viewY = entity.y - math.round(@height/2)
    @keepInBounds()

  # prevents an entity from going outside of the view area.
  # @param [Entity] entity the entity to force inside
  # @param [Int] buffer the minimum distance an entity can be from the edge of the view area, defaults to 0
  #
  forceInside: (entity, buffer=0) ->
    w = @viewWidth; h = @viewHeight
    if entity.x < buffer then entity.x = buffer
    if entity.y < buffer then entity.y = buffer
    if entity.x > w-buffer then entity.x = w-buffer
    if entity.y > h-buffer then entity.y = h-buffer
 
  # used for checking the visibility of objects
  # @return [Rect] a rectangle object of the currently visible area
  #
  rect: ->
    width: @width
    height: @height
    x: @viewX
    y: @viewY

  # Checks if an entity is currently visible.
  # @param [Entity] entity
  # @return [Bool] true if the entity is visible
  #
  visible: (entity) ->
    collision.AABB entity.rect(), @rect()

  keepInBounds: ->
    if @viewX < 0 then @viewX = 0
    if @viewY < 0 then @viewY = 0
    if @viewX+@width > @viewWidth then @viewX = @viewWidth - @width
    if @viewY+@height > @viewHeight then @viewY = @viewHeight - @height

  # @see Game.find
  #
  find: (components,ex) ->
    find.call(@,components,ex)

  close: (entity) ->
    collision.AABB entity.rect(),
      width: @width*2
      height: @height*2
      x:@viewX-@width/2
      y:@viewY-@height/2

# Logging function. uses Rogue.loglevel to determine which logs should be displayed.
# 1: error
# 2: warning
# 3: info
# 4: debug
# All logs with numbers less than the current log level will be displayed.
# @param [Int] level loglevel of this log
# All other arguments are passed to the console function
#
log = (level, args...) ->
  return unless level <= Rogue.loglevel
  switch level
    when 1 then func = console.error or console.log
    when 2 then func = console.warn or console.log
    when 3 then func = console.info or console.log
    when 4 then func = console.debug or console.log
  func.call(console,"(Rogue)", args...)

# Utility functions
util =
  # Makes a new canvas
  canvas: -> document.createElement("canvas")

  imgToCanvas: (i) ->
    c = @canvas()
    c.src = i.src; c.width = i.width; c.height = i.height
    cx = c.getContext "2d"
    cx.drawImage i,0,0,i.width,i.height
    c

  isArray: (value) ->
    Object::toString.call(value) is '[object Array]'

  remove: (a,val) ->
    idx = a.indexOf(val)
    idx and a.splice idx, 1

  mixin: (obj, mixin) ->
    for name, method of mixin when method isnt null
      if method.slice
        obj[name] = method.slice(0)
      else
        obj[name] = method
    obj
    
  IE: ->
    `//@cc_on navigator.appVersion`


class Eventer
  constructor: (@context) -> @handlers = {}
  on: (e,func) -> (@handlers[e] ?= []).push func
  off: (e,func) -> @handlers[e] and util.remove @handlers[e], func
  emit: (e, data...) -> @handlers[e] and for handler in @handlers[e] then handler.call @context,data... 

find = (c,ex) ->
  found = []
  for ent in @e when ent isnt ex
      f = 0
      f++ for i in c when ent.components[i]?
      if f is c.length
        found.push ent
  return found
# Maths
math =
  # A faster round implementation
  round: (num) ->
    return (0.5 + num) | 0
math.vector = v

# Globals

Rogue = @Rogue   = {}
module?.exports  = Rogue

Rogue.ticker = window.requestAnimationFrame or 
               window.webkitRequestAnimationFrame or 
               window.mozRequestAnimationFrame or
               window.oRequestAnimationFrame or
               window.msRequestAnimationFrame or
               (tick) -> window.setTimeout(tick, 1000/60)

# Calls a function when the DOM is ready
# @param [Function] f function to call               

Rogue.ready = (f) -> document.addEventListener "DOMContentLoaded", ->
  document.removeEventListener "DOMContentLoaded", arguments.callee, false
  f()

Rogue.log          = log
Rogue.util         = util
Rogue.math         = math
Rogue.physics      = physics
Rogue.Game         = Game
Rogue.GameLoop     = GameLoop
Rogue.TileMap      = TileMap
Rogue.AssetManager = AssetManager
Rogue.SpriteSheet  = SpriteSheet
Rogue.gfx          = gfx
Rogue.collision    = collision
Rogue.Animation    = Animation
Rogue.ViewPort     = ViewPort
Rogue.components   = c
Rogue.Entity       = Entity
Rogue.Keyboard     = Keyboard
Rogue.Mouse        = Mouse

Rogue.loglevel = 4