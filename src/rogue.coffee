###
# RogueJS #

This is the main RogueJS module. Contains classes for constructing 
the skeleton of a game. Also contains utility functions
###

class Game
	###
	The Game class. This is where the game state and canvas are managed.
	###
	constructor: (@options) ->
		@canvas = document.getElementById(options.canvas) if options?.canvas?
		if not @canvas?
			@canvas = util.canvas()
			document.body.appendChild(@canvas)
		@canvas.tabIndex=1
		@width = @canvas.width = options?.width ? 400
		@height = @canvas.height = options?.height ? 300
		@canvas.x = @canvas.y = 0
		@context = @canvas.getContext('2d')
		### 
		Options:
		+ canvas: the ID of an existing canvas element to use
		+ width: the width to set the canvas to, default: 400
		+ height: the height to set the canvas to, default: 300
		###

	start: (state) ->
		loading = @options?.loadingScreen ? ->
		@switchState(state)
		###
		Starts the game with a state:
		A state is an object with 2 methods, a start method, 
		which is run when the state is first loaded, and a
		update method, which is run every tick. 
		###

	switchState: (state) ->
		@e = []
		@loop and @loop.stop()
		@oldState = @state
		@state = state
		@state.setup()
		@loop = new GameLoop
		@loop.add @state.update
		@loop.start()
		###
		Switches the game to a new state. Old state is stored in oldState.
		A GameLoop instance is automatically created. 
		###

	clear: ->
		@context.clearRect(0,0,@width,@height)
		###
		Clears the canvas, can be run at the end of each frame.
		TODO: automatic partical update system.
		###

	find: (c) ->
		find.call(@,c)
		###
		Used to find entitys with given components within the namespace of the game.
		###


class GameLoop
	###
	The GameLoop class. Runs a list of functions, stored in @call, every tick
	###
	constructor: (@state) ->
		@fps = 0
		@averageFPS = new RollingAverage 20
		@call = []

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

	pause: -> 
		@paused = true

	stop: ->
		@stopped = true

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


class ViewPort extends Entity
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
		@updates = [@draw]

	add: (entity) ->
		if entity.forEach
			entity.forEach (obj) => @add obj
		else
			entity.parent = @
			@e.push(entity)
			@parent.e.push(entity)

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

	move: (x,y) ->
		@viewX += x
		@viewY += y
		@keepInBounds()

	moveTo: (x,y) ->
		@viewX = x
		@viewY = y
		@keepInBounds()

	follow: (entity) ->
		@viewX = entity.x - math.round(@width/2)
		@viewY = entity.y - math.round(@height/2)
		@keepInBounds()

	forceInside: (entity, visible=false, buffer=0) ->
		if visible then w = @width; h = @height else w = @viewWidth; h = @viewHeight
		if entity.x < buffer then entity.x = buffer
		if entity.y < buffer then entity.y = buffer
		if entity.x > w-buffer then entity.x = w-buffer
		if entity.y > h-buffer then entity.y = h-buffer

	rect: ->
		width: @width
		height: @height
		x: @viewX
		y: @viewY

	visible: (entity) ->
		util.collide entity.rect(), @rect()

	keepInBounds: ->
		if @viewX < 0 then @viewX = 0
		if @viewY < 0 then @viewY = 0
		if @viewX+@width > @viewWidth then @viewX = @viewWidth - @width
		if @viewY+@height > @viewHeight then @viewY = @viewHeight - @height

	find: (c) ->
		find.call(@,c)



# Logging

log = (level, args...) ->
	return unless level <= Rogue.loglevel
	switch level
		when 1 then func = console.error or console.log
		when 2 then func = console.warn or console.log
		when 3 then func = console.info or console.log
		when 4 then func = console.debug or console.log
	func.call(console,"(Rogue)", args...)
	this

# Utilities

util =
	canvas: -> document.createElement("canvas")

	isArray: (value) ->
		Object::toString.call(value) is '[object Array]'

	remove: (a,val) ->
		a.splice a.indexOf(val), 1

	collide: (r1,r2) ->
		not (r2.x >= r1.x+r1.width or r2.x+r2.width <= r1.x or r2.y >= r1.y+r1.height or r2.y+r2.height <= r1.y)

	mixin: (obj, mixin)	->
		obj[name] = method for name, method of mixin        
		obj

	import: (components,obj) ->
		for comp in components
			if comp not in obj.components
				obj.components.push comp
				util.mixin obj, c[comp]
				c[comp].init.apply(obj)
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
Rogue.Animation       = Animation
Rogue.ViewPort        = ViewPort
Rogue.components      = c
Rogue.Entity          = Entity
Rogue.KeyboardManager = KeyboardManager

Rogue.loglevel = 4