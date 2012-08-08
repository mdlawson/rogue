
# The main entity class. All entities are based on this.
#
class Entity

  # @param [Object] options the attributes the new entity should have
  # @option options [Array] require components that should be imported on creation
  # @option options [Object] parent the parent of this entity, is set automatically when added to a ViewPort
  constructor: (options) ->
    @updates=[]    
    util.mixin @, options
    #if @require then @components.add(@require)
    
    @ev         = new Eventer @
    @components = new Importer Rogue.components,@
    @components.add @require

    delete @require

    if @parent then @parent.e.push @
  # imports an array of components or a single component to the entity
  # @param [Array] imports array of components to import, or a string of a single component
  # The update function of the component, should be run each tick. This is done automatically by the viewport
  update: (dt) ->
    func.call(@,dt) for func in @updates when func?

class Importer
  constructor: (@from,@dest,@mixin=true) ->
  add: (imports) ->
    imports = [].concat(imports)
    for imp in imports when not @[imp]?
      if @from[imp]?
        @[imp] = new @from[imp]
        if @mixin
          for key,val of @[imp] when (key isnt "onadd" and key isnt "onremove" and key isnt "run" and val?)
            @dest[key] = val
        if @[imp].onadd then @[imp].onadd.call(@dest)
      else log 2,"mixin #{imp} does not exist!"
  remove: (imports) ->
    imports = [].concat(imports)
    for imp in imports when @[imp]?
      if @mixin
        for key,val of @[imp] when @dest[key]? and @dest[key] is @[imp][key]
          delete @dest[key]
      if @[imp].onremove then @[imp].onremove.call(@dest)
      delete @[imp]

c = {}

class c.sprite
  onadd: ->
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
  onadd: ->
    @components.add "sprite"

  move: (x,y) ->
    @x += x
    @y += y

  moveTo: (@x,@y) ->

class c.tile
  onadd: ->
    @components.add "sprite"

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
  onadd: ->
    unless @components["layer"]? then @components.add "sprite"
    @solid = if @components["physics"]? then false else true

  findCollisions: ->
    solid = @parent.find ["collide"],@
    @colliding = []
    for obj in solid
      col = @collide obj
      if col
        @ev.emit "hit",col
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

#   d = collision.movesearch @,x,y
#   if d then @x+=d[0]; @y+=d[1]
#   return d

class c.layer extends c.sprite
  onadd: ->
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

class c.tween
  onadd: -> 
    @tweening = false
    @tweens = []
    @updates.push applytweens
  onremove: ->
    util.remove @updates,applytweens   
  tween: (props, time, cb) ->
    @tweens.push new Tween(@,props,time,cb)
    return @
  applytweens = -> 
    for tween in @tweens
      unless tween.run() then util.remove @tweens,tween

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