gfx = {}

gfx.scale = (img,s) ->
	data = img.getContext('2d').getImageData(0,0,img.width,img.height).data
	canvas = util.canvas()
	canvas.width = img.width*s
	canvas.height = img.height*s
	context = canvas.getContext('2d')
	for x in [0...img.width]
		for y in [0...img.height]
			i = (y*img.width+x)*4
			context.fillStyle = "rgba(#{data[i]},#{data[i++]},#{data[i++]},#{(data[i++]/255)})"
			context.fillRect(x*s,y*s,s,s)
	return canvas
