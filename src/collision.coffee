collision =
  AABB: (r1,r2) ->
    w = (r1.width+r2.width)/2
    h = (r1.height+r2.height)/2
    dx = (r1.x+r1.width/2)-(r2.x+r2.width/2)
    dy = (r1.y+r1.height/2)-(r2.y+r2.height/2)
    if Math.abs(dx) <= w-1 and Math.abs(dy) <= h-1
      wy = w*dy
      hx = h*dx
      if wy > hx
        if wy > -hx then return "top" else return "left"
      else
        if wy > -hx then return "right" else return "bottom"
    return false
  hitTest: (p,r) ->
    @AABB {x:p[0], y:p[1], width:1, height:1},r

  AABBhitmap: (r,e) ->
    unless collision.AABB r, e.rect() then return false
    for dir,points of e.hitmap
      for p in points
        dir = @hitTest [e.x+p[0],e.y+p[1]],r
        if dir then return dir
    return false

  createHitmap: (img,res=2) ->
    points = gfx.edgeDetect(img,res)
    hitmap = {left:[],right:[],up:[],down:[]}
    for point in points by res
      hitmap[point[2]].push [point[0],point[1]]
    return hitmap

class c.AABB
  type: "AABB"
  collide: (obj) ->
    if obj.forEach
      obj.forEach (o) => @collide o
    if obj.type is @type then return collision.AABB @rect(), obj.rect()
    else if obj.type is "hitmap" then return collision.AABBhitmap @rect(), obj
    return false

class c.hitmap
  type: "hitmap"
  init: ->
    @_recalculateImage()

  _recalculateImage: ->
    @width = @image.width
    @height = @image.height
    @xOffset = math.round(@width/2)
    @yOffset = math.round(@height/2)
    @hitmap = collision.createHitmap @image
  collide: (obj) ->
    if obj.forEach
      obj.forEach (o) => @collide o
    unless collision.AABB @rect(), obj.rect() then return false
    if obj.type is @type
      for dir,points of obj.hitmap
        for opoint in points
          for dir2,points2 in @hitmap
            for point in points2
              if opoint[0]+obj.x is point[0]+@x and opoint[1]+obj.y is point[1]+@y then return true 
      return false
    else if obj.type is "AABB" then return collision.AABBhitmap obj.rect(),@

class c.polygon
  type: "polygon"
  init: ->
    unless @points then log 2,"Polygons must have points!"


