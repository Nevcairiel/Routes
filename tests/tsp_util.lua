--[[
	Helpers shared by tests/tsp_gen.lua and tests/tsp_test.lua.

	The geometry here is written independently of TSP.lua on purpose, so that
	the tests do not inherit its bugs.
]]

local util = {}
local floor = math.floor

-- The defaults of db.defaults.tsp in Routes.lua
util.DEFAULT_PARAMS = {
	initial_pheromone = 0.1, alpha = 1, beta = 6, local_decay = 0.2, local_update = 0.4,
	global_decay = 0.2, twoopt_passes = 3, two_point_five_opt = false,
}

local function xy(coord) -- zone units 0..9999
	return floor(coord / 10000), coord % 10000
end

function util.Distance(a, b, zoneW, zoneH)
	local x, y = xy(a)
	local x2, y2 = xy(b)
	return ((((x2 - x) / 10000) * zoneW) ^ 2 + (((y2 - y) / 10000) * zoneH) ^ 2) ^ 0.5
end

-- Length in yards of the closed route
function util.RouteLength(nodes, zoneW, zoneH)
	local n = #nodes
	if n < 2 then return 0 end
	local length = 0
	local prev = nodes[n]
	for i = 1, n do
		length = length + util.Distance(prev, nodes[i], zoneW, zoneH)
		prev = nodes[i]
	end
	return length
end

-- Even-odd rule point in polygon test
function util.PointInPolygon(coord, polygon)
	local px, py = xy(coord)
	local inside = false
	local n = #polygon
	local x1, y1 = xy(polygon[n])
	for i = 1, n do
		local x2, y2 = xy(polygon[i])
		if (y1 > py) ~= (y2 > py) and px < (x2 - x1) * (py - y1) / (y2 - y1) + x1 then
			inside = not inside
		end
		x1, y1 = x2, y2
	end
	return inside
end

local function orient(ax, ay, bx, by, cx, cy)
	local v = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
	return v > 0 and 1 or v < 0 and -1 or 0
end

-- Do the segments a-b and c-d properly cross each other? (all integer zone
-- units, so this is exact). Merely touching does not count.
local function segmentsCross(ax, ay, bx, by, cx, cy, dx, dy)
	local o1, o2 = orient(ax, ay, bx, by, cx, cy), orient(ax, ay, bx, by, dx, dy)
	local o3, o4 = orient(cx, cy, dx, dy, ax, ay), orient(cx, cy, dx, dy, bx, by)
	return o1 * o2 < 0 and o3 * o4 < 0
end

-- Does the route leg a-b cross any edge of any taboo polygon?
function util.CrossesTaboo(a, b, taboos)
	if not taboos then return false end
	local ax, ay = xy(a)
	local bx, by = xy(b)
	for t = 1, #taboos do
		local polygon = taboos[t]
		local n = #polygon
		local x1, y1 = xy(polygon[n])
		for i = 1, n do
			local x2, y2 = xy(polygon[i])
			if segmentsCross(ax, ay, bx, by, x1, y1, x2, y2) then return true end
			x1, y1 = x2, y2
		end
	end
	return false
end

-- Returns the number of legs of the closed route that cross a taboo region,
-- and the cost of the route the way the solver is supposed to rate it: a leg
-- that crosses a taboo region counts as twice its length plus the zone width.
function util.RouteCost(nodes, taboos, zoneW, zoneH)
	local n = #nodes
	if n < 2 then return 0, 0 end
	local crossings, cost = 0, 0
	local prev = nodes[n]
	for i = 1, n do
		local d = util.Distance(prev, nodes[i], zoneW, zoneH)
		if util.CrossesTaboo(prev, nodes[i], taboos) then
			crossings = crossings + 1
			d = d * 2 + zoneW
		end
		cost = cost + d
		prev = nodes[i]
	end
	return crossings, cost
end

-- Converts the polygons of a test case into the taboo tables SolveTSP() wants
function util.MakeTaboos(polygons)
	local taboos = {}
	for i = 1, polygons and #polygons or 0 do
		taboos[i] = { route = polygons[i] }
	end
	return taboos
end

-- Median of list[i][field] (or of list[i] if field is nil)
function util.Median(list, field)
	local values = {}
	for i = 1, #list do values[i] = field and list[i][field] or list[i] end
	table.sort(values)
	local n = #values
	if n == 0 then return nil end
	if n % 2 == 1 then return values[(n + 1) / 2] end
	return (values[n / 2] + values[n / 2 + 1]) / 2
end

return util
