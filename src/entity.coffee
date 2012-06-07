class Entity
	constructor: (@options) ->
		@components=[]
		util.mixin @, @options
		if @import then util.import(@import,@)


c = {}

c.drawable =
	init: ->
		unless @image then log 2, "Drawable entitys require an image"
		@width ?= @image.width
		@height ?= @image.height
		@x ?= 0
		@y ?= 0
		@res ?= [1,1] 
		@xOffset ?= math.round(@image.width/2)
		@yOffset ?= math.round(@image.height/2)
	draw: ->
		@parent.context.save()
		@parent.context.translate((@x*@res[0])-@xOffset, (@y*@res[1])-@yOffset)
		@parent.context.drawImage(@image, 0, 0, @width, @height)
		@parent.context.restore()
	rect: ->
		x: @x-@xOffset
		y: @y-@yOffset
		width: @width
		height: @height

c.movable =
	init: ->
		util.import(["drawable"],@)

	move: (x,y) ->
		@x += x
		@y += y

	moveTo: (@x,@y) ->

c.tilemove =
	init: ->
		util.import(["drawable"],@)
	move: (x,y) ->
		dest = @tile
		@tile.contents.splice(@tile.contents.indexOf(@),1)
		dir1 = if x < 0 then 'n' else 's'
		dir2 = if y < 0 then 'e' else 'w'
