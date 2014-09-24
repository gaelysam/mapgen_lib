mapgen = {}
mapgen.generated_in_singlenode = {}
mapgen.start = false
mapgen.seed = 0
mapgen.time = 0
mapgen.chunks = 0
mapgen.metadata = {}

function load_modfile(file)
	local mod = minetest.get_current_modname()
	local path = minetest.get_modpath(mod) .. "/" .. file
	dofile(path)
end

load_modfile("flatarea.lua")

function mapgen.load_file(filename)
	local path
	for _, mod in pairs(minetest.get_modnames()) do
		path = minetest.get_modpath(mod) .. "/mapgen/" .. filename
		local file = io.open(path, "r")
		if file then
			dofile(path)
			file:close()
			break
		end
	end
end

function mapgen.send(str, all)
	if all then
		minetest.chat_send_all(str)
	else
		minetest.chat_send_player(mapgen.main_player, str)
	end
	minetest.log("action", str)
end

-- Shortcut for "VoxelArea:new({MinEdge = minp, MaxEdge = maxp})"

function minetest.voxel_area(minp, maxp)
	return VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
end

function minetest.flat_area(minp, maxp)
	return FlatArea:new({MinEdge = minp, MaxEdge = maxp})
end

-- translate coordinates from an area (flat or voxel) to a second

function mapgen.translate(area1, area2, i, alt)
	local pos = pos3d(area1:position(i), alt or area2.MinEdge.y)
	if not area2:containsp(pos) then
		return
	else
		return area2:indexp(pos)
	end
end

-- Including this function in classes
VoxelArea.translate = mapgen.translate
FlatArea.translate = mapgen.translate

-- used for storing datas
function mapgen.serialize(...)
	return minetest.serialize({...})
end

function mapgen.deserialize(str)
	return unpack(minetest.deserialize(str))
end

-- easier way to get perlin maps
function mapgen.noise2d(minp, maxp, offset, scale, spread, seed, octaves, persist)
	return minetest.get_perlin_map({offset = offset, scale = scale, spread = spread, seed = seed, octaves = octaves, persist = persist}, {x = maxp.x - minp.x + 1, y = maxp.y - minp.y + 1, z = 1}):get2dMap_flat(pos2d(minp))
end

function mapgen.noise3d(minp, maxp, offset, scale, spread, seed, octaves, persist)
	return minetest.get_perlin_map({offset = offset, scale = scale, spread = spread, seed = seed, octaves = octaves, persist = persist}, {x = maxp.x - minp.x + 1, y = maxp.y - minp.y + 1, z = maxp.z - minp.z + 1}):get3dMap_flat(minp)
end

-- Getting perlin maps from areas
function VoxelArea.noise(area, offset, scale, spread, seed, octaves, persist)
	return mapgen.noise3d(area.MinEdge, area.MaxEdge, offset, scale, spread, seed, octaves, persist)
end

function FlatArea.noise(area, offset, scale, spread, seed, octaves, persist)
	spread = pos3d(spread, math.max(spread.x, spread.y))
	return mapgen.noise2d(area.MinEdge, area.MaxEdge, offset, scale, spread, seed, octaves, persist)
end

-- to get only the y coordinate ; faster
function VoxelArea.altitude(area, i)
	i = (i - 1) % area.zstride
	return math.floor(i / area.ystride) + area.MinEdge.y
end

-- data storage : mapgen metadata
function mapgen.define_map_meta(field, value)
	if mapgen.metadata[field] == nil then
		mapgen.metadata[field] = value
	end
end

function mapgen.set_map_meta(field, value)
	mapgen.metadata[field] = value
end

function mapgen.increment_map_meta(field)
	mapgen.metadata[field] = mapgen.metadata[field] + 1
end

function mapgen.get_map_meta(...)
	local t = {}
	for key, val in pairs({...}) do
		t[key] = mapgen.metadata[val]
	end
	return unpack(t)
end

minetest.register_on_mapgen_init(function(params)
	mapgen.seed = params.seed
	minetest.set_mapgen_params({mgname = "singlenode"})
	minetest.registered_on_generateds = {mapgen.pregenerate}
end)

function mapgen.get_table_ids(nodes) -- nodes can be an itemstring or a table
	local t = {}
	for n, node in pairs(nodes) do
		if type(node) == "string" then
			t[n] = minetest.get_content_id(node)
		else
			t[n] = mapgen.get_table_ids(node)
		end
	end
	return t
end

-- unpacked ids
function mapgen.get_ids(...)
	return unpack(mapgen.get_table_ids({...}))
end

function mapgen.choose(name)
	mapgen.chosen = name
end

-- GENERATE A MAP

function mapgen.pregenerate(minp, maxp, seed)
	if mapgen.start then -- Mapgen already started
		mapgen.generate(minp, maxp, seed)
	else
		-- mapgen not started : generate air
		local message = minetest.pos_to_string(minp) .."|".. minetest.pos_to_string(maxp)
		print("Singlenode : " .. message)
		table.insert(mapgen.generated_in_singlenode, message)
		if mapgen.first then
			mapgen.send("GUI calls", false)
			if mapgen.chosen then -- is there an already chosen mapgen file ?
				mapgen.send("Loading file : " .. mapgen.chosen, false)
				mapgen.load_file(mapgen.chosen)
				-- show params formspec
				if mapgen.formspec then
					mapgen.send("Showing params", false)
					minetest.show_formspec(mapgen.main_player, "mapgen_params", mapgen.formspec)
				else
					-- the selected mapgen has no params
					mapgen.send("No required GUI", false)
					mapgen.begin()
				end
			else
				-- mapgen not already selected
				mapgen.send("Showing mapgen dialog", false)
				mapgen.show_formspec(mapgen.main_player)
			end
			mapgen.first = false
		end
		-- make a spawn platform if the mapgen isn't begun
		for x = -2, 2 do
			for z = -2, 2 do
				minetest.set_node({x = x, y = -2, z = z}, {name = "default:dirt_with_grass"})
			end
		end
	end
end

function mapgen.show_formspec(player)
	minetest.show_formspec(player, "mapgen", "field[file;File;.lua]")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.quit then -- don't do anything if the window isn't closed
		player = player:get_player_name()
		local dirdelim = DIR_DELIM or "/"
		if formname == "mapgen_params" then
			for key, value in pairs(fields) do
				mapgen.metadata[key] = tonumber(value) or value -- store mapgen params in metadata
			end
			mapgen.begin() -- start the mapgen
		elseif formname == "mapgen" then
			mapgen.chosen = fields.file
			mapgen.send("Loading file : " .. mapgen.chosen, false)
			mapgen.load_file(mapgen.chosen)
			if mapgen.formspec then
				mapgen.send("Showing params", false)
				minetest.show_formspec(player, "mapgen_params", mapgen.formspec)
			else
				mapgen.begin()
			end
		end
	end
end)

function mapgen.begin()
	mapgen.send("Starting map generation", true)
	mapgen.start = true
	local count = #mapgen.generated_in_singlenode
	for i = 1, count do -- regenerate all of the pregenerated chunks
		local chunk = mapgen.generated_in_singlenode[i]
		local minp,maxp = string.match(chunk, "(.+)%|(.+)")
		minp, maxp = minetest.string_to_pos(minp), minetest.string_to_pos(maxp)
		mapgen.generate(minp, maxp, mapgen.seed)
		if i == count then
			mapgen.send("Map generation complete", true)
		else
			mapgen.send("Generating map : " .. math.floor(100 * i / count) .. " %", false)
		end
	end
	for _, player in ipairs(minetest.get_connected_players()) do -- spawn players
		player:setpos(mapgen.spawn_player(player, mapgen.seed))
	end
end

function mapgen.generate(minp, maxp, seed, delete)
	print("Preparing to map generation")
	local time1 = os.clock()
	-- mapgen stuff
	local air = minetest.get_content_id("air")
	local manip = minetest.get_voxel_manip()
	local emin, emax = manip:read_from_map(minp, maxp)
	local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local data = manip:get_data()
	local param = manip:get_light_data()
	local param2 = manip:get_param2_data()
	-- delete the spawn platform
	if area:contains(0, -2, 0) then
		for x = -2, 2 do
			for z = -2, 2 do
				local index = area:index(x, -2, z)
				data[index] = air
			end
		end
	end
	-- delete the old map in case of chatcommand /regen
	if delete then
		print("Removing old map")
		for x = minp.x, maxp.x do
		for y = minp.y, maxp.y do
		for z = minp.z, maxp.z do
			data[area:index(x, y, z)] = air
		end
		end
		end
	end
	print("Map generation : from " .. minetest.pos_to_string(minp) .. " to " .. minetest.pos_to_string(maxp))
	print("Data collecting")
	local time2 = os.clock()
	-- the core of the mod : run the on_generated function
	local data_after, param_after, param2_after = mapgen.on_generated(minp, maxp, data, param, param2, area, seed)
	print("Data writing")
	local time3 = os.clock()
	-- write datas down to the map
	data, param, param2 = data_after or data, param_after or param, param2_after or param2
	manip:set_data(data)
	manip:set_param2_data(param2)
	manip:update_liquids()
	if param == true then -- lighting
		manip:calc_lighting()
	else
		manip:set_light_data(param)
	end
	manip:write_to_map()
	manip:update_map()
	print("Generating complementary structures")
	local time4 = os.clock()
	-- calling after_generated
	mapgen.after_generated(minp, maxp, seed)
	local time5 = os.clock()
	-- timing stuff
	print("Map generation finished in " .. math.round(time5 - time1, 0.001) .. " seconds :")
	mapgen.time = mapgen.time + time5 - time1
	mapgen.chunks = mapgen.chunks + 1
	print(math.round(time2 - time1, 0.001) .. " ; " .. math.round(time3 - time2, 0.001) .. " ; " .. math.round(time4 - time3, 0.001) .. " ; " .. math.round(time5 - time4, 0.001))
end

minetest.register_on_newplayer(function(player)
	if #minetest.get_connected_players() == 0 and not mapgen.start then
		mapgen.main_player = player:get_player_name()
	elseif mapgen.start then
		player:setpos(mapgen.spawn_player(player, mapgen.seed))	
	else
		player:setpos({x = 0, y = 0, z = 0})
	end
end)

-- write metadatas to map
minetest.register_on_shutdown(function()
	local file = io.open(minetest.get_worldpath() .. "/mapgen.txt", "w")
	file:write(mapgen.serialize(mapgen.chosen, mapgen.time, mapgen.chunks, mapgen.metadata, mapgen.main_player))
	file:close()
	print("Average map generation time : " .. math.round(mapgen.average_time(), 0.001) .. " seconds")
end)

-- load metadatas
local file = io.open(minetest.get_worldpath() .. "/mapgen.txt", "r")
if file then
	mapgen.chosen, mapgen.time, mapgen.chunks, mapgen.metadata, mapgen.main_player = mapgen.deserialize(file:read("*a"))
	file:close()
	mapgen.load_file(mapgen.chosen)
	mapgen.start = true
end

mapgen.first = not mapgen.start

mapgen.on_generated = mapgen.on_generated or function(minp, maxp, data, param, param2, area, seed) return data, param, param2 end
mapgen.after_generated = mapgen.after_generated or function() end
mapgen.spawn_player = mapgen.spawn_player or function(player) return player:getpos() end

function mapgen.average_time()
	return mapgen.time / mapgen.chunks
end

function math.round(n, div)
	div = div or 1
	return div * math.floor(n / div + 0.5)
end

function tobool(val)
	if val then
		return true
	else
		return false
	end
end

-- allow the main player to regenerate a chunk
minetest.register_chatcommand("regen", {
	params = "size",
	description = "Regenerate a chunk",
	func = function(name, param)
		if minetest.check_player_privs(name, {server=true}) then
			local size = (tonumber(param) or 80) - 1
			local minp = minetest.get_player_by_name(name):getpos()
			minp.x, minp.y, minp.z = math.round(minp.x - size / 2), math.round(minp.y - size / 2), math.round(minp.z - size / 2)
			local maxp = vector.add(minp, size)
			mapgen.generate(minp, maxp, mapgen.seed, true)
		end
		return true, "Regenerated"
	end,
})

function minetest.add_group(groupname, ...)
	local items = {...}
	if #items == 1 then
		items = items[1]
	end
	for i, a in pairs(items) do
		local value = 1
		local item = a
		if type(i) == "string" then
			item = i
			value = a
		end
		local def = minetest.registered_items[item]
		def.groups = def.groups or {}
		def.groups[groupname] = value
		minetest.override_item(item, {groups = def.groups})
	end
end
