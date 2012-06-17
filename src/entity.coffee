class Entity
	constructor: (@options) ->
		@components=[]
		@updates={}
		util.mixin @, @options
		if @require then @import(@require)
		if @parent then @parent.e.push @

	import: (imports) ->
		util.import(@, imports) 

	update: ->
		func.call(@) for key,func of @updates

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
		@updates[99] = @draw
	draw: ->
		c = @parent.context
		r = math.round
		c.save()
		c.translate(r(@x-@xOffset), r(@y-@yOffset))
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
		@dy ?= 0
		@dx ?= 0
		@updates[97] = ->
			@move math.round(@dx),math.round(-@dy)

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
		#@updates[98] = @colliding

	collide: (obj) ->
		if obj.forEach
			obj.forEach (o) => @collide o
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
		while @colliding().length > 0
			if x isnt 0 then (if x > 0 then @x-- else @x++)
			if y isnt 0 then (if y > 0 then @y-- else @y++)

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
		@updates[99] = @draw
	draw: (x=0, y=0)->
		rect = @parent.rect()
		r = math.round
		unless x > 0 or y > 0
			if @scrollX then @x = (rect.x)*@speed | 0
			if @scrollY then @y = (rect.y)*@speed | 0
		c = @parent.context
		c.save()
		if @angle then c.rotate(@angle*Math.PI/180)
		if @alpha then c.globalAlpha = @alpha
		c.translate(r(@x+x),r(@y+y))
		c.drawImage(@image, 0, 0, @width, @height)
		c.restore()
		if @repeatX and @x+@width+x < rect.x+rect.width
			@draw(x+@width,0)
		if @repeatY and @y+@height+y < rect.y+rect.height
			@draw(0,y+@height)

class c.gravity
	init: ->
		@import ["move"]
		@gravity ?= -10
		@updates[96] = ->
			if @dy > @gravity
				@dy -= 1




