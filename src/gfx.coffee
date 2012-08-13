gfx = {}

# Scales an image by scale factor s, producing a new canvas with the scaled image.
# Most useful when pixel is set to true, as this allows for scaling using nearest neighbor 
# scaling for pixel art graphics.
# @param {Canvas} simg source image to scale
# @param {Array} s scale factor, [x,y]
# @param {Bool} pixel use nearest neighbor scaling where available (aka not in IE)
# @return {Canvas} scaled image 
gfx.scale = (simg,s,pixel) ->
  if pixel
    dimg = util.canvas()
    dimg.width = simg.width*s[0]
    dimg.height = simg.height*s[1]
    ctx = dimg.getContext("2d")
    ctx.scale(s[0],s[1])
    ctx.imageSmoothingEnabled = ctx.mozImageSmoothingEnabled = ctx.webkitImageSmoothingEnabled = false
    ctx.drawImage(simg,0,0,simg.width,simg.height)
    ctx.fillStyle = ctx.createPattern(simg, 'repeat')
    ctx.fillRect(0,0,simg.width,simg.height)
    return dimg
  else
    simg.width*=s[0]
    simg.height*=s[1]
    ctx = simg.getContext("2d")
    ctx.scale(s[0],s[1])
    return simg
  
# Useful for editing/viewing canvas image data
# If rgba is set, then the data is written to with the new values, and the new data is returned
# otherwise the existing values are returned
# @param {ImageData} data some canvas image data
# @param {Int} x 
# @param {Int} y
# @param {Int} r
# @param {Int} g
# @param {Int} b
# @param {Int} a
# @return {Array/ImageData} either an array of [r,g,b,a] or modified image data 
gfx.edit = (data,x,y,r,g,b,a) ->
  darray = data.data
  index = (y*data.width+x)*4
  if r or g or b or a 
    darray[index] = r or darray[index]
    darray[index++] = g or darray[index]
    darray[index++] = b or darray[index]
    darray[index++] = a or darray[index]
    return data.data = darray
  else
    return [darray[index],darray[index++],darray[index++],darray[index++]]

# Performs primitive edge detection to find the borders where the image becomes transparent.
# each point is in the form [x,y,dir] where dir is the direction that an object colliding at this point
# is coming from. 
# @param {Canvas} img image to process
# @return {Array} array of points marking the edges of the image.
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
