gfx = {}

gfx.scale = (img,s) ->
	ctx = img.getContext('2d')
	if ctx.mozImageSmoothingEnabled
		ctx.mozImageSmoothingEnabled = false # hack for ff
	else # hack for chrome
		ctx.scale(s,s)
		ctx.fillStyle = ctx.createPattern(img, 'repeat')
		ctx.fillRect(0,0,img.width,img.height)
	img.width*=s
	img.height*=s
	return img

	#data = img.getContext('2d').getImageData(0,0,img.width,img.height).data
	#for x in [0...img.width]
	#	for y in [0...img.height]
	#		i = (y*img.width+x)*4
	#		context.fillStyle = "rgba(#{data[i]},#{data[i++]},#{data[i++]},#{(data[i++]/255)})"
	#		context.fillRect(x*s,y*s,s,s)
	#return canvas
