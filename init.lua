--------------------------------------------------------
-- Minetest :: Advanced Rangefinder Mod v1.0 (finder)
--
-- See README.txt for licensing and other information.
-- Copyright (c) 2016-2020, Leslie E. Krause
--
-- ./games/minetest_game/mods/finder/init.lua
--------------------------------------------------------

dofile( minetest.get_modpath( "finder" ) .. "/api.lua" )

local function locator( pos, size, color )
	minetest.add_particle( {
		pos = pos,
		vel = { x=0, y=0, z=0 },
		acc = { x=0, y=0, z=0 },
		exptime = 3.0,
		size = size,
		collisiondetection = false,
		vertical = true,
		texture = "wool_" .. color .. ".png",
	} )
end

local function show_results_viewer( player_name, source, region, radius, results )
	local page_idx = 1
	local page_size = 25

	local function get_formspec( )
		local formspec = string.format( "size[6.0,%0.1f]", 1.5 + math.min( #results, page_size ) * 0.4 )
			.. "position[0.8,0.5]"
			.. string.format( "label[0.0,0.0;Found %d %s within %s of radius %d:]", #results, source, region, radius )

		local off = 0.0
		for idx = ( page_idx - 1 ) * page_size + 1, math.min( page_idx * page_size, #results ) do
			local data = results[ idx ]

			if data.type == "player" then
				formspec = formspec
					.. string.format( "box[0.0,%0.1f;0.4,0.3;#FFFF00]", 0.6 + off )
					.. string.format( "image_button[0.0,%0.1f;0.6,0.4;;show:%s;;false;false]", 0.6 + off, idx )
					.. string.format( "label[0.5,%0.2f;Player '%s' at %d meters.]", 0.5 + off, data.name, data.dist )
				locator( data.obj:getpos( ), 8.0, "yellow" )
			elseif data.type == "entity" then
				formspec = formspec
					.. string.format( "box[0.0,%0.1f;0.4,0.3;#00FF00]", 0.6 + off )
					.. string.format( "image_button[0.0,%0.1f;0.6,0.4;;show:%s;;false;false]", 0.6 + off, idx )
					.. string.format( "label[0.5,%0.2f;Entity '%s' at %d meters.]", 0.5 + off, data.name, data.dist )
				locator( data.obj:getpos( ), 8.0, "green" )
			else
				formspec = formspec
					.. string.format( "box[0.0,%0.1f;0.4,0.3;#00FFFF]", 0.6 + off )
					.. string.format( "image_button[0.0,%0.1f;0.6,0.4;;show:%s;;false;false]", 0.6 + off, idx )
					.. string.format( "label[0.5,%0.2f;Node '%s' at %d meters.]", 0.5 + off, data.name, data.dist )
				locator( vector.offset( data.pos, 0.0, 0.55, 0.0 ), 2.5, "cyan" )
				locator( vector.offset( data.pos, 0.0, -0.55, 0.0 ), 2.5, "cyan" )
				locator( vector.offset( data.pos, 0.55, 0.0, 0.0 ), 2.5, "cyan" )
				locator( vector.offset( data.pos, -0.55, 0.0, 0.0 ), 2.5, "cyan" )
				locator( vector.offset( data.pos, 0.5, 0.0, 0.55 ), 2.5, "cyan" )
				locator( vector.offset( data.pos, 0.5, 0.0, -0.55 ), 2.5, "cyan" )
			end

			off = off + 0.4
		end

		formspec = formspec
			.. string.format( "button[0.0,%0.1f;2,0.3;export;Export]", off + 1.0 )
			.. string.format( "button[2.0,%0.1f;1,0.3;prev;<<]", off + 1.0 )
			.. string.format( "label[3.0,%0.1f;%d of %d]", off + 1.0, page_idx, math.max( math.ceil( #results / page_size ) ) )
			.. string.format( "button[4.0,%0.1f;1,0.3;next;>>]", off + 1.0 )

		return formspec
	end

	local function on_close( meta, player, fields )
		if fields.quit then return end

		if fields.export then
			--
		elseif fields.prev then
			if page_idx > 1 then
				page_idx = page_idx - 1
				minetest.update_form( player_name, get_formspec( ) )
			end
		elseif fields.next then
			if page_idx < #results / page_size then
				page_idx = page_idx + 1
				minetest.update_form( player_name, get_formspec( ) )
			end
		else
			local fname = next( fields, nil )     -- use next since we only care about the name of a single button
			local fval = string.match( fname, "show:(.+)" )

			if fval then
				local data = results[ tonumber( fval ) ]
				if data.type == "player" then
					locator( data.obj:getpos( ), 8.0, "yellow" )
				elseif data.type == "entity" then
					locator( data.obj:getpos( ), 8.0, "green" )
				else
					locator( vector.offset( data.pos, 0.0, 0.55, 0.0 ), 2.5, "cyan" )
					locator( vector.offset( data.pos, 0.0, -0.55, 0.0 ), 2.5, "cyan" )
					locator( vector.offset( data.pos, 0.55, 0.0, 0.0 ), 2.5, "cyan" )
					locator( vector.offset( data.pos, -0.55, 0.0, 0.0 ), 2.5, "cyan" )
					locator( vector.offset( data.pos, 0.5, 0.0, 0.55 ), 2.5, "cyan" )
					locator( vector.offset( data.pos, 0.5, 0.0, -0.55 ), 2.5, "cyan" )
				end
			end
		end
	end

	minetest.create_form( nil, player_name, get_formspec( ), on_close )
end

minetest.register_chatcommand( "finder", {
	description = "Find various nodes or objects inside a sphere or cuboid region.",
	privs = { server = true },
	func = function( player_name, param )
		local player = minetest.get_player_by_name( player_name )
		local args = string.split( param, " " )

		if #args == 0 then
			return false "Invalid parameters supplied!"

		elseif args[ 1 ] == "objects" then
			local region, radius, player_names, entity_globs, search_logic, has_parent
			local pos = player:getpos( )
			local options = { }
			local results = { }

			if #args ~= 7 then
				return false, "Usage: /finder objects [region] [radius] [player_names] [entity_globs] [search_logic] [has_parent]"
			end

			region = ( { sphere = "sphere" } )[ args[ 2 ] ]
			if region == nil then return false, "Invalid 'region' parameter specified!" end

			radius = tonumber( args[ 3 ] )
			if radius == nil then return false, "Invalid 'radius' parameter specified!" end

			if args[ 4 ] ~= "nil" and string.find( args[ 4 ], "^{.*}$" ) then
				player_names = string.split( string.sub( args[ 4 ], 2, -2 ) )
				if player_names == nil then return false, "Invalid 'player_names' parameter specified!" end
			end
			if args[ 5 ] ~= "nil" and string.find( args[ 5 ], "^{.*}$" ) then
				entity_globs = string.split( string.sub( args[ 5 ], 2, -2 ) )
				if entity_globs == nil then return false, "Invalid 'entity_globs' parameter specified!" end
			end
			if args[ 6 ] ~= "nil" then
				search_logic = ( { any = "any", all = "all" } )[ args[ 6 ] ]
				if search_logic == nil then return false, "Invalid 'search_logic' parameter specified!" end
			end
			if args[ 7 ] ~= "nil" then
				options.has_parent = ( { ["true"] = true, ["false"] = false } )[ args[ 7 ] ]
				if options.has_parent == nil then return false, "Invalid 'has_parent' parameter specified!" end
			end

			if region == "sphere" then
				results = minetest.find_objects_in_sphere( pos, radius, player_names, entity_globs, search_logic, options )
			elseif region == "cuboid" then
				results = minetest.find_objects_in_cuboid( pos, radius, radius, player_names, entity_globs, search_logic, options )
			end

			show_results_viewer( player_name, "objects", region, radius, results )

		elseif args[ 1 ] == "nodes" then
			local region, radius, node_globs, search_logic
			local pos = player:getpos( )
			local results = { }

			if #args ~= 5 then
				return false, "Usage: /finder nodes [region] [radius] [node_globs] [search_logic]"
			end

			region = ( { sphere = "sphere", cuboid = "cuboid" } )[ args[ 2 ] ]
			if region == nil then return false, "Invalid 'region' parameter specified!" end

			radius = tonumber( args[ 3 ] )
			if radius == nil then return false, "Invalid 'radius' parameter specified!" end

			if args[ 4 ] ~= "nil" and string.find( args[ 4 ], "^{.*}$" ) then
				node_globs = string.split( string.sub( args[ 4 ], 2, -2 ) )
				if node_globs == nil then return false, "Invalid 'node_globs' parameter specified!" end
			end
			if args[ 5 ] ~= "nil" then
				search_logic = ( { any = "any", all = "all" } )[ args[ 5 ] ]
				if search_logic == nil then return false, "Invalid 'search_logic' parameter specified!" end
			end

			local node_names = minetest.search_registered_nodes( node_globs, search_logic )

			if region == "sphere" then
				results = minetest.find_nodes_in_sphere( pos, radius, node_names )
			elseif region == "cuboid" then
				results = minetest.find_nodes_in_cuboid( pos, radius, radius, node_names )
			end

			show_results_viewer( player_name, "nodes", region, radius, results )
		end

		return true
	end
} )

--[[
find_objects_in_sphere( pos, 5, { }, { "!group:*" } )		find only entities that do not have a group
find_objects_in_sphere( pos, 5, { "!sorcerykid" }, { } )	find only players not named 'sorcerykid'
find_objects_in_sphere( pos, 5, { }, { "mobs:*" } )		find only entities registered with the Mobs Redo API
find_objects_in_sphere( pos, 5, { "__builtin:item" ) 		find only dropped items
find_objects_in_sphere( pos, 5, { ":*:*" )			same as above, but somewhat obfuscated
find_objects_in_sphere( pos, 5, { "group:dropped_item",":default:apple", "all" )	find only dropped items named "default:apple"
find_objects_in_sphere( pos, 5, { "group:mob", "!group:animal" }, "all" ) 		find only entities that are not in the "mob_animal" group but are in the "mob" group
]]
