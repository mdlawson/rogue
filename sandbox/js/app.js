(function(/*! Brunch !*/) {
  'use strict';

  var globals = typeof window !== 'undefined' ? window : global;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};

  var has = function(object, name) {
    return ({}).hasOwnProperty.call(object, name);
  };

  var expand = function(root, name) {
    var results = [], parts, part;
    if (/^\.\.?(\/|$)/.test(name)) {
      parts = [root, name].join('/').split('/');
    } else {
      parts = name.split('/');
    }
    for (var i = 0, length = parts.length; i < length; i++) {
      part = parts[i];
      if (part === '..') {
        results.pop();
      } else if (part !== '.' && part !== '') {
        results.push(part);
      }
    }
    return results.join('/');
  };

  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function(name) {
      var dir = dirname(path);
      var absolute = expand(dir, name);
      return globals.require(absolute);
    };
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    definition(module.exports, localRequire(name), module);
    var exports = cache[name] = module.exports;
    return exports;
  };

  var require = function(name) {
    var path = expand(name, '.');

    if (has(cache, path)) return cache[path];
    if (has(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has(cache, dirIndex)) return cache[dirIndex];
    if (has(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '"');
  };

  var define = function(bundle) {
    for (var key in bundle) {
      if (has(bundle, key)) {
        modules[key] = bundle[key];
      }
    }
  }

  globals.require = require;
  globals.require.define = define;
  globals.require.brunch = true;
})();

window.require.define({"game": function(exports, require, module) {
  var assets, game, state;

  state = require('state');

  game = new Rogue.Game({
    fps: true,
    width: 680,
    height: 400,
    canvas: "game-canvas"
  });

  game.input = new Rogue.Keyboard(game.canvas);

  game.mouse = new Rogue.Mouse(game);

  game.assets = assets = new Rogue.AssetManager({
    baseUrl: "",
    packs: {
      core: [
        {
          name: "bg1",
          src: "img/b1.png"
        }, {
          name: "bg2",
          src: "img/b2.png"
        }, {
          name: "red",
          src: "img/1.png"
        }, {
          name: "blue",
          src: "img/2.png"
        }, {
          name: "jump",
          src: "sound/jump.ogg",
          alt: "sound/jump.mp3"
        }
      ]
    },
    preload: false
  });

  assets.on("load", "core", function(asset, percent) {
    return console.log("Assets loading: " + percent);
  });

  assets.on("complete", "core", function() {
    console.log("Assets loaded");
    return game.start(state);
  });

  assets.download("core");

  module.exports = game;
  
}});

window.require.define({"initialize": function(exports, require, module) {
  
  Rogue.ready(function() {
    return window.game = require('game');
  });
  
}});

window.require.define({"state": function(exports, require, module) {
  var state;

  state = {
    setup: function(game) {
      var assets, bg1, bg2, tiles, x, _i, _ref, _results;
      console.log("setup run");
      assets = game.assets.core;
      this.viewport = new Rogue.ViewPort({
        parent: game,
        viewWidth: 1000,
        viewHeight: 400
      });
      bg1 = new Rogue.Entity({
        name: "bg1",
        image: assets.bg1,
        speed: 0.5,
        repeatX: true,
        require: ["layer"]
      });
      bg2 = new Rogue.Entity({
        name: "bg2",
        image: assets.bg2,
        speed: 0.9,
        repeatX: true,
        require: ["layer"]
      });
      game.player = new Rogue.Entity({
        name: "player",
        image: assets.blue,
        require: ["move", "collide", "AABB", "physics"]
      });
      game.player.behavior.add("gravity");
      game.player.ev.on("hit", function(col) {
        if (col.dir === "bottom") {
          return this.canJump = true;
        }
      });
      tiles = new Rogue.TileMap({
        name: "tiles",
        y: 300,
        size: [30, 1]
      });
      this.viewport.add([bg2, bg1, game.player, tiles]);
      this.viewport.updates.push(function() {
        this.follow(this.player);
        return this.forceInside(this.player, false);
      });
      _results = [];
      for (x = _i = 0, _ref = this.viewport.tiles.size[0]; 0 <= _ref ? _i < _ref : _i > _ref; x = 0 <= _ref ? ++_i : --_i) {
        _results.push(this.viewport.tiles.place(new Rogue.Entity({
          image: assets.red,
          x: x,
          y: 0,
          require: ["sprite", "collide", "AABB"]
        })));
      }
      return _results;
    },
    update: function(game, dt) {
      var input, player;
      player = game.player;
      input = game.input;
      if (input.pressed("right")) {
        player.move(2, 0);
      }
      if (input.pressed("left")) {
        player.move(-2, 0);
      }
      if (input.pressed("up")) {
        if (player.canJump) {
          game.assets.core.jump.play();
          player.canJump = false;
          player.acc[1] = -25;
        }
      }
      if (input.pressed("down")) {
        player.move(0, 2);
      }
      return this.viewport.update(dt);
    },
    draw: function(game, dt) {
      game.clear();
      return this.viewport.draw();
    }
  };

  module.exports = state;
  
}});

