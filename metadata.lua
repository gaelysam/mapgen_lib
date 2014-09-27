mapgen.metadata = {}

-- used to store data
function mapgen.serialize(...)
	return minetest.serialize({...})
end

function mapgen.deserialize(str)
	return unpack(minetest.deserialize(str))
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

-- write metadata to map
minetest.register_on_shutdown(function()
	local file = io.open(minetest.get_worldpath() .. "/mapgen.txt", "w")
	file:write(mapgen.serialize(mapgen.chosen, mapgen.time, mapgen.chunks, mapgen.metadata, mapgen.main_player))
	file:close()
	print("Average map generation time : " .. math.round(mapgen.average_time(), 0.001) .. " seconds")
end)

-- load metadata
local file = io.open(minetest.get_worldpath() .. "/mapgen.txt", "r")
if file then
	mapgen.chosen, mapgen.time, mapgen.chunks, mapgen.metadata, mapgen.main_player = mapgen.deserialize(file:read("*a"))
	file:close()
	mapgen.load_file(mapgen.chosen)
	mapgen.start = true
end
