state = require 'state'

game = new Rogue.Game
  fps: true
  width: 800
  height: 600
game.input = new Rogue.Keyboard game.canvas
game.mouse = new Rogue.Mouse game
game.assets = assets = new Rogue.AssetManager
  baseUrl: ""
  packs:
    core: [
      {name:"bg1",src:"img/b1.png"}
      {name:"bg2",src:"img/b2.png"}
      {name:"red",src:"img/1.png"}
      {name:"blue",src:"img/2.png"}
      {name:"jump",src:"sound/jump.ogg",alt:"sound/jump.mp3"}
    ]
  preload: false
assets.on "load","core", (asset,percent) -> console.log "Assets loading: #{percent}"
assets.on "complete","core", -> console.log "Assets loaded"; game.start state
assets.download("core")

module.exports = game
