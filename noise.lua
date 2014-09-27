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
	return mapgen.noise2d(area.MinEdge, area.MaxEdge, offset, scale, pos3d(spread, 20), seed, octaves, persist)
end
