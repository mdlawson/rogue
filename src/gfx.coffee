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

gfx.edit = (data,x,y,r,g,b,a) ->
  darray = data.data
  index = (y*data.width+x)*4
  if r or g or b or a 
    darray[index] = r or 0
    darray[index++] = g or 0
    darray[index++] = b or 0
    darray[index++] = a or 0
    return data.data = darray
  else
    return [darray[index],darray[index++],darray[index++],darray[index++]]

gfx.edgeDetect = (img) ->
  ctx = img.getContext("2d")
  data = ctx.getImageData(0,0,img.width,img.height)
  lookup = (x,y) -> gfx.edit(data,x,y)[3]
  points = []
  for x in [0..img.width] 
    for y in [0..img.height]
      if lookup(x,y) > 0
        if lookup(x+1,y) is 0 then points.push [x,y,"right"]
        else if lookup(x-1,y) is 0 then points.push [x,y,"left"]
        else if lookup(x,y+1) is 0 then points.push [x,y,"down"]
        else if lookup(x,y-1) is 0 then points.push [x,y,"up"]
  return points
