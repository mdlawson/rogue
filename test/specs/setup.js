(function() {

  Rogue.ready(function() {
    var app;
    app = {};
    app.game = new Rogue.Game();
    app.input = new Rogue.KeyboardManager(app.game.canvas);
    app.state = {
      setup: function() {
        var x, y, _ref, _ref2;
        console.log("setup run");
        app.sprites = new Rogue.SpriteSheet({
          image: app.assets.get('img/2.png'),
          res: [16, 16]
        });
        app.animation = new Rogue.Animation({
          spritesheet: app.sprites,
          speed: 15
        });
        app.viewport = new Rogue.ViewPort({
          parent: app.game,
          canvas: app.game.canvas,
          viewWidth: 1000,
          viewHeight: 1000
        });
        app.player = new Rogue.Entity({
          parent: app.game,
          image: app.animation.next(),
          "import": ["movable", "collide"]
        });
        app.player.move = function(x, y) {
          this.x += x;
          this.y += y;
          if (this.colliding().length > 0) {
            this.x -= x;
            return this.y -= y;
          }
        };
        app.player2 = new Rogue.Entity({
          parent: app.game,
          image: app.assets.get('img/2.png'),
          "import": ["movable", "collide"],
          x: 64,
          y: 64
        });
        app.tiles = new Rogue.TileMap({
          size: [20, 20]
        });
        app.viewport.add([app.tiles, app.player, app.player2]);
        app.viewport.updates.unshift(function() {
          app.viewport.follow(app.player);
          return app.viewport.forceInside(app.player, false);
        });
        app.blocks = [];
        for (y = 0, _ref = app.tiles.size[1]; 0 <= _ref ? y < _ref : y > _ref; 0 <= _ref ? y++ : y--) {
          for (x = 0, _ref2 = app.tiles.size[0]; 0 <= _ref2 ? x < _ref2 : x > _ref2; 0 <= _ref2 ? x++ : x--) {
            app.blocks.push(new Rogue.Entity({
              image: app.assets.get('img/1.png'),
              x: x,
              y: y,
              "import": ["drawable"]
            }));
          }
        }
        return app.tiles.place(app.blocks);
      },
      update: function() {
        if (app.input.pressed("right")) app.player.move(2, 0);
        if (app.input.pressed("left")) app.player.move(-2, 0);
        if (app.input.pressed("up")) app.player.move(0, -2);
        if (app.input.pressed("down")) app.player.move(0, 2);
        app.player.image = app.animation.next();
        app.game.clear();
        return app.viewport.update();
      }
    };
    app.assets = new Rogue.AssetManager();
    app.assets.add(['img/1.png', 'img/2.png']);
    app.assets.loadAll({
      onFinish: function() {
        console.log("Assets Loaded");
        return app.game.start(app.state);
      },
      onLoad: function(percent) {
        return console.log("Assets loading: " + percent);
      }
    });
    return window.app = app;
  });

}).call(this);
