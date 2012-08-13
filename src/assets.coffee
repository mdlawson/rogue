# Asset manager. Helps download and organize all your asset files.
# Is initially created with a manifest that must describe all your game assets.
# Example:
# ```coffee
# assets = new Rogue.AssetManager({
#   baseUrl: ""
#   packs:
#     core: [
#       {name:"bg1",src:"img/b1.png"}
#       {name:"bg2",src:"img/b2.png"}
#       {name:"red",src:"img/1.png"}
#       {name:"blue",src:"img/2.png"}
#       {name:"jump",src:"sound/jump.ogg",alt:"sound/jump.mp3"}
#     ]
#   preload: false
# })
# # "img/b1.png" is now available as a canvas as assets.core.bg1
# # "sound/jump.ogg"/"sound/jump.mp3" is now available as an Audio() element as assets.core.jump
# # By having sounds as both ogg and mp3 we can cover all browsers.  
# ```
class AssetManager
  # AssetManager constructor
  # @param {Object} manifest a manifest declares "packs" of assets. See above example
  # @option {String} baseUrl this will be added to all source urls
  # @option {Object} packs 
  # @option {Bool} preload note: If preload is set to true, and your assets load really fast, callbacks may not fire.
  constructor: (manifest) ->
    @callbacks = {load:{},complete:{},error:{}}
    @base = manifest.baseUrl or ""
    @packs = {}
    @total = @complete = 0
    for name,contents of manifest.packs
      @packs[name] = contents
      @total += contents.length
    manifest.preload and @downloadAll()
  # Download a pack manually from the manifest. If it has already been downloaded, it will not be downloaded again
  # @param {String} pack name of pack to download
  download: (pack) ->
    that = @
    contents = @packs[pack]
    unless contents?
      log 2, "Pack #{pack} does not exist"
      return false
    unless contents.loaded is contents.length
      contents.loaded = 0
      for asset in contents
        ext = asset.src.split(".").pop()
        asset.src = @base+asset.src
        asset.pack = pack
        for key,value of filetypes
          if ext in value
            asset.type = key
        unless asset.type?
          log 2,"Unknown asset type for extension: #{ext}"
          return false
        switch asset.type
          when "image"
            data = new Image()
            data.a = asset
            data.onload = ->
              canvas = util.imgToCanvas @
              a = util.mixin canvas,@a
              that.loaded a
            data.onerror = -> callback.call(that,@a,false)
            data.src = asset.src
          when "sound"
            asset.alt = @base+asset.alt
            data = new Audio()
            data.preload = "none"
            asset = util.mixin data,asset
            unless data.canPlayType codecs[ext] then asset.src = asset.alt
            asset.onerror = -> callback.call(that,asset,false)
            asset.addEventListener 'canplaythrough', -> that.loaded @
            asset.load()

  loaded: (asset) ->
    pack = @packs[asset.pack]
    @[asset.pack] ?= {}
    @[asset.pack][asset.name] = asset
    callback.call(@,asset,true)
  
  # Download all packs
  # It's probably preferable to set up callbacks and then downloadAll() rather than `preload: true` and hope for the best
  # unless your assets are really small. Callbacks can be set up so that the game can start running as soon as a minimum of assets
  # has been downloaded.
  downloadAll: (eee) ->
    @download key for key,val of @packs
  
  # Set up callbacks. You can have callbacks on the events "load","complete" and "error" for each of your packs,
  # or set pack to "all" to run for all packs. Yes that does mean you can't have callbacks on a pack named all. That's a silly name for a pack anyway
  # callbacks on the "load" event get passed the current percentage
  # @param {String} e an event to call on. Must be one of "load","complete" or "error"
  # @param {String} pack the name of the pack you want the event to apply to
  # @param {Function} fn the callback function
  on: (e,pack,fn) ->
    if e in ["load","complete","error"]
      if pack is "all"
        @["on"+e] ?= []
        @["on"+e].push fn
      else 
        @callbacks[e][pack] ?= []
        @callbacks[e][pack].push fn

  callback = (asset,status) ->
    pack = @packs[asset.pack]
    percent = math.round ++pack.loaded/pack.length*100
    apercent = math.round ++@complete/@total*100
    funcs = []
    afuncs = []
    if status then s = "load" else "error"
    funcs = funcs.concat @callbacks[s][asset.pack]
    afuncs = afuncs.concat @["on"+s]
    if percent is 100 then funcs = funcs.concat @callbacks.complete[asset.pack]
    if apercent is 100 then afuncs = afuncs.concat @oncomplete
    func asset,percent for func in funcs when func
    func asset,apercent for func in afuncs when func
    

  filetypes =
      image: ["png","gif","jpg","jpeg","tiff"]
      sound: ["mp3","ogg"]
  codecs =
    'mp3':'audio/mpeg'
    'ogg':'audio/ogg'

# SpriteSheet class. The spritesheet class takes an image and a resolution, and chops it down into chunks of that resolution,
# making an array-like object. 
# @param {Object} options
# @option {Canvas/Image} image image to slice
# @option {Array} res resolution of resultant images, in the form [x,y]
class SpriteSheet
  constructor: (@options) ->
    @img = @options.image
    @res = @options.res or [32,32]
    @length = 0
    for x in [0...@img.width] by @res[0]
      for y in [0...@img.height] by @res[1]
        c = util.canvas()
        cx = c.getContext "2d"
        c.width = @res[0]
        c.height = @res[1]
        cx.drawImage(@img,x,y,c.width,c.height,0,0,c.width,c.height)
        this[@length] = c
        @length++
  # Slices a portion of this spritesheet
  # @param {Int} start position to start slice at
  # @param {Int} end position to end slice at
  # @return {Array} an array of images in the range
  slice: (start, end) ->
    return Array::slice.call(this, start, end);

# Animation class. from a given spritesheet, produces an animation instance with a `next()` function that should
# be ran every tick to advance the animation state. 
class Animation
  # Animation constructor
  # @param {Object} options
  # @option {Object/Array} spritesheet an array or array-like object that contains animation frames
  # @option {Int} speed the number of ticks between each frame of the animation. defaults to 6, or 10fps
  # @option {Int} start the frame of the animation to start on. defaults to 0
  # @option {Bool} loop should the animation loop?
  # @option {Bool} bounce should the animation reverse instead of loop?
  # @option {Function} onFinish callback on animation end
  constructor: (@options) ->
    @sprites = @options.spritesheet
    @speed = @options.speed or 6
    @i = @options.start or 0
    @t = 0
    @loop = @options.loop or true
    @bounce = @options.bounce or false
    @finished = false
    @onFinish = @options.onFinish
    @dir = 1

    @frame = @sprites[@i]
  # Advanced the animation to the next state. Returns the next animation frame, 
  # which isn't necessarily different from the last, depending on speed.
  # @return {Canvas} An image-like canvas of the next frame 
  next: ->
    if @t is @speed and not @finished
      @frame = @sprites[@i+=@dir]
      @t = 0
    if @i is @sprites.length-1 
      if not @loop
        @finished = true
        if @onFinish then @onFinish()
      else
        if @bounce
          @dir = -1
        else
          @i = 0
    if @i is 0 and @dir is -1 then @dir = 1
    @t++
    return @frame



