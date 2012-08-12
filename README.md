Rogue - A canvas games library written in CoffeeScript
=====

## Features

* Simple Entity-Component system
* Physics engine with mass, friction, and AABB and pixel based collision
* Extensible components and physics behaviors
* Animation and property tweening support
* Parallax layers
* Game states for organization
* Loose-ish coupling of modules: Global namespaces are not used to share data
* Light: 50kb compiled, 25kb minified, 8kb minified+gzip (at last count, still growing)
* No dependencies

* Basic classes:
  * Game
  * GameLoop
  * TileMap
  * AssetManager
  * SpriteSheet
  * ViewPort
  * Animation
  * Keyboard
  * Mouse
  * Factory
  * Entity
  * Tween

* Components:
  * Collisions
  * Movement
  * Sprite
  * Tile
  * Layers
  * Tween

* Behaviors:
  * Collide
  * Gravity
  
## Credits

The design of this library draws strongly from [jaws](https://github.com/ippa/jaws)
