function mapgen.generate(minp, maxp, data, param, param2, area, seed)
	local stone, water = mapgen.get_ids("default:stone", "default:water_source")
	local noisearea = minetest.voxel_area(minp, maxp)	
	local flatarea = minetest.flat_area(minp, {x = maxp.x, y = maxp.y + 7, z = maxp.z)
	local noise1 = noisearea:noise(0, 1, {x = 512, y = 512, z = 512}, 9790, 5, 0.6)
	local noise2 = flatarea:noise(0, 100, {x = 1024, y = 1024, z = 1024}, -4283, 8, 0.5)
	for x = minp.x, maxp.x do
	for z = minp.z, maxp.z do
		local i2 = flatarea:index(x, z)
		local v2 = noise2[i2]
		for y = minp.y, maxp.y + 7 do
			local i3 = noisearea:index(x, y, z)
			local vi = area:index(x, y, z)
			local v1 = noise1[i3]
			if y / v2 <= v1 then
				data[vi] = stone
			elseif y <= 1 then
				data[vi] = water
			end
		end
	end
	return data, true, param2
end
