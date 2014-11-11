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

local function fill_with_ignore(minp, maxp)
	local ignore = minetest.get_content_id("mapgen_lib:ignore")
	local data, area = mapgen.get_voxel_data(minp, maxp)
	for x = minp.x, maxp.x do
	for y = minp.y, maxp.y do
	for z = minp.z, maxp.z do
		data[area:index(x, y, z)] = ignore
	end
	end
	end
	mapgen.set_voxel_data(minp, maxp, data, false)
end

local function fill_with_air(minp, maxp, data, area)
	local air = minetest.get_content_id("air")
	for x = minp.x, maxp.x do
	for y = minp.y, maxp.y do
	for z = minp.z, maxp.z do
		data[area:index(x, y, z)] = air
	end
	end
	end
end

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
		fill_with_ignore(minp, maxp)
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

function mapgen.generate(minp, maxp, seed)
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
	-- convert ignore to air
	fill_with_air(minp, maxp, data, area)
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

-- allow the main player to regenerate a chunk
minetest.register_chatcommand("regen", {
	params = "size",
	description = "Regenerate a chunk",
	func = function(name, param)
		if name == mapgen.main_player then
			local size = (tonumber(param) or 80) - 1
			local minp = minetest.get_player_by_name(name):getpos()
			minp.x, minp.y, minp.z = math.round(minp.x - size / 2), math.round(minp.y - size / 2), math.round(minp.z - size / 2)
			local maxp = vector.add(minp, size)
			mapgen.generate(minp, maxp, mapgen.seed, true)
		end
		return true, "Regenerated"
	end,
})

function mapgen.get_voxel_manip(minp, maxp)
	local manip = minetest.get_voxel_manip()
	local emin, emax = manip:read_from_map(minp, maxp)
	local area = minetest.voxel_area(emin, emax)
	return manip, area
end

function mapgen.check_voxelmanip(minp, maxp)
	local vminp, vmaxp = mapgen.vm[1], mapgen.vm[2]
	return vminp and vmaxp
		and vminp.x == minp.x
		and vminp.y == minp.y
		and vminp.z == minp.z
		and vmaxp.x == maxp.x
		and vmaxp.y == maxp.y
		and vmaxp.z == maxp.z
end

function mapgen.get_voxel_data(minp, maxp)
	if mapgen.check_voxelmanip(minp, maxp) then
		local vm = mapgen.vm[3]
		return vm:get_data(), mapgen.vm[4]
	else
		local vm, area = mapgen.get_voxel_manip(minp, maxp)
		mapgen.vm = {minp, maxp, vm, area}
		return vm:get_data(), area
	end
end

function mapgen.get_voxel_light_data(minp, maxp)
	if mapgen.check_voxelmanip(minp, maxp) then
		local vm = mapgen.vm[3]
		return vm:get_light_data(), mapgen.vm[4]
	else
		local vm, area = mapgen.get_voxel_manip(minp, maxp)
		mapgen.vm = {minp, maxp, vm, area}
		return vm:get_light_data(), area
	end
end

function mapgen.get_voxel_param2_data(minp, maxp)
	if mapgen.check_voxelmanip(minp, maxp) then
		local vm = mapgen.vm[3]
		return vm:get_param2_data(), mapgen.vm[4]
	else
		local vm, area = mapgen.get_voxel_manip(minp, maxp)
		mapgen.vm = {minp, maxp, vm, area}
		return vm:get_param2_data(), area
	end
end

function mapgen.set_voxel_data(minp, maxp, data, calc_light)
	if mapgen.check_voxelmanip(minp, maxp) then
		local vm = mapgen.vm[3]
		vm:set_data(data)
		if calc_light then
			vm:calc_lighting()
		end
		vm:write_to_map()
		vm:update_map()
	else
		local vm, area = mapgen.voxel_area()
		mapgen.vm = {minp, maxp, vm, area}
		vm:set_data(data)
		if calc_light then
			vm:calc_lighting()
		end
		vm:write_to_map()
		vm:update_map()
	end
end

function mapgen.set_voxel_light_data(minp, maxp, data)
	if mapgen.check_voxelmanip(minp, maxp) then
		local vm = mapgen.vm[3]
		vm:set_light_data(data)
		vm:write_to_map()
		vm:update_map()
	else
		local vm, area = mapgen.voxel_area()
		mapgen.vm = {minp, maxp, vm, area}
		vm:set_light_data(data)
		vm:write_to_map()
		vm:update_map()
	end
end

function mapgen.set_voxel_param2_data(minp, maxp, data)
	if mapgen.check_voxelmanip(minp, maxp) then
		local vm = mapgen.vm[3]
		vm:set_param2_data(data)
		vm:write_to_map()
		vm:update_map()
	else
		local vm, area = mapgen.voxel_area()
		mapgen.vm = {minp, maxp, vm, area}
		vm:set_param2_data(data)
		vm:write_to_map()
		vm:update_map()
	end
end
