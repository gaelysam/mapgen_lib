mapgen = {}
mapgen.generated_in_singlenode = {}
mapgen.start = false
mapgen.seed = 0
mapgen.time = 0
mapgen.chunks = 0

function load_modfile(...)
	for _, file in ipairs({...}) do
		local mod = minetest.get_current_modname()
		local path = minetest.get_modpath(mod) .. "/" .. file
		dofile(path)
	end
end

load_modfile("voxelarea.lua", "generate.lua", "metadata.lua", "noise.lua")

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
