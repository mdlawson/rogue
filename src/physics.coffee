physics = {}
v = {}
b = {}
physics.behavior = b

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
v.add    = (a,b,c) -> c[0]=a[0]+b[0]; c[1]=a[1]+b[1]; c
v.sub    = (a,b,c) -> c[0]=a[0]-b[0]; c[1]=a[1]-b[1]; c
v.dir    = (a,b,c) -> dx=b[0]-a[0]; dy=b[1]-a[1]; l = 1/(sqrt dx*dx+dy*dy); c[0] = dx*l; c[1] = dy*l; c
v.scale  = (a,b,c) -> c[0]=a[0]*b; c[1]= a[1]*b; c
v.proj   = (a,b,c) -> dpb=(a[0]*b[0]+a[1]*b[1])/(b[0]*b[0]+b[1]*b[1]); c[0]=dpb*b[0]; c[1]=dpb*b[1]; c
v.dot    = (a,b)   -> a[0]*b[0]+a[1]*b[1]
v.cross  = (a,b)   -> (a[0]*b[0])-(a[1]*b[1])
v.dist   = (a,b)   -> dx=b[0]-a[0];dy=b[1]-a[1]; sqrt dx*dx+dy*dy
v.distSq = (a,b)   -> dx=b[0]-a[0];dy=b[1]-a[1]; dx*dx+dy*dy
v.norm   = (a,c)   -> m = sqrt a[0]*a[0]+a[1]*a[1]; c[0]=a[0]/m; c[1]=a[1]/m; c
v.clone  = (a,c)   -> c = a[..]
v.neg    = (a,c)   -> c[0]=-a[0]; c[1]=-a[1] c
v.mag    = (a)     -> sqrt a[0]*a[0]+a[1]*a[1]
v.magSq  = (a)     -> a[0]*a[0]+a[1]*a[1]

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
  intergrate: (dt) ->
    i = 0
    while i++ < 8 then intergrate(@,dt/8)
    #console.log @vel
  still: -> @vel[0] is 0 and @vel[1] is 0 and @acc[0] is 0 and @acc[1] is 0

class b.gravity
  run: ->
    if @acc[1] < 9.8 
      @acc[1]++
      @acc[1] = 9.8 if @acc[1] > 9.8

class b.collide
  responce = (col) ->
    if col.e2.solid
      if col.dir is "left" or col.dir is "right" then @vel[0] = 0 else @vel[1] = 0
  onadd: ->
    @ev.on "hit", responce
  onremove: ->
    @ev.off "hit", responce