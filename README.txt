Advanced Rangefinder Mod v1.0
By Leslie E. Krause

Advanced Rangefinder extends the Minetest API with more powerful search capabilities for
both nodes and entities, in addition to a versatile chat command for use in testing.

The following library functions are available:

 * minetest.search_registered_nodes( node_globs, search_logic )
   Returns the names of all registered nodes that match the given list of globs. The 
   output of this function may be passed to either of the wrapper functions below or to
   minetest.find_nodes_in_area( ) directly. Two boolean search modes are possible:
    * "any" for logical OR matching (default)
    * "all" for logical AND matching

   Example:
   > minetest.search_registered_nodes( { "!default:lava*", "group:liquid" }, "all" )

 * minetest.find_nodes_in_sphere( pos, radius, node_names )
   This is a wrapper function for minetest.find_nodes_in_area( ) that provides a means to
   locate nodes by name in a spherical region. The output is a table:
    * node - the node
    * ndef - the node definition
    * pos - the node position
    * dist - the distance to the node position
    * groups - the groups belonging to the node

 * minetest.find_nodes_in_cuboid( pos, radius, height, node_names )
   This is a wrapper function for minetest.find_nodes_in_area( ) that provides a means to
   locate nodes by name in a cubicle region. The output is the same as above.

 * minetest.find_objects_in_sphere(
           pos, radius, player_names, entity_globs, search_logic, search_options )
   Since the builtin API of Minetest does not provide a means to locate entities by name
   or group, this function fulfills that purpose. It supports the same two boolean search
   modes as minetest.search_registered_nodes( ). If either the player names or entity 
   globs are nil, then all players or entities in the given range will match accordingly. 
   However, supplying an empty list will match none.

If you are already familiar with globs, then you should have no difficulties working with
the functions above. The syntax is very similar, but with only a few additions:

   ? - matches any single character
   * - matches zero or more characters
   + - matches one or more characters

A glob that is prefixed with "!" is equivalent to a logical NOT and will invert the 
resulting match. Hence "!default:chest*" would not match either "default:chest_locked" or
"default:chest", but it would match "default:bookshelf".

An additionally powerful feature is the ability to locate wielded and dropped items
without having to examine the property tables of entities such as "__builtin:item" or
"itemframes:visual". Simply prefix the registered item's name (or the name of the group) 
with a ":" as this example demonstrates:

   > minetest.find_objects_in_sphere( player:get_pos( ), 10.0,
   >         { "__builtin:item", ":buckets:bucket_*" }, "all" )

While Minetest does not formally recognize the concept of groups for entitites, I've
nonetheless included support for group-searches. If you wish to use this feature, then it
will be necessary to add a "groups" property to your entity definitions.

You'll want to start by modifying "builtin/game/item_entity.lua" as follows:

   > core.register_entity(":__builtin:item", {
   >         initial_properties = {
   >                 hp_max = 1,
   >                 physical = true,
   >                 collide_with_objects = false,
   >                 collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
   >                 visual = "wielditem",
   >                 visual_size = {x = 0.4, y = 0.4},
   >                 textures = {""},
   >                 spritediv = {x = 1, y = 1},
   >                 initial_sprite_basepos = {x = 0, y = 0},
   >                 is_visible = false,
   >         },
   >
   >         groups = {item = 1, dropped_item = 1},   -- add this line
   >         itemstring = "",
   >         moving_state = true,
   >         slippery_state = false,

Since there isn't yet a formal system of entity grouping, I'm using the following scheme
currently. But you are welcome to devise your own, depending on your needs.

 o Class of entities that represent a registered item (node, craftitem, or tool):
    - group:item

 o Subclass of 'group:item' entities
    - group:dropped_item
    - group:wielded_item
    - group:falling_node

 o Class of entitites that are non-interactive
    - group:visual

 o Class of entities that are capable of motion
    - group:mobile

 o Class of entities that have AI characteristics (including NPCs, monsters, etc.)
    - group:mob

 o Subclass of 'group:mob' entities
    - group:animal
    - group:human
    - group:monster
    - group:alien
    - group:walks
    - group:swims
    - group:flies

Just a few closing thoughts...

I've taken great care to optimize the functions above as much as possible. But
given that they are extending the CPP interface, they can only perform as well
as the inputs provided. So the most restrictive searches are always preferable.

As an added word of advice, if you'll be performing multiple searches on nodes
using the same globs, then the output of minetest.search_registered_nodes( )
should be cached in your mod for efficiency. After all, the resulting node
names will never change, so regenerating the list each time is unnecessary.

Unfortunately, such an optimization is not possible with entities due to the
nature of the search algorithm (as entities are post-processed). Ideally, all
of these functions may at some point be ported to CPP.


Repository
----------------------

Browse source code...
  https://bitbucket.org/sorcerykid/finder

Download archive...
  https://bitbucket.org/sorcerykid/finder/get/master.zip
  https://bitbucket.org/sorcerykid/finder/get/master.tar.gz

Installation
----------------------

  1) Unzip the archive into the mods directory of your game
  2) Rename the finder-master directory to "finder"
  3) Add "finder" as a dependency to any mods using the API

Source Code License
----------------------

MIT License

Copyright (c) 2020, Leslie E. Krause.

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

For more details:
https://opensource.org/licenses/MIT
