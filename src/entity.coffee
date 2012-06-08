e = []

class Entity
	constructor: (@options) ->
		e.push @
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

c.tile =
	init: ->
		util.import(["drawable"],@)
	move: (x,y) ->
		@tile.contents.splice(@tile.contents.indexOf(@),1)
		@x += x
		@y += y
		@tile.parent.place @
	moveTo: (@x,@y) ->
		@tile.contents.splice(@tile.contents.indexOf(@),1)
		@tile.parent.place @
	rect: ->
		x: (@res[0]*@x)-@xOffset
		y: (@res[1]*@y)-@yOffset
		width: @width
		height: @height

c.collide =
	init: ->
		util.import(["drawable"],@)
	collide: (obj) ->
		util.collide @rect(), obj.rect()
