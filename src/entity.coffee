class Entity
	constructor: (@options) ->
		@components=[]
		@updates=[]
		util.mixin @, @options
		if @require then @import(@require)
		if @parent then @parent.e.push @

	import: (imports) ->
		util.import(@, imports) 

	update: ->
		func.call(@) for func in @updates

c = {}

class c.sprite
	init: ->
		unless @image then log 2, "Sprite entitys require an image"
		@width ?= @image.width
		@height ?= @image.height
		@x ?= 0
		@y ?= 0
		@xOffset ?= math.round(@width/2)
		@yOffset ?= math.round(@height/2)
		if @scaleFactor then @scale @scaleFactor
		@updates.push @draw
	draw: ->
		c = @parent.context
		c.save()
		c.translate(@x-@xOffset, @y-@yOffset)
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

class c.move
	init: ->
		@import ["sprite"] 

	move: (x,y) ->
		@x += x
		@y += y

	moveTo: (@x,@y) ->

class c.tile
	init: ->
		@import ["sprite"]

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

class c.collide
	init: ->
		@import ["sprite"]
		@updates.unshift @colliding

	collide: (obj) ->
		util.collide @rect(), obj.rect()

	colliding: ->
		solid = @parent.find(["collide"])
		util.remove solid, @
		results = []
		results.push obj for obj in solid when @collide(obj)
		return results
	move: (x,y) ->
				@x += x
				@y += y
				if @colliding().length > 0
					@x -= x
					@y -= y

class c.collidePixel
	init: ->
		@import ["sprite"]
	collide: (obj) ->
		#if util.collide @rect(), obj.rect()

class c.layer extends c.sprite
	init: ->
		@width ?= @image.width
		@height ?= @image.height
		@x ?= 0
		@y ?= 0
		if @scaleFactor then @scale @scaleFactor
		@repeatX ?= false
		@repeatY ?= false
		@scrollY ?= false
		@scrollX ?= true
		@speed ?= 0
		@updates.push @draw
	draw: (x=0, y=0)->
		rect = @parent.rect()
		unless x > 0 or y > 0
			if @scrollX then @x = (rect.x - @x)*@speed | 0
			if @scrollY then @y = (rect.y - @y)*@speed | 0
		c = @parent.context
		c.save()
		if @angle then c.rotate(@angle*Math.PI/180)
		if @alpha then c.globalAlpha = @alpha
		c.translate(@x+x,@y+y)
		c.drawImage(@image, 0, 0, @width, @height)
		c.restore()
		if @repeatX and @x+@width+x < rect.x+rect.width
			@draw(x+@width,0)
		if @repeatY and @y+@height+y < rect.y+rect.height
			@draw(0,y+@height)






