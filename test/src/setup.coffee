Rogue.ready ->

	app = {}

	app.game = new Rogue.Game
		fps: true
	app.input = new Rogue.Keyboard(app.game.canvas)
	app.mouse = new Rogue.Mouse(app.game.canvas)
	app.state =
		setup: ->
			assets = app.assets.core
			console.log "setup run"

			app.viewport = new Rogue.ViewPort
				parent: app.game
				viewWidth: 1000
				viewHeight: 400

			app.center = new Rogue.Entity
				parent: app.game
				image: assets.blue
				require: ["sprite","collide","AABB"]
				x: 150
				y: 150

			positions = [[150,0],[300,150],[150,300],[0,150]]
			accel     = [[0,10],[-10,0],[0,-10],[10,0]]
			for i in [0...4]
				app["b"+i] = new Rogue.Entity
					parent: app.game
					image: assets.red
					require: ["move","collide","AABB","physics"]
					x: positions[i][0]
					y: positions[i][1]
					acc: accel[i]
				app.viewport.add app["b"+i]
			app.viewport.add [app.center]

		update: (game,dt) ->
			app.viewport.update(dt)
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

	window.app = app
