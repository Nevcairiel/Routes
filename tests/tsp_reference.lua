--[[
	FROZEN REFERENCE IMPLEMENTATION - DO NOT EDIT

	Verbatim copies of TSP:SolveTSP(), TSP:TwoOpt() and TSP:PathLength() as of
	commit 93cd4d7 (the Ant Colony Optimization solver with an NxN weight
	matrix). Used as the quality and performance baseline for the route
	optimizer tests:
	  - tests/tsp_gen.lua uses it to generate the *.baseline.lua files
	  - tests/tsp_test.lua --reference runs the test suite against it

	Usage: local ref = loadfile("tests/tsp_reference.lua")(Routes)
	       ref:SolveTSP(nodes, metadata, taboos, zoneID, parameters)
]]
local Routes = ...
local ipairs, pairs, type = ipairs, pairs, type
local random = random
local floor, ceil = math.floor, math.ceil
local coroutine = coroutine
local tinsert, tremove = table.insert, table.remove
local wipe = table.wipe
local debugprofilestop = debugprofilestop
local inf = math.huge
local pathR = {}
local lastpath
local function yield() end
local TSPUpdateFrame = {}
local TSP = {}

function TSP:SolveTSP(nodes, metadata, taboos, zoneID, parameters, path, nonblocking)
	-- Notes: Some of these code might look convoluted, with seemingly unnecessary use of too many locals
	-- and make the code look longer. But they are for speed optimization.
	assert(type(nodes) == "table", "SolveTSP() expected table in 1st argument, got "..type(nodes).." instead.")
	assert(type(taboos) == "table", "SolveTSP() expected table in 3rd argument, got "..type(taboos).." instead.")
	assert(type(parameters) == "table", "SolveTSP() expected table in 5th argument, got "..type(parameters).." instead.")
	if type(path) == "table" then
		wipe(path)
	else
		path = {}
	end

	if nonblocking then
		-- Ensure that at least 1 yield() is called in a nonblocking call
		coroutine.yield()
	end

	-- Check for trivial problem of 3 or less nodes
	local numNodes = #nodes
	if numNodes < 4 then
		-- Trivial solution for an input size of 3 or less nodes
		for i = 1, numNodes do
			path[i] = nodes[i]
		end
		-- Create a copy of the metadata[] table too, if there is one
		local metadata2
		if metadata then
			metadata2 = {}
			for i = 1, numNodes do
				metadata2[i] = {}
				for j = 1, #metadata[i] do
					metadata2[i][j] = metadata[i][j]
				end
			end
		end
		return path, metadata2, TSP:PathLength(path, zoneID), 0, 0
	end

	-- Create a copy of the nodes[] table and use this instead of the original because data could get changed
	local nodes2 = {}
	for i = 1, numNodes do
		nodes2[i] = nodes[i]
	end
	local nodes = nodes2
	-- Create a copy of the metadata[] table too, if there is one
	local metadata2
	if metadata then
		metadata2 = {}
		for i = 1, numNodes do
			metadata2[i] = {}
			for j = 1, #metadata[i] do
				metadata2[i][j] = metadata[i][j]
			end
		end
	end
	local metadata = metadata2
	
	-- Setup ACO parameters
	local startTime
	if nonblocking then
		startTime = GetTime()
	else
		startTime = debugprofilestop()
	end
	local zoneW, zoneH	= Routes.Dragons:GetZoneSize(zoneID)

	local INITIAL_PHEROMONE = parameters.initial_pheromone or 0.1   -- Parameter: Initial pheromone trail value
	local ALPHA             = parameters.alpha or 1                 -- Parameter: Likelihood of ants to follow pheromone trails (larger value == more likely)
	local BETA              = parameters.beta or 6                  -- Parameter: Likelihood of ants to choose closer nodes (larger value == more likely)
	local LOCALDECAY        = parameters.local_decay or 0.2         -- Parameter: Governs local trail decay rate [0, 1]
	local LOCALUPDATE       = parameters.local_update or 0.4        -- Parameter: Amount of pheromone to reinforce local trail update by
	local GLOBALDECAY       = parameters.global_decay or 0.2        -- Parameter: Governs global trail decay rate [0, 1]
	local TWOOPTPASSES      = parameters.twoopt_passes or 3         -- Parameter: Number of times to perform 2-opt passes
	local TWOPOINTFIVEOPT   = parameters.two_point_five_opt or false-- Parameter: Run improved 2-opt pass?
	local QUALITY           = 2 * zoneH                             -- Parameter: Tunable parameter that should be somewhat close to 1/4 to 1/2 (distance) of a good solution
	local numAnts           = ceil(2 * numNodes ^ 0.5)              -- Parameter: Number of ants.
	local LOCALDECAYUPDATE  = LOCALDECAY * LOCALUPDATE              -- Just a constant.
	-- If ALPHA = 0, the closest cities are more likely to be selected.
	-- If BETA = 0, only pheromone amplifications is at work.
	-- The number of ants will directly determine the speed of the algorithm proportionally. More ants will get more optimal results, but don't use more ants than the number of nodes.
	-- You need more ants when there are more nodes to have more chances to find a good path quickly. The usual default is numAnts = numNodes, but this takes too long in WoW.
	local PRUNEDIST         = zoneW * 0.30                          -- Another constant for our own pruning

	local shortestPathLength = math.huge
	local shortestPath = {}

	-- Step 1	- Initialize and generate the weight matrix, the pheromone matrix and the ants
	local weight = {}
	local phero = {}
	local ants = {}
	local prune = {}
	local antprob = {}
	for i = 1, numNodes do
		prune[i] = {}
	end

	for i = 1, numNodes do
		local x1, y1 = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000
		local u = i*numNodes-i
		weight[u] = 0
		phero[u] = INITIAL_PHEROMONE
		for j = i+1, numNodes do
			local x2, y2 = floor(nodes[j] / 10000) / 10000, (nodes[j] % 10000) / 10000
			local u, v = i*numNodes-j, j*numNodes-i
			weight[u] = (((x2 - x1)*zoneW)^2 + ((y2 - y1)*zoneH)^2)^0.5 -- Calc distance between each node pair
			weight[v] = weight[u]
			phero[u] = INITIAL_PHEROMONE -- All pheromone trails start
			phero[v] = INITIAL_PHEROMONE -- with a initial small value
			-- Table containing data for 2-opt pruning operations. This is just a list of nodes that are near each node.
			if weight[u] < PRUNEDIST then
				tinsert(prune[i], j)
				tinsert(prune[j], i)
			end
			-- For taboo regions
			local flag = false
			for m = 1, #taboos do -- loop over every taboo
				local taboo_data = taboos[m].route
				local last_point = taboo_data[ #taboo_data ]
				local sx, sy = floor(last_point / 10000) / 10000, (last_point % 10000) / 10000
				for n = 1, #taboo_data do
					local point = taboo_data[n]
					local ex, ey = floor(point / 10000) / 10000, (point % 10000) / 10000
					-- inlined the intersection check so that it is faster
					local dx = x2-x1
					local dy = y2-y1
					local numer = dx*(sy-y1) - dy*(sx-x1)
					local demon = dx*(sy-ey) + dy*(ex-sx)
					if demon ~= 0 and dx ~= 0 then
						local u = numer / demon
						local t = (sx + (ex-sx)*u - x1)/dx
						if u >= 0 and u <= 1 and t >= 0 and t <= 1 then
							flag = true
							break
						end
					end
					sx, sy = ex, ey
					last_point = point
				end
				if flag then break end
			end
			if flag then -- we increase/bias the weight by a constant factor and by the zone width, since it passes thru a taboo region
				weight[u] = weight[u] * 2 + zoneW
				weight[v] = weight[u]
			end

			-- Initialize the probability table of travelling from city i to j
			antprob[u] = phero[u] ^ ALPHA / weight[u] ^ BETA
			antprob[v] = antprob[u]
		end
	end
	for k = 1, numAnts do
		ants[k] = {}
		local antpath = ants[k] -- This table will stores both the partially constructed path (from 1 to j) and the remainder unvisited nodes (from j+1 to N)
		for j = 1, numNodes do
			antpath[j] = j
		end
	end

	-- Step 2	- Loop until path has small to no changes over the last MAXUNCHANGEDINTERATION iterations
	local nochanges = 0
	local count = 0
	local MAXUNCHANGEDINTERATION = 3
	if numAnts >= 25 then
		MAXUNCHANGEDINTERATION = 2
	end
	while nochanges < MAXUNCHANGEDINTERATION do
		nochanges = nochanges + 1
		count = count + 1
		
		-- Step 3	- Each ant k starts at a randomly selected node
		for k = 1, numAnts do
			local antpath = ants[k]
			local p = random(numNodes)
			antpath[1], antpath[p] = antpath[p], antpath[1]
		end

		-- Step 4	- Construct/path the next N-1 nodes...
		for j = 1, numNodes-1 do
			-- Step 5	- ...for each ant k
			for k = 1, numAnts do
				-- Step 6	- Calculate the probability of visiting each remainder node, and the total probability
				local antpath = ants[k]
				local curnode = antpath[j] -- j is the "current node" index in the path
				local totalprob = 0
				for i = j+1, numNodes do
					local u = curnode*numNodes-antpath[i]
					totalprob = totalprob + antprob[u]
				end
				-- Step 7	- Now randomly choose one of these nodes to go to based on the calculated probabilities
				local p = totalprob * random()
				totalprob = 0
				for i = j+1, numNodes do
					local u = curnode*numNodes-antpath[i]
					totalprob = totalprob + antprob[u]
					if p <= totalprob then
						antpath[j+1], antpath[i] = antpath[i], antpath[j+1]
						phero[u] = (1 - LOCALDECAY) * phero[u] + LOCALDECAYUPDATE -- Perform local pheromone update
						antprob[u] = phero[u] ^ ALPHA / weight[u] ^ BETA -- Update the probability
						break
					end
				end
			end
			if nonblocking then
				yield()
			end
		end

		for k = 1, numAnts do
			-- Send out status update if requested  (this loop is the one that actually takes lots of time)
			if nonblocking and TSPUpdateFrame.statusFunc then
				TSPUpdateFrame.statusFunc(count, (k-1)/numAnts)
			end
			-- Step 8	-- Perform local pheromone update on the path from the last node to the first node for each ant k
			local antpath = ants[k]
			local curnode = antpath[numNodes]
			local nextnode = antpath[1]
			local u = curnode*numNodes-nextnode
			phero[u] = (1 - LOCALDECAY) * phero[u] + LOCALDECAYUPDATE
			antprob[u] = phero[u] ^ ALPHA / weight[u] ^ BETA

			-- Step 9	-- Perform 2-opt on the path to improve it
			--[[for i = 1, TWOOPTPASSES do
				if nonblocking then
					yield()
				end
				if TSP:TwoOpt(antpath, weight, prune) == 0 then
					break
				end
			end]]
			while TSP:TwoOpt(antpath, weight, prune, TWOPOINTFIVEOPT, nonblocking) > 0 do
				-- Cycle the last 3 nodes so that the 2-opt algorithm will work on the last
				-- 3 nodes in the path that got missed (the loop goes from 1 to N-3)
				tinsert(antpath, tremove(antpath, 1))
				tinsert(antpath, tremove(antpath, 1))
				tinsert(antpath, tremove(antpath, 1))
				if nonblocking then
					yield()
				end
			end

			-- Step 10	-- At the same time, we also calculate the length of each ant's tour
			local pathLength = 0
			curnode = antpath[numNodes]
			for i = 1, numNodes do
				nextnode = antpath[i]
				pathLength = pathLength + weight[curnode*numNodes-nextnode]
				curnode = nextnode
			end

			-- Step 11	-- If this ant's path is shorter than the global shortest known solution, copy it
			if pathLength < shortestPathLength then
				shortestPathLength = pathLength
				for i = 1, numNodes do
					shortestPath[i] = antpath[i]
				end
				nochanges = 0 -- There were changes, so reset nochanges counter to 0
			end
		
		end
			
		-- Step 12	- Perform global pheromone trail update on the best known solution
		local curnode = shortestPath[numNodes]
		local tempConstant = GLOBALDECAY * QUALITY / shortestPathLength
		for i = 1, numNodes do
			local nextnode = shortestPath[i]
			local u = curnode*numNodes-nextnode
			phero[u] = (1 - GLOBALDECAY) * phero[u] + tempConstant
			antprob[u] = phero[u] ^ ALPHA / weight[u] ^ BETA -- Update the probability
			curnode = nextnode
		end
		
		-- report how long path this round found (with progress==1)
		if nonblocking and TSPUpdateFrame.statusFunc then
			TSPUpdateFrame.statusFunc(count, 1, shortestPathLength)
			yield()
		end
	end

	do
		-- Perform a non-pruned 2-opt on the final path so that there is absolutely no criss-cross
		local noprune = {}
		for i = 1, numNodes do
			noprune[i] = {}
		end
		for i = 1, numNodes do
			for j = i+1, numNodes do
				tinsert(noprune[i], j)
				tinsert(noprune[j], i)
			end
		end
		while TSP:TwoOpt(shortestPath, weight, noprune, TWOPOINTFIVEOPT, nonblocking) > 0 do
			tinsert(shortestPath, tremove(shortestPath, 1))
			tinsert(shortestPath, tremove(shortestPath, 1))
			tinsert(shortestPath, tremove(shortestPath, 1))
			if nonblocking then
				yield()
			end
		end
		
		-- Recompute the path length
		shortestPathLength = 0
		local curnode = shortestPath[numNodes]
		for i = 1, numNodes do
			local nextnode = shortestPath[i]
			shortestPathLength = shortestPathLength + weight[curnode*numNodes-nextnode]
			curnode = nextnode
		end
	end

	-- Step 13	-- Check the length of the original tour that was sent in in nodes[]
	local pathLength = 0
	for i = 2, numNodes do
		pathLength = pathLength + weight[(i-1)*numNodes-i]
	end
	pathLength = pathLength + weight[numNodes*numNodes-1]

	-- Step 14	-- Check solution with original that was sent in
	if pathLength < shortestPathLength then
		-- TSP didn't find a shorter solution, so copy the input to the output
		for i = 1, numNodes do
			path[i] = nodes[i]
		end
		shortestPathLength = pathLength
	else
		-- TSP found a shorter path than the original, convert our shortest path to the output format wanted
		local meta
		if metadata then
			meta = {}
		end
		for i = 1, numNodes do
			path[i] = nodes[shortestPath[i]]
			if metadata then
				meta[i] = metadata[shortestPath[i]]
			end
		end
		metadata = meta -- prev metadata[] not recycled here, will go out of scope at function end and get GCed
	end

	lastpath = nil

	-- This step is necessary because our pathlength above is calculated from biased data from taboos
	shortestPathLength = TSP:PathLength(path, zoneID)

	if nonblocking then
		startTime = GetTime() - startTime
	else
		startTime = debugprofilestop() - startTime
		startTime = startTime / 1000
	end
	return path, metadata, shortestPathLength, count, startTime
end

function TSP:TwoOpt(path, weight, prune, twoPointFiveOpt, nonblocking)
	local count = 0
	local numNodes = #path
	local pathR = pathR

	-- Generate reverse lookup table
	if lastpath ~= path then
		for i = 1, numNodes do
			pathR[path[i]] = i
		end
	end

	-- Perform normal 2-opt
	for i = 1, numNodes-3 do
		local a, b = path[i], path[i+1]
		local z = weight[a*numNodes-b]
		--for j = i+2, numNodes-1 do
		for m = 1, #prune[a] do
			local j = pathR[prune[a][m]]
			if j > i+1 and j ~= numNodes then
				local c, d = path[j], path[j+1]
				local currW = z + weight[c*numNodes-d]
				local newW = weight[a*numNodes-c] + weight[b*numNodes-d]
				if newW < currW then
					-- Swap these 2 edges to get a shorter path
					-- This is done by reversing the node order between i+1 to j
					local left = i+1
					local right = j
					while left < right do
						local L, R = path[right], path[left]
						path[left], path[right] = L, R
						pathR[L], pathR[R] = left, right
						left = left + 1
						right = right - 1
					end
					b = path[i+1]
					z = weight[a*numNodes-b]
					count = count + 1
				end
			end
		end
	end

	-- Then perform 2.5-opt
	if twoPointFiveOpt then
		if nonblocking then
			yield()
		end
		for i = 1, numNodes-4 do
			local a, b, c = path[i], path[i+1], path[i+2]
			local z = weight[a*numNodes-b] + weight[b*numNodes-c]
			for m = 1, #prune[a] do
				local j = pathR[prune[a][m]]
				if j > i+2 and j ~= numNodes then
					local d, e = path[j], path[j+1]
					local currW = z + weight[d*numNodes-e]
					local newW = weight[a*numNodes-c] + weight[d*numNodes-b] + weight[b*numNodes-e]
					if newW < currW then
						-- Remove node b from the path, then reinsert it between d and e
						for q = i+1, j-1 do
							path[q] = path[q+1]
							pathR[path[q]] = q
						end
						path[j] = b
						pathR[b] = j
						b, c = path[i+1], path[i+2]
						z = weight[a*numNodes-b] + weight[b*numNodes-c]
						count = count + 1
					end
				end
			end
		end
	end

	lastpath = path
	return count
end

function TSP:PathLength(nodes, zoneID)
	assert(type(nodes) == "table", "PathLength() expected table in 1st argument, got "..type(nodes).." instead.")
	local zoneW, zoneH = Routes.Dragons:GetZoneSize(zoneID)
	local numNodes = #nodes
	local pathLength = 0

	-- Check for trivial problem of 1 or less nodes
	if numNodes <= 1 then
		return 0
	end

	-- Get coordinate of last node
	local x2, y2 = floor(nodes[numNodes] / 10000) / 10000, (nodes[numNodes] % 10000) / 10000
	for i = 1, #nodes do
		local x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000
		pathLength = pathLength + (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5
		x2, y2 = x, y
	end

	return pathLength
end

return TSP
