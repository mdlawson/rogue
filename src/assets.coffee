class AssetManager
	constructor: ->
		@count = 0
		@ecount = 0
		@queue = []
		@assets = {}
		@filetypes =
			image: ["png","gif","jpg","jpeg","tiff"]
			sound: ["mp3","ogg"]

	add: (url) ->
		@queue = @queue.concat url

	get: (src) ->
		if not @assets[src]? then Rogue.log 2,"asset not loaded: #{src}"
		@assets[src]

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
			Rogue.log 2,"unknown extension on: #{src}"
			return
		switch type
			when "image"
				asset = new Image()
				asset.addEventListener "load", ->
					canvas = util.canvas()
					canvas.width = @width
					canvas.height = @height
					canvas.src = src
					context = canvas.getContext "2d"
					context.drawImage @, 0, 0, @width, @height
					that.count++
					that.loaded canvas
				asset.addEventListener "error", ->
					that.ecount++
					Rogue.log 2,"could not load asset: #{@src}"
					that.loaded @
				asset.src = src

	loaded: (asset) ->
		@assets[asset.src] = asset
		percentage = ((@count+@ecount)/@queue.length)*100
		@onLoad(percentage)
		if percentage is 100 then @onFinish()

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



