class Game
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

	start: (state) ->
		loading = @options.loadingScreen ? ->
		@switchState(state)

	switchState: (state) ->
		@e = []
		@loop and @loop.stop()
		@oldState = @state
		@state = state
		@state.setup.call(@)
		@loop = new GameLoop @,@showFPS
		@loop.add [@state.update,@state.draw]
		@loop.start()


	#	Clears the canvas, can be run at the end of each frame.
	#	@todo automatic partial update system?
	clear: ->
		@context.clearRect(0,0,@width,@height)

	find: (components) ->
		find.call(@,components)

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
	loop: =>
		@currentTick = (new Date()).getTime()
		@tickDuration = @currentTick - @lastTick
		@fps = @averageFPS.add(1000/@tickDuration)
		unless @stopped or @paused
			func.call(@parent) for func in @call
		unless @stopped
			Rogue.ticker.call window, @loop
		if @showFPS then @parent.context.fillText(@fps,10,10)
		@lastTick = @currentTick
	# Pauses the game loop, loop still runs, but no functions are called
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

class ViewPort
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

	add: (entity) ->
		if entity.forEach
			entity.forEach (obj) => @add obj
		else
			entity.parent = @
			@e.push(entity)
			@parent.e.push(entity)
			if entity.name? then @[entity.name] = entity
	
	update: ->
		for entity in @e
			if @close(entity) and entity.update?
				entity.update()
		func.call(@) for func in @updates when func?

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
		collision.AABB entity.rect(), @rect()

	keepInBounds: ->
		if @viewX < 0 then @viewX = 0
		if @viewY < 0 then @viewY = 0
		if @viewX+@width > @viewWidth then @viewX = @viewWidth - @width
		if @viewY+@height > @viewHeight then @viewY = @viewHeight - @height

	find: (components) ->
		find.call(@,components)

	close: (entity) ->
		collision.AABB entity.rect(),
			width: @width*2
			height: @height*2
			x:@viewX-@width/2
			y:@viewY-@height/2

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

	isArray: (value) ->
		Object::toString.call(value) is '[object Array]'

	remove: (a,val) ->
		a.splice a.indexOf(val), 1

	mixin: (obj, mixin)	->
		for name, method of mixin
			if method.slice
				obj[name] = method.slice(0)
			else
				obj[name] = method
		obj

	import: (obj,components) ->
		for comp in components
			if comp not in obj.components
				obj.components.push comp
				util.mixin obj, new c[comp]
				if obj.init then obj.init()
				delete obj.init; delete obj.import
	IE: ->
		`//@cc_on navigator.appVersion`
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
							 window.msRequestAnimationFrame or
							 (tick) -> window.setTimeout(tick, 1000/60)

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
Rogue.SoundBox        = SoundBox
Rogue.gfx             = gfx
Rogue.collision       = collision
Rogue.Animation       = Animation
Rogue.ViewPort        = ViewPort
Rogue.components      = c
Rogue.Entity          = Entity
Rogue.KeyboardManager = KeyboardManager
Rogue.Mouse           = Mouse

Rogue.loglevel = 4