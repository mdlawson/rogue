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
		switchState(@state)

	switchState: (state) ->
		@loop and @loop.stop()
		@oldState = @state
		@loop = new GameLoop @state
		@loop.start()

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

Rogue.loglevel = 6