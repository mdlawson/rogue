(function() {

  Rogue.ready(function() {
    var app;
    app = {};
    app.game = new Rogue.Game({
      fps: true
    });
    app.input = new Rogue.KeyboardManager(app.game.canvas);
    app.state = {
      setup: function() {
        var x, _ref;
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
        app.bg1 = new Rogue.Entity({
          image: app.assets.get('img/b1.png'),
          speed: 0.5,
          repeatX: true,
          require: ["layer"]
        });
        app.bg2 = new Rogue.Entity({
          image: app.assets.get('img/b2.png'),
          speed: 0.9,
          repeatX: true,
          require: ["layer"]
        });
        app.player = new Rogue.Entity({
          parent: app.game,
          image: app.assets.get('img/2.png'),
          scaleFactor: 2,
          require: ["move", "collide", "gravity"]
        });
        app.tiles = new Rogue.TileMap({
          y: 300,
          size: [30, 1]
        });
        app.viewport.add([app.bg2, app.bg1, app.player, app.tiles]);
        app.viewport.updates[98] = function() {
          this.follow(app.player);
          return this.forceInside(app.player, false);
        };
        app.blocks = [];
        for (x = 0, _ref = app.tiles.size[0]; 0 <= _ref ? x < _ref : x > _ref; 0 <= _ref ? x++ : x--) {
          app.blocks.push(new Rogue.Entity({
            image: app.assets.get('img/1.png'),
            x: x,
            y: 0,
            require: ["sprite", "collide"]
          }));
        }
        return app.tiles.place(app.blocks);
      },
      update: function() {
        if (app.input.pressed("right")) app.player.move(2, 0);
        if (app.input.pressed("left")) app.player.move(-2, 0);
        if (app.input.pressed("up")) app.player.dy = 5;
        if (app.input.pressed("down")) app.player.move(0, 2);
        app.game.clear();
        return app.viewport.update();
      }
    };
    app.assets = new Rogue.AssetManager();
    app.assets.add(['img/1.png', 'img/2.png', 'img/b1.png', 'img/b2.png']);
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
