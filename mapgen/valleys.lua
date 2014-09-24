river_width = 0.05
river_depth = 3

function mapgen.on_generated(minp, maxp, data, param, param2, area, seed)
	local dirt, lawn, stone, water = mapgen.get_ids("default:dirt", "default:dirt_with_grass", "default:stone", "default:water_source")
	local minpxz, maxpxz = {x = minp.x - 1, y = minp.z - 1}, {x = maxp.x + 1, y = maxp.z + 1}
	local flatarea = minetest.voxel_area({x = minp.x - 1, y = 0, z = minp.z - 1}, {x = maxp.x + 1, y = 0, z = maxp.z + 1})
	print("Generating noises")
	print("noise1")
	local noise1 = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 2000, y = 2000}, 4019, 8, 0.3)
	print("noise2")
	local noise2 = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 400, y = 400}, 9439, 3, 0.2)
	print("noise3a")
	local noise3a = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 100, y = 100}, 7740, 3, 0.2)
	print("noise3b")
	local noise3b = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 100, y = 100}, 8310, 3, 0.2)
	print("noise4a")
	local noise4a = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 30, y = 30}, 2888, 3, 0.2)
	print("noise4b")
	local noise4b = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 30, y = 30}, 9845, 3, 0.2)
	print("noise5")
	local noise5 = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 1000, y = 1000}, 1165, 1, 0.5)
	print("noise6")
	local noise6 = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 800, y = 800}, 9756, 3, 0.1)
	print("noise7")
	local noise7 = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 500, y = 500}, 3523, 2, 0.1)
	print("noise8")
	local noise8 = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 200, y = 200}, 6823, 1, 0.1)
	print("noise9")
	local noise9 = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 10, y = 10}, 7778, 4, 0.4)
	print("noise10")
	local noise10 = mapgen.noise2d(minpxz, maxpxz, 0, 1, {x = 120, y = 120}, 5397, 1, 0.5)
	print("Loop")
	local elev = {}
	local river = {}
	for i in flatarea:iterp({x = minp.x - 1, y = 0, z = minp.z - 1}, {x = maxp.x + 1, y = 0, z = maxp.z + 1}) do
		local n1, n2, n5, n6, n7, n8, n9, n10 = noise1[i], noise2[i], noise5[i], noise6[i], noise7[i], noise8[i], noise9[i], noise10[i]
		local n3, n4
		if n2 > 0 then
			n3 = noise3a[i]
			if n3 > 0 then
				n4 = noise4a[i]
			else
				n4 = noise4b[i]
			end
		else
			n3 = noise3b[i]
			if n3 < 0 then
				n4 = noise4a[i]
			else
				n4 = noise4b[i]
			end
		end
		local val5 = (n5 + 1) ^ 2 / 2
		local inv5 = 1 - val5
		local abs2, abs3, abs4, abs6, abs7, abs8 = math.abs(n2), math.abs(n3), math.abs(n4), math.abs(n6), math.abs(n7), math.abs(n8)
		local hills1 = math.sqrt(abs6) * (val5 * abs2 + inv5 * abs2 ^ 2)
		local hills2 = math.sqrt(abs2 * abs7) * (val5 * abs3 + inv5 * abs3 ^ 2)
		local hills3 = math.sqrt(abs2 * abs3 * abs8) * (val5 * abs4 + inv5 * abs4 ^ 2)
		elev[i] = hills1 * 50 + hills2 * 35 + hills3 * 20 --math.ceil(n1 * 50 + hills1 * 50 + hills2 * 40 + hills3 * (30 + n9 * n10 * 5))
		river[i] = math.min(abs2, abs3, abs4) < river_width
	end
	for x = minp.x, maxp.x do
	for z = minp.z, maxp.z do
		local i = flatarea:index(x, 0, z)
		local river_here, elev_here = river[i], math.ceil(elev[i])
	for y = minp.y, math.max(elev_here, 1) do
		local index = area:index(x, y, z)
		if elev_here == y then
			if not river_here then
				if y >= 1 then
					data[index] = lawn
				else
					data[index] = dirt
				end
			end
		elseif elev_here > y then
			if river_here then
				local elev_water = math.min(elev_here,
					elev[flatarea:index(x + 1, 0, z)],
					elev[flatarea:index(x - 1, 0, z)],
					elev[flatarea:index(x, 0, z + 1)],
					elev[flatarea:index(x, 0, z - 1)]) - 0.5
				if y <= elev_water then
					if y + river_depth >= elev_water then
						data[index] = water
					elseif y + math.random(7) >= elev_here then
						data[index] = dirt
					else
						data[index] = stone
					end
				end
			elseif y + math.random(7) >= elev_here then
				data[index] = dirt
			else
				data[index] = stone
			end
		else
			data[index] = water
		end
	end
	end
	end
	return data, true, param2
end 
