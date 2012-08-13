# Linked tile map class. provides tile maps where each tile is linked to 
# surrounding tiles by its n,e,s,w properties (north, east, south west)
# Tiles are objects with properties x,y,n,e,s,w and content, and are stored
# in a 2d array at tilemap.tiles
class TileMap
  # TileMap constructor
  # @param {Object} options
  # @option {Int} x x coordinate of tilemap, defaults to 0
  # @option {Int} y y coordinate of tilemap, defaults to 0
  # @option {Array} res size of tiles, in the form [x,y], defaults to [32,32]
  # @option {Array} size size of tilemap in tiles, in the form [x,y], defaults to [100,100]
  # @option {Object} parent parent of tilemap, all entities in the tilemap share this parent.
  # @option {String} name tilemap name
  constructor: (options={}) ->
    @x = options.x or 0
    @y = options.y or 0
    @res = options.res or [32,32]
    @size = options.size or [100,100]
    @parent = options.parent
    if options.name then @name = options.name
    @width = @size[0]*@res[0]
    @height = @size[1]*@res[1]
    @tiles = ({parent: @} for x in [0...@size[1]] for y in [0...@size[0]])
    dirs = {s: [0,1], e: [1,0], n: [0,-1], w: [-1,0]}
    for y in [0...@size[1]]
      for x in [0...@size[0]]
        @tiles[x][y].x = x
        @tiles[x][y].y = y
        @tiles[x][y].content = []
        for d,calc of dirs
          @tiles[x][y][d] = if @tiles[x+calc[0]]? and @tiles[x+calc[0]][y+calc[1]]? then @tiles[x+calc[0]][y+calc[1]] else null
  # Add an entity or array of entities to the tilemap
  # Entity parents are automatically updated.
  # The entity gets a tile property that holds its current location,
  # and the x and y coordinates of an entity being added to a tilemap are taken
  # to be a position on the tilemap.
  # @param {Entity/Array} obj entity/ies to add
  place: (obj) ->
    if obj.forEach
      obj.forEach (item) => @place item
    else
      @parent.e.push(obj)
      #obj.import("tile")
      obj.tile = @tiles[obj.x][obj.y]
      obj.parent = @parent
      @tiles[obj.x][obj.y].content.unshift(obj)
      obj.x = obj.x*@res[0]+@x
      obj.y = obj.y*@res[1]+@y

  # Look up the contents of a tile at a given coordinate
  # @param {Int} x 
  # @param {Int} y
  # @return {Array} an array of the tiles contents
  lookup: (x,y) ->
    return @tiles[x][y].content

  # Clear the tilemap, 
  # removing all entities
  clear: ->
    for col in @tiles
      for tile in col
        tile.content = []
  # Returns all tile contents that are inside rectangle rect
  # @param {Object} rect a rectangle with x,y,width, and height properties
  atRect: (rect) ->
    tiles = []
    round = Rogue.math.round
    x1 = round(rect.x/@res[0])
    y1 = round(rect.y/@res[1])
    x2 = round((rect.x+rect.width)/@res[0])
    y2 = round((rect.y+rect.height)/@res[1])
    (if @tiles[x]?[y]? then tiles.push(@tiles[x][y].content)) for x in [x1..x2] for y in [y1..y2]
    return tiles

  # Returns a object suitable for use as a bounding box 
  # with the whole tilemap, for collisions
  rect: -> @

