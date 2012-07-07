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
		for dir in e.hitmap
			for p in dir
				if @hitTest [e.x+p[0],e.y+p[1]],r
					return true
		return false

	createHitmap: (img,res=[2,2]) ->
		ctx = img.getContext('2d')
		data = ctx.getImageData(0,0,img.width,img.height)
		pix = data.data
		y = 0
		points = []
		hitmap = [[],[],[],[]]
		while y <= img.height
			x = 0
			offset = img.width*y
			while x <= img.width
				index = (offset+x)*4
				if pix[index+3] isnt 0
					points.push([x,y])
				x+=res[0]
			y+=res[1]
		for point in points
			if point[0] >= math.round(img.width/2) then hitmap[1].push(point) else hitmap[3].push(point)
			if point[1] >= math.round(img.height/2) then hitmap[2].push(point) else hitmap[0].push(point)
		return hitmap
	type: {}

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
		if obj.type is @type and collision
			for dir in obj.hitmap
				for opoint in dir
					for dir2 in @hitmap
						for point in dir2
							if opoint[0]+obj.x is point[0]+@x and opoint[1]+obj.y is point[1]+@y then return true	
			return false
		else if obj.type is "AABB" then return collision.AABBhitmap obj.rect(),@


