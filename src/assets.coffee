class AssetManager
	constructor: ->
		@src = @loading = @loaded = []
	filetypes =
		png:  "image"
		jpg:  "image"
		jpeg: "image"
		gif:  "image"
		bmp:  "image"
	add: (url) ->
		if Rogue.util.isArray(url)
			url.map (url) => @src.push(url)
		else
			@src.push(url)
	


