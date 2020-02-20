Advanced Rangefinder Mod v1.1
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

   For more advanced searches, a matching function may be used instead. Each parameter
   corresponds to the respective node glob and will be assigned true or false depending
   on the comparison result. This function should return true for a successful match.

   Example:
   > node_globs = { "group:liquid", "!default:lava_source", "!default:water_source" }
   > match_func = function ( a, b, c ) return a and ( b or c ) end
   > res = minetest.search_registered_nodes( node_globs, match_func )

 * minetest.find_nodes_in_sphere( pos, radius, node_names )
   This is a wrapper function for minetest.find_nodes_in_area( ) that provides a means to
   locate nodes by name in a spherical region. The output is a table:
    * name = the name of the node
    * node - the node
    * pos - the node position
    * dist - the distance to the node
    * groups - the groups belonging to the node

 * minetest.find_nodes_in_cuboid( pos, radius, height, node_names )
   This is a wrapper function for minetest.find_nodes_in_area( ) that provides a means to
   locate nodes by name in a cubicle region. The output is the same as above.

 * minetest.find_objects_in_sphere( pos, radius, player_names, entity globs,
           search_logic, search_options )
   Since the builtin API of Minetest does not provide a means to locate entities by name
   or group, this function fulfills that purpose. It supports the same two boolean search
   modes as minetest.search_registered_nodes( ). The output is a table:
    * name - the name of the entity or player
    * obj - the ObjectRef of the entity or player
    * pos - the object position
    * dist - the distance to the object
    * groups - the groups belonging to the entity (nil for players)

   If either the player names or entity globs are nil, then all players or entities in the 
   given range will match accordingly. However, supplying an empty list will match none.
   Currently, the only supported search option is 'is_attached' which is a boolean
   indicating whether attached entities should be included.

 * minetest.search_registered_entities( entity_globs, search_logic )
   Returns the names of all registered entities that match the given list of globs. The 
   output of this function may be passed to minetest.find_entities_in_sphere( ) below.

 * minetest.find_entities_in_sphere( pos, radius, entity_names )
   This is a lightweight alternative to minetest.find_objects_in_sphere( ). It expects a
   list of entity names which may be obtained via minetest.search_registered_entities( ).

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

While Minetest does not formally recognize the concept of groups for entities, I've
nonetheless included support for group-searches. In order to use this feature, it will be 
necessary to add a "groups" property to your entity definitions.

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

 o Class of entities that are for visualization (including signs, markers, etc.)
    - group:visual

 o Subclass of 'group:visual' entities
    - group:sign
    - group:marker

 o Class of entities that are capable of motion
    - group:mobile

 o Class of entities that have AI characteristics (including NPCs, monsters, etc.)
    - group:mob

 o Subclass of 'group:mob' entities
    - group:animal
    - group:human
    - group:monster
    - group:alien
    - group:walking
    - group:swimming
    - group:flying

The "/find" chat command offers a convenient front-end to the search functionality.

   /finder objects sphere [radius] [player_names] [entity_globs] [search_logic]

   /finder nodes [region] [radius] [node_globs] [search_logic]

For node searches, the region can be either "sphere" or "cuboid". The player names,
entity globs, and node_globs lists should be surrounded by braces. To eliminate any
parameter simply specify "nil". For example, to find all nearby dirt nodes, enter

   /finder nodes sphere 5.0 {default:dirt*} nil 

Just a few closing thoughts...

I've taken great care to optimize the functions above as much as possible. However, given 
that they are extending the CPP interface, they can only perform as well as the inputs 
provided. So the most restrictive searches are always preferable.

Also keep in mind, if you need to perform multiple searches for the same node globs or 
entity globs, then be sure to cache the output of minetest.search_registered_nodes( ) or 
minetest.search_registered_entities( ) for efficiency. After all, the resulting node and
and entity names won't change, so regenerating these lists every time is unnecessary.


Repository
----------------------

Browse source code...
  https://bitbucket.org/sorcerykid/finder

Download archive...
  https://bitbucket.org/sorcerykid/finder/get/master.zip
  https://bitbucket.org/sorcerykid/finder/get/master.tar.gz

Compatability
----------------------

Minetest 0.4.15+ required

Dependencies
----------------------

ActiveFormspecs Mod (optional)
  https://bitbucket.org/sorcerykid/formspecs

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
