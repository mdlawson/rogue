physics = {}
b = {}
physics.behavior = b

# The physics integration function. It is given and entity, e, and a change in time, dt,
# and should modify the entities position and velocity based on its acceleration in that time period.
# uses by default a Euler variation, and the default physics component runs it 8 times a tick, which gives reasonable 
# accuracy/performance 
# @param {Entity} e Entity to integrate upon
# @param {Float} dt change in time since last integration.
physics.intergrate = intergrate = (e,dt) ->
  if e.still() then return
  d = []
  v.scale e.acc, 10000/e.mass, e.acc
  v.add (v.scale e.vel, dt, []),(v.scale e.acc, 0.5*dt*dt, []), d
  v.add e.vel, (v.scale e.acc, dt, []), e.vel
  e.move(d[0],d[1])
  #e.x += d[0]; e.y += d[1]
  v.scale e.vel, 1-(e.friction/5), e.vel
  e.acc = [0,0]

sqrt = Math.sqrt

# 2D Vector maths functions, where a and b are 2 input vectors as arrays, 
# and c is the destination vector of the operation where applicable.  
# I am aware they are utterly unreadable. 
# They are accessible from Rogue.math.vector, though it recommended to bind them to a global if you are using them.
v =
  add:    (a,b,c) -> c[0]=a[0]+b[0]; c[1]=a[1]+b[1]; c
  sub:    (a,b,c) -> c[0]=a[0]-b[0]; c[1]=a[1]-b[1]; c
  dir:    (a,b,c) -> dx=b[0]-a[0]; dy=b[1]-a[1]; l = 1/(sqrt dx*dx+dy*dy); c[0] = dx*l; c[1] = dy*l; c
  scale:  (a,b,c) -> c[0]=a[0]*b; c[1]= a[1]*b; c
  proj:   (a,b,c) -> dpb=(a[0]*b[0]+a[1]*b[1])/(b[0]*b[0]+b[1]*b[1]); c[0]=dpb*b[0]; c[1]=dpb*b[1]; c
  dot:    (a,b)   -> a[0]*b[0]+a[1]*b[1]
  cross:  (a,b)   -> (a[0]*b[0])-(a[1]*b[1])
  dist:   (a,b)   -> dx=b[0]-a[0];dy=b[1]-a[1]; sqrt dx*dx+dy*dy
  distSq: (a,b)   -> dx=b[0]-a[0];dy=b[1]-a[1]; dx*dx+dy*dy
  norm:   (a,c)   -> m = sqrt a[0]*a[0]+a[1]*a[1]; c[0]=a[0]/m; c[1]=a[1]/m; c
  clone:  (a,c)   -> c = a[..]
  neg:    (a,c)   -> c[0]=-a[0]; c[1]=-a[1] c
  mag:    (a)     -> sqrt a[0]*a[0]+a[1]*a[1]
  magSq:  (a)     -> a[0]*a[0]+a[1]*a[1]

# Physics component. Adds physics integration to an entities updates. Adds support for "behaviors", which are like components added to entity.behavior, and their
# properties aren't mixed in. The main purpose of a behavior is to modify entity acceleration or velocity each tick. this can be done though a behaviors "run" function which is called
# each tick with the entity as the context. Additional behaviors can be made available to entities by attaching them to Rogue.physics.behavior
#
# Entities with the physics component have velocity, `vel`, acceleration, `acc`, friction, and mass.
# They also have an integration function that runs each tick.
class c.physics
  onadd: ->
    @components.add ["move","collide"]
    @behavior = new Importer Rogue.physics.behavior,@,false
    @behavior.add "collide"
    @updates.push (dt) ->
      behave.run.call(@,dt) for name,behave of @behavior when behave.run?
      @intergrate dt
    @vel ?= [0,0]
    @acc ?= [0,0]
    @old = {}
    @friction ?= 0
    @mass ?= 1
    @solid = false
  intergrate: (dt) ->
    i = 0
    while i++ < 8 then intergrate(@,dt/8)
  # Useful for checking if an entity is still.
  # @return {Bool} returns true if entity has no velocity and acceleration.
  still: -> @vel[0] is 0 and @vel[1] is 0 and @acc[0] is 0 and @acc[1] is 0

# Gravity behavior
# Applies a downward force of 9.8 each tick
class b.gravity
  run: ->
    if @acc[1] < 9.8 
      @acc[1]++
      @acc[1] = 9.8 if @acc[1] > 9.8

# Collision behavior. 
# sets velocity in the collision direction to 0 on collision
class b.collide
  responce = (col) ->
    if col.e2.solid
      if col.dir is "left" or col.dir is "right" then @vel[0] = 0 else @vel[1] = 0
  onadd: ->
    @ev.on "hit", responce
  onremove: ->
    @ev.off "hit", responce