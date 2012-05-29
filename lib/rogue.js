(function() {
  var AssetManager, Game, GameLoop, Rogue, RollingAverage, TileMap, log, math, util,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = Array.prototype.slice;

  AssetManager = (function() {

    function AssetManager() {
      this.count = 0;
      this.ecount = 0;
      this.queue = [];
      this.assets = {};
      this.filetypes = {
        image: ["png", "gif", "jpg", "jpeg", "tiff"]
      };
    }

    AssetManager.prototype.add = function(url) {
      return this.queue = this.queue.concat(url);
    };

    AssetManager.prototype.get = function(src) {
      if (!(this.assets[src] != null)) Rogue.log(2, "asset not loaded: " + src);
      return this.assets[src];
    };

    AssetManager.prototype.loadAll = function(options) {
      var a, _i, _len, _ref, _results;
      this.onFinish = options.onFinish;
      this.onLoad = options.onLoad;
      _ref = this.queue;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        a = _ref[_i];
        _results.push(this.load(a));
      }
      return _results;
    };

    AssetManager.prototype.load = function(src) {
      var asset, ext, key, that, type, value, _ref;
      that = this;
      ext = src.split(".").pop();
      _ref = this.filetypes;
      for (key in _ref) {
        value = _ref[key];
        if (__indexOf.call(value, ext) >= 0) type = key;
      }
      if (!(type != null)) {
        Rogue.log(2, "unknown extension on: " + src);
        return;
      }
      switch (type) {
        case "image":
          asset = new Image();
          asset.addEventListener("load", function() {
            var canvas, context;
            canvas = document.createElement("canvas");
            canvas.width = this.width;
            canvas.height = this.height;
            canvas.src = this.src;
            context = canvas.getContext("2d");
            context.drawImage(this, 0, 0, this.width, this.height);
            that.count++;
            return that.loaded(canvas);
          });
          asset.addEventListener("error", function() {
            that.ecount++;
            Rogue.log(2, "could not load asset: " + this.src);
            return that.loaded(this);
          });
          return asset.src = src;
      }
    };

    AssetManager.prototype.loaded = function(asset) {
      var percentage;
      this.assets[asset.src] = asset;
      percentage = ((this.count + this.ecount) / this.queue.length) * 100;
      this.onLoad(percentage);
      if (percentage === 100) return this.onFinish();
    };

    return AssetManager;

  })();

  TileMap = (function() {

    function TileMap(options) {
      var calc, d, dirs, x, y, _ref, _ref2;
      this.res = options.res || [32, 32];
      this.size = options.size || [100, 100];
      this.tiles = (function() {
        var _ref, _results;
        _results = [];
        for (y = 0, _ref = this.size[1]; 0 <= _ref ? y < _ref : y > _ref; 0 <= _ref ? y++ : y--) {
          _results.push((function() {
            var _ref2, _results2;
            _results2 = [];
            for (x = 0, _ref2 = this.size[0]; 0 <= _ref2 ? x < _ref2 : x > _ref2; 0 <= _ref2 ? x++ : x--) {
              _results2.push({});
            }
            return _results2;
          }).call(this));
        }
        return _results;
      }).call(this);
      dirs = {
        s: [0, 1],
        e: [1, 0],
        n: [0, -1],
        w: [-1, 0]
      };
      for (x = 0, _ref = this.size[0]; 0 <= _ref ? x < _ref : x > _ref; 0 <= _ref ? x++ : x--) {
        for (y = 0, _ref2 = this.size[1]; 0 <= _ref2 ? y < _ref2 : y > _ref2; 0 <= _ref2 ? y++ : y--) {
          this.tiles[x][y].x = x;
          this.tiles[x][y].y = y;
          this.tiles[x][y].content = [];
          for (d in dirs) {
            calc = dirs[d];
            this.tiles[x][y][d] = (this.tiles[x + calc[0]] != null) && (this.tiles[x + calc[0]][y + calc[1]] != null) ? this.tiles[x + calc[0]][y + calc[1]] : null;
          }
        }
      }
    }

    TileMap.prototype.place = function(obj) {
      var _this = this;
      if (obj.forEach) {
        obj.forEach(function(item) {
          return _this.place(item);
        });
        return obj;
      }
      obj.tile = this.tiles[obj.x][obj.y];
      return this.tiles[obj.x][obj.y].push(obj);
    };

    TileMap.prototype.lookup = function(x, y) {
      return this.tiles[x][y].content;
    };

    TileMap.prototype.clear = function() {
      var col, tile, _i, _len, _ref, _results;
      _ref = this.tiles;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        col = _ref[_i];
        _results.push((function() {
          var _j, _len2, _results2;
          _results2 = [];
          for (_j = 0, _len2 = col.length; _j < _len2; _j++) {
            tile = col[_j];
            _results2.push(tile.content = []);
          }
          return _results2;
        })());
      }
      return _results;
    };

    return TileMap;

  })();

  Game = (function() {

    function Game(options) {
      var _ref, _ref2;
      this.options = options;
      if ((options != null ? options.canvas : void 0) != null) {
        this.canvas = document.getElementById(options.canvas);
      }
      if (!(this.canvas != null)) {
        this.canvas = document.createElement("canvas");
        document.body.appendChild(this.canvas);
      }
      this.width = this.canvas.width = (_ref = options != null ? options.width : void 0) != null ? _ref : 400;
      this.height = this.canvas.height = (_ref2 = options != null ? options.height : void 0) != null ? _ref2 : 300;
      this.context = this.canvas.getContext('2d');
    }

    Game.prototype.start = function(state) {
      var loading, _ref;
      this.state = state;
      loading = (_ref = this.options.loadingScreen) != null ? _ref : function() {};
      return switchState(this.state);
    };

    Game.prototype.switchState = function(state) {
      this.loop && this.loop.stop();
      this.oldState = this.state;
      this.loop = new GameLoop(this.state);
      return this.loop.start();
    };

    return Game;

  })();

  GameLoop = (function() {

    function GameLoop(state) {
      this.state = state;
      this.loop = __bind(this.loop, this);
      this.fps = 0;
      this.paused = this.stopped = false;
      this.averageFPS = new RollingAverage(20);
    }

    GameLoop.prototype.start = function() {
      var currentTick, firstTick, lastTick;
      firstTick = currentTick = lastTick = (new Date()).getTime();
      return Rogue.ticker(this.loop);
    };

    GameLoop.prototype.loop = function() {
      this.currentTick = (new Date()).getTime();
      this.tickDuration = this.currentTick - this.lastTick;
      this.fps = this.averageFPS.add(1000 / this.tickDuration);
      if (!(this.stopped || this.paused)) {
        this.state.update();
        this.state.draw();
      }
      if (!this.stopped) Rogue.ticker(this.loop);
      return this.lastTick = this.currentTick;
    };

    GameLoop.prototype.pause = function() {
      return this.paused = true;
    };

    GameLoop.prototype.stop = function() {
      return this.stopped = true;
    };

    return GameLoop;

  })();

  RollingAverage = (function() {

    function RollingAverage(size) {
      this.size = size;
      this.values = new Array(this.size);
      this.count = 0;
    }

    RollingAverage.prototype.add = function(value) {
      this.values = this.values.slice(1, this.size);
      this.values.push(value);
      if (this.count < this.size) this.count++;
      return parseInt((this.values.reduce(function(t, s) {
        return t + s;
      })) / this.count);
    };

    return RollingAverage;

  })();

  log = function() {
    var args, level;
    level = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if (!(level <= Rogue.loglevel)) return;
    if (typeof console !== "undefined" && console !== null) {
      if (typeof console.log === "function") {
        console.log.apply(console, ["(Rogue)"].concat(__slice.call(args)));
      }
    }
    return this;
  };

  util = {
    isArray: function(value) {
      return Object.prototype.toString.call(value) === '[object Array]';
    }
  };

  math = {
    round: function(num) {
      return (0.5 + num) | 0;
    }
  };

  Rogue = this.Rogue = {};

  if (typeof module !== "undefined" && module !== null) module.exports = Rogue;

  Rogue.ticker = window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame;

  Rogue.log = log;

  Rogue.util = util;

  Rogue.math = math;

  Rogue.Game = Game;

  Rogue.GameLoop = GameLoop;

  Rogue.TileMap = TileMap;

  Rogue.AssetManager = AssetManager;

  Rogue.loglevel = 6;

}).call(this);
