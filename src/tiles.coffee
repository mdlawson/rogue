class TileMap
	constructor: (options={}) ->
		@x = options.x or 0
		@y = options.y or 0
		@res = options.res or [32,32]
		@size = options.size or [100,100]
		@width = @size[0]*@res[0]
		@height = @size[1]*@res[1]
		@parent = options.parent
		@tiles = ({} for x in [0...@size[0]] for y in [0...@size[1]])
		dirs = {s: [0,1], e: [1,0], n: [0,-1], w: [-1,0]}
		for x in [0...@size[0]]
			for y in [0...@size[1]]
				@tiles[x][y].x = x
				@tiles[x][y].y = y
				@tiles[x][y].content = []
				for d,calc of dirs
					@tiles[x][y][d] = if @tiles[x+calc[0]]? and @tiles[x+calc[0]][y+calc[1]]? then @tiles[x+calc[0]][y+calc[1]] else null
	place: (obj) ->
		if obj.forEach
			obj.forEach (item) => @place item
		else
			obj.tile = @tiles[obj.x][obj.y]
			obj.res = @res
			obj.parent = @parent
			@tiles[obj.x][obj.y].content.unshift(obj)
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

	draw: ->
		tiles = @atRect
							x: if @parent.x then @parent.x - @x else 0
							y: if @parent.y then @parent.y - @y else 0
							width: @parent.width
							height: @parent.height
		for tile in tiles
			for obj in tile
				obj.draw()
	rect: -> @

