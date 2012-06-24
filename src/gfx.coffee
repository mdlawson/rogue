gfx = {}

gfx.scale = (simg,s,pixel) ->
	dimg = util.canvas()
	dimg.width = simg.width*s[0]
	dimg.height = simg.height*s[1]
	ctx = dimg.getContext("2d")
	ctx.scale(s[0],s[1])
	if pixel
		if ctx.mozImageSmoothingEnabled?
			ctx.mozImageSmoothingEnabled = false
			ctx.imageSmoothingEnabled = false 
			ctx.drawImage(simg,0,0,simg.width,simg.height)
		else
			ctx.fillStyle = ctx.createPattern(simg, 'repeat')
			ctx.fillRect(0,0,simg.width,simg.height)
	else
		ctx.drawImage(simg,0,0,simg.width,simg.height)
	return dimg
