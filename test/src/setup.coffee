Rogue.ready ->

	app = {}

	app.game = new Rogue.Game()
	app.input = new Rogue.KeyboardManager(app.game.canvas)
	app.state =
		setup: ->
			console.log "setup run"
			app.viewport = new Rogue.ViewPort
				canvas: app.game.canvas
				viewWidth: 1000
				viewHeight: 1000
			app.player = new Rogue.Entity
				parent: app.game
				image: app.assets.get 'img/2.png'
				import: ["movable"]
			app.tiles = new Rogue.TileMap
				size: [20,20]
			app.viewport.add app.tiles
			app.viewport.add app.player
			app.blocks = []
			app.blocks.push(new Rogue.Entity({image: app.assets.get('img/1.png'), x: x, y: y, import: ["drawable"]})) for x in [0...app.tiles.size[0]] for y in [0...app.tiles.size[1]]
			app.tiles.place app.blocks
		update: ->
			if app.input.pressed("right")
				app.player.x += 2
			if app.input.pressed("left")
				app.player.x -= 2
			if app.input.pressed("up")
				app.player.y -= 2
			if app.input.pressed("down")
				app.player.y += 2
			app.viewport.follow app.player
			app.viewport.forceInside app.player, false
		draw: ->
			app.game.clear()
			#app.player.draw()
			app.viewport.draw()
	app.assets = new Rogue.AssetManager()
	app.assets.add ['img/1.png','img/2.png']
	app.assets.loadAll
		onFinish: -> 
			console.log "Assets Loaded"
			app.game.start app.state
		onLoad: (percent) -> console.log "Assets loading: #{percent}"

	window.app = app
