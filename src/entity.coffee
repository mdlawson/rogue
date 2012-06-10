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

c.sprite =
	init: ->
		unless @image then log 2, "Sprite entitys require an image"
		@width ?= @image.width
		@height ?= @image.height
		@x ?= 0
		@y ?= 0
		@res ?= [1,1] 
		@xOffset ?= math.round(@width/2)
		@yOffset ?= math.round(@height/2)
		if @scaleFactor then @scale @scaleFactor
		@updates.push @draw
	draw: ->
		c = @parent.context
		c.save()
		c.translate((@x*@res[0])-@xOffset, (@y*@res[1])-@yOffset)
		if @angle then c.rotate(@angle*Math.PI/180)
		if @alpha then c.globalAlpha = @alpha
		c.drawImage(@image, 0, 0, @width, @height)
		c.restore()
	scale: (factor) ->
		@image = gfx.scale @image,factor
		@width = @image.width
		@height = @image.height
		@xOffset = math.round(@width/2)
		@yOffset = math.round(@height/2)

	rect: ->
		x: @x-@xOffset
		y: @y-@yOffset
		width: @width
		height: @height

c.move =
	init: ->
		util.import(["sprite"],@)

	move: (x,y) ->
		@x += x
		@y += y

	moveTo: (@x,@y) ->

c.tile =
	init: ->
		util.import ["sprite"], @

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
		util.import(["sprite"],@)
		@updates.unshift @colliding

	collide: (obj) ->
		util.collide @rect(), obj.rect()

	colliding: ->
		solid = @parent.find(["collide"])
		util.remove solid, @
		results = []
		results.push obj for obj in solid when @collide(obj)
		return results




