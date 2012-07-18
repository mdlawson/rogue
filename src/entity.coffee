class Entity
  constructor: (@options) ->
    @components=[]
    @updates=[]
    util.mixin @, @options
    if @require then @import(@require)
    delete @require
    if @parent then @parent.e.push @

  import: (imports) ->
    imports = [].concat(imports)
    for comp in imports
      if comp not in @components
        @components.push comp
        util.mixin @, new Rogue.components[comp]
        @init() if @init?
        delete @init

  update: ->
    func.call(@) for func in @updates when func?

c = {}

class c.sprite
  init: ->
    unless @image then log 2, "Sprite entitys require an image"
    @x ?= 0
    @y ?= 0
    @angle ?= 0
    @opacity ?= 255
    if @scaleFactor? then @scale @scaleFactor, @pixel else @_recalculateImage()
  draw: ->
    c = @parent.context
    r = math.round
    c.save()
    c.translate(r(@x-@xOffset), r(@y-@yOffset))
    c.rotate(@angle*Math.PI/180)
    c.globalAlpha = @opacity
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
    @import ["sprite"] unless "layer" in @components
    #@updates[97] = @findCollisions

  findCollisions: ->
    solid = @parent.find(["collide"])
    util.remove solid, @
    @colliding = []
    for obj in solid
      dir = @collide obj
      if dir
        col = 
          dir: dir
          entity: obj
        if @onHit? then @onHit col
        @colliding.push col
    return @colliding

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

class c.layer extends c.sprite
  init: ->
    @width ?= @image.width
    @height ?= @image.height
    @x ?= 0
    @y ?= 0
    @opacity ?= 255
    @angle ?= 0
    @xOffset = @yOffset = 0
    if @scaleFactor then @scale @scaleFactor
    @repeatX ?= false
    @repeatY ?= false
    @scrollY ?= false
    @scrollX ?= true
    @speed ?= 0
  draw: (x=0, y=0)->
    rect = @parent.rect()
    r = math.round
    unless x > 0 or y > 0
      if @scrollX then @x = math.round(rect.x*@speed)
      if @scrollY then @y = math.round(rect.y*@speed)
    c = @parent.context
    c.save()
    c.rotate(@angle*Math.PI/180)
    c.globalAlpha = @opacity
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

class c.tween
  init: -> 
    @tweening = false
    @tweens = []
    @updates[95] = ->
      for tween in @tweens
        if tween.tl() > 0 then tween.run() else util.remove @tweens,tween
  tween: (props, time) ->
    @tweens.push new Tween(@,props,time)
    return @

class Tween
  constructor: (@target,@result,time) ->
    @iter = {}
    @t = time*60
    for prop, val of @result
      unless isNaN(val) or isNaN(@target[prop])
        @iter[prop] = (val-@target[prop])/@t
      else
        log 2, "Cannot tween #{prop} as only numerics can be tweened"
        return
  run: ->
    for prop, val of @iter
      if prop is "x" then @target.move(val,0)
      else if prop is "y" then @target.move(0,val)
      @target[prop] += val
  tl: ->
    @t--
