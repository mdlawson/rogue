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
		iters = [[y,x,res[1],res[0]],[x,y,res[0],res[1]],[y,x,-res[1],-res[0]],[x,y,-res[0],-res[1]]]
		hitmap = [[],[],[],[]]
		while y <= img.height
			x = 0
			offset = img.width*y
			while x <= img.width
				index = (offset+x)*4
				if pix[index+3] isnt 0
					hitmap[0].push([x,y])
					break
				x+=res[0]
			y+=res[1]
		x = 0
		while x <= img.width
			y = 0
			offset = img.width*x
			while y <= img.height
				index = (offset+y)*4
				if pix[index+3] isnt 0
					hitmap[1].push([x,y])
					break
				y+=res[1]
			x+=res[0]
		y = img.height
		while y >= 0
			x = img.width
			offset = img.width*y
			while x >= 0
				index = (offset+x)*4
				if pix[index+3] isnt 0
					hitmap[2].push([x,y])
					break
				x-=res[0]
			y-=res[1]
		x = img.width
		while x >= 0
			y = img.height
			offset = img.width*x
			while y >= 0
				index = (offset+y)*4
				if pix[index+3] isnt 0
					hitmap[3].push([x,y])
					break
				y-=res[1]
			x-=res[0]
		return hitmap

