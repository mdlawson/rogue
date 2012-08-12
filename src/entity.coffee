# The main entity class. All entities are based on this.
# Components can be added to the entity with `entity.components.add`
# or though the property `require` on initialization.
# Example:
# ```
# myEntity = new Entity({require:"move"})
# myEntity.add("sprite") # sprite was already imported by move, it is not added a second time
# myEntity.add(["collide","physics"]) # adding arrays is also supported
# ```
# New components can be made available to entities by attaching them to `Rogue.components.[name]`
# Entities have an event emitter on `ev`
class Entity
  # Entity constructor
  # @param {Object} options the attributes the new entity should have
  # @option {Array/String} require components that should be imported on creation
  # @option {Object} parent the parent of this entity, is set automatically when added to a ViewPort
  constructor: (options) ->
    @updates=[]    
    util.mixin @, options
    #if @require then @components.add(@require)
    
    @ev         = new Eventer @
    @components = new Importer Rogue.components,@
    if @require then @components.add @require

    delete @require

    if @parent then @parent.e.push @

  # The update function of the component, should be run each tick. This is done automatically by the viewport
  update: (dt) ->
    func.call(@,dt) for func in @updates when func?

# Importer class. This is not exposed publicly, but is the basis of the component system and the physics behavior system.
# The importer allows a class to maintain a list of extensions, in Entities these are called Components, but physics behaviors follow the same system.
# The extensions must be objects produced by running a function with "new".
# Any properties/methods of the created object will be mixed in to the target object, apart from the "special" properties `onadd`, `onremove` and `run`.
# 
# `onadd` is an optional function that is called when the extension is added to a target. 
# Likewise `onremove` is called when the extension is removed. This can be used to "clean up" additional properties created with `onadd`.
# `run` is called on tick if the extension is added to the physics engine. More is explained about this in the physics section.
# When an extension is removed from an object, all mixed in properties/methods are removed automatically, unless they have been modified.
# If a property is likely to have been changed but is safe to remove, it should be removed in the onremove function. 
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

# an Entity factory class. This can be used to hold a group of pre-built entities to reduce
# the time spend building fast spawning entities dynamically, eg. bullets.
# If you set the "parent" property on entities created in a factory, then they will be automatically added/removed from the parent
# using its (the parents) `add()` and `remove()` functions. This makes sense if the parent is a ViewPort
class Factory
  # Factory Constructor
  # @param {Object} options the options for this factory
  # @option {Entity} entity (optional) the entity to manufacture
  # @option {Object} options the options to use when creating the entity
  # @option {Int} initial the initial number of entities to build
  constructor: (options) ->
    @hanger = []
    @entity = options.entity or Rogue.Entity
    @opts = options.options or {}
    @initial = options.initial
    for i in [0...@initial]
      @hanger.push @build()

  # Take a single entity from the factory, create a new one only if none are available. The new entity has a `return()` function
  # that should be called when it is no longer needed. Entities produced by a factory cannot be guaranteed to be "clean" so it is best
  # to manually reinitialize important variables. The original options will be re-mixed in.
  # @return {Entity} a new entity
  deploy: ->
    if @hanger.length > 0
      e = @hanger.pop()
    else 
      e = @build()
    if e.parent then e.parent.add e
    e

  build: ->
    ent = new @entity @opts
    ent.factory = @
    ent.return = ->
      if @parent then @parent.remove @
      @factory.hanger.push @
      util.mixin @, @factory.opts
    ent


c = {}

# Sprite component. Entities with this component require an image property. 
# Sprites have x and y coordinates, which default to 0. They also support angle and opacity properties
# If a entity is initialized with a scaleFactor property, then it will be scaled on creation.
class c.sprite
  onadd: ->
    unless @image then log 2, "Sprite entities require an image"
    @x ?= 0
    @y ?= 0
    @angle ?= 0
    @opacity ?= 255
    if @scaleFactor? then @scale @scaleFactor, @pixel else @_recalculateImage()
  # Draw the entity. This function should be ran at the end of each tick
  # If the entity is a child of a viewport, then this will be called automatically.
  draw: ->
    c = @parent.context
    r = math.round
    c.save()
    c.translate(r(@x-@xOffset), r(@y-@yOffset))
    c.rotate(@angle*Math.PI/180)
    c.globalAlpha = @opacity
    c.drawImage(@image, 0, 0, @width, @height)
    c.restore()
  # Scale the entity by a scale factor. Optionally use "pixel perfect" nearest neighbor scaling
  # @param {Int} scaleFactor the factor to scale the dimensions by
  # @param {Bool} pixel use nearest neighbor scaling
  scale: (@scaleFactor, @pixel) ->
    @y-=@height*@scaleFactor[1]/2
    @image = gfx.scale @image,@scaleFactor,@pixel
    @_recalculateImage()

  # Used to calculate a AABB around the entity.
  # @return {Rect} A rect has x,y,width and height properties
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

# Move component. Adds the sprite component on add, as only drawable things can move
# Provided methods for moving. 
class c.move
  onadd: ->
    @components.add "sprite"

  # Adds x,y to the current position
  # @param {Int} x 
  # @param {Int} y 
  move: (x,y) ->
    @x += x
    @y += y

  # Sets the current position to x,y
  # @param {Int} x 
  # @param {Int} y 
  moveTo: (@x,@y) ->

# Tile component. Overrides move() and moveTo() to versions 
# friendly for entities part of a TileMap
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

# Collision component. Adds this entity to the collidables of the parent, so other entities will
# account for it in there collision detection.
# Provides methods for finding collisions with this entity, and "hit" events will be emitted on contact with other collidables
# Overrides the entities move function with one that will only move as far as it can without colliding.
# In addition to having this component, collidable entities need to have a component that provides a `collide(ent)` function
# that will test for collisions with the entity ent.
# AABB and hitmap components are built in. 
class c.collide
  onadd: ->
    unless @components["layer"]? then @components.add "sprite"
    @solid = if @components["physics"]? then false else true

  # finds all entities that are colliding with us.
  # @return {Array} an array of collisions. Collisions are in the form {e1,e2,dir,pv} where dir is the rough direction of collision and pv is the penetration vector.
  findCollisions: ->
    solid = @parent.find ["collide"],@
    @colliding = []
    for obj in solid
      col = @collide obj
      if col
        @ev.emit "hit",col
        obj.ev.emit "hit",col
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

# Layer components. "Converts" an entity into a parallax layer. 
# Extends sprite, so support all the same options plus:
# @param {} properties
# @option {Int} speed the move speed of this layer
# @option {Bool} repeatX should this layer tile on the x-axis?
# @option {Bool} repeatY should this layer tile on the y-axis?
# @option {Bool} scrollX should this layer scroll on the x-axis?
# @option {Bool} scrollY should this layer scroll on the y-axis?
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

# Adds tween support to an entity. All tweens are applied on update, 
# and are automatically removed when done.
class c.tween
  onadd: -> 
    @tweening = false
    @tweens = []
    @updates.push applytweens
  onremove: ->
    util.remove @updates,applytweens   

  # Tween properties to certain values. Smoothly animate the properties to `props` over time `time`
  # Only supports numeric values. 
  # Optionally takes a callback to execute when done. 
  # @param {Object} props final values of properties to adjust
  # @param {Int} time in seconds to animate over. 
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