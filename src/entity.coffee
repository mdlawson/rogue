class Entity
  constructor: (@options) ->
    @components=[]
    @updates=[]
    util.mixin @, @options
    util.eventer @
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

  update: (dt) ->
    func.call(@,dt) for func in @updates when func?

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

  findCollisions: ->
    solid = @parent.find ["collide"],@
    @colliding = []
    for obj in solid
      dir = @collide obj
      if dir
        col = 
          dir: dir
          entity: obj
        @emit "hit",col
        @colliding.push col
    return @colliding

  move: (x,y) ->
    @x += x
    @y += y
    if @findCollisions().length > 0
      @x -= x
      @y -= y
      if Math.abs(x) < 1 and Math.abs(y) < 1
        return false
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
    @updates.push ->
      if @dy > @gravity
        @dy -= 1

class c.tween
  init: -> 
    @tweening = false
    @tweens = []
    @updates.push ->
      for tween in @tweens
        unless tween.run() then util.remove @tweens,tween          
  tween: (props, time, cb) ->
    @tweens.push new Tween(@,props,time,cb)
    return @

class Tween
  constructor: (@en,@props,time,func,@cb) ->
    @func = func or (t,b,c,d) -> b+c*(t/d)
    @d = time*60; @t = 0; @b = {}; @c = {}
    for prop, val of @props
      unless isNaN(val) or isNaN(@en[prop])
        @c[prop] = val-@en[prop]
        @b[prop] = @en[prop]
      else
        log 2, "Cannot tween #{prop} as only numerics can be tweened"
  run: ->
    for prop, val of @c
      @en[prop] = @func(@t,@b[prop],@c[prop],@d)
    if @t++ is @d
      if @cb? then @cb()
      false
    else
      true