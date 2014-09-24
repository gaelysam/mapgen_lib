function mapgen.on_generated(minp, maxp, data, param, param2, area, seed)
	local level, depth, spread, seed, octaves, persist = mapgen.get_map_meta("level", "depth", "spread", "seed", "octaves", "persist")
	local rate = - level / depth
	local c_stone, c_water, c_air = mapgen.get_ids("default:stone", "default:water_source", "air")
	local noise_area = minetest.voxel_area(minp, maxp)
	local noise = noise_area:noise(0, 1, {x = spread, y = spread, z = spread}, seed, octaves, persist / 100)
	for i in noise_area:iterp(minp, maxp) do
		local n = noise[i]
		local alt = noise_area:altitude(i)
		if n >= rate + alt / depth then
			data[i] = c_stone
		elseif alt <= 1 then
			data[i] = c_water
		else
			data[i] = c_air
		end
	end
	return data, true, param2
end

mapgen.formspec = "size[4,5]field[0.25,0.5;1.5,1;spread;Scale of noise;100]field[2.25,0.5;1.5,1;seed;Seed;0]field[0.25,2;1.5,1;octaves;Details;6]field[2.25,2;1.5,1;persist;Details depth;50]field[0.25,3.5;1.5,1;level;Ground level;0]field[2.25,3.5;1.5,1;depth;Ground depth;100]button_exit[1.25,3.5;1.5,1;generate;Generate]"
