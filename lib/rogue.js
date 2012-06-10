(function() {
  var Animation, AssetManager, Entity, Game, GameLoop, KeyboardManager, Rogue, RollingAverage, SpriteSheet, TileMap, ViewPort, c, find, log, math, util,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
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
            canvas = util.canvas();
            canvas.width = this.width;
            canvas.height = this.height;
            canvas.src = src;
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

  SpriteSheet = (function() {

    function SpriteSheet(options) {
      var c, cx, x, y, _ref, _ref2, _ref3, _ref4;
      this.options = options;
      this.img = this.options.image;
      this.res = this.options.res || [32, 32];
      this.length = 0;
      for (x = 0, _ref = this.img.width, _ref2 = this.res[0]; 0 <= _ref ? x < _ref : x > _ref; x += _ref2) {
        for (y = 0, _ref3 = this.img.height, _ref4 = this.res[1]; 0 <= _ref3 ? y < _ref3 : y > _ref3; y += _ref4) {
          c = util.canvas();
          cx = c.getContext("2d");
          c.width = this.res[0];
          c.height = this.res[1];
          cx.drawImage(this.img, x, y, c.width, c.height, 0, 0, c.width, c.height);
          this[this.length] = c;
          this.length++;
        }
      }
    }

    return SpriteSheet;

  })();

  Animation = (function() {

    function Animation(options) {
      this.options = options;
      this.sprites = this.options.spritesheet;
      this.speed = this.options.speed || 6;
      this.i = this.options.start || 0;
      this.t = 0;
      this.loop = this.options.loop || true;
      this.bounce = this.options.bounce || false;
      this.onFinish = this.options.onFinish;
      this.dir = 1;
      this.frame = this.sprites[this.i];
    }

    Animation.prototype.next = function() {
      if (this.t === this.speed) {
        this.frame = this.sprites[this.i += this.dir];
        this.t = 0;
      }
      if (this.i === this.sprites.length - 1) {
        if (!this.loop) {
          if (this.onFinish) this.onFinish();
        } else {
          if (this.bounce) {
            this.dir = -1;
          } else {
            this.i = 0;
          }
        }
      }
      if (this.i === 0 && this.dir === -1) this.dir = 1;
      this.t++;
      return this.frame;
    };

    return Animation;

  })();

  Entity = (function() {

    function Entity(options) {
      this.options = options;
      this.components = [];
      this.updates = [];
      util.mixin(this, this.options);
      if (this["import"]) util["import"](this["import"], this);
      if (this.parent) this.parent.e.push(this);
    }

    Entity.prototype.update = function() {
      var func, _i, _len, _ref, _results;
      _ref = this.updates;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        func = _ref[_i];
        _results.push(func.call(this));
      }
      return _results;
    };

    return Entity;

  })();

  c = {};

  c.drawable = {
    init: function() {
      if (!this.image) log(2, "Drawable entitys require an image");
      if (this.width == null) this.width = this.image.width;
      if (this.height == null) this.height = this.image.height;
      if (this.x == null) this.x = 0;
      if (this.y == null) this.y = 0;
      if (this.res == null) this.res = [1, 1];
      if (this.xOffset == null) this.xOffset = math.round(this.image.width / 2);
      if (this.yOffset == null) this.yOffset = math.round(this.image.height / 2);
      return this.updates.push(this.draw);
    },
    draw: function() {
      this.parent.context.save();
      this.parent.context.translate((this.x * this.res[0]) - this.xOffset, (this.y * this.res[1]) - this.yOffset);
      this.parent.context.drawImage(this.image, 0, 0, this.width, this.height);
      return this.parent.context.restore();
    },
    rect: function() {
      return {
        x: this.x - this.xOffset,
        y: this.y - this.yOffset,
        width: this.width,
        height: this.height
      };
    }
  };

  c.movable = {
    init: function() {
      return util["import"](["drawable"], this);
    },
    move: function(x, y) {
      this.x += x;
      return this.y += y;
    },
    moveTo: function(x, y) {
      this.x = x;
      this.y = y;
    }
  };

  c.tile = {
    init: function() {
      return util["import"](["drawable"], this);
    },
    move: function(x, y) {
      util.remove(this.tile.contents, this);
      this.x += x;
      this.y += y;
      return this.tile.parent.place(this);
    },
    moveTo: function(x, y) {
      this.x = x;
      this.y = y;
      util.remove(this.tile.contents, this);
      return this.tile.parent.place(this);
    },
    rect: function() {
      return {
        x: (this.res[0] * this.x) - this.xOffset,
        y: (this.res[1] * this.y) - this.yOffset,
        width: this.width,
        height: this.height
      };
    }
  };

  c.collide = {
    init: function() {
      util["import"](["drawable"], this);
      return this.updates.unshift(this.colliding);
    },
    collide: function(obj) {
      return util.collide(this.rect(), obj.rect());
    },
    colliding: function() {
      var obj, results, solid, _i, _len;
      solid = this.parent.find(["collide"]);
      util.remove(solid, this);
      results = [];
      for (_i = 0, _len = solid.length; _i < _len; _i++) {
        obj = solid[_i];
        if (this.collide(obj)) results.push(obj);
      }
      return results;
    }
  };

  TileMap = (function(_super) {

    __extends(TileMap, _super);

    function TileMap(options) {
      var calc, d, dirs, x, y, _ref, _ref2;
      if (options == null) options = {};
      this.x = options.x || 0;
      this.y = options.y || 0;
      this.res = options.res || [32, 32];
      this.size = options.size || [100, 100];
      this.width = this.size[0] * this.res[0];
      this.height = this.size[1] * this.res[1];
      this.parent = options.parent;
      this.components = [];
      this.tiles = (function() {
        var _ref, _results;
        _results = [];
        for (y = 0, _ref = this.size[1]; 0 <= _ref ? y < _ref : y > _ref; 0 <= _ref ? y++ : y--) {
          _results.push((function() {
            var _ref2, _results2;
            _results2 = [];
            for (x = 0, _ref2 = this.size[0]; 0 <= _ref2 ? x < _ref2 : x > _ref2; 0 <= _ref2 ? x++ : x--) {
              _results2.push({
                parent: this
              });
            }
            return _results2;
          }).call(this));
        }
        return _results;
      }).call(this);
      this.updates = [this.draw];
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
        util["import"](["tile"], obj);
        obj.tile = this.tiles[obj.x][obj.y];
        obj.res = this.res;
        obj.parent = this.parent;
        return this.tiles[obj.x][obj.y].content.unshift(obj);
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
      var round, tiles, x, x1, x2, y, y1, y2, _ref;
      tiles = [];
      round = Rogue.math.round;
      x1 = round(rect.x / this.res[0]);
      y1 = round(rect.y / this.res[1]);
      x2 = round((rect.x + rect.width) / this.res[0]);
      y2 = round((rect.y + rect.height) / this.res[1]);
      for (y = y1; y1 <= y2 ? y <= y2 : y >= y2; y1 <= y2 ? y++ : y--) {
        for (x = x1; x1 <= x2 ? x <= x2 : x >= x2; x1 <= x2 ? x++ : x--) {
          if (((_ref = this.tiles[x]) != null ? _ref[y] : void 0) != null) {
            tiles.push(this.tiles[x][y].content);
          }
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
          var _j, _len2, _results2;
          _results2 = [];
          for (_j = 0, _len2 = tile.length; _j < _len2; _j++) {
            obj = tile[_j];
            _results2.push(obj.draw());
          }
          return _results2;
        })());
      }
      return _results;
    };

    TileMap.prototype.rect = function() {
      return this;
    };

    return TileMap;

  })(Entity);

  KeyboardManager = (function() {
    var char, downFn, i, keys, num, pressedKeys, upFn, _len, _ref;

    function KeyboardManager(context) {
      var handleEvent,
        _this = this;
      this.context = context;
      this.context.oncontextmenu = function() {
        return false;
      };
      handleEvent = function(e) {
        var fn, key, _ref;
        e = e || window.event;
        if (e.target !== _this.context) return;
        if (e.type === 'keyup') {
          key = false;
          fn = upFn;
        } else {
          key = true;
          fn = downFn;
        }
        pressedKeys[e.keyCode] = key;
        if (_ref = e.keyCode, __indexOf.call(fn, _ref) >= 0) fn[e.keyCode]();
        return e.preventDefault();
      };
      window.addEventListener('keyup', handleEvent, false);
      window.addEventListener('keydown', handleEvent, false);
    }

    KeyboardManager.prototype.press = function(key, fn) {
      var k, _i, _len, _results;
      if (key.forEach) {
        _results = [];
        for (_i = 0, _len = key.length; _i < _len; _i++) {
          k = key[_i];
          _results.push(this.press(k, fn));
        }
        return _results;
      } else {
        if (keys[key] != null) {
          return downFn[keys[key]] = fn;
        } else {
          return Rogue.log(3, "invalid key: " + key);
        }
      }
    };

    KeyboardManager.prototype.release = function(key, fn) {
      var k, _i, _len, _results;
      if (key.forEach) {
        _results = [];
        for (_i = 0, _len = key.length; _i < _len; _i++) {
          k = key[_i];
          _results.push(this.release(k, fn));
        }
        return _results;
      } else {
        if (keys[key] != null) {
          return upFn[keys[key]] = fn;
        } else {
          return Rogue.log(3, "invalid key: " + key);
        }
      }
    };

    KeyboardManager.prototype.pressed = function(key) {
      if (keys[key] != null) {
        return pressedKeys[keys[key]];
      } else {
        return Rogue.log(3, "invalid key: " + key);
      }
    };

    downFn = [];

    upFn = [];

    pressedKeys = [];

    keys = {
      backspace: 8,
      tab: 9,
      enter: 13,
      shift: 16,
      ctrl: 17,
      alt: 18,
      pause: 19,
      capslock: 20,
      escape: 27,
      space: 32,
      pageup: 33,
      pagedown: 34,
      end: 35,
      home: 36,
      left: 37,
      up: 38,
      right: 39,
      down: 40,
      insert: 45,
      'delete': 46,
      leftwin: 91,
      rightwin: 92,
      multiply: 106,
      add: 107,
      subtract: 109,
      decimalpoint: 110,
      divide: 111,
      numlock: 144,
      scrollock: 145,
      semicolon: 186,
      equals: 187,
      comma: 188,
      dash: 189,
      period: 190,
      forwardslash: 191,
      backtick: 192,
      openbracket: 219,
      backslash: 220,
      closebracket: 221,
      quote: 222
    };

    for (num = 0; num < 10; num++) {
      keys['' + num] = 48 + num;
      keys['numpad' + num] = 96 + num;
      keys['f' + num] = 112 + num;
    }

    _ref = 'abcdefghijklmnopqrstuvwxyz';
    for (i = 0, _len = _ref.length; i < _len; i++) {
      char = _ref[i];
      keys[char] = 65 + i;
    }

    return KeyboardManager;

  })();

  /*
  # RogueJS #
  
  This is the main RogueJS module. Contains classes for constructing 
  the skeleton of a game. Also contains utility functions
  */

  Game = (function() {
    /*
    	The Game class. This is where the game state and canvas are managed.
    */
    function Game(options) {
      var _ref, _ref2;
      this.options = options;
      if ((options != null ? options.canvas : void 0) != null) {
        this.canvas = document.getElementById(options.canvas);
      }
      if (!(this.canvas != null)) {
        this.canvas = util.canvas();
        document.body.appendChild(this.canvas);
      }
      this.canvas.tabIndex = 1;
      this.width = this.canvas.width = (_ref = options != null ? options.width : void 0) != null ? _ref : 400;
      this.height = this.canvas.height = (_ref2 = options != null ? options.height : void 0) != null ? _ref2 : 300;
      this.canvas.x = this.canvas.y = 0;
      this.context = this.canvas.getContext('2d');
      /* 
      		Options:
      		+ canvas: the ID of an existing canvas element to use
      		+ width: the width to set the canvas to, default: 400
      		+ height: the height to set the canvas to, default: 300
      */
    }

    Game.prototype.start = function(state) {
      var loading, _ref, _ref2;
      loading = (_ref = (_ref2 = this.options) != null ? _ref2.loadingScreen : void 0) != null ? _ref : function() {};
      return this.switchState(state);
      /*
      		Starts the game with a state:
      		A state is an object with 2 methods, a start method, 
      		which is run when the state is first loaded, and a
      		update method, which is run every tick.
      */
    };

    Game.prototype.switchState = function(state) {
      this.e = [];
      this.loop && this.loop.stop();
      this.oldState = this.state;
      this.state = state;
      this.state.setup();
      this.loop = new GameLoop;
      this.loop.add(this.state.update);
      return this.loop.start();
      /*
      		Switches the game to a new state. Old state is stored in oldState.
      		A GameLoop instance is automatically created.
      */
    };

    Game.prototype.clear = function() {
      return this.context.clearRect(0, 0, this.width, this.height);
      /*
      		Clears the canvas, can be run at the end of each frame.
      		TODO: automatic partical update system.
      */
    };

    Game.prototype.find = function(c) {
      return find.call(this, c);
      /*
      		Used to find entitys with given components within the namespace of the game.
      */
    };

    return Game;

  })();

  GameLoop = (function() {
    /*
    	The GameLoop class. Runs a list of functions, stored in @call, every tick
    */
    function GameLoop(state) {
      this.state = state;
      this.loop = __bind(this.loop, this);
      this.fps = 0;
      this.averageFPS = new RollingAverage(20);
      this.call = [];
    }

    GameLoop.prototype.start = function() {
      var currentTick, firstTick, lastTick;
      this.paused = this.stopped = false;
      firstTick = currentTick = lastTick = (new Date()).getTime();
      return Rogue.ticker.call(window, this.loop);
    };

    GameLoop.prototype.loop = function() {
      var func, _i, _len, _ref;
      this.currentTick = (new Date()).getTime();
      this.tickDuration = this.currentTick - this.lastTick;
      this.fps = this.averageFPS.add(1000 / this.tickDuration);
      if (!(this.stopped || this.paused)) {
        _ref = this.call;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          func = _ref[_i];
          func();
        }
      }
      if (!this.stopped) Rogue.ticker.call(window, this.loop);
      return this.lastTick = this.currentTick;
    };

    GameLoop.prototype.pause = function() {
      return this.paused = true;
    };

    GameLoop.prototype.stop = function() {
      return this.stopped = true;
    };

    GameLoop.prototype.add = function(func) {
      return this.call = this.call.concat(func);
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

  ViewPort = (function(_super) {

    __extends(ViewPort, _super);

    function ViewPort(options) {
      this.options = options;
      this.canvas = this.options.canvas || util.canvas();
      this.context = this.canvas.getContext('2d');
      this.parent = this.options.parent;
      this.width = this.options.width || this.canvas.width;
      this.height = this.options.height || this.canvas.height;
      this.viewWidth = this.options.viewWidth || this.width;
      this.viewHeight = this.options.viewHeight || this.height;
      this.viewX = this.options.viewX || 0;
      this.viewY = this.options.viewY || 0;
      this.x = this.options.x || 0;
      this.y = this.options.y || 0;
      this.e = [];
      this.updates = [this.draw];
    }

    ViewPort.prototype.add = function(entity) {
      var _this = this;
      if (entity.forEach) {
        return entity.forEach(function(obj) {
          return _this.add(obj);
        });
      } else {
        entity.parent = this;
        this.e.push(entity);
        return this.parent.e.push(entity);
      }
    };

    ViewPort.prototype.draw = function() {
      var entity, _i, _len, _ref;
      this.context.save();
      this.context.translate(-this.viewX, -this.viewY);
      this.context.beginPath();
      this.context.rect(this.x + this.viewX, this.y + this.viewY, this.width, this.height);
      this.context.clip();
      _ref = this.e;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        entity = _ref[_i];
        if (this.visible(entity)) entity.update();
      }
      return this.context.restore();
    };

    ViewPort.prototype.move = function(x, y) {
      this.viewX += x;
      this.viewY += y;
      return this.keepInBounds();
    };

    ViewPort.prototype.moveTo = function(x, y) {
      this.viewX = x;
      this.viewY = y;
      return this.keepInBounds();
    };

    ViewPort.prototype.follow = function(entity) {
      this.viewX = entity.x - math.round(this.width / 2);
      this.viewY = entity.y - math.round(this.height / 2);
      return this.keepInBounds();
    };

    ViewPort.prototype.forceInside = function(entity, visible, buffer) {
      var h, w;
      if (visible == null) visible = false;
      if (buffer == null) buffer = 0;
      if (visible) {
        w = this.width;
        h = this.height;
      } else {
        w = this.viewWidth;
        h = this.viewHeight;
      }
      if (entity.x < buffer) entity.x = buffer;
      if (entity.y < buffer) entity.y = buffer;
      if (entity.x > w - buffer) entity.x = w - buffer;
      if (entity.y > h - buffer) return entity.y = h - buffer;
    };

    ViewPort.prototype.rect = function() {
      return {
        width: this.width,
        height: this.height,
        x: this.viewX,
        y: this.viewY
      };
    };

    ViewPort.prototype.visible = function(entity) {
      return util.collide(entity.rect(), this.rect());
    };

    ViewPort.prototype.keepInBounds = function() {
      if (this.viewX < 0) this.viewX = 0;
      if (this.viewY < 0) this.viewY = 0;
      if (this.viewX + this.width > this.viewWidth) {
        this.viewX = this.viewWidth - this.width;
      }
      if (this.viewY + this.height > this.viewHeight) {
        return this.viewY = this.viewHeight - this.height;
      }
    };

    ViewPort.prototype.find = function(c) {
      return find.call(this, c);
    };

    return ViewPort;

  })(Entity);

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
    canvas: function() {
      return document.createElement("canvas");
    },
    isArray: function(value) {
      return Object.prototype.toString.call(value) === '[object Array]';
    },
    remove: function(a, val) {
      return a.splice(a.indexOf(val), 1);
    },
    collide: function(r1, r2) {
      return !(r2.x >= r1.x + r1.width || r2.x + r2.width <= r1.x || r2.y >= r1.y + r1.height || r2.y + r2.height <= r1.y);
    },
    mixin: function(obj, mixin) {
      var method, name;
      for (name in mixin) {
        method = mixin[name];
        obj[name] = method;
      }
      return obj;
    },
    "import": function(components, obj) {
      var comp, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = components.length; _i < _len; _i++) {
        comp = components[_i];
        if (__indexOf.call(obj.components, comp) < 0) {
          obj.components.push(comp);
          util.mixin(obj, c[comp]);
          c[comp].init.apply(obj);
          delete obj.init;
          _results.push(delete obj["import"]);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  };

  find = function(c) {
    var ent, f, found, i, _i, _j, _len, _len2, _ref;
    found = [];
    _ref = this.e;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      ent = _ref[_i];
      f = 0;
      for (_j = 0, _len2 = c.length; _j < _len2; _j++) {
        i = c[_j];
        if (__indexOf.call(ent.components, i) >= 0) f++;
      }
      if (f === c.length) found.push(ent);
    }
    return found;
  };

  math = {
    round: function(num) {
      return (0.5 + num) | 0;
    }
  };

  Rogue = this.Rogue = {};

  if (typeof module !== "undefined" && module !== null) module.exports = Rogue;

  Rogue.ticker = window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame;

  Rogue.ready = function(f) {
    return document.addEventListener("DOMContentLoaded", function() {
      document.removeEventListener("DOMContentLoaded", arguments.callee, false);
      return f();
    });
  };

  Rogue.log = log;

  Rogue.util = util;

  Rogue.math = math;

  Rogue.Game = Game;

  Rogue.GameLoop = GameLoop;

  Rogue.TileMap = TileMap;

  Rogue.AssetManager = AssetManager;

  Rogue.SpriteSheet = SpriteSheet;

  Rogue.Animation = Animation;

  Rogue.ViewPort = ViewPort;

  Rogue.components = c;

  Rogue.Entity = Entity;

  Rogue.KeyboardManager = KeyboardManager;

  Rogue.loglevel = 6;

}).call(this);
