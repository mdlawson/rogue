(function() {
  var AssetManager, Entity, Game, GameLoop, Rogue, RollingAverage, TileMap, ViewPort, log, math, util,
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
        image: ["png", "gif", "jpg", "jpeg", "tiff"],
        sound: ["mp3", "ogg"]
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
      this.x = options.x || 0;
      this.y = options.y || 0;
      this.res = options.res || [32, 32];
      this.size = options.size || [100, 100];
      this.width = this.size[0] * this.res[0];
      this.height = this.size[1] * this.res[1];
      this.parent = options.parent;
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
        return obj.forEach(function(item) {
          return _this.place(item);
        });
      } else {
        obj.tile = this.tiles[obj.x][obj.y];
        obj.res = this.res;
        obj.parent = this.parent;
        return this.tiles[obj.x][obj.y].push(obj);
      }
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

    TileMap.prototype.atRect = function(rect) {
      var round, tiles, x, x1, x2, y, y1, y2;
      tiles = [];
      round = Rogue.math.round;
      x1 = round(rect.x / this.res[0]);
      y1 = round(rect.y / this.res[1]);
      x2 = round((rect.x + rect.width) / this.res[0]);
      y2 = round((rect.y + rect.height) / this.res[1]);
      for (y = y1; y1 <= y2 ? y <= y2 : y >= y2; y1 <= y2 ? y++ : y--) {
        for (x = x1; x1 <= x2 ? x <= x2 : x >= x2; x1 <= x2 ? x++ : x--) {
          tiles.push(this.tiles[x][y]);
        }
      }
      return tiles;
    };

    TileMap.prototype.draw = function() {
      var obj, tile, tiles, _i, _len, _results;
      tiles = this.atRect({
        x: this.parent.x ? this.parent.x - this.x : 0,
        y: this.parent.y ? this.parent.y - this.y : 0,
        width: this.parent.width,
        height: this.parent.height
      });
      _results = [];
      for (_i = 0, _len = tiles.length; _i < _len; _i++) {
        tile = tiles[_i];
        _results.push((function() {
          var _j, _len2, _ref, _results2;
          _ref = tile.content;
          _results2 = [];
          for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
            obj = _ref[_j];
            _results2.push(obj.draw);
          }
          return _results2;
        })());
      }
      return _results;
    };

    return TileMap;

  })();

  Entity = (function() {

    function Entity(options) {
      var key, value, _len;
      for (value = 0, _len = options.length; value < _len; value++) {
        key = options[value];
        this[key] = value;
      }
            if (this.x != null) {
        this.x;
      } else {
        0;
      };
            if (this.y != null) {
        this.y;
      } else {
        0;
      };
      this.res = [1, 1];
    }

    Entity.prototype.move = function(x, y) {
      this.x += x;
      return this.y += y;
    };

    Entity.prototype.moveTo = function(x, y) {
      this.x = x;
      return this.y = y;
    };

    Entity.prototype.draw = function() {
      this.parent.context.save();
      this.parent.context.translate(this.x * this.res[0], this.y * this.res[1]);
      this.parent.context.drawImage(this.image, 0, 0, this.width, this.height);
      return this.parent.context.restore();
    };

    return Entity;

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
      return this.switchState(this.state);
    };

    Game.prototype.switchState = function(state) {
      this.loop && this.loop.stop();
      this.oldState = this.state;
      this.loop = new GameLoop(this.state);
      return this.loop.start();
    };

    Game.prototype.clear = function() {
      return this.context.clearRect(0, 0, this.width, this.height);
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

  ViewPort = (function() {

    function ViewPort(options) {
      this.options = options;
      this.canvas = this.options.canvas || document.createElement("canvas");
      this.context = this.cavas.getContext('2d');
      this.width = this.options.width || this.canvas.width;
      this.height = this.options.height || this.canvas.height;
      this.maxWidth = this.options.maxWidth || this.width;
      this.maxheight = this.options.maxHeight || this.height;
      this.x = this.options.x || 0;
      this.y = this.options.y || 0;
      this.entities = [];
    }

    ViewPort.prototype.add = function(entity) {
      var _this = this;
      if (entity.forEach) {
        return entity.forEach(function(obj) {
          return _this.add(obj);
        });
      } else {
        entity.parent = this;
        return this.entities.push(entity);
      }
    };

    ViewPort.prototype.draw = function() {
      var entity, _i, _len, _ref, _results;
      _ref = this.entities;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        entity = _ref[_i];
        if (this.visible(entity)) {
          _results.push(entity.draw);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    ViewPort.prototype.move = function(x, y) {
      this.x += x;
      this.y += y;
      return this.keepInBounds();
    };

    ViewPort.prototype.moveTo = function(x, y) {
      this.x = x;
      this.y = y;
      return this.keepInBounds();
    };

    ViewPort.prototype.centerAround = function(entity) {
      this.x = entity.x - Rogue.math.round(this.width / 2);
      this.y = entity.y - Rogue.math.round(this.height / 2);
      return this.keepInBounds();
    };

    ViewPort.prototype.visible = function(entity) {
      return (entity.x >= this.x && entity.y >= this.y) || ((entity.x + entity.width) <= (this.x + this.width) && (entity.y + entity.height) <= (this.y + this.height));
    };

    ViewPort.prototype.keepInBounds = function() {
      if (this.x < 0) this.x = 0;
      if (this.y < 0) this.y = 0;
      if (this.x + this.width > this.maxWidth) this.x = this.maxWidth - this.width;
      if (this.y + this.height > this.maxHeight) {
        return this.y = this.maxHeight - this.height;
      }
    };

    return ViewPort;

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

  Rogue.ViewPort = ViewPort;

  Rogue.Entity = Entity;

  Rogue.loglevel = 6;

}).call(this);
