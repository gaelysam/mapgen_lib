params = {}
params.spread = 900
params.seed = 1089
params.octaves = 8
params.persist = 0.5
params.high = 100

function mapgen.on_generated(minp, maxp, data, param, param2, area, seed)
	local stone, dirt, lawn, water, sand = mapgen.get_ids("default:stone", "default:dirt", "default:dirt_with_grass", "default:water_source", "default:sand")
	local noisearea = minetest.flat_area(minp, maxp)
	local noise1 = noisearea:noise(0, 1, {x = params.spread, y = params.spread, z = params.spread}, params.seed, params.octaves, params.persist)
	local noise2 = noisearea:noise(0, 1, {x = 1000, y = 1000, z = 1000}, 1265, 1, 1)
	local noise3 = noisearea:noise(0, 1, {x = 200, y = 200, z = 200}, 7783, 3, 0.4)
	for x = minp.x, maxp.x do
	for z = minp.z, maxp.z do
		local i = noisearea:index(x, z)
		local elev = math.round(noise1[i] * noise2[i] * params.high)
		for y = minp.y, maxp.y do
			local index = area:index(x, y, z)
			if y <= elev then
				local layer1, layer2
				if math.abs(elev) < noise3[i] ^ 2 * 8 then
					layer1 = sand
					layer2 = sand
				else
					layer1 = lawn
					layer2 = dirt
				end
				if y + math.random(3, 7) > elev then
					if elev <= 0 then
						layer1 = layer2
					end
					if y == elev then
						data[index] = layer1
					else
						data[index] = layer2
					end
				else
					data[index] = stone
				end
			elseif y <= 0 then
				data[index] = water
			end
		end
	end
	end
	return data, true, param2
end
