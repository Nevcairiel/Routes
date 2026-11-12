--[[
	Correctness and performance tests for TSP:ClusterRoute().

	Usage (from the addon root):
		lua5.1 tests/cluster_test.lua [options] [pattern]

	Options:
		--perf        also run the large "perf" tier cases
		--reference   run the frozen reference implementation instead of
		              TSP.lua (to get baseline timings)
		--fuzz N      number of randomized differential cases (default 300,
		              0 to disable)
		--seed N      seed for the randomized cases (default 1)
		--no-bg       skip the background (coroutine) runs
		--file PATH   test this file instead of TSP.lua (path relative to the
		              addon root), e.g. to compare an experimental version
		pattern       only run data set cases whose name matches (Lua pattern)

	Every case is checked three ways:
		1. invariants that any valid clustering must satisfy
		2. exact equality with the result of the reference implementation
		   (<name>.expected.lua), where one exists
		3. the background (coroutine) mode must return the same result as the
		   blocking mode

	Exit code is 0 if everything passed, 1 otherwise.
]]

local root = (arg[0]:gsub("\\", "/"):match("^(.*)/tests/[^/]*$")) or "."
local shims = dofile(root .. "/tests/wow_shims.lua")(root)
local reference = loadfile(root .. "/tests/cluster_reference.lua")(shims.Routes)
local dataDir = root .. "/tests/data/cluster"

local floor = math.floor

-- Cases the current implementation is known to fail, with the reason.
-- Remove an entry once it is fixed (the runner complains if it passes).
local KNOWN_FAILURES = {
}

-----------------------------------------------------------------------
-- Options
local opt = { fuzz = 300, seed = 1, bg = true, file = "TSP.lua" }
do
	local i = 1
	while arg[i] do
		local a = arg[i]
		if a == "--perf" then opt.perf = true
		elseif a == "--reference" then opt.reference = true
		elseif a == "--no-bg" then opt.bg = false
		elseif a == "--file" then i = i + 1 opt.file = assert(arg[i], "--file needs a path")
		elseif a == "--fuzz" then i = i + 1 opt.fuzz = assert(tonumber(arg[i]), "--fuzz needs a number")
		elseif a == "--seed" then i = i + 1 opt.seed = assert(tonumber(arg[i]), "--seed needs a number")
		elseif a:sub(1, 2) == "--" then error("unknown option " .. a)
		else opt.pattern = a end
		i = i + 1
	end
end
shims.LoadAddonFile(opt.file)
local TSP = shims.Routes.TSP
local impl = opt.reference and reference or TSP
if opt.reference then opt.bg = false end

-----------------------------------------------------------------------
-- Helpers
local function dist(a, b, zoneW, zoneH)
	local x, y = floor(a / 10000) / 10000, (a % 10000) / 10000
	local x2, y2 = floor(b / 10000) / 10000, (b % 10000) / 10000
	return (((x2 - x) * zoneW) ^ 2 + ((y2 - y) * zoneH) ^ 2) ^ 0.5
end

local function copy(t)
	local c = {}
	for i = 1, #t do c[i] = t[i] end
	return c
end

local function sameList(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end
	return true
end

local nextZone = 0
local function newZone(zoneW, zoneH)
	nextZone = nextZone + 1
	shims.SetZoneSize(nextZone, zoneW, zoneH)
	return nextZone
end

-- Would the two clusters be merged by the algorithm? This mirrors the merge
-- test of ClusterRoute(): weighted centroid of the two cluster points, rounded
-- to the coordinate grid, must be within radius of every member.
local function canMerge(n1, m1, n2, m2, radius, zoneW, zoneH)
	local num1, num2 = #m1, #m2
	local total = num1 + num2
	local x = (floor(n1 / 10000) / 10000 * num1 + floor(n2 / 10000) / 10000 * num2) / total
	local y = ((n1 % 10000) / 10000 * num1 + (n2 % 10000) / 10000 * num2) / total
	local coord = floor(x * 10000 + 0.5) * 10000 + floor(y * 10000 + 0.5)
	for i = 1, num1 do
		if dist(coord, m1[i], zoneW, zoneH) > radius then return false end
	end
	for i = 1, num2 do
		if dist(coord, m2[i], zoneW, zoneH) > radius then return false end
	end
	return true
end

-- Returns nil if the result is a valid clustering, an error message otherwise
local function checkInvariants(input, zoneW, zoneH, radius, nodes, metadata, length)
	if type(nodes) ~= "table" or type(metadata) ~= "table" or type(length) ~= "number" then
		return "result is not (table, table, number)"
	end
	local numClusters = #nodes
	if #metadata ~= numClusters then
		return ("%d cluster points but %d metadata entries"):format(numClusters, #metadata)
	end

	-- 1. every input node is in exactly one cluster, and nothing was invented
	local count = {}
	for i = 1, #input do
		count[input[i]] = (count[input[i]] or 0) + 1
	end
	local total = 0
	for i = 1, numClusters do
		local m = metadata[i]
		if type(m) ~= "table" or #m == 0 then
			return ("cluster %d has no members"):format(i)
		end
		for j = 1, #m do
			local c = count[m[j]]
			if not c or c == 0 then
				return ("cluster %d contains node %s which is not in the input (or too often)"):format(i, tostring(m[j]))
			end
			count[m[j]] = c - 1
			total = total + 1
		end
	end
	if total ~= #input then
		return ("%d input nodes but %d clustered nodes"):format(#input, total)
	end

	-- 2. cluster points are valid node IDs and every member is within radius
	for i = 1, numClusters do
		local n, m = nodes[i], metadata[i]
		if type(n) ~= "number" or n ~= floor(n) or n < 0 or n > 99999999 then
			return ("cluster %d has an invalid cluster point %s"):format(i, tostring(n))
		end
		if #m == 1 and m[1] ~= n then
			return ("cluster %d has a single member %d but its cluster point is %d"):format(i, m[1], n)
		end
		for j = 1, #m do
			local d = dist(n, m[j], zoneW, zoneH)
			if d > radius then
				return ("cluster %d: member %d is %.3f yards from the cluster point, radius is %d"):format(i, m[j], d, radius)
			end
		end
	end

	-- 3. the reported length is the length of the route through the cluster points
	local expectLength = 0
	if numClusters > 1 then
		local prev = nodes[numClusters]
		for i = 1, numClusters do
			expectLength = expectLength + dist(prev, nodes[i], zoneW, zoneH)
			prev = nodes[i]
		end
	end
	if math.abs(expectLength - length) > 1e-6 * math.max(1, expectLength) then
		return ("reported length %.6f but the route is %.6f yards long"):format(length, expectLength)
	end

	-- 4. the clustering is complete: no two remaining clusters could be merged
	local diameter = radius * 2
	local order = {}
	for i = 1, numClusters do order[i] = i end
	table.sort(order, function(a, b)
		local xa, xb = floor(nodes[a] / 10000), floor(nodes[b] / 10000)
		if xa ~= xb then return xa < xb end
		return a < b
	end)
	local reach = diameter / zoneW * 10000 + 1 -- in x units, with slack for rounding
	for a = 1, numClusters - 1 do
		local i = order[a]
		local xi = floor(nodes[i] / 10000)
		for b = a + 1, numClusters do
			local j = order[b]
			if floor(nodes[j] / 10000) - xi > reach then break end
			local lo, hi = i, j
			if lo > hi then lo, hi = hi, lo end
			if dist(nodes[lo], nodes[hi], zoneW, zoneH) <= diameter
				and canMerge(nodes[lo], metadata[lo], nodes[hi], metadata[hi], radius, zoneW, zoneH) then
				return ("clusters %d and %d are %.3f yards apart and could have been merged"):format(
					lo, hi, dist(nodes[lo], nodes[hi], zoneW, zoneH))
			end
		end
	end
end

-- Returns nil if both results are identical, an error message otherwise
local function compareResults(what, nodes, metadata, length, enodes, emetadata, elength)
	if #nodes ~= #enodes then
		return ("%s: %d clusters, expected %d"):format(what, #nodes, #enodes)
	end
	for i = 1, #nodes do
		if nodes[i] ~= enodes[i] then
			return ("%s: cluster point %d is %d, expected %d"):format(what, i, nodes[i], enodes[i])
		end
		if not sameList(metadata[i], emetadata[i]) then
			return ("%s: members of cluster %d differ: {%s}, expected {%s}"):format(
				what, i, table.concat(metadata[i], ","), table.concat(emetadata[i], ","))
		end
	end
	if math.abs(length - elength) > 1e-6 * math.max(1, elength) then
		return ("%s: length is %.6f, expected %.6f"):format(what, length, elength)
	end
end

local function traceback(msg)
	return debug.traceback(tostring(msg), 2)
end

-- Runs the blocking mode. Returns ok, nodes|error, metadata, length, seconds, allocatedMB
local function runBlocking(nodes, zone, radius)
	collectgarbage()
	collectgarbage()
	collectgarbage("stop") -- so that the memory delta is the total allocation
	local mem, t = collectgarbage("count"), os.clock()
	local ok, rnodes, rmeta, rlength = xpcall(function()
		return impl:ClusterRoute(nodes, zone, radius)
	end, traceback)
	t, mem = os.clock() - t, collectgarbage("count") - mem
	collectgarbage("restart")
	return ok, rnodes, rmeta, rlength, t, mem / 1024
end

-- Runs the background mode by simulating frames.
-- Returns ok, nodes|error, metadata, length, frames, longestFrameMs
local function runBackground(nodes, zone, radius)
	local done, rnodes, rmeta, rlength
	local numPrinted = #shims.printed
	local longest = 0
	local t = os.clock()
	local ok, status = xpcall(function()
		return TSP:ClusterRouteBackground(nodes, zone, radius, function(n, m, l)
			done, rnodes, rmeta, rlength = true, n, m, l
		end)
	end, traceback)
	longest = os.clock() - t
	if not ok then return false, status end
	if status ~= 1 then
		return false, "ClusterRouteBackground() returned " .. tostring(status)
	end
	local frames = 1
	while not done do
		t = os.clock()
		local ran = shims.PumpFrame()
		t = os.clock() - t
		if t > longest then longest = t end
		frames = frames + 1
		if #shims.printed > numPrinted then
			return false, "background run printed: " .. table.concat(shims.printed, " | ", numPrinted + 1)
		end
		if ran == 0 and not done then
			return false, "background run stopped without calling the finish function"
		end
	end
	return true, rnodes, rmeta, rlength, frames, longest * 1000
end

-----------------------------------------------------------------------
-- Data set cases
local passed, failed, xfailed = 0, 0, 0
local failures = {}

local function report(name, n, clusters, seconds, mb, bg, status, err)
	print(("%-26s %6d %6s %9s %8s %-14s %s"):format(name, n, clusters or "-",
		seconds and ("%.3f"):format(seconds) or "-", mb and ("%.1f"):format(mb) or "-", bg or "-", status))
	if err then
		print("    " .. tostring(err):gsub("\n", "\n    "))
	end
	io.stdout:flush()
end

local function runCase(entry)
	local case = dofile(("%s/%s.lua"):format(dataDir, entry.name))
	local expected = entry.expected and dofile(("%s/%s.expected.lua"):format(dataDir, entry.name))
	local zone = newZone(case.zoneW, case.zoneH)
	local input = copy(case.nodes)

	local ok, nodes, metadata, length, seconds, mb = runBlocking(case.nodes, zone, case.radius)
	local err, bg
	if not ok then
		err = nodes
	else
		if not sameList(case.nodes, input) then
			err = "the input table was modified"
		end
		err = err or checkInvariants(input, case.zoneW, case.zoneH, case.radius, nodes, metadata, length)
		if not err and expected then
			err = compareResults("blocking", nodes, metadata, length, expected.nodes, expected.metadata, expected.length)
		end
		if not err and opt.bg then
			local bok, bnodes, bmeta, blength, frames, longest = runBackground(case.nodes, zone, case.radius)
			if not bok then
				err = bnodes
			else
				bg = ("%d/%.0fms"):format(frames, longest)
				err = compareResults("background", bnodes, bmeta, blength, nodes, metadata, length)
			end
		end
	end

	local known = not opt.reference and KNOWN_FAILURES[entry.name] or opt.reference and entry.name == "edge_empty" and "reference errors on empty input"
	local clusters = ok and type(nodes) == "table" and #nodes or nil
	if err and known then
		xfailed = xfailed + 1
		report(entry.name, entry.n, clusters, seconds, mb, bg, "known failure: " .. known)
	elseif err then
		failed = failed + 1
		failures[#failures + 1] = entry.name
		report(entry.name, entry.n, clusters, seconds, mb, bg, "FAIL", err)
	elseif known then
		failed = failed + 1
		failures[#failures + 1] = entry.name
		report(entry.name, entry.n, clusters, seconds, mb, bg, "FAIL", "passes now, remove it from KNOWN_FAILURES")
	else
		passed = passed + 1
		report(entry.name, entry.n, clusters, seconds, mb, bg, expected and "ok" or "ok (invariants only)")
	end
end

print(("Testing %s"):format(opt.reference and "the frozen reference implementation" or "TSP:ClusterRoute() from " .. opt.file))
print(("%-26s %6s %6s %9s %8s %-14s %s"):format("case", "nodes", "clust", "seconds", "alloc MB", "bg frames/max", "result"))
local index = dofile(dataDir .. "/index.lua")
local total = os.clock()
for _, entry in ipairs(index) do
	if (entry.tier == "core" or opt.perf) and (not opt.pattern or entry.name:find(opt.pattern)) then
		runCase(entry)
	end
end

-----------------------------------------------------------------------
-- Background API: status codes and the running state
if not opt.reference and not opt.pattern then
	local err
	local function check(cond, msg)
		if not cond and not err then err = msg end
	end
	local case = dofile(dataDir .. "/mixed_1000_r60.lua")
	local zone = newZone(case.zoneW, case.zoneH)
	local finished = 0
	local function finish() finished = finished + 1 end

	check(TSP:IsClusterRunning() == false, "IsClusterRunning() should be false when idle")
	check(TSP:ClusterRouteBackground(case.nodes, zone, case.radius, finish) == 1, "first start should return 1")
	local running, nodes = TSP:IsClusterRunning()
	check(running == true and nodes == case.nodes, "IsClusterRunning() should return true and the nodes table")
	check(TSP:ClusterRouteBackground(case.nodes, zone, case.radius, finish) == 2, "second start should return 2")
	check(shims.PumpUntil(function() return finished > 0 end, 100000), "background run did not finish")
	check(finished == 1, "finish function should be called exactly once")
	check(TSP:IsClusterRunning() == false, "IsClusterRunning() should be false after finishing")

	-- an error before the first yield must be returned, not swallowed
	local status, msg = TSP:ClusterRouteBackground(case.nodes, -1, case.radius, finish)
	check(status == 3 and type(msg) == "string", "start with an unknown zone should return 3 and the error message")
	check(TSP:IsClusterRunning() == false, "IsClusterRunning() should be false after a failed start")
	check(TSP:ClusterRouteBackground(case.nodes, zone, case.radius, finish) == 1, "start after a failed start should return 1")
	check(shims.PumpUntil(function() return finished > 1 end, 100000), "background run after a failed start did not finish")

	-- the route may be modified as soon as the background run was started,
	-- the result must be that of the route as it was when it was started
	local enodes, emeta, elength = TSP:ClusterRoute(case.nodes, zone, case.radius)
	for _, mutate in ipairs({
		function(t) table.remove(t, 50) end,
		function(t) table.insert(t, 50, 12345678) end,
		function(t) for i = #t, 1, -1 do t[i] = nil end end,
	}) do
		local nodes, rnodes, rmeta, rlength = copy(case.nodes)
		local numPrinted = #shims.printed
		check(TSP:ClusterRouteBackground(nodes, zone, case.radius, function(n, m, l) rnodes, rmeta, rlength = n, m, l end) == 1,
			"start before a modification should return 1")
		mutate(nodes)
		check(shims.PumpUntil(function() return rnodes or #shims.printed > numPrinted end, 100000) and rnodes,
			"background run failed after the route was modified: " .. tostring(shims.printed[#shims.printed]))
		if rnodes then
			check(not compareResults("modified", rnodes, rmeta, rlength, enodes, emeta, elength),
				"modifying the route after the start changed the result")
		end
	end

	print(("%-26s %s"):format("background API", err and "FAIL" or "ok"))
	if err then
		print("    " .. err)
		failed = failed + 1
		failures[#failures + 1] = "background API"
	else
		passed = passed + 1
	end
end

-----------------------------------------------------------------------
-- Extreme zone sizes and radii, compared with the reference implementation
if not opt.reference and not opt.pattern then
	local state = 4711
	local function rint(lo, hi)
		state = (state * 16807) % 2147483647
		return lo + floor(state / 2147483647 * (hi - lo + 1))
	end
	local err
	for _, e in ipairs({
		-- zoneW, zoneH, radius
		{ 2e9, 2e9, 10 }, { 1e7, 1e7, 0.05 }, { 1e12, 1, 60 }, { 1, 1e12, 60 }, { 1e15, 1e15, 1 },
		{ 5000, 3333, 1e-300 }, { 5000, 3333, 0 }, { 5000, 3333, -5 }, { 5000, 3333, 1e9 },
		{ 0, 0, 60 }, { 0, 3333, 60 }, { -5000, 3333, 60 }, { 5000, -3333, 60 }, { 0.001, 0.001, 60 },
	}) do
		for run = 1, 20 do
			local nodes, span = {}, run % 2 == 0 and 9999 or rint(1, 40)
			for i = 1, rint(1, 60) do
				nodes[i] = i > 3 and rint(0, 4) == 0 and nodes[rint(1, i - 1)] -- some duplicates
					or rint(0, span) * 10000 + rint(0, span)
			end
			local zone = newZone(e[1], e[2])
			local enodes, emeta, elength = reference:ClusterRoute(nodes, zone, e[3])
			local ok, rnodes, rmeta, rlength = xpcall(function()
				return TSP:ClusterRoute(nodes, zone, e[3])
			end, traceback)
			local msg = not ok and rnodes or compareResults("extreme", rnodes, rmeta, rlength, enodes, emeta, elength)
			if msg and not err then
				err = ("zone %gx%g, radius %g, nodes = { %s }: %s"):format(e[1], e[2], e[3], table.concat(nodes, ", "), tostring(msg))
			end
		end
	end
	print(("%-26s %s"):format("extreme inputs", err and "FAIL" or "ok"))
	if err then
		print("    " .. err)
		failed = failed + 1
		failures[#failures + 1] = "extreme inputs"
	else
		passed = passed + 1
	end
end

-----------------------------------------------------------------------
-- Randomized differential testing against the reference implementation
if opt.fuzz > 0 and not opt.reference and not opt.pattern then
	local state = opt.seed
	local function rnd() -- Park-Miller, deterministic on every platform
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
	local function rint(lo, hi) return lo + floor(rnd() * (hi - lo + 1)) end

	local fuzzFailed = 0
	local t = os.clock()
	for run = 1, opt.fuzz do
		local n = rint(0, 3) == 0 and rint(1, 12) or rint(2, 90)
		local zoneW = rint(200, 6000)
		local zoneH = rint(0, 2) == 0 and zoneW or rint(150, 6000)
		local radius = rint(10, 200)
		-- keep the nodes in an area that makes merges likely
		local spanX = math.min(9999, floor(radius * rint(2, 12) / zoneW * 10000))
		local spanY = math.min(9999, floor(radius * rint(2, 12) / zoneH * 10000))
		local x0, y0 = rint(0, 9999 - spanX), rint(0, 9999 - spanY)
		-- a third of the runs snap to a coarse grid to provoke equal distances
		local snap = rint(0, 2) == 0 and rint(2, 60) or 1
		local nodes = {}
		for i = 1, n do
			local x = math.min(9999, x0 + floor(rint(0, spanX) / snap) * snap)
			local y = math.min(9999, y0 + floor(rint(0, spanY) / snap) * snap)
			nodes[i] = x * 10000 + y
		end

		local zone = newZone(zoneW, zoneH)
		local enodes, emeta, elength = reference:ClusterRoute(nodes, zone, radius)
		local ok, rnodes, rmeta, rlength = xpcall(function()
			return TSP:ClusterRoute(nodes, zone, radius)
		end, traceback)
		local err
		if not ok then
			err = rnodes
		else
			err = checkInvariants(nodes, zoneW, zoneH, radius, rnodes, rmeta, rlength)
				or compareResults("fuzz", rnodes, rmeta, rlength, enodes, emeta, elength)
		end
		if not err and opt.bg and run % 10 == 0 then
			local bok, bnodes, bmeta, blength = runBackground(nodes, zone, radius)
			err = not bok and bnodes or compareResults("fuzz background", bnodes, bmeta, blength, enodes, emeta, elength)
		end
		if err then
			fuzzFailed = fuzzFailed + 1
			if fuzzFailed <= 3 then
				print(("fuzz run %d FAILED (seed %d): zone %dx%d, radius %d"):format(run, opt.seed, zoneW, zoneH, radius))
				print("    nodes = { " .. table.concat(nodes, ", ") .. " }")
				print("    " .. tostring(err):gsub("\n", "\n    "))
			end
		end
	end
	print(("%-26s %s, %.2fs"):format(("fuzz x%d (seed %d)"):format(opt.fuzz, opt.seed),
		fuzzFailed == 0 and "ok" or ("FAIL (%d runs)"):format(fuzzFailed), os.clock() - t))
	if fuzzFailed > 0 then
		failed = failed + 1
		failures[#failures + 1] = "fuzz"
	else
		passed = passed + 1
	end
end

print(("\n%d passed, %d failed, %d known failures, %.1fs total"):format(passed, failed, xfailed, os.clock() - total))
if failed > 0 then
	print("FAILED: " .. table.concat(failures, ", "))
end
os.exit(failed > 0 and 1 or 0)
