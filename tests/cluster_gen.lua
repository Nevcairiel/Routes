--[[
	Generates the clustering test data set in tests/data/cluster/.

	Usage (from the addon root):
		lua5.1 tests/cluster_gen.lua             regenerate everything
		lua5.1 tests/cluster_gen.lua <pattern>   only cases whose name matches

	For every case this writes
		<name>.lua            the input: zone size, cluster radius, node list
		<name>.expected.lua   the result of the frozen reference implementation
		                      (tests/cluster_reference.lua), where affordable
	and an index.lua listing all cases.

	Everything is deterministic (own PRNG, no math.random), so regenerating
	yields byte-identical files on every machine.

	Tiers:
		core - small/medium cases, run by default
		perf - large cases, only run with --perf. The biggest ones have no
		       expected file because the reference implementation cannot
		       process them in reasonable time/memory; they are validated by
		       invariants only.
]]

local root = (arg[0]:gsub("\\", "/"):match("^(.*)/tests/[^/]*$")) or "."
local shims = dofile(root .. "/tests/wow_shims.lua")(root)
local reference = loadfile(root .. "/tests/cluster_reference.lua")(shims.Routes)
local dataDir = root .. "/tests/data/cluster"
local filter = arg[1]

local floor, sqrt, log, cos, sin, pi = math.floor, math.sqrt, math.log, math.cos, math.sin, math.pi

-----------------------------------------------------------------------
-- Deterministic PRNG (Park-Miller minimal standard, exact in doubles)
local function newRandom(seed)
	local state = seed
	local rng = {}
	function rng.float() -- (0, 1)
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
	function rng.range(lo, hi) -- float in [lo, hi)
		return lo + rng.float() * (hi - lo)
	end
	function rng.int(lo, hi) -- integer in [lo, hi]
		return lo + floor(rng.float() * (hi - lo + 1))
	end
	function rng.gauss() -- standard normal
		return sqrt(-2 * log(rng.float())) * cos(2 * pi * rng.float())
	end
	return rng
end

-----------------------------------------------------------------------
-- Node list builder. Routes node IDs are x * 10000 + y with x and y being
-- zone coordinates in 1/10000th of the zone size (0..9999).
local function newBuilder(zoneW, zoneH, allowDuplicates)
	local b = { nodes = {}, seen = {}, zoneW = zoneW, zoneH = zoneH }
	-- add by integer zone units; returns true if the node was added
	function b.addUnits(ux, uy)
		if ux < 0 or ux > 9999 or uy < 0 or uy > 9999 then return false end
		local id = ux * 10000 + uy
		if b.seen[id] and not allowDuplicates then return false end
		b.seen[id] = true
		b.nodes[#b.nodes + 1] = id
		return true
	end
	-- add by position in yards
	function b.addYards(x, y)
		return b.addUnits(floor(x / zoneW * 10000 + 0.5), floor(y / zoneH * 10000 + 0.5))
	end
	return b
end

-- n nodes spread uniformly over the zone
local function uniform(b, rng, n)
	local target = #b.nodes + n
	while #b.nodes < target do
		b.addYards(rng.range(0, b.zoneW), rng.range(0, b.zoneH))
	end
end

-- n nodes in gaussian blobs around k spawn areas (herb patches, ore camps)
local function blobs(b, rng, n, k, sigmaLo, sigmaHi)
	local centers = {}
	for i = 1, k do
		centers[i] = { rng.range(0.05, 0.95) * b.zoneW, rng.range(0.05, 0.95) * b.zoneH, rng.range(sigmaLo, sigmaHi) }
	end
	local target = #b.nodes + n
	while #b.nodes < target do
		local c = centers[rng.int(1, k)]
		b.addYards(c[1] + rng.gauss() * c[3], c[2] + rng.gauss() * c[3])
	end
end

-- n nodes strung along k line segments (ore along cliffs, herbs along rivers)
local function veins(b, rng, n, k, jitter)
	local segs = {}
	for i = 1, k do
		local x, y = rng.range(0.05, 0.95) * b.zoneW, rng.range(0.05, 0.95) * b.zoneH
		local angle, len = rng.range(0, 2 * pi), rng.range(300, 1200)
		segs[i] = { x, y, cos(angle) * len, sin(angle) * len }
	end
	local target = #b.nodes + n
	while #b.nodes < target do
		local s, t = segs[rng.int(1, k)], rng.float()
		b.addYards(s[1] + s[3] * t + rng.gauss() * jitter, s[2] + s[4] * t + rng.gauss() * jitter)
	end
end

-- a regular lattice in zone units: produces masses of exactly equal distances
local function lattice(b, x0, y0, stepX, stepY, cols, rows)
	for i = 0, cols - 1 do
		for j = 0, rows - 1 do
			b.addUnits(x0 + i * stepX, y0 + j * stepY)
		end
	end
end

-- realistic mix: 65% blobs, 20% veins, 15% scattered
local function mixed(b, rng, n)
	local nBlob, nVein = floor(n * 0.65), floor(n * 0.20)
	blobs(b, rng, nBlob, math.max(3, floor(n / 12)), 10, 45)
	veins(b, rng, nVein, math.max(2, floor(n / 60)), 12)
	uniform(b, rng, n - nBlob - nVein)
end

-- Routes are not sorted spatially before they are clustered, shuffle them
local function shuffle(nodes, rng)
	for i = #nodes, 2, -1 do
		local j = rng.int(1, i)
		nodes[i], nodes[j] = nodes[j], nodes[i]
	end
end

-----------------------------------------------------------------------
-- Case definitions
local cases = {}
local function case(name, tier, zoneW, zoneH, radius, build, opts)
	opts = opts or {}
	cases[#cases + 1] = {
		name = name, tier = tier, zoneW = zoneW, zoneH = zoneH, radius = radius,
		build = build, opts = opts,
	}
end

-- A typical zone map is 3:2. With 5000 x 3333.33 yards one zone unit is
-- 0.5 x 0.333 yards.
local W, H = 5000, 5000 * 2 / 3
local seed = 1000
local function nextSeed() seed = seed + 7919 return seed end

-- hand made edge cases ------------------------------------------------
case("edge_empty", "core", W, H, 60, function(b) end,
	{ note = "no nodes at all", expected = { nodes = {}, metadata = {}, length = 0 } })
case("edge_single", "core", W, H, 60, function(b) b.addUnits(5000, 5000) end,
	{ note = "one node" })
case("edge_pair_near", "core", W, H, 60, function(b)
	b.addUnits(5000, 5000) b.addUnits(5100, 5000) -- 50 yards apart
end, { note = "two nodes that merge" })
case("edge_pair_far", "core", W, H, 60, function(b)
	b.addUnits(5000, 5000) b.addUnits(5300, 5000) -- 150 yards apart
end, { note = "two nodes that do not merge" })
case("edge_pair_at_diameter", "core", W, H, 60, function(b)
	b.addUnits(5000, 5000) b.addUnits(5240, 5000) -- exactly 120 yards apart
end, { note = "two nodes exactly 2*radius apart" })
case("edge_pair_past_diameter", "core", W, H, 60, function(b)
	b.addUnits(5000, 5000) b.addUnits(5241, 5000) -- 120.5 yards apart
end, { note = "two nodes just over 2*radius apart" })
case("edge_stack_outlier", "core", W, H, 60, function(b)
	-- 5 nodes within a yard of each other plus one 100 yards away: the
	-- weighted centroid ends up 83 yards from the outlier -> rejected merge
	b.addUnits(5000, 5000) b.addUnits(5001, 5000) b.addUnits(5000, 5001)
	b.addUnits(5001, 5001) b.addUnits(4999, 5000) b.addUnits(5200, 5000)
end, { note = "merge rejected because the centroid is too far from an outlier" })
case("edge_duplicates", "core", W, H, 60, function(b)
	for i = 1, 4 do b.addUnits(2000, 2000) end
	for i = 1, 3 do b.addUnits(2050, 2000) end
	b.addUnits(8000, 8000) b.addUnits(8000, 8000)
	b.addUnits(1, 1)
end, { note = "identical node IDs (distance 0)", allowDuplicates = true })
case("edge_chain", "core", W, H, 60, function(b)
	for i = 0, 29 do b.addUnits(1000 + i * 100, 5000) end -- 50 yards apart
end, { note = "30 nodes in a line, 50 yards apart: all ties" })
case("edge_corners", "core", W, H, 60, function(b)
	b.addUnits(0, 0) b.addUnits(9999, 0) b.addUnits(0, 9999) b.addUnits(9999, 9999)
	b.addUnits(40, 30) b.addUnits(9960, 9970) b.addUnits(0, 9950) b.addUnits(9950, 20)
end, { note = "nodes on the extreme corners of the coordinate space" })
case("edge_tiny_zone", "core", 150, 100, 60, function(b, rng) uniform(b, rng, 120) end,
	{ note = "zone smaller than the cluster diameter" })

-- lattices: stress the tie breaking order ------------------------------
case("lattice_15x15_r60", "core", W, H, 60, function(b)
	lattice(b, 1000, 1000, 80, 120, 15, 15) -- 40 x 40 yards
end, { note = "square lattice, 40 yard pitch" })
case("lattice_20x20_r60", "core", W, H, 60, function(b)
	lattice(b, 2000, 2000, 50, 75, 20, 20) -- 25 x 25 yards
end, { note = "dense square lattice, 25 yard pitch" })
case("lattice_25x12_r35", "core", W, H, 35, function(b)
	lattice(b, 500, 500, 60, 150, 25, 12) -- 30 x 50 yards
end, { note = "rectangular lattice, 30 x 50 yard pitch" })
case("lattice_shuffled_r60", "core", W, H, 60, function(b, rng)
	lattice(b, 3000, 3000, 70, 105, 18, 18) -- 35 x 35 yards
	shuffle(b.nodes, rng)
end, { note = "square lattice in random route order" })

-- random distributions --------------------------------------------------
for _, c in ipairs({
	-- name, tier, zoneW, zoneH, radius, generator, n
	{ "uniform_100_r60", "core", W, H, 60, uniform, 100 },
	{ "uniform_500_r60", "core", W, H, 60, uniform, 500 },
	{ "uniform_500_r10", "core", W, H, 10, uniform, 500 },
	{ "uniform_500_r200", "core", W, H, 200, uniform, 500 },
	{ "uniform_800_square_r60", "core", 3000, 3000, 60, uniform, 800 },
	{ "uniform_600_wide_r60", "core", 9000, 1500, 60, uniform, 600 },
	{ "dense_600_r60", "core", 1200, 800, 60, uniform, 600 },
	{ "dense_400_r150", "core", 1500, 1000, 150, uniform, 400 },
	{ "mixed_300_r60", "core", W, H, 60, mixed, 300 },
	{ "mixed_800_r60", "core", W, H, 60, mixed, 800 },
	{ "mixed_800_r25", "core", W, H, 25, mixed, 800 },
	{ "mixed_800_r120", "core", W, H, 120, mixed, 800 },
	{ "mixed_1000_r60", "core", W, H, 60, mixed, 1000 },
	-- perf tier, still verified against the reference implementation
	{ "mixed_1500_r60", "perf", W, H, 60, mixed, 1500 },
	{ "mixed_2000_r60", "perf", W, H, 60, mixed, 2000 },
	{ "uniform_2000_r60", "perf", W, H, 60, uniform, 2000 },
	-- perf tier, too big for the reference implementation: invariants only
	{ "mixed_5000_r60", "perf", W, H, 60, mixed, 5000, true },
	{ "mixed_10000_r60", "perf", W, H, 60, mixed, 10000, true },
	{ "mixed_20000_r60", "perf", 8000, 5333, 60, mixed, 20000, true },
	{ "uniform_20000_r60", "perf", 8000, 5333, 60, uniform, 20000, true },
	{ "uniform_20000_r200", "perf", 8000, 5333, 200, uniform, 20000, true },
	{ "mixed_50000_r60", "perf", 12000, 8000, 60, mixed, 50000, true },
}) do
	local generator, n = c[6], c[7]
	case(c[1], c[2], c[3], c[4], c[5], function(b, rng)
		generator(b, rng, n)
		shuffle(b.nodes, rng)
	end, { noReference = c[8] })
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

local function writeInput(c, nodes)
	local f = assert(io.open(("%s/%s.lua"):format(dataDir, c.name), "wb"))
	f:write("-- Generated by tests/cluster_gen.lua, do not edit\n")
	f:write("return {\n")
	f:write(("\tname = %q,\n"):format(c.name))
	if c.opts.note then f:write(("\tnote = %q,\n"):format(c.opts.note)) end
	f:write(("\tzoneW = %.17g,\n\tzoneH = %.17g,\n\tradius = %d,\n"):format(c.zoneW, c.zoneH, c.radius))
	f:write("\tnodes = {\n")
	writeList(f, nodes, "\t\t")
	f:write("\t},\n}\n")
	f:close()
end

local function writeExpected(c, result)
	local f = assert(io.open(("%s/%s.expected.lua"):format(dataDir, c.name), "wb"))
	f:write("-- Generated by tests/cluster_gen.lua from tests/cluster_reference.lua, do not edit\n")
	f:write("return {\n")
	f:write(("\tlength = %.17g,\n"):format(result.length))
	f:write("\tnodes = {\n")
	writeList(f, result.nodes, "\t\t")
	f:write("\t},\n\tmetadata = {\n")
	for i = 1, #result.metadata do
		local m, s = result.metadata[i], {}
		for j = 1, #m do s[j] = ("%d"):format(m[j]) end
		f:write("\t\t{ ", table.concat(s, ", "), " },\n")
	end
	f:write("\t},\n}\n")
	f:close()
end

local index = {}
for i, c in ipairs(cases) do
	local b = newBuilder(c.zoneW, c.zoneH, c.opts.allowDuplicates)
	c.build(b, newRandom(nextSeed())) -- seed advances for every case, filtered or not
	local nodes = b.nodes
	local entry = { name = c.name, tier = c.tier, n = #nodes, expected = not c.opts.noReference }
	index[#index + 1] = entry

	if not filter or c.name:find(filter) then
		writeInput(c, nodes)
		local status = "no reference"
		if c.opts.expected then
			writeExpected(c, c.opts.expected)
			status = "hand written expectation"
		elseif not c.opts.noReference then
			shims.SetZoneSize(i, c.zoneW, c.zoneH)
			local t = os.clock()
			local rnodes, rmeta, rlength = reference:ClusterRoute(nodes, i, c.radius)
			t = os.clock() - t
			writeExpected(c, { nodes = rnodes, metadata = rmeta, length = rlength })
			status = ("%d clusters, reference took %.2fs"):format(#rnodes, t)
			collectgarbage()
		end
		print(("%-26s %6d nodes  %s"):format(c.name, #nodes, status))
		io.stdout:flush()
	end
end

local f = assert(io.open(dataDir .. "/index.lua", "wb"))
f:write("-- Generated by tests/cluster_gen.lua, do not edit\n")
f:write("return {\n")
for _, e in ipairs(index) do
	f:write(("\t{ name = %q, tier = %q, n = %d, expected = %s },\n"):format(e.name, e.tier, e.n, tostring(e.expected)))
end
f:write("}\n")
f:close()
