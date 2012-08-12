# Keyboard input class. Receives all keyboard input on a given context, and provides event driven and polling driven access
# to keyboard input.
# @param {DOMElement} context Element to receive input on. 
class Keyboard
  constructor: (@context) ->
    handleEvent = (e) =>
      e = e or window.event
      #return unless e.target is @context
      if e.type is 'keyup' then key = false; fn = upFn else key = true; fn = downFn
      pressedKeys[e.keyCode] = key
      if e.keyCode in fn then fn[e.keyCode]()
      e.preventDefault()
    @context.onkeydown = @context.onkeyup = handleEvent
  # Binds the press a key or array of keys to a function. For supported keys, see the `keys` object below
  # @param {Array/String} key Key(s) to execute callback function on
  # @param {Function} fn function to execute on press.
  press: (key, fn) ->
    if key.forEach
      @press(k,fn) for k in key
    else
      if keys[key]? then downFn[keys[key]] = fn else Rogue.log 3, "invalid key: #{key}"
  # Binds the release a key or array of keys to a function. For supported keys, see the `keys` object below
  # @param {Array/String} key Key(s) to execute callback function on
  # @param {Function} fn function to execute on release.
  release: (key, fn) ->
    if key.forEach
      @release(k,fn) for k in key
    else
      if keys[key]? then upFn[keys[key]] = fn else Rogue.log 3, "invalid key: #{key}"
  # Find the status of a given key.
  # @return {Bool} true if key is pressed
  pressed: (key) ->
    if keys[key]? then return pressedKeys[keys[key]] else Rogue.log 3, "invalid key: #{key}"

  downFn = []
  upFn = []
  pressedKeys = []

  # Supported keys and keycodes
  # In addition to this list, all letter, number, f, and numpad keys are supported.
  keys = {
    backspace: 8
    tab: 9
    enter: 13
    shift: 16
    ctrl: 17
    alt: 18
    pause: 19
    capslock: 20
    escape: 27
    space: 32
    pageup: 33
    pagedown: 34
    end: 35
    home: 36
    left: 37
    up: 38
    right: 39
    down: 40
    insert: 45
    'delete': 46
    leftwin: 91
    rightwin: 92

    multiply: 106
    add: 107
    subtract: 109
    decimalpoint: 110
    divide: 111

    numlock: 144
    scrollock: 145
    semicolon: 186
    equals: 187
    comma: 188
    dash: 189
    period: 190
    forwardslash: 191
    backtick: 192
    openbracket: 219
    backslash: 220
    closebracket: 221
    quote: 222
  }
  for num in [0...10] then keys[''+num]=48+num; keys['numpad'+num]=96+num; keys['f'+num]=112+num 
  keys[chr] = 65+i for chr,i in 'abcdefghijklmnopqrstuvwxyz'

# Mouse input class. Tracks the position of the cursor and allows for binding functions to mouse actions.
# Could probably redo to use event emitter style.
# Mouse position can be accessed at any time from mouse.x and mouse.y
# Functions are called in the context of mouse, and are passed the event.
# Example:
# ```
# mouse = new Rogue.Mouse(game.canvas)
# mouse.left.click = (e) -> console.log @x,@y # => logs the mouses position on click
# ```
# Supports binding to left, middle, and right buttons on click, down, and up events
# @param {DOMElement} context the dom element to bind to
class Mouse
  constructor: (@context) ->
    @context.oncontextmenu = -> false
    buttons = ["left","middle","right"]
    actions = ["click","down","up"]
    mousemove = (e) =>
      e = e or window.event
      @x = e.offsetX
      @y = e.offsetX
    for b in buttons
      @[b] = {}
      for a in actions
        @[b][a] = () ->
    for a in actions
        listener = if a is "click" then "onclick" else "onmouse#{a}"
        @context[listener] = (e) =>
          e = e or window.event
          @context.focus()
          @[buttons[e.button]][e.type.replace("mouse","")].call(@,e)
          e.preventDefault()
    @context.onmousemove = mousemove