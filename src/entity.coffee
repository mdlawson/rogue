class Entity
	constructor: (@options) ->
		@components=[]
		@updates=[]
		util.mixin @, @options
		if @import then util.import(@import,@)
		if @parent then @parent.e.push @

	update: ->
		func.call(@) for func in @updates

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
		@updates.push @draw
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
		util.import ["drawable"], @

	move: (x,y) ->
		util.remove @tile.contents, @
		@x += x
		@y += y
		@tile.parent.place @

	moveTo: (@x,@y) ->
		util.remove @tile.contents, @
		@tile.parent.place @

	rect: ->
		x: (@res[0]*@x)-@xOffset
		y: (@res[1]*@y)-@yOffset
		width: @width
		height: @height

c.collide =
	init: ->
		util.import(["drawable"],@)
		@updates.unshift @colliding

	collide: (obj) ->
		util.collide @rect(), obj.rect()

	colliding: ->
		solid = @parent.find(["collide"])
		util.remove solid, @
		results = []
		results.push obj for obj in solid when @collide(obj)
		return results




