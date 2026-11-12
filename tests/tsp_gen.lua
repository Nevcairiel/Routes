--[[
	Generates the route optimizer (TSP) test data set in tests/data/tsp/.

	Usage (from the addon root):
		lua5.1 tests/tsp_gen.lua             regenerate everything
		lua5.1 tests/tsp_gen.lua <pattern>   only cases whose name matches

	The cases are built from the clustering data set (tests/data/cluster/, run
	tests/cluster_gen.lua first) so that they look like real routes: the nodes
	are put in the order a new route gets (TSP:DecrossRoute) and are optionally
	clustered (TSP:ClusterRoute), which also provides the cluster metadata.

	For every case this writes
		<name>.lua            the input: zone size, nodes, metadata, taboos
		<name>.baseline.lua   lengths, taboo crossings and time of the frozen
		                      reference solver (tests/tsp_reference.lua) for
		                      a few seeds, where affordable
	and an index.lua listing all cases.

	Tiers:
		core - small cases, run by default
		perf - large cases, only run with --perf. Cases with more than 724
		       nodes have no baseline, the reference solver was limited to
		       724 nodes.
]]

local root = (arg[0]:gsub("\\", "/"):match("^(.*)/tests/[^/]*$")) or "."
local shims = dofile(root .. "/tests/wow_shims.lua")(root)
shims.LoadAddonFile("TSP.lua")
local TSP = shims.Routes.TSP
local reference = loadfile(root .. "/tests/tsp_reference.lua")(shims.Routes)
local util = dofile(root .. "/tests/tsp_util.lua")
local clusterDir = root .. "/tests/data/cluster"
local dataDir = root .. "/tests/data/tsp"
local filter = arg[1]

local floor = math.floor
local BASELINE_SEEDS = 3
local PARAMS = util.DEFAULT_PARAMS

local nextZone = 0
local function newZone(zoneW, zoneH)
	nextZone = nextZone + 1
	shims.SetZoneSize(nextZone, zoneW, zoneH)
	return nextZone
end

-----------------------------------------------------------------------
-- Case builders. Each returns { zoneW, zoneH, nodes, metadata, taboos }
local W, H = 5000, 5000 * 2 / 3

local function copy(t)
	local c = {}
	for i = 1, #t do c[i] = t[i] end
	return c
end

-- nodes of a clustering case in new-route order, optionally limited to n nodes
local function raw(clusterCase, limit)
	return function()
		local case = dofile(("%s/%s.lua"):format(clusterDir, clusterCase))
		local nodes = copy(case.nodes)
		if limit then
			for i = #nodes, limit + 1, -1 do nodes[i] = nil end
		end
		nodes = TSP:DecrossRoute(nodes)
		return { zoneW = case.zoneW, zoneH = case.zoneH, nodes = nodes }
	end
end

-- a clustering case as a clustered route
local function clustered(clusterCase)
	return function()
		local case = dofile(("%s/%s.lua"):format(clusterDir, clusterCase))
		local nodes = TSP:DecrossRoute(copy(case.nodes))
		local zone = newZone(case.zoneW, case.zoneH)
		local cnodes, metadata = TSP:ClusterRoute(nodes, zone, case.radius)
		return { zoneW = case.zoneW, zoneH = case.zoneH, nodes = cnodes, metadata = metadata }
	end
end

-- explicit nodes given as {x, y} in zone units (0..9999), in that order
local function points(list)
	return function()
		local nodes = {}
		for i = 1, #list do nodes[i] = list[i][1] * 10000 + list[i][2] end
		return { zoneW = W, zoneH = H, nodes = nodes }
	end
end

-- Taboo regions are polygons given as {x, y} in zone units. Like the addon
-- does, nodes (or clusters) inside a taboo region are removed from the route.
local function withTaboos(builder, polygons)
	return function()
		local case = builder()
		local taboos = {}
		for i, polygon in ipairs(polygons) do
			taboos[i] = {}
			for j, p in ipairs(polygon) do taboos[i][j] = p[1] * 10000 + p[2] end
		end
		local nodes, metadata = {}, case.metadata and {}
		for i = 1, #case.nodes do
			local inside = false
			for j = 1, #taboos do
				if util.PointInPolygon(case.nodes[i], taboos[j]) then inside = true break end
			end
			if not inside then
				nodes[#nodes + 1] = case.nodes[i]
				if metadata then metadata[#metadata + 1] = case.metadata[i] end
			end
		end
		case.nodes, case.metadata, case.taboos = nodes, metadata, taboos
		return case
	end
end

local LAKE = { { 3200, 3000 }, { 4600, 2600 }, { 5600, 3900 }, { 5100, 5800 }, { 3600, 5600 } } -- pentagon
local WALL = { { 7000, 1000 }, { 7150, 1000 }, { 7150, 7500 }, { 7000, 7500 } }                  -- long thin wall
local RIDGE = { { 1000, 7000 }, { 2600, 7600 }, { 1200, 8200 } }                                 -- triangle
local BAR = { { 2000, 4900 }, { 8000, 4900 }, { 8000, 5100 }, { 2000, 5100 } }                   -- horizontal bar

local function lattice(cols, rows, step)
	local list = {}
	for i = 0, cols - 1 do
		for j = 0, rows - 1 do
			list[#list + 1] = { 1000 + i * step, 1000 + j * step * 1.5 }
		end
	end
	return list
end

-- Deterministic pseudo random numbers in [0, 1) for the builders below
local function newRandom(seed)
	local state = seed
	return function()
		state = (state * 16807) % 2147483647
		return (state - 1) / 2147483646
	end
end

-- n nodes of which all but "spread" are packed into a corner of the zone that
-- is 1% of its width and height, the others are spread over the whole zone
local function lopsided(n, spread, seed)
	return function()
		local rnd, list, seen = newRandom(seed), {}, {}
		while #list < n do
			local x, y
			if #list < spread then
				x, y = floor(rnd() * 10000), floor(rnd() * 10000)
			else
				x, y = 200 + floor(rnd() * 100), 300 + floor(rnd() * 100)
			end
			if not seen[x * 10000 + y] then
				seen[x * 10000 + y] = true
				list[#list + 1] = { x, y }
			end
		end
		-- not in a helpful order
		for i = #list, 2, -1 do
			local j = 1 + floor(rnd() * i)
			list[i], list[j] = list[j], list[i]
		end
		return points(list)()
	end
end

local function samePoint(n)
	return function()
		local list = {}
		for i = 1, n do list[i] = { 4321, 1234 } end
		return points(list)()
	end
end

-- Taboo regions for lattices: their corners are nodes of the lattice and
-- their outlines run along its lines, so lots of route legs touch them
local function latticeTaboos(step)
	local function p(i, j) return { 1000 + i * step, 1000 + j * step * 1.5 } end
	return {
		{ p(3, 3), p(8, 3), p(8, 7), p(3, 7) },      -- a rectangle
		{ p(11, 2), p(16, 7), p(11, 12) },           -- a triangle with 2 diagonal sides
		{ p(2, 12), p(9, 12), p(9, 13), p(2, 13) },  -- a flat bar
	}
end

-- n nodes and some random taboo regions, all with coordinates that are
-- multiples of 100 zone units, so that lots of route legs pass exactly
-- through the corners of taboo regions or run along their outlines
local function coarseTaboos(n, numTaboos, seed)
	return function()
		local rnd = newRandom(seed)
		local function coord() return floor(rnd() * 100) * 100 end
		local polygons = {}
		for i = 1, numTaboos do
			local polygon = {}
			local cx, cy = 1500 + floor(rnd() * 70) * 100, 1500 + floor(rnd() * 70) * 100
			for j = 1, 3 + floor(rnd() * 3) do
				polygon[j] = { cx + floor(rnd() * 16 - 8) * 100, cy + floor(rnd() * 16 - 8) * 100 }
			end
			polygons[i] = polygon
		end
		local list, seen = {}, {}
		while #list < n do
			local x, y = coord(), coord()
			if not seen[x * 10000 + y] then
				seen[x * 10000 + y] = true
				list[#list + 1] = { x, y }
			end
		end
		return withTaboos(points(list), polygons)()
	end
end

local cases = {
	-- name, tier, builder, note
	{ "edge_0", "core", points({}), "no nodes" },
	{ "edge_1", "core", points({ { 5000, 5000 } }), "one node" },
	{ "edge_2", "core", points({ { 5000, 5000 }, { 6000, 5000 } }), "two nodes" },
	{ "edge_3", "core", points({ { 5000, 5000 }, { 6000, 5000 }, { 5500, 7000 } }), "three nodes (still trivial)" },
	{ "edge_4_crossed", "core", points({ { 1000, 1000 }, { 9000, 9000 }, { 9000, 1000 }, { 1000, 9000 } }), "four nodes in a crossed order" },
	{ "edge_5", "core", points({ { 1000, 1000 }, { 5000, 9000 }, { 9000, 1000 }, { 1000, 6000 }, { 9000, 6000 } }), "five nodes (a star)" },
	{ "edge_same_point", "core", points({ { 3000, 3000 }, { 3000, 3000 }, { 3000, 3000 }, { 3000, 3000 }, { 3000, 3000 }, { 3000, 3000 } }), "6 identical nodes (all distances 0)" },
	{ "edge_duplicates", "core", points({ { 1000, 1000 }, { 8000, 2000 }, { 1000, 1000 }, { 8000, 2000 }, { 4000, 9000 }, { 1000, 1000 }, { 4000, 9000 }, { 6000, 6000 }, { 8000, 2000 }, { 6000, 6000 } }), "repeated node IDs" },
	{ "edge_collinear", "core", function()
		local list = {}
		for i = 1, 20 do list[i] = { 500 + ((i * 7) % 20) * 400, 5000 } end -- scrambled order on a line
		return points(list)()
	end, "20 nodes on a horizontal line" },
	{ "edge_vertical", "core", function()
		local list = {}
		for i = 1, 20 do list[i] = { 5000, 500 + ((i * 3) % 20) * 400 } end
		return points(list)()
	end, "20 nodes on a vertical line" },
	{ "lattice_10x10", "core", points(lattice(10, 10, 300)), "square lattice: many equally good routes" },
	{ "uniform_100", "core", raw("uniform_100_r60") },
	{ "clustered_93", "core", clustered("mixed_300_r60"), "clustered route with metadata" },
	{ "mixed_300", "core", raw("mixed_300_r60") },
	{ "clustered_251", "core", clustered("mixed_800_r60"), "clustered route with metadata" },
	{ "taboo_uniform_100", "core", withTaboos(raw("uniform_100_r60"), { LAKE, WALL }) },
	{ "taboo_clustered_251", "core", withTaboos(clustered("mixed_800_r60"), { LAKE, WALL, RIDGE }), "clustered route with metadata and taboos" },
	{ "taboo_bar_mixed_300", "core", withTaboos(raw("mixed_300_r60"), { BAR }), "a taboo that cuts the zone almost in half" },
	{ "taboo_lattice_400", "core", withTaboos(points(lattice(20, 20, 300)), latticeTaboos(300)), "taboo outlines that run along the lines of a lattice" },
	{ "taboo_coarse_600", "core", coarseTaboos(600, 8, 21), "nodes and taboo corners on a coarse grid: legs through taboo corners" },
	{ "lopsided_300", "core", lopsided(300, 1, 11), "299 nodes in 1% x 1% of the zone and one far away" },
	{ "two_scales_400", "core", lopsided(400, 200, 12), "half of the nodes in 1% x 1% of the zone, half all over it" },
	{ "same_point_300", "core", samePoint(300), "300 identical nodes" },

	{ "uniform_500", "perf", raw("uniform_500_r60") },
	{ "clustered_510", "perf", clustered("mixed_2000_r60") },
	{ "taboo_uniform_500", "perf", withTaboos(raw("uniform_500_r60"), { LAKE, WALL, RIDGE }) },
	{ "uniform_600_wide", "perf", raw("uniform_600_wide_r60") },
	{ "mixed_724", "perf", raw("mixed_800_r60", 724), "the node limit of the reference solver" },
	-- too big for the reference solver
	{ "clustered_954", "perf", clustered("mixed_5000_r60") },
	{ "clustered_1421", "perf", clustered("mixed_10000_r60") },
	{ "mixed_2000", "perf", raw("mixed_2000_r60") },
	{ "taboo_clustered_1421", "perf", withTaboos(clustered("mixed_10000_r60"), { LAKE, WALL, RIDGE, BAR }) },
	{ "clustered_3971", "perf", clustered("uniform_20000_r60") },
	{ "mixed_5000", "perf", raw("mixed_5000_r60") },
	{ "clustered_7532", "perf", clustered("mixed_50000_r60") },
	{ "uniform_20000", "perf", raw("uniform_20000_r60") },
	-- layouts that are hard on the grid used to find the neighbours
	{ "lopsided_5000", "perf", lopsided(5000, 1, 13), "4999 nodes in 1% x 1% of the zone and one far away" },
	{ "two_scales_6000", "perf", lopsided(6000, 3000, 14), "half of the nodes in 1% x 1% of the zone, half all over it" },
	{ "same_point_5000", "perf", samePoint(5000), "5000 identical nodes" },
	-- enough taboo checks to overflow the cache of them
	{ "taboo_lattice_6400", "perf", withTaboos(points(lattice(80, 80, 90)), latticeTaboos(360)), "taboo outlines that run along the lines of a lattice" },
}

-- Real routes. Their input files are not generated here, they were extracted
-- from saved variables with tests/tsp_extract.lua. Only their baseline is
-- generated, and they are listed in the index.
local external = {}
for _, c in ipairs({
	-- Ohn'ahran Plains herbs: 2037 nodes in 475 clusters, 2 taboos
	{ "real_herbs_475", "core" },
	{ "real_herbs_475_optimized", "core" },
	{ "real_herbs_475_raw", "perf" },
}) do
	local path = ("%s/%s.lua"):format(dataDir, c[1])
	external[c[1]] = true
	cases[#cases + 1] = { c[1], c[2], function() return dofile(path) end }
end

-----------------------------------------------------------------------
-- Output
local function writeList(f, list, indent)
	local line = {}
	for i = 1, #list do
		line[#line + 1] = ("%d"):format(list[i])
		if #line == 12 or i == #list then
			f:write(indent, table.concat(line, ", "), ",\n")
			line = {}
		end
	end
end

local function writeInput(name, note, case)
	local f = assert(io.open(("%s/%s.lua"):format(dataDir, name), "wb"))
	f:write("-- Generated by tests/tsp_gen.lua, do not edit\n")
	f:write("return {\n")
	f:write(("\tname = %q,\n"):format(name))
	if note then f:write(("\tnote = %q,\n"):format(note)) end
	f:write(("\tzoneW = %.17g,\n\tzoneH = %.17g,\n"):format(case.zoneW, case.zoneH))
	f:write("\tnodes = {\n")
	writeList(f, case.nodes, "\t\t")
	f:write("\t},\n")
	if case.metadata then
		f:write("\tmetadata = {\n")
		for i = 1, #case.metadata do
			local s = {}
			for j = 1, #case.metadata[i] do s[j] = ("%d"):format(case.metadata[i][j]) end
			f:write("\t\t{ ", table.concat(s, ", "), " },\n")
		end
		f:write("\t},\n")
	end
	if case.taboos then
		f:write("\ttaboos = {\n")
		for i = 1, #case.taboos do
			local s = {}
			for j = 1, #case.taboos[i] do s[j] = ("%d"):format(case.taboos[i][j]) end
			f:write("\t\t{ ", table.concat(s, ", "), " },\n")
		end
		f:write("\t},\n")
	end
	f:write("}\n")
	f:close()
end

local function writeBaseline(name, runs)
	local f = assert(io.open(("%s/%s.baseline.lua"):format(dataDir, name), "wb"))
	f:write("-- Generated by tests/tsp_gen.lua from tests/tsp_reference.lua, do not edit\n")
	f:write("-- One entry per seed (1, 2, ...): route length in yards, number of taboo\n")
	f:write("-- crossings, penalized cost, iterations and seconds taken\n")
	f:write("return {\n")
	for i, r in ipairs(runs) do
		f:write(("\t{ length = %.17g, crossings = %d, cost = %.17g, iterations = %d, seconds = %.3f },\n"):format(
			r.length, r.crossings, r.cost, r.iterations, r.seconds))
	end
	f:write("}\n")
	f:close()
end

local index = {}
for _, c in ipairs(cases) do
	local name, tier, builder, note = c[1], c[2], c[3], c[4]
	local case = builder()
	local n = #case.nodes
	local hasBaseline = n <= 724
	index[#index + 1] = { name = name, tier = tier, n = n, baseline = hasBaseline }

	if not filter or name:find(filter) then
		if not external[name] then
			writeInput(name, note, case)
		end
		local status = "no baseline"
		if hasBaseline then
			local zone = newZone(case.zoneW, case.zoneH)
			local taboos = util.MakeTaboos(case.taboos)
			local runs, total = {}, 0
			for seed = 1, BASELINE_SEEDS do
				shims.SeedRandom(seed)
				local t = os.clock()
				local path, _, length, iterations = reference:SolveTSP(case.nodes, case.metadata, taboos, zone, PARAMS)
				t = os.clock() - t
				total = total + t
				local crossings, cost = util.RouteCost(path, case.taboos, case.zoneW, case.zoneH)
				runs[seed] = { length = length, crossings = crossings, cost = cost, iterations = iterations, seconds = t }
				collectgarbage()
			end
			writeBaseline(name, runs)
			status = ("reference: %.0f yards (median), %.2fs per run"):format(util.Median(runs, "length"), total / BASELINE_SEEDS)
		end
		print(("%-22s %6d nodes  %s"):format(name, n, status))
		io.stdout:flush()
	end
end

local f = assert(io.open(dataDir .. "/index.lua", "wb"))
f:write("-- Generated by tests/tsp_gen.lua, do not edit\n")
f:write("return {\n")
for _, e in ipairs(index) do
	f:write(("\t{ name = %q, tier = %q, n = %d, baseline = %s },\n"):format(e.name, e.tier, e.n, tostring(e.baseline)))
end
f:write("}\n")
f:close()
