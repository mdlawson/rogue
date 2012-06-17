# RogueJS 
#
# This is the main RogueJS module. Contains classes for constructing 
# the skeleton of a game. Also contains utility functions
#

# The Game class. This is where the game state and canvas are managed.
# @example Creating a Game instance:
# 	myGame = new Game
# 		canvas: "myCanvasId"
# 		width: 500
# 		height: 350
#
class Game
	# Construct a new game.
	#
	# @param [Object] options Game options
	# @option options [String] canvas the Id of a canvas element, if blank a new one is created
	# @option options [Integer] width the width to set the canvas to
	# @option options [Integer] height the height to set the canvas to
	#
	constructor: (@options={}) ->
		@canvas = document.getElementById(options.canvas) if @options.canvas?
		if not @canvas?
			@canvas = util.canvas()
			document.body.appendChild(@canvas)
		@canvas.tabIndex=1
		@width = @canvas.width = @options.width ? 400
		@height = @canvas.height = @options.height ? 300
		@showFPS = @options.fps ? false
		@canvas.x = @canvas.y = 0
		@context = @canvas.getContext('2d')

	# Start the game with a given state.
	# @param [Object] state the state to use
	#
	#	A state is an object with 2 methods, a start method, 
	#	which is run when the state is first loaded, and a
	#	update method, which is run every tick.
	#
	# @example
	# 	myGame.start({setup: -> foo();, update: -> bar()})
	start: (state) ->
		loading = @options.loadingScreen ? ->
		@switchState(state)

	# Switches the state to a different state.
	# @param [Object] state the state to switch to
	# The old state is stored in @oldState
	switchState: (state) ->
		@e = []
		@loop and @loop.stop()
		@oldState = @state
		@state = state
		@state.setup()
		@loop = new GameLoop @context,@showFPS
		@loop.add @state.update
		@loop.start()


	#	Clears the canvas, can be run at the end of each frame.
	#	@todo automatic partial update system?
	clear: ->
		@context.clearRect(0,0,@width,@height)

	# Finds entities within the scope of the game, given a list of components to match
	# @param [Array] components array of components a matched object must have
	#
	# @example
	# 	solidEnemies = myGame.find ["enemy","collide"]
	# @return [Array] An array of {Entity} that have the components
	find: (components) ->
		find.call(@,components)

# The GameLoop class. Runs a list of functions, stored in @call, every tick.
# Is handled internally, but can be used manually if desired.
class GameLoop
	constructor: (@ctx,@showFPS) ->
		@fps = 0
		@averageFPS = new RollingAverage 20
		@call = []
	# Starts the loop, running each function in @call every tick
	start: ->
		@paused = @stopped = false
		firstTick = currentTick = lastTick = (new Date()).getTime()
		Rogue.ticker.call window, @loop
	loop: =>
		@currentTick = (new Date()).getTime()
		@tickDuration = @currentTick - @lastTick
		@fps = @averageFPS.add(1000/@tickDuration)
		unless @stopped or @paused
			func() for func in @call
		unless @stopped
			Rogue.ticker.call window, @loop
		@lastTick = @currentTick
	# Pauses the game loop, loop still runs, but no functions are called
	pause: -> 
		@paused = true

	# Stops the game loop
	stop: ->
		@stopped = true

	# Adds a function to the gameloop
	# @param [Function] func function to run every tick
	# Can also be passed an array of functions
	# @param [Array] func array of functions to run
	# Functions will run after existing functions. To run them before, you could do
	# @example running a function before exisisting functions
	# 	loop.call.unshift -> #foo
	add: (func) ->
		@call = @call.concat func

class RollingAverage
	constructor: (@size) ->
		@values = new Array @size
		@count = 0

	add: (value) ->
		@values = @values[1...@size]
		@values.push value
		if @count < @size then @count++
		return parseInt (@values.reduce (t, s) -> t+s)/@count

# The ViewPort class
# Creates a "window" into a larger area, and allows entities to be drawn relative
# to the larger area. The viewport becomes the parent of all enclosed entities.
# @example Creating a viewport
# 	view = new ViewPort
# 		canvas: myGame.canvas
# 		parent: myGame
# 		viewWidth: 1000
# 		viewHeight: 300
class ViewPort extends Entity
	# Makes a new ViewPort instance 
	# @param [Object] options the viewport options
	# @option options [Canvas] canvas the canvas the viewport should render on
	# @option options [Object] parent the parent object of the viewport, usually a game instance
	# @option options [Integer] width the width of the viewport, defaults to the canvas width
	# @option options [Integer] height the height of the viewport, defaults to the canvas height
	# @option options [Integer] viewWidth the width of the viewable area, defaults to the canvas width
	# @option options [Integer] viewHeight the height of the viewable area, defaults to the canvas height
	# @option options [Integer] viewX the initial x offset of the viewable area, defaults to 0
	# @option options [Integer] viewY the initial y offset of the viewable area, defaults to 0
	# @option options [Integer] x the x position of the viewport relative to the parent
	# @option options [Integer] y the y position of the viewport relative to the parent
	constructor: (@options) ->
		@canvas = @options.canvas or util.canvas()
		@context = @canvas.getContext('2d')
		@parent = @options.parent
		@width = @options.width or @canvas.width
		@height = @options.height or @canvas.height
		@viewWidth = @options.viewWidth or @width
		@viewHeight = @options.viewHeight or @height
		@viewX = @options.viewX or 0
		@viewY = @options.viewY or 0
		@x = @options.x or 0
		@y = @options.y or 0
		@e = []
		@updates = {99:@draw}
	# adds an {Entity} to the viewport, updates its parent automatically. 
	# The {Entity} will now be updated with the viewport, and drawn relative to the viewport
	# @param [Entity] entity the {Entity} to add
	# also supports adding an array of entities,
	# @param [Array] entity an array of entities to add
	add: (entity) ->
		if entity.forEach
			entity.forEach (obj) => @add obj
		else
			entity.parent = @
			@e.push(entity)
			@parent.e.push(entity)

	# The draw function of the viewport, calls update on all visible enclosed entities.
	draw: ->
		@context.save()
		@context.translate(-@viewX, -@viewY)
		@context.beginPath()
		@context.rect(@x+@viewX, @y+@viewY, @width, @height)
		@context.clip()
		for entity in @e
			if @visible entity
				entity.update()
		@context.restore()

	# Moves the viewport by a given amount, ensures the viewport is kept within the bounds of the viewable area.
	# @param [Integer] x the amount to move in the x axis
	# @param [Integer] y the amount to move in the y axis
	move: (x,y) ->
		@viewX += x
		@viewY += y
		@keepInBounds()

	# Moves the viewport to a given position, ensures the viewport is kept within the bounds of the viewable area.
	# @param [Integer] x the value to set x to
	# @param [Integer] y the value to set y to
	moveTo: (x,y) ->
		@viewX = x
		@viewY = y
		@keepInBounds()

	# Has the viewport move automatically to keep an entity in the center.
	# @param [Entity] entity the entity to follow
	# Needs to run every tick, so can be added to the start of the viewports @updates like so
	# @example following an entity 
	# 	viewPort.updates.unshift ->
	# 		@follow app.player
	follow: (entity) ->
		@viewX = entity.x - math.round(@width/2)
		@viewY = entity.y - math.round(@height/2)
		@keepInBounds()

	# Ensures an entity can never move outside the viewable area.
	# @param [Entity] entity entity to prevent moving outside
	# @param [Boolean] visible whether the entity should be forced inside the viewable area or the bounds of the viewport. defaults to viewable area
	# @param [Integer] buffer the closest the entity can come to the limits, defaults to 0
	forceInside: (entity, visible=false, buffer=0) ->
		if visible then w = @width; h = @height else w = @viewWidth; h = @viewHeight
		if entity.x < buffer then entity.x = buffer
		if entity.y < buffer then entity.y = buffer
		if entity.x > w-buffer then entity.x = w-buffer
		if entity.y > h-buffer then entity.y = h-buffer

	# Gets a rectangle of the viewable areas dimensions
	# @return [Object] an object with x, y, width and height properties. 
	rect: ->
		width: @width
		height: @height
		x: @viewX
		y: @viewY

	# Determines if an entity is visible, by checking if it collides with the visible area.
	# @param [Entity] entity the entity to check
	# @return [Boolean] returns true if the object is visible
	visible: (entity) ->
		util.collide entity.rect(), @rect()

	# keeps the viewport within the bounds of the viewable area
	keepInBounds: ->
		if @viewX < 0 then @viewX = 0
		if @viewY < 0 then @viewY = 0
		if @viewX+@width > @viewWidth then @viewX = @viewWidth - @width
		if @viewY+@height > @viewHeight then @viewY = @viewHeight - @height

	# Finds entities within the scope of the viewport, given a list of components to match
	# @param [Array] components array of components a matched object must have
	# @example
	# 	solidEnemies = myView.find ["enemy","collide"]
	# @return [Array] An array of {Entity} that have the components
	find: (components) ->
		find.call(@,components)



# Logging function, supports loglevels and generates appropriate 
# console messages based on the log level
# @param [Integer] level the loglevel of the message (1: error, 2: warn, 3: info, 4: debug)
# Logs with loglevel higher than the value of Rogue.loglevel will not be displayed
# @param [Args...] args... The data to pass to console.log

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

	# Checks if value is an array
	# @param [*] value value to check
	isArray: (value) ->
		Object::toString.call(value) is '[object Array]'

	# Removes (the first instance of) a given element from an array
	# @param [Array] a array to search
	# @param [*] val value to remove
	remove: (a,val) ->
		a.splice a.indexOf(val), 1

	# Checks if two rectangular objects (with x, y, width and height parameters) collide
	# @param [Object] r1 1st object
	# @param [Object] r2 2ns object
	# @return [Boolean] Returns true if the two object collide
	collide: (r1,r2) ->
		not (r2.x >= r1.x+r1.width or r2.x+r2.width <= r1.x or r2.y >= r1.y+r1.height or r2.y+r2.height <= r1.y)

	overlap: (r1,r2) ->
		x = Math.max(r1.x, r2.x) 

	# Mixes in the properties/methods of mixin into obj
	# @param [Object] obj the target object
	# @param [Object] mixin the mixin
	mixin: (obj, mixin)	->
		for name, method of mixin
			if method.slice
				obj[name] = method.slice(0)
			else
				obj[name] = method
		obj

	# Imports an array of components into an Entity, checking they are not already imported,
	# and running the init functions of each component
	# @param [Array] components and array of components to import
	# @param [Entity] the Entity to import the components to
	import: (obj,components) ->
		for comp in components
			if comp not in obj.components
				obj.components.push comp
				util.mixin obj, new c[comp]
				obj.init()
				delete obj.init; delete obj.import

find = (c) ->
	found = []
	for ent in @e
			f = 0
			f++ for i in c when i in ent.components
			if f is c.length
				found.push ent
	return found
# Maths
math =
	# A faster round implementation
	round: (num) ->
		return (0.5 + num) | 0

# Globals

Rogue = @Rogue   = {}
module?.exports  = Rogue

Rogue.ticker = window.requestAnimationFrame or 
							 window.webkitRequestAnimationFrame or 
							 window.mozRequestAnimationFrame or
							 window.oRequestAnimationFrame or
							 window.msRequestAnimationFrame

Rogue.ready = (f) -> document.addEventListener "DOMContentLoaded", ->
	document.removeEventListener "DOMContentLoaded", arguments.callee, false
	f()

Rogue.log             = log
Rogue.util            = util
Rogue.math            = math
Rogue.Game            = Game
Rogue.GameLoop        = GameLoop
Rogue.TileMap         = TileMap
Rogue.AssetManager    = AssetManager
Rogue.SpriteSheet     = SpriteSheet
Rogue.gfx             = gfx
Rogue.Animation       = Animation
Rogue.ViewPort        = ViewPort
Rogue.components      = c
Rogue.Entity          = Entity
Rogue.KeyboardManager = KeyboardManager

Rogue.loglevel = 4