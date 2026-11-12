--[[
	Correctness, quality and performance tests for TSP:SolveTSP().

	Usage (from the addon root):
		lua5.1 tests/tsp_test.lua [options] [pattern]

	Options:
		--perf        also run the large "perf" tier cases
		--reference   run the frozen reference solver instead of TSP.lua
		--file PATH   test this file instead of TSP.lua (path relative to the
		              addon root), e.g. to compare an experimental version
		--seeds N     number of random seeds to run every case with (default 3)
		--no-bg       skip the background (coroutine) runs
		--record      store the shortest routes found in data/tsp/best.lua
		--check       run with assertions added to the solver: the cost it
		              keeps track of must match the route (checked regularly
		              and at the end), and its cache of taboo checks is made
		              tiny so that it overflows all the time. Much slower.
		pattern       only run cases whose name matches (Lua pattern)

	Every case is run with several seeds and checked for
		1. validity: the result is the same set of nodes (and metadata), the
		   input is untouched, the reported length is right, and the route is
		   not worse than the order the nodes were given in
		2. determinism: the same seed gives the same route, and the background
		   (coroutine) mode gives the same route as the blocking mode
		3. quality: the median route length is not longer than the median of
		   the reference solver (<name>.baseline.lua), and the route does not
		   cross taboo regions more often than the reference solver's routes

	Exit code is 0 if everything passed, 1 otherwise.
]]

local root = (arg[0]:gsub("\\", "/"):match("^(.*)/tests/[^/]*$")) or "."
local shims = dofile(root .. "/tests/wow_shims.lua")(root)
local reference = loadfile(root .. "/tests/tsp_reference.lua")(shims.Routes)
local util = dofile(root .. "/tests/tsp_util.lua")
local dataDir = root .. "/tests/data/tsp"

-- The median length may be this much longer than the reference median
local QUALITY_TOLERANCE = 0.0
-- Determinism and background runs are skipped if a blocking run took longer (seconds)
local RERUN_LIMIT = 20

-----------------------------------------------------------------------
-- Options
local opt = { seeds = 3, bg = true, file = "TSP.lua" }
do
	local i = 1
	while arg[i] do
		local a = arg[i]
		if a == "--perf" then opt.perf = true
		elseif a == "--reference" then opt.reference = true
		elseif a == "--no-bg" then opt.bg = false
		elseif a == "--record" then opt.record = true
		elseif a == "--check" then opt.check = true
		elseif a == "--file" then i = i + 1 opt.file = assert(arg[i], "--file needs a path")
		elseif a == "--seeds" then i = i + 1 opt.seeds = assert(tonumber(arg[i]), "--seeds needs a number")
		elseif a:sub(1, 2) == "--" then error("unknown option " .. a)
		else opt.pattern = a end
		i = i + 1
	end
end
if opt.check then
	-- add assertions to the source of the solver
	local f = assert(io.open(root .. "/" .. opt.file, "rb"))
	local source = f:read("*a"):gsub("^\239\187\191", "")
	f:close()
	local function patch(pattern, replacement)
		local count
		source, count = source:gsub(pattern, replacement)
		assert(count == 1, "--check: expected exactly one match for " .. pattern .. ", got " .. count)
	end
	patch("\n\t%-%- Step 8\t%- Kick the route", function(match)
		return [==[

	local function __verify(where)
		local real = D(tour[numNodes], tour[1])
		for i = 1, numNodes - 1 do real = real + D(tour[i], tour[i + 1]) end
		if math.abs(real - cost) > 1e-6 * math.max(1, real) then
			error(("--check (%s): the solver thinks the cost is %.6f but it is %.6f"):format(where, cost, real))
		end
		for i = 1, numNodes do
			if tourPos[tour[i]] ~= i then error(("--check (%s): tourPos is wrong"):format(where)) end
		end
	end
	__verify("after the local search")]==] .. match
	end)
	patch("\n\t\tjournalSize = nil\n", function(match)
		return match .. "\t\tif kick % 97 == 0 then __verify('kick ' .. kick) end\n"
	end)
	patch("\n\t%-%- Step 9\t%- Convert the route", function(match)
		return "\n\t__verify('end')" .. match
	end)
	patch("numCrossing >= 400000", "numCrossing >= 2000")
	assert(loadstring(source, "@" .. opt.file))("Routes", {})
else
	shims.LoadAddonFile(opt.file)
end
local TSP = shims.Routes.TSP
local impl = opt.reference and reference or TSP
if opt.reference then opt.bg = false end
local PARAMS = util.DEFAULT_PARAMS

-----------------------------------------------------------------------
-- Helpers
local function copy(t)
	local c = {}
	for i = 1, #t do c[i] = t[i] end
	return c
end

local function deepCopy(t)
	if not t then return nil end
	local c = {}
	for i = 1, #t do c[i] = copy(t[i]) end
	return c
end

local function sameList(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end
	return true
end

local function sameDeep(a, b)
	if (a == nil) ~= (b == nil) then return false end
	if not a then return true end
	if #a ~= #b then return false end
	for i = 1, #a do
		if not sameList(a[i], b[i]) then return false end
	end
	return true
end

local nextZone = 0
local function newZone(zoneW, zoneH)
	nextZone = nextZone + 1
	shims.SetZoneSize(nextZone, zoneW, zoneH)
	return nextZone
end

local function traceback(msg)
	return debug.traceback(tostring(msg), 2)
end

-- Returns nil if the result is a valid solution for the case, an error message otherwise
local function checkResult(case, input, path, metadata, length, iterations, seconds)
	if type(path) ~= "table" or type(length) ~= "number" or type(iterations) ~= "number" or type(seconds) ~= "number" then
		return "result is not (table, metadata, number, number, number)"
	end
	local n = #input.nodes
	if #path ~= n then
		return ("%d nodes in, %d nodes out"):format(n, #path)
	end
	if not sameList(case.nodes, input.nodes) then return "the input nodes table was modified" end
	if not sameDeep(case.metadata, input.metadata) then return "the input metadata table was modified" end
	if path == case.nodes then return "the input nodes table was returned as the result" end

	-- the same nodes, each still with its own metadata
	if (metadata ~= nil) ~= (input.metadata ~= nil) then
		return input.metadata and "the metadata was dropped" or "metadata appeared from nowhere"
	end
	if metadata and #metadata ~= n then
		return ("%d nodes but %d metadata entries"):format(n, #metadata)
	end
	local count = {}
	for i = 1, n do
		local key = input.nodes[i] .. ":" .. (input.metadata and table.concat(input.metadata[i], ",") or "")
		count[key] = (count[key] or 0) + 1
	end
	for i = 1, n do
		if metadata and type(metadata[i]) ~= "table" then
			return ("metadata entry %d is not a table"):format(i)
		end
		local key = tostring(path[i]) .. ":" .. (metadata and table.concat(metadata[i], ",") or "")
		if not count[key] or count[key] == 0 then
			return ("node %d of the result (%s) is not in the input, or is there too often, or has the wrong metadata"):format(i, tostring(path[i]))
		end
		count[key] = count[key] - 1
	end

	-- the reported length
	local realLength = util.RouteLength(path, case.zoneW, case.zoneH)
	if math.abs(realLength - length) > 1e-6 * math.max(1, realLength) then
		return ("reported length %.6f but the route is %.6f yards long"):format(length, realLength)
	end

	-- trivial routes are returned as they are
	if n < 4 and not sameList(path, input.nodes) then
		return "a route with less than 4 nodes was reordered"
	end

	-- never worse than the order the nodes were given in
	local _, cost = util.RouteCost(path, case.taboos, case.zoneW, case.zoneH)
	local _, inputCost = util.RouteCost(input.nodes, case.taboos, case.zoneW, case.zoneH)
	if cost > inputCost * (1 + 1e-9) + 1e-6 then
		return ("the result (cost %.3f) is worse than the input order (cost %.3f)"):format(cost, inputCost)
	end
end

-- Runs the blocking mode with a seed.
-- Returns ok, path|error, metadata, length, iterations, reportedSeconds, seconds, allocatedMB
local function runBlocking(case, zone, taboos, seed, pathArg)
	shims.SeedRandom(seed)
	collectgarbage()
	collectgarbage()
	collectgarbage("stop") -- so that the memory delta is the total allocation
	local mem, t = collectgarbage("count"), os.clock()
	local ok, path, metadata, length, iterations, seconds = xpcall(function()
		return impl:SolveTSP(case.nodes, case.metadata, taboos, zone, PARAMS, pathArg)
	end, traceback)
	t, mem = os.clock() - t, collectgarbage("count") - mem
	collectgarbage("restart")
	return ok, path, metadata, length, iterations, seconds, t, mem / 1024
end

-- Runs the background mode with a seed by simulating frames.
-- Returns ok, path|error, metadata, length, frames, longestFrameMs
local function runBackground(case, zone, taboos, seed)
	local done, path, metadata, length, statusError
	local numPrinted = #shims.printed
	shims.SeedRandom(seed)
	local t = os.clock()
	local ok, status, errormsg = xpcall(function()
		return TSP:SolveTSPBackground(case.nodes, case.metadata, taboos, zone, PARAMS)
	end, traceback)
	local longest = os.clock() - t
	if not ok then return false, status end
	if status ~= 1 then
		return false, "SolveTSPBackground() returned " .. tostring(status) .. " " .. tostring(errormsg)
	end
	TSP:SetStatusFunction(function(pass, progress, len)
		if type(pass) ~= "number" or type(progress) ~= "number" or progress < 0 or progress > 1
			or (len ~= nil and type(len) ~= "number") then
			statusError = ("bad status update (%s, %s, %s)"):format(tostring(pass), tostring(progress), tostring(len))
		end
	end)
	TSP:SetFinishFunction(function(p, m, l)
		done, path, metadata, length = true, p, m, l
	end)
	local running, nodes = TSP:IsTSPRunning()
	if running ~= true or nodes ~= case.nodes then
		return false, "IsTSPRunning() should return true and the nodes table while running"
	end
	if TSP:SolveTSPBackground(case.nodes, case.metadata, taboos, zone, PARAMS) ~= 2 then
		return false, "a second SolveTSPBackground() should return 2"
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
	if statusError then return false, statusError end
	if TSP:IsTSPRunning() ~= false then
		return false, "IsTSPRunning() should return false after finishing"
	end
	return true, path, metadata, length, frames, longest * 1000
end

-----------------------------------------------------------------------
local best = {}
do
	local f = loadfile(dataDir .. "/best.lua")
	if f then best = f() end
end
local bestChanged = false

local passed, failed = 0, 0
local failures = {}

local function runCase(entry)
	local case = dofile(("%s/%s.lua"):format(dataDir, entry.name))
	local baseline = entry.baseline and dofile(("%s/%s.baseline.lua"):format(dataDir, entry.name))
	local zone = newZone(case.zoneW, case.zoneH)
	local taboos = util.MakeTaboos(case.taboos)
	local input = { nodes = copy(case.nodes), metadata = deepCopy(case.metadata) }

	local err, bg
	local lengths, maxCrossings, totalSeconds, maxMB = {}, 0, 0, 0
	local firstPath, firstMeta
	for seed = 1, opt.seeds do
		-- the first run also checks that a supplied result table is used
		local pathArg = seed == 1 and { 1, 2, 3, "junk" } or nil
		local ok, path, metadata, length, iterations, reported, seconds, mb = runBlocking(case, zone, taboos, seed, pathArg)
		if not ok then
			err = path
			break
		end
		err = checkResult(case, input, path, metadata, length, iterations, reported)
		if not err and pathArg and path ~= pathArg then
			err = "the result table passed in was not used for the result"
		end
		if err then
			err = ("seed %d: %s"):format(seed, err)
			break
		end
		local crossings = util.RouteCost(path, case.taboos, case.zoneW, case.zoneH)
		lengths[seed] = length
		if crossings > maxCrossings then maxCrossings = crossings end
		totalSeconds = totalSeconds + seconds
		if mb > maxMB then maxMB = mb end
		if seed == 1 then firstPath, firstMeta = copy(path), deepCopy(metadata) end
		if length < (best[entry.name] or math.huge) - 1e-6 and not case.taboos then
			if opt.record then best[entry.name] = length bestChanged = true end
		end
	end
	local seconds = totalSeconds / math.max(1, #lengths)

	-- determinism: the same seed must give the same route
	if not err and seconds <= RERUN_LIMIT then
		local ok, path, metadata = runBlocking(case, zone, taboos, 1)
		if not ok then
			err = path
		elseif not sameList(path, firstPath) or not sameDeep(metadata, firstMeta) then
			err = "running seed 1 again gave a different route"
		end
	end

	-- background mode: must give the same route as the blocking mode
	if not err and opt.bg and seconds <= RERUN_LIMIT then
		local ok, path, metadata, length, frames, longest = runBackground(case, zone, taboos, 1)
		if not ok then
			err = path
		else
			bg = ("%d/%.0fms"):format(frames, longest)
			err = checkResult(case, input, path, metadata, length, 0, 0)
			if not err and (not sameList(path, firstPath) or not sameDeep(metadata, firstMeta)) then
				err = "the background mode gave a different route than the blocking mode"
			end
			if err then err = "background: " .. err end
		end
	end

	-- quality compared to the reference solver
	local median = util.Median(lengths)
	local versus, cross = "-", "-"
	if median and baseline then
		local refMedian = util.Median(baseline, "length")
		if refMedian > 0 then
			versus = ("%+.1f%%"):format((median / refMedian - 1) * 100)
		end
		if not err and median > refMedian * (1 + QUALITY_TOLERANCE) + 1e-6 then
			err = ("median length %.1f is longer than the reference median %.1f"):format(median, refMedian)
		end
		if case.taboos then
			local refCrossings = 0
			for i = 1, #baseline do
				if baseline[i].crossings > refCrossings then refCrossings = baseline[i].crossings end
			end
			cross = ("%d/%d"):format(maxCrossings, refCrossings)
			if not err and maxCrossings > refCrossings then
				err = ("crosses taboo regions up to %d times, the reference at most %d times"):format(maxCrossings, refCrossings)
			end
		end
	elseif median and case.taboos then
		cross = ("%d/-"):format(maxCrossings)
	end
	local versusBest = "-"
	if median and best[entry.name] and best[entry.name] > 0 then
		versusBest = ("%+.1f%%"):format((median / best[entry.name] - 1) * 100)
	end

	print(("%-22s %6d %10s %7s %7s %6s %8s %7s %-12s %s"):format(entry.name, entry.n,
		median and ("%.0f"):format(median) or "-", versus, versusBest, cross,
		median and ("%.3f"):format(seconds) or "-", median and ("%.1f"):format(maxMB) or "-", bg or "-",
		err and "FAIL" or (baseline and "ok" or "ok (no baseline)")))
	if err then
		print("    " .. tostring(err):gsub("\n", "\n    "))
		failed = failed + 1
		failures[#failures + 1] = entry.name
	else
		passed = passed + 1
	end
	io.stdout:flush()
end

print(("Testing %s, %d seeds"):format(opt.reference and "the frozen reference solver" or "TSP:SolveTSP() from " .. opt.file, opt.seeds))
print(("%-22s %6s %10s %7s %7s %6s %8s %7s %-12s %s"):format("case", "nodes", "length", "vs ref", "vs best", "cross", "seconds", "MB", "bg frm/max", "result"))
local index = dofile(dataDir .. "/index.lua")
local total = os.clock()
for _, entry in ipairs(index) do
	if (entry.tier == "core" or opt.perf) and (not opt.pattern or entry.name:find(opt.pattern)) then
		runCase(entry)
	end
end

-----------------------------------------------------------------------
-- Parameters and the background API: giving up early, stopping, errors
if not opt.reference and not opt.pattern then
	local err
	local function check(cond, msg)
		if not cond and not err then err = msg end
	end
	local case = dofile(dataDir .. "/mixed_300.lua")
	local n = #case.nodes
	local zone = newZone(case.zoneW, case.zoneH)
	local input = { nodes = copy(case.nodes) }

	-- kicks_per_node sets the number of attempts, patience_per_node ends them early
	shims.SeedRandom(1)
	local path, meta, length, iterations, seconds = TSP:SolveTSP(case.nodes, nil, {}, zone, { kicks_per_node = 2 })
	check(iterations == 2 * n, ("kicks_per_node = 2 should make %d attempts, made %s"):format(2 * n, tostring(iterations)))
	shims.SeedRandom(1)
	local path0, _, length0, iterations0 = TSP:SolveTSP(case.nodes, nil, {}, zone, { kicks_per_node = 0 })
	check(iterations0 == 0, "kicks_per_node = 0 should make no attempts")
	check(length <= length0 + 1e-6, "more attempts made the route longer")
	shims.SeedRandom(1)
	path, meta, length, iterations, seconds = TSP:SolveTSP(case.nodes, nil, {}, zone, { kicks_per_node = 1000, patience_per_node = 1 })
	check(iterations > n and iterations < 1000 * n, "patience_per_node = 1 should end the attempts early, made " .. tostring(iterations))
	check(not checkResult(case, input, path, meta, length, iterations, seconds), "the result with patience_per_node is not valid")

	-- a background run can be stopped and returns the best route so far
	local function start(nodes, zoneID, params)
		local result = {}
		local numPrinted = #shims.printed
		shims.SeedRandom(1)
		local status, errormsg = TSP:SolveTSPBackground(nodes, nil, {}, zoneID, params)
		if status == 1 then
			TSP:SetStatusFunction(function() end)
			TSP:SetFinishFunction(function(p, m, l, i, s)
				result.done, result.path, result.length, result.iterations, result.seconds = true, p, l, i, s
			end)
		end
		result.status, result.errormsg = status, errormsg
		result.finish = function(maxFrames)
			return shims.PumpUntil(function() return result.done or #shims.printed > numPrinted end, maxFrames)
		end
		result.printed = function() return table.concat(shims.printed, " | ", numPrinted + 1) end
		return result
	end
	local run = start(case.nodes, zone, { kicks_per_node = 1e6 })
	check(run.status == 1, "start should return 1")
	for i = 1, 30 do shims.PumpFrame() end
	check(not run.done, "a run with a huge number of attempts finished within 30 frames")
	TSP:StopTSP()
	check(run.finish(5) and run.done, "the run did not finish within 5 frames after StopTSP()")
	if run.done then
		check(run.iterations > 0 and run.iterations < 1e6 * n, "a stopped run should report the attempts it made")
		check(not checkResult(case, input, run.path, nil, run.length, run.iterations, run.seconds), "the result of a stopped run is not valid")
	end
	check(TSP:IsTSPRunning() == false, "IsTSPRunning() should be false after a stopped run")
	TSP:StopTSP() -- must not affect the next run
	run = start(case.nodes, zone, { kicks_per_node = 2 })
	check(run.finish(100000) and run.done and run.iterations == 2 * n, "the run after a stopped run was stopped as well")

	-- the route may be modified as soon as the background run was started
	shims.SeedRandom(1)
	local expected = TSP:SolveTSP(case.nodes, nil, {}, zone, { kicks_per_node = 2 })
	for _, mutate in ipairs({
		function(t) table.remove(t, 50) end,
		function(t) table.insert(t, 50, 12345678) end,
		function(t) for i = #t, 1, -1 do t[i] = nil end end,
	}) do
		local nodes = copy(case.nodes)
		run = start(nodes, zone, { kicks_per_node = 2 })
		mutate(nodes)
		check(run.finish(100000) and run.done, "background run failed after the route was modified: " .. run.printed())
		check(run.done and sameList(run.path, expected), "modifying the route after the start changed the result")
	end

	-- errors: before the first yield they are returned, later they are printed
	run = start(nil, zone, {})
	check(run.status == 3 and type(run.errormsg) == "string", "starting with invalid arguments should return 3 and the error message")
	check(TSP:IsTSPRunning() == false, "IsTSPRunning() should be false after a failed start")
	run = start(case.nodes, -1, {})
	check(run.status == 1, "start with an unknown zone should return 1")
	run.finish(100)
	check(not run.done and run.printed():find("unknown zone", 1, true) or run.printed():find("has no size", 1, true),
		"an error in the background should be printed, got: " .. run.printed())
	check(TSP:IsTSPRunning() == false, "IsTSPRunning() should be false after an error")
	run = start(case.nodes, zone, { kicks_per_node = 1 })
	check(run.status == 1 and run.finish(100000) and run.done, "a run after a failed run did not finish")

	print(("%-22s %s"):format("parameters and API", err and "FAIL" or "ok"))
	if err then
		print("    " .. err)
		failed = failed + 1
		failures[#failures + 1] = "parameters and API"
	else
		passed = passed + 1
	end
end

if bestChanged then
	local names = {}
	for name in pairs(best) do names[#names + 1] = name end
	table.sort(names)
	local f = assert(io.open(dataDir .. "/best.lua", "wb"))
	f:write("-- Shortest route length found so far per case, written by tests/tsp_test.lua --record\n")
	f:write("return {\n")
	for _, name in ipairs(names) do
		f:write(("\t[%q] = %.17g,\n"):format(name, best[name]))
	end
	f:write("}\n")
	f:close()
	print("updated " .. dataDir .. "/best.lua")
end

print(("\n%d passed, %d failed, %.1fs total"):format(passed, failed, os.clock() - total))
if failed > 0 then
	print("FAILED: " .. table.concat(failures, ", "))
end
os.exit(failed > 0 and 1 or 0)
