class Game
	constructor: (@options) ->
		@canvas = document.getElementById(options.canvas) if options?.canvas?
		if not @canvas?
			@canvas = document.createElement "canvas"
			document.body.appendChild(@canvas)
		@width = @canvas.width = options?.width ? 400
		@height = @canvas.height = options?.height ? 300
		@context = @canvas.getContext('2d')
	start: (@state) ->
		loading = @options.loadingScreen ? ->
		@switchState(@state)

	switchState: (state) ->
		@loop and @loop.stop()
		@oldState = @state
		@loop = new GameLoop @state
		@loop.start()

	clear: ->
		@context.clearRect(0,0,@width,@height)

class GameLoop
	constructor: (@state) ->
		@fps = 0
		@paused = @stopped = false
		@averageFPS = new RollingAverage 20

	start: ->
		firstTick = currentTick = lastTick = (new Date()).getTime()
		Rogue.ticker @loop

	loop: =>
		@currentTick = (new Date()).getTime()
		@tickDuration = @currentTick - @lastTick
		@fps = @averageFPS.add(1000/@tickDuration)
		unless @stopped or @paused
			@state.update()
			@state.draw()
		unless @stopped
			Rogue.ticker @loop
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
		@context = @cavas.getContext('2d')
		@width = @options.width or @canvas.width
		@height = @options.height or @canvas.height
		@maxWidth = @options.maxWidth or @width
		@maxheight = @options.maxHeight or @height
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
		for entity in @entities
			if @visible entity
				entity.draw

	move: (x,y) ->
		@x += x
		@y += y
		@keepInBounds()

	moveTo: (x,y) ->
		@x = x
		@y = y
		@keepInBounds()

	centerAround: (entity) ->
		@x = entity.x - Rogue.math.round(@width/2)
		@y = entity.y - Rogue.math.round(@height/2)
		@keepInBounds()

	visible: (entity) ->
		(entity.x >= @x and entity.y >= @y) or ((entity.x+entity.width) <= (@x+@width) and (entity.y+entity.height) <= (@y+@height))

	keepInBounds: ->
		if @x < 0 then @x = 0
		if @y < 0 then @y = 0
		if @x+@width > @maxWidth then @x = @maxWidth - @width
		if @y+@height > @maxHeight then @y = @maxHeight - @height



# Logging

log = (level, args...) ->
	return unless level <= Rogue.loglevel
	console?.log?("(Rogue)", args...)
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

Rogue.ticker = window.requestAnimationFrame or 
							 window.webkitRequestAnimationFrame or 
							 window.mozRequestAnimationFrame or
							 window.oRequestAnimationFrame or
							 window.msRequestAnimationFrame

Rogue.log          = log
Rogue.util         = util
Rogue.math         = math
Rogue.Game         = Game
Rogue.GameLoop     = GameLoop
Rogue.TileMap      = TileMap
Rogue.AssetManager = AssetManager
Rogue.ViewPort     = ViewPort
Rogue.Entity       = Entity

Rogue.loglevel = 6