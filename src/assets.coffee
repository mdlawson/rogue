class AssetManager
  constructor: (manifest) ->
    @callbacks = {load:{},complete:{},error:{}}
    @base = manifest.baseUrl or ""
    @packs = {}
    @total = @complete = 0
    for name,contents of manifest.packs
      @packs[name] = contents
      @total += contents.length
    manifest.preload and @downloadAll()
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
  
  downloadAll: ->
    @download key for key,val of @packs
      
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
  slice: (start, end) ->
    return Array::slice.call(this, start, end);

class Animation
  constructor: (@options) ->
    @sprites = @options.spritesheet
    @speed = @options.speed or 6
    @i = @options.start or 0
    @t = 0
    @loop = @options.loop or true
    @bounce = @options.bounce or false
    @onFinish = @options.onFinish
    @dir = 1

    @frame = @sprites[@i]

  next: ->
    if @t is @speed
      @frame = @sprites[@i+=@dir]
      @t = 0
    if @i is @sprites.length-1 
      if not @loop
        if @onFinish then @onFinish()
      else
        if @bounce
          @dir = -1
        else
          @i = 0
    if @i is 0 and @dir is -1 then @dir = 1
    @t++
    return @frame



