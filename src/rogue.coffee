class Game
	constructor: (@options) ->
		@canvas = document.getElementById(options.canvas) if options?.canvas?
		if not @canvas?
			@canvas = document.createElement "canvas"
			document.body.appendChild(@canvas)
		@canvas.tabIndex=1
		@width = @canvas.width = options?.width ? 400
		@height = @canvas.height = options?.height ? 300
		@canvas.x = @canvas.y = 0
		@context = @canvas.getContext('2d')
	start: (state) ->
		loading = @options?.loadingScreen ? ->
		@switchState(state)

	switchState: (state) ->
		@loop and @loop.stop()
		@oldState = @state
		@state = state
		@state.setup()
		@loop = new GameLoop @state
		@loop.start()

	clear: ->
		@context.clearRect(0,0,@width,@height)

class GameLoop
	constructor: (@state) ->
		@fps = 0
		@averageFPS = new RollingAverage 20

	start: ->
		@paused = @stopped = false
		firstTick = currentTick = lastTick = (new Date()).getTime()
		Rogue.ticker.call window, @loop

	loop: =>
		@currentTick = (new Date()).getTime()
		@tickDuration = @currentTick - @lastTick
		@fps = @averageFPS.add(1000/@tickDuration)
		unless @stopped or @paused
			@state.update()
			@state.draw()
		unless @stopped
			Rogue.ticker.call window, @loop
		@lastTick = @currentTick
	pause: -> 
		@paused = true
	stop: ->
		@stopped = true

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
		@canvas = @options.canvas or document.createElement "canvas"
		@context = @canvas.getContext('2d')
		@width = @options.width or @canvas.width
		@height = @options.height or @canvas.height
		@viewWidth = @options.viewWidth or @width
		@viewHeight = @options.viewHeight or @height
		@viewX = @options.viewX or 0
		@viewY = @options.viewY or 0
		@x = @options.x or 0
		@y = @options.y or 0
		@entities = []

	add: (entity) ->
		if entity.forEach
			entity.forEach (obj) => @add obj
		else
			entity.parent = @
			@entities.push(entity)

	draw: ->
		@context.save()
		@context.translate(-@viewX, -@viewY)
		for entity in @entities
			if @visible entity
				entity.draw()
		@context.restore()
		@context.strokeRect(@x,@y,@width,@height)

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
		if entity.x > h-buffer then entity.y = h-buffer

	visible: (entity) ->
		util.collide entity, @

	keepInBounds: ->
		if @viewX < 0 then @viewX = 0
		if @viewY < 0 then @viewY = 0
		if @viewX+@width > @viewWidth then @viewX = @viewWidth - @width
		if @viewY+@height > @viewHeight then @viewY = @viewHeight - @height



# Logging

log = (level, args...) ->
	return unless level <= Rogue.loglevel
	console?.log?("(Rogue)", args...)
	this

# Utilities

util =
	isArray: (value) ->
		Object::toString.call(value) is '[object Array]'
	collide: (r1,r2) ->
		not (r2.x >= r1.x+r1.width or r2.x+r2.width <= r1.x or r2.y >= r1.y+r1.height or r2.y+r2.height <= r1.y)	

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
Rogue.ViewPort        = ViewPort
Rogue.Entity          = Entity
Rogue.KeyboardManager = KeyboardManager

Rogue.loglevel = 6