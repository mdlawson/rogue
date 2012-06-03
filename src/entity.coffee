class Entity
	constructor: (options) ->
		for key,val of options
			this[key] = val
		@width ?= @image.width
		@height ?= @image.height
		@x ?= 0
		@y ?= 0
		@res = [1,1]

	move: (x,y) ->
		@x += x
		@y += y
	moveTo: (x,y) ->
		@x = x
		@y = y

	draw: ->
		@parent.context.save()
		@parent.context.translate(@x*@res[0], @y*@res[1])
		@parent.context.drawImage(@image, 0, 0, @width, @height)
		@parent.context.restore()
