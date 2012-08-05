class TileMap
  constructor: (options={}) ->
    @x = options.x or 0
    @y = options.y or 0
    @res = options.res or [32,32]
    @size = options.size or [100,100]
    @parent = options.parent
    if options.name then @name = options.name
    @width = @size[0]*@res[0]
    @height = @size[1]*@res[1]
    @components = []
    @tiles = ({parent: @} for x in [0...@size[1]] for y in [0...@size[0]])
    dirs = {s: [0,1], e: [1,0], n: [0,-1], w: [-1,0]}
    for y in [0...@size[1]]
      for x in [0...@size[0]]
        @tiles[x][y].x = x
        @tiles[x][y].y = y
        @tiles[x][y].content = []
        for d,calc of dirs
          @tiles[x][y][d] = if @tiles[x+calc[0]]? and @tiles[x+calc[0]][y+calc[1]]? then @tiles[x+calc[0]][y+calc[1]] else null

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

  lookup: (x,y) ->
    return @tiles[x][y].content

  clear: ->
    for col in @tiles
      for tile in col
        tile.content = []

  atRect: (rect) ->
    tiles = []
    round = Rogue.math.round
    x1 = round(rect.x/@res[0])
    y1 = round(rect.y/@res[1])
    x2 = round((rect.x+rect.width)/@res[0])
    y2 = round((rect.y+rect.height)/@res[1])
    (if @tiles[x]?[y]? then tiles.push(@tiles[x][y].content)) for x in [x1..x2] for y in [y1..y2]
    return tiles

  rect: -> @

