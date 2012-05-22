Rogue = @Rogue or require('rogue')

# A better tilemap, extending jaws

class TileMap
	constructor: (options) ->
		@res = options.res || [32,32]
		@size = options.size || [100,100]
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
			return obj
		obj.tile = @tiles[obj.x][obj.y]
		@tiles[obj.x][obj.y].push(obj)
	lookup: (x,y) ->
		return @tiles[x][y].content
	clear: ->
		for col in @tiles
			for tile in col
				tile.content = []



Rogue.TileMap = TileMap