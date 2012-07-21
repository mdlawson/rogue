Rogue.ready ->

	app = {}

	app.game = new Rogue.Game
		fps: true
	app.input = new Rogue.KeyboardManager(app.game.canvas)
	app.mouse = new Rogue.Mouse(app.game)
	app.state =
		setup: ->
			assets = app.assets.core
			console.log "setup run"

			app.viewport = new Rogue.ViewPort
				parent: app.game
				viewWidth: 1000
				viewHeight: 400

			app.bg1 = new Rogue.Entity
				image: assets.bg1
				speed: 0.5
				repeatX: true
				require: ["layer"]
			app.bg2 = new Rogue.Entity
				image: assets.bg2
				speed: 0.9
				repeatX: true
				require: ["layer","collide","hitmap"]


			app.player = new Rogue.Entity
				parent: app.game
				image: assets.blue
				require: ["move","collide","AABB","gravity","tween"]
				onHit: (col) -> if col.dir is "bottom" then @canJump = true 
			#app.player2 = new Rogue.Entity
			#	parent: app.game
			#	image: app.assets.get 'img/2.png'
			#	require: ["move","collide"]
			#	x: 64
			#	y: 64

			app.tiles = new Rogue.TileMap
				y: 300
				size: [30,1]

			app.viewport.add [app.bg2, app.bg1, app.player, app.tiles]
			app.viewport.updates[98] = ->
				@follow app.player
				@forceInside app.player, false

			app.blocks = []
			app.blocks.push(new Rogue.Entity({image: assets.red, x: x, y: 0, require: ["sprite","collide","AABB"]})) for x in [0...app.tiles.size[0]]
			
			app.tiles.place app.blocks

		update: ->
			if app.input.pressed("right")
				app.player.move(2,0)
			if app.input.pressed("left")
				app.player.move(-2,0)
			if app.input.pressed("up")
				#if app.player.canJump
				app.assets.core.jump.play()
				app.player.canJump = false
				app.player.dy = 17
			if app.input.pressed("down")
				app.player.move(0,2)

			#app.player.image = app.animation.next()
			app.viewport.update()
		draw: ->
			app.game.clear()
			app.viewport.draw()

	app.assets = new Rogue.AssetManager
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
	app.assets.on "load","core", (asset,percent) -> console.log "Assets loading: #{percent}"
	app.assets.on "complete","core", -> console.log "Assets loaded"; app.game.start app.state
	app.assets.download("core")

#	app.assets = new Rogue.AssetManager()
#	app.assets.add ['img/1.png','img/2.png','img/b1.png','img/b2.png', 'sound/jump.ogg', 'sound/jump.mp3']
#	app.assets.loadAll
#		onFinish: -> 
#			console.log "Assets Loaded"
#			app.game.start app.state
#
#		onLoad: (percent) -> console.log "Assets loading: #{percent}"

	window.app = app
