--------------------------------------------------------
-- Minetest :: Advanced Rangefinder Mod v1.0 (finder)
--
-- See README.txt for licensing and other information.
-- Copyright (c) 2020, Leslie E. Krause
--
-- ./games/minetest_game/mods/finder/init.lua
--------------------------------------------------------

local converter = {
	["*"] = "[^:]*",
	["+"] = "[^:]+",
	["?"] = "[^:]?",
}

---------------------
-- private methods --
---------------------

local function hash_values( list )
	local map = { }
	for idx, val in ipairs( list ) do
		map[ val ] = true
	end
	return map
end

local function compare( text, prefix, suffix )
	return string.find( text, "^" .. prefix .. ":" .. suffix .. "$" ) ~= nil
end

local function compare_groups( groups, suffix )
	for text in pairs( groups ) do
		if string.find( text, "^" .. suffix  .. "$" ) then
			return true
		end
	end
	return false
end

local function parse_entity_globs( entity_globs )
	if not entity_globs then return nil end

	-- build a cache of globs derived from the `entity_globs` list
	local raw_entity_globs = { }

	for _, val in ipairs( entity_globs ) do
		local res = { string.match( val, "^(!?)(:?)([?+*a-z0-9_]*):([?+*a-z0-9_]*)$" ) }
		local prefix = string.gsub( res[ 3 ], ".", converter )
		local suffix = string.gsub( res[ 4 ], ".", converter )
		local is_inverse = res[ 1 ] == "!"   -- match inverse logic?
		local is_dropped = res[ 2 ] == ":"   -- match dropped items?

		table.insert( raw_entity_globs,
			{ prefix = prefix, suffix = suffix, is_inverse = is_inverse, is_dropped = is_dropped }
		)
	end

	return raw_entity_globs
end

local function search_registered_assets_raw( registered_assets, asset_globs, search_logic )
	local match_bool, match_func
	local raw_asset_globs = { }
	local asset_names = { }

	if type( search_logic ) == "function" then
		match_func = search_logic
	else
		match_bool = ( { any = true, all = false } )[ search_logic or "any" ]
	end

	for _, val in ipairs( asset_globs ) do
		local res = { string.match( val, "^(!?)([?+*a-z0-9_]*):([?+*a-z0-9_]*)$" ) }
		local prefix = string.gsub( res[ 2 ], ".", converter )
		local suffix = string.gsub( res[ 3 ], ".", converter )
		local is_inverse = res[ 1 ] == "!"   -- match inverse logic?

		table.insert( raw_asset_globs, { prefix = prefix, suffix = suffix, is_inverse = is_inverse } )
	end

	for name, def in pairs( registered_assets ) do
		local groups = def.groups or { }

		if not match_func then
			local is_match = false

			for _, v in ipairs( raw_asset_globs ) do
				if v.prefix == "group" then
					is_match = compare_groups( groups, v.suffix ) ~= v.is_inverse
				else
					is_match = compare( name, v.prefix, v.suffix ) ~= v.is_inverse
				end
				if is_match == match_bool then break end   -- short circuit boolean logic
			end

			if is_match then
				table.insert( asset_names, name )
			end
		else
			local matches = { }

			for _, v in ipairs( raw_asset_globs ) do
				if v.prefix == "group" then
					table.insert( matches, compare_groups( groups, v.suffix ) ~= v.is_inverse )
				else
					table.insert( matches, compare( name, v.prefix, v.suffix ) ~= v.is_inverse )
				end
			end

			if match_func( unpack( matches ) ) then
				table.insert( asset_names, name )
			end
		end
	end

	return asset_names
end

--------------------
-- public methods --
--------------------

minetest.locator = function ( results, color, exptime )
	if not color then color = "white" end
	if not exptime then exptime = 4.0 end

	for _, data in ipairs( results ) do
		if data.type == "player" or data.type == "entity" then
		        minetest.add_particle( {
                		pos = data.pos,
		                vel = { x = 0, y = 0, z = 0 },
                		acc = { x = 0, y = 0, z = 0 },
		                exptime = exptime,
                		size = 8.0,
		                collisiondetection = false,
                		vertical = true,
		                texture = "wool_" .. color .. ".png",
		        } )
		end
	end
end

minetest.find_entities_in_sphere = function ( sphere_pos, sphere_radius, has_players, entity_names, options )
	assert( type( sphere_pos ) == "table" )
	assert( type( sphere_radius ) == "number" )
	assert( type( has_players ) == "boolean" )
	assert( type( entity_names ) == "table" )

	local results = { }
	local entities = hash_values( entity_names )

	if not options then options = { } end

	for _, obj in ipairs( minetest.get_objects_inside_radius( sphere_pos, sphere_radius ) ) do
		local pos = obj:getpos( )

		if obj:is_player( ) then
			local name = obj:get_player_name( )
			local dist = vector.distance( sphere_pos, pos )
			local elem = { obj = obj, pos = pos, dist = dist, name = name, type = "player" }

			table.insert( results, elem )

		elseif not obj:get_attach( ) or options.has_parent then
			local name = obj:get_luaentity( ).name
			local dist = vector.distance( sphere_pos, pos )
			local elem = { obj = obj, pos = pos, dist = dist, name = name, type = "entity" }

			if entities[ name ] then
				table.insert( results, elem )
			end
		end
	end

	return results
end

minetest.find_objects_in_sphere = function ( sphere_pos, sphere_radius, player_names, entity_globs, search_logic, options )
	assert( type( sphere_pos ) == "table" )
	assert( type( sphere_radius ) == "number" )
	assert( player_names == nil or type( player_names ) == "table" )
	assert( entity_globs == nil or type( entity_globs ) == "table" )

	local raw_entity_globs = parse_entity_globs( entity_globs )
	local match_func, match_bool
	local results = { }

	if not options then options = { } end

	if type( search_logic ) == "function" then
		match_func = search_logic
	else
		match_bool = ( { any = true, all = false } )[ search_logic or "any" ]
	end

	for _, obj in ipairs( minetest.get_objects_inside_radius( sphere_pos, sphere_radius ) ) do
		local pos = obj:getpos( )

		if obj:is_player( ) then
			local name = obj:get_player_name( )
			local dist = vector.distance( sphere_pos, pos )
			local elem = { obj = obj, pos = pos, dist = dist, name = name, type = "player" }

			if not player_names then
				-- always include players, if `player_names` is nil
				table.insert( results, elem )
			else
				for _, val in ipairs( player_names ) do
					local is_inverse = string.byte( val, 1 ) == 33	 -- invert match
					local phrase = string.match( val, "!?(.+)" )

					if ( phrase == name ) ~= is_inverse then
						table.insert( results, elem )
					end
				end
			end

		elseif not obj:get_attach( ) or options.has_parent then
			local entity = obj:get_luaentity( )
			local groups = entity.groups or { }
			local name = entity.name
			local dist = vector.distance( sphere_pos, pos )
			local elem = { obj = obj, pos = pos, dist = dist, name = name, type = "entity", groups = groups }

			if not entity_globs then
				-- always include entities, if `entity_globs` is nil
				table.insert( results, elem )
			else
				local item_name = ""
				local item_groups = { }

				if groups.item then
					-- any entity in the `item` group must have an `itemstring` property
					local defs = minetest.registered_items

					item_name = string.split( entity.itemstring, " " )[ 1 ]
					item_groups = defs[ item_name ] and defs[ item_name ].groups or { }
				end

				if not match_func then
					local is_match = false

					for _, v in ipairs( raw_entity_globs ) do
						if v.prefix == "group" then
							is_match = compare_groups( v.is_dropped and item_groups or groups, v.suffix ) ~= v.is_inverse
						else
							is_match = compare( v.is_dropped and item_name or name, v.prefix, v.suffix ) ~= v.is_inverse
						end
						if is_match == match_bool then break end   -- short circuit boolean logic
					end

					if is_match then
						table.insert( results, elem )
					end
				else
					local matches = { }

					for _, v in ipairs( raw_entity_globs ) do
						if v.prefix == "group" then
							table.insert( matches,
								compare_groups( v.is_dropped and item_groups or groups, v.suffix ) ~= v.is_inverse )
						else
							table.insert( matches,
								compare( v.is_dropped and item_name or name, v.prefix, v.suffix ) ~= v.is_inverse )
						end
					end

					if match_func( unpack( matches ) ) then
						table.insert( results, elem )
					end
				end
			end
		end
	end

	return results
end

minetest.search_registered_entities = function ( entity_globs, search_logic )
	assert( type( entity_globs ) == "table" )
	assert( search_logic == nil or type( search_logic ) == "string" or type( search_logic ) == "function" )

	return search_registered_assets_raw( minetest.registered_entities, entity_globs, search_logic )
end

minetest.search_registered_nodes = function ( node_globs, search_logic )
	assert( type( node_globs ) == "table" )
	assert( search_logic == nil or type( search_logic ) == "string" or type( search_logic ) == "function" )

	return search_registered_assets_raw( minetest.registered_nodes, node_lobs, search_logic )
end

minetest.find_nodes_in_sphere = function ( sphere_pos, sphere_radius, node_names )
	local pos1 = vector.add( sphere_pos, -sphere_radius )
	local pos2 = vector.add( sphere_pos, sphere_radius )
	local results = { }

	for _, pos in ipairs( minetest.find_nodes_in_area( pos1, pos2, node_names ) ) do
		local node = minetest.get_node( pos )
		local ndef = minetest.registered_nodes[ node.name ]
		local dist = vector.distance( sphere_pos, pos )

		if ndef and dist <= sphere_radius then   -- ignore unknown nodes and nodes outside of radius
			local groups = ndef.groups or { }
			local name = node.name
			local elem = { node = node, pos = pos, dist = dist, name = name, groups = groups }

			table.insert( results, elem )
		end
	end

	return results
end

minetest.find_nodes_in_cuboid = function ( cuboid_pos, cuboid_radius, cuboid_height, node_names )
	local pos1 = vector.add( cuboid_pos, { x = -cuboid_radius, y = -cuboid_height, z = -cuboid_radius } )
	local pos2 = vector.add( cuboid_pos, { x = cuboid_radius, y = cuboid_height, z = cuboid_radius } )
	local results = { }

	for _, pos in ipairs( minetest.find_nodes_in_area( pos1, pos2, node_names ) ) do
		local node = minetest.get_node( pos )
		local ndef = minetest.registered_nodes[ node.name ]
		local dist = vector.distance( cuboid_pos, pos )

		if ndef then   -- ignore unknown nodes
			local groups = ndef.groups or { }
			local name = node.name
			local elem = { node = node, pos = pos, dist = dist, name = name, groups = groups }

			table.insert( results, elem )
		end
	end

	return results
end
