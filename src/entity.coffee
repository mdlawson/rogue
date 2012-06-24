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
		func.call(@) for func in @updates when func?

c = {}

class c.sprite
	init: ->
		unless @image then log 2, "Sprite entitys require an image"
		@x ?= 0
		@y ?= 0	
		if @scaleFactor? then @scale @scaleFactor, @pixel else @_recalculateImage()
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
	scale: (@scaleFactor, @pixel) ->
		@y-=@height*@scaleFactor[1]/2
		@image = gfx.scale @image,@scaleFactor,@pixel
		@_recalculateImage()


	rect: ->
		x: @x-@xOffset
		y: @y-@yOffset
		width: @width
		height: @height

	_recalculateImage: ->
		@width = @image.width
		@height = @image.height
		@xOffset = math.round(@width/2)
		@yOffset = math.round(@height/2)

class c.move
	init: ->
		@import ["sprite"]
		@dy ?= 0
		@dx ?= 0
		@updates[98] = ->
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
		#@updates[97] = @findCollisions

	collide: (obj) ->
		if obj.forEach
			obj.forEach (o) => @collide o
		if obj in @colliding then true else false

	findCollisions: ->
		solid = @parent.find(["collide"])
		util.remove solid, @
		results = []
		for obj in solid
			dir = util.collide(@rect(),obj.rect())
			if dir
				col = 
					dir: dir
					entity: obj
				if @onHit? then @onHit col
				results.push col
					
		@colliding = results
	move: (x,y) ->
		if Math.abs(x) < 1 and Math.abs(y) < 1
				return false
		@x += x
		@y += y
		if @findCollisions().length > 0
			@x -= x
			@y -= y
			if @move(~~(x/2), ~~(y/2))
				if not @move(~~(x/2), ~~(y/2)) then return false else
					return true
			else return false
		else return true

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
		@xOffset = @yOffset = 0
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
			if @scrollX then @x = math.round(rect.x*@speed)
			if @scrollY then @y = math.round(rect.y*@speed)
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




