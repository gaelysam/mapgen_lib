FlatArea = {
	MinEdge = {x=1, y=1},
	MaxEdge = {x=0, y=0},
	stride = 0,
}

function FlatArea:new(o)
	o = o or {}
	o.MinEdge = pos2d(o.MinEdge)
	o.MaxEdge = pos2d(o.MaxEdge)
	setmetatable(o, self)
	self.__index = self

	local e = o:getExtent()
	o.stride = e.x
	return o
end

function FlatArea:getExtent()
	return {
		x = self.MaxEdge.x - self.MinEdge.x + 1,
		y = self.MaxEdge.y - self.MinEdge.y + 1,
	}
end

function FlatArea:getVolume()
	local e = self:getExtent()
	return e.x * e.y
end

function FlatArea:index(x, y)
	local i = (y - self.MinEdge.y) * self.stride +
			  (x - self.MinEdge.x) + 1
	return math.floor(i)
end

function FlatArea:indexp(p)
	p = pos2d(p)
	local i = (p.y - self.MinEdge.y) * self.stride +
			  (p.x - self.MinEdge.x) + 1
	return math.floor(i)
end

function FlatArea:position(i)
	local p = {}
 
	i = i - 1

	p.y = math.floor(i / self.stride) + self.MinEdge.y
	i = i % self.stride

	p.x = math.floor(i) + self.MinEdge.x

	return p
end

function FlatArea:contains(x, y)
	return (x >= self.MinEdge.x) and (x <= self.MaxEdge.x) and
		   (y >= self.MinEdge.y) and (y <= self.MaxEdge.y)
end

function FlatArea:containsp(p)
	p = pos2d(p)
	return (p.x >= self.MinEdge.x) and (p.x <= self.MaxEdge.x) and
		   (p.y >= self.MinEdge.y) and (p.y <= self.MaxEdge.y)
end

function FlatArea:containsi(i)
	return (i >= 1) and (i <= self:getVolume())
end

function FlatArea:iter(minx, miny, maxx, maxy)
	local i = self:index(minx, miny) - 1
	local last = self:index(maxx, maxy)
	local stride = self.stride
	local off = (last+1) % stride
	local stridediff = (i - last) % stride
	return function()
		i = i + 1
		if i % stride == yoff then
			i = i + stridediff
		end
		if i <= last then
			return i
		end
	end
end

function FlatArea:iterp(minp, maxp)
	minp, maxp = pos2d(minp), pos2d(maxp)
	return self:iter(minp.x, minp.y, maxp.x, maxp.y)
end

function pos2d(pos)
	if not pos then
		return
	elseif pos.z then
		return {x = pos.x, y = pos.z}
	else
		return {x = pos.x, y = pos.y}
	end
end

function pos3d(pos, alt)
	if not pos then
		return
	elseif not pos.z then
		return {x = pos.x, y = alt, z = pos.y}
	else
		return {x = pos.x, y = pos.y, z = pos.z}
	end
end
