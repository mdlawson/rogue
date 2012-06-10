Rogue.ready ->

	app = {}

	app.game = new Rogue.Game()
	app.input = new Rogue.KeyboardManager(app.game.canvas)
	app.state =
		setup: ->
			console.log "setup run"

			app.sprites = new Rogue.SpriteSheet
				image: app.assets.get 'img/2.png'
				res: [16,16]

			app.animation = new Rogue.Animation
				spritesheet: app.sprites
				speed: 15

			app.viewport = new Rogue.ViewPort
				parent: app.game
				canvas: app.game.canvas
				viewWidth: 1000
				viewHeight: 1000

			app.player = new Rogue.Entity
				parent: app.game
				image: app.animation.next()
				scaleFactor: 2
				import: ["move","collide"]

			app.player.move = (x,y) ->
				@x += x
				@y += y
				if @colliding().length > 0
					@x -= x
					@y -= y

			app.player2 = new Rogue.Entity
				parent: app.game
				image: app.assets.get 'img/2.png'
				import: ["move","collide"]
				x: 64
				y: 64

			app.tiles = new Rogue.TileMap
				size: [20,20]

			app.viewport.add [app.tiles, app.player, app.player2]
			app.viewport.updates.unshift ->
				app.viewport.follow app.player
				app.viewport.forceInside app.player, false

			app.blocks = []
			app.blocks.push(new Rogue.Entity({image: app.assets.get('img/1.png'), x: x, y: y, import: ["sprite"]})) for x in [0...app.tiles.size[0]] for y in [0...app.tiles.size[1]]
			
			app.tiles.place app.blocks

		update: ->
			if app.input.pressed("right")
				app.player.move(2,0)
			if app.input.pressed("left")
				app.player.move(-2,0)
			if app.input.pressed("up")
				app.player.move(0,-2)
			if app.input.pressed("down")
				app.player.move(0,2)

			app.player.image = app.animation.next()

			app.game.clear()

			app.viewport.update()

	app.assets = new Rogue.AssetManager()
	app.assets.add ['img/1.png','img/2.png']
	app.assets.loadAll
		onFinish: -> 
			console.log "Assets Loaded"
			app.game.start app.state

		onLoad: (percent) -> console.log "Assets loading: #{percent}"

	window.app = app
