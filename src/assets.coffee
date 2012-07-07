class AssetManager
	constructor: ->
		@count = 0
		@ecount = 0
		@queue = []
		@image = {}
		@sound = {}
		@filetypes =
			image: ["png","gif","jpg","jpeg","tiff"]
			sound: ["mp3","ogg"]

	add: (url) ->
		@queue = @queue.concat url

	get: (src) ->
		if not this[src]? then log 2,"asset not loaded: #{src}"
		this[src]

	loadAll: (options) ->
		@onFinish = options.onFinish
		@onLoad = options.onLoad
		@load(a) for a in @queue

	load: (src) ->
		that = @
		ext = src.split(".").pop()
		for key,value of @filetypes
			if ext in value
				type = key
		if not type?
			log 2,"unknown extension on: #{src}"
			return
		switch type
			when "image"
				asset = new Image()
				asset.onload = ->
					canvas = util.canvas()
					canvas.type = type
					canvas.width = @width
					canvas.height = @height
					canvas.src = src
					context = canvas.getContext "2d"
					context.drawImage @, 0, 0, @width, @height
					that.count++
					that.loaded canvas
				asset.onerror = -> that.onerror(@)
					
				asset.src = src
			when "sound"
				asset = new Audio(src)
				asset.type = type
				asset.name = src
				switch ext
					when 'mp3' then codec = 'audio/mpeg'
					when 'ogg' then codec = 'audio/ogg'
				unless asset.canPlayType(codec) then @loaded asset
				cb = ->
					@removeEventListener "canplaythrough", cb
					that.count++
					that.loaded @
				asset.addEventListener "canplaythrough", cb
				asset.onerror = -> that.onerror(@)
				asset.load()

	onerror: (asset) ->
		@ecount++
		log 2,"could not load asset: #{asset.src}"
		@loaded asset

	loaded: (asset) ->
#		log 2, "loaded:",asset
		name = asset.name or asset.src
		this[asset.type][name.split(".")[0]] = asset
		this[name] = asset
		percentage = ((@count+@ecount)/@queue.length)*100
		@onLoad(math.round percentage)
		if percentage is 100 then @onFinish()
		
class SoundBox
	constructor: (@sounds, map) ->

	play: (sound) ->
		if @sounds[sound]? then @sounds[sound].play()
	pause: (sound) ->
		if @sounds[sound]? then @sounds[sound].pause()
	stop: (sound) ->
		if @sounds[sound]? then @sounds[sound].stop()
	func: (name,asset) ->
		if @sounds[asset]? then this[name] = -> @play(asset) 
		else "no such sound!"


class SpriteSheet
	constructor: (@options) ->
		@img = @options.image
		@res = @options.res or [32,32]
		@length = 0
		for x in [0...@img.width] by @res[0]
			for y in [0...@img.height] by @res[1]
				c = util.canvas()
				cx = c.getContext "2d"
				c.width = @res[0]
				c.height = @res[1]
				cx.drawImage(@img,x,y,c.width,c.height,0,0,c.width,c.height)
				this[@length] = c
				@length++
	slice: (start, end) ->
		return Array::slice.call(this, start, end);

class Animation
	constructor: (@options) ->
		@sprites = @options.spritesheet
		@speed = @options.speed or 6
		@i = @options.start or 0
		@t = 0
		@loop = @options.loop or true
		@bounce = @options.bounce or false
		@onFinish = @options.onFinish
		@dir = 1

		@frame = @sprites[@i]

	next: ->
		if @t is @speed
			@frame = @sprites[@i+=@dir]
			@t = 0
		if @i is @sprites.length-1 
			if not @loop
				if @onFinish then @onFinish()
			else
				if @bounce
					@dir = -1
				else
					@i = 0
		if @i is 0 and @dir is -1 then @dir = 1
		@t++
		return @frame



