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
					canvas = document.createElement "canvas"
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