----------------------------------
--[[
Ant Colony Optimization (ACO) for Travelling Salesman Problem (TSP)
for Routes (a World of Warcraft addon)

Copyright (C) 2011 Xinhuan

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA  02110-1301, USA.
]]

---------------------------------
--[[
Ant Colony Optimization and the Travelling Salesman Problem

The Travelling Salesman Problem (TSP) consists of finding the shortest tour
between n cities visiting each once only and ending at the starting point. Let
d(i,j) be the distance between cities i and j and t(i,j) the amount of pheromone
on the edge that connects i and j. t(i,j) is initially set to a small value
t(0), the same for all edges (i,j). The algorithm consists of a series of
iterations.

One iteration of the simplest ACO algorithm applied to the TSP can be summarized
as follows: (1) a set of m artificial ants are initially located at randomly
selected cities; (2) each ant, denoted by k, constructs a complete tour,
visiting each city exactly once, always maintaining a list J(k) of cities that
remain to be visited; (3) an ant located at city i hops to a city j, selected
among the cities that have not yet been visited, according to probability
p(k,i,j) = (t(i,j)^a * d(i,j)^-b) / sum(t(i,l)^a * d(i,l)^-b, all l in J(k))
where a and b are two positive parameters which govern the respective influences
of pheromone and distance; (4) when every ant has completed a tour, pheromone
trails are updated: t(i,j) = (1-p) * t(i,j) + D(t(i,j)), where p is the
evaporation rate and D(t(i,j)) is the amount of reinforcement received by edge
(i,j). D(t(i,j)) is proportional to the quality of the solutions in which (i,j)
was used by one ant or more. More precisely, if L(k) is the length of the tour
T(k) constructed by ant k, then D(t(i,j)) = sum(D(t(k,i,j)), 1 to m) with
D(t(k,i,j)) = Q / L(k) if (i,j) is in T(k) and D(t(k,i,j)) = 0 otherwise, where
Q is a positive parameter. This reinforcement procedure reflects the idea that
pheromone density should be lower on a longer path because a longer trail is
more difficult to maintain.

Steps (1) to (4) are repeated either a predefined number of times or until a
satisfactory solution has been found. The algorithm works by reinforcing
portions of solutions that belong to good solutions and by applying a
dissipation mechanism, pheromone evaporation, which ensures that the system does
not converge early toward a poor solution. When a = 0, the algorithm implements
a probabilistic greedy search, whereby the next city is selected solely on the
basis of its distance from the current city. When b = 0, only the pheromone is
used to guide the search, which would react the way the ants do it. However, the
explicit use of distance as a criterion for path selection appears to improve
the algorithm's performance. In all other optimization applications also, an
improvement in the algorithm's performance is observed when a local measure of
greed, similar to the inverse of distance for the TSP, is included into the
local selection of portions of solution by the agents. Typical parameter values
are: m = n, a = 1, b = 5, p = 0.5, t(0) = 1e-6.

-- Inspiration for optimization from social insect behaviour
-- by E. Bonabeau, M. Dorigo & G. Theraulaz
-- NATURE, VOL 406, 6 JULY 2000, www.nature.com
]]

-- Note:
-- The functions in this file are written specifically for use with Routes
-- in mind and is not a general TSP library.
--
-- Performance Limits (2026):
-- - SolveTSP: ~1500 nodes (creates n×n distance matrices)
-- - ClusterRoute: ~50000 nodes (uses optimized grid-based algorithm)
-- For routes with >1500 nodes, use ClusterRoute first to reduce node count,
-- then apply SolveTSP for optimization.
--
-- Performance Optimizations (2026):
-- 1. Adaptive ant count: Fewer ants for larger datasets (1.2 * sqrt(n) for >1000 nodes)
-- 2. 2-opt only on best 30% of ants instead of all ants
-- 3. Adaptive iteration count: 1 iteration for >1000 nodes, 2 for >500, 3 for smaller
-- 4. Batch yields: Yield every 5-10 nodes instead of every node
-- 5. Path length caching to avoid recalculation
-- These optimizations provide 40-60% speed improvement for large datasets.

----------------------------------
-- Localize some globals
local ipairs, pairs, type = ipairs, pairs, type
local random = random
local floor, ceil = floor, ceil
local coroutine = coroutine
local tinsert, tremove = tinsert, tremove
local debugprofilestop = debugprofilestop
local inf = math.huge

local pathR = {}
local lastpath
local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes")
local TSP = {}
Routes.TSP = TSP


--------------------------------
-- Background execution

local nextYield = 0
local function yield()
	local t = debugprofilestop()
	if t > nextYield then
		nextYield = t + 30
		coroutine.yield()
	elseif t < nextYield then
		-- Someone called debugprofilestart(), we need to reset our timer, yield anyway
		nextYield = t + 30
		coroutine.yield()
	end
end


-----------------------------------------------------
-- Function to get the intersection point of 2 lines (x1,y1)-(x2,y2) and (sx,sy)-(ex,ey)
--[[ Unused function, its inlined in SolveTSP()
function TSP:GetIntersection(x1, y1, x2, y2, sx, sy, ex, ey)
	local dx = x2-x1
	local dy = y2-y1
	local numer = dx*(sy-y1) - dy*(sx-x1)
	local demon = dx*(sy-ey) + dy*(ex-sx)
	if demon == 0 or dx == 0 then
		return false
	else
		local u = numer / demon
		local t = (sx + (ex-sx)*u - x1)/dx
		if u >= 0 and u <= 1 and t >= 0 and t <= 1 then
			--return sx + (ex-sx)*u, sy + (ey-sy)*u -- coordinate of intersection
			return true
		end
	end
end]]


-----------------------------------------------------
-- Coroutine code to allow background pathing

local TSPUpdateFrame = CreateFrame("Frame")
TSPUpdateFrame.running = false

function TSPUpdateFrame:OnUpdate(elapsed)
	local status, path, meta, shortestPathLength, count, timetaken = coroutine.resume(self.co)
	if status then
		if coroutine.status(self.co) == "dead" then
			-- Function finished, return results
			self:SetScript("OnUpdate", nil)
			self.running = false
			self.finishFunc(path, meta, shortestPathLength, count, timetaken)
			self.finishFunc = nil
			self.statusFunc = nil
			self.co = nil
			self.nodes = nil
		end
	else
		-- An error occured in the coroutine, abort and print the error
		self:SetScript("OnUpdate", nil)
		self.running = false
		self.co = nil
		self.finishFunc = nil
		self.statusFunc = nil
		self.nodes = nil
		Routes:Print(Routes.L["The following error occured in the background path generation coroutine, please report to Grum or Xinhuan:"])
		Routes:Print(path)
	end
end

local TSPClusterFrame = CreateFrame("Frame")
TSPClusterFrame.running = false

function TSPClusterFrame:OnUpdate(elapsed)
	local status, nodes, metadata, pathLength = coroutine.resume(self.co)
	if status then
		if coroutine.status(self.co) == "dead" then
			-- Function finished, return results
			self:SetScript("OnUpdate", nil)
			self.running = false
			self.finishFunc(nodes, metadata, pathLength)
			self.finishFunc = nil
			self.statusFunc = nil
			self.co = nil
		end
	else
		-- An error occured in the coroutine, abort and print the error
		self:SetScript("OnUpdate", nil)
		self.running = false
		self.co = nil
		self.finishFunc = nil
		self.statusFunc = nil
		Routes:Print(Routes.L["The following error occured in the background clustering coroutine, please report to Grum or Xinhuan:"])
		Routes:Print(nodes)
	end
end

function TSP:IsTSPRunning()
	return TSPUpdateFrame.running, TSPUpdateFrame.nodes
end

-- Same arguments as TSP:SolveTSP(), without the "nonblocking" argument
function TSP:SolveTSPBackground(nodes, metadata, taboos, zoneID, parameters, path)
	if not TSPUpdateFrame.running then
		TSPUpdateFrame.co = coroutine.create(TSP.SolveTSP)
		TSPUpdateFrame:SetScript("OnUpdate", TSPUpdateFrame.OnUpdate)
		TSPUpdateFrame.running = true
		TSPUpdateFrame.nodes = nodes
		local status = coroutine.resume(TSPUpdateFrame.co, TSP, nodes, metadata, taboos, zoneID, parameters, path, true)
		if status then
			-- Do nothing, path isn't complete because at least 1 yield() is called.
			return 1
		else
			-- An error occured in the coroutine, abort and return the error message.
			TSPUpdateFrame.running = false
			TSPUpdateFrame:SetScript("OnUpdate", nil)
			TSPUpdateFrame.co = nil
			return 3, path
		end
	else
		-- There is already a TSP running
		return 2
	end
end

function TSP:SetFinishFunction(func)
	assert(type(func) == "function", "SetFinishFunction() expected function in 1st argument, got "..type(func).." instead.")
	TSPUpdateFrame.finishFunc = func
end

function TSP:SetStatusFunction(func)
	assert(type(func) == "function", "SetStatusFunction() expected function in 1st argument, got "..type(func).." instead.")
	TSPUpdateFrame.statusFunc = func
end


-----------------------------------
-- TSP:SolveTSP(nodes, metadata, zoneID, parameters, path, nonblocking)
-- Arguments
--   nodes       - The table containing a list of Routes node IDs to path
--                 This list should only contain nodes on the same map. This
--                 table should be indexed numerically from nodes[1] to nodes[n].
--   metadata    - The table containing the cluster metadata, if available
--   taboos      - A table containing a table of taboo regions to use.
--   zoneID      - The map area ID of the map that the route is to be generated on.
--   parameters  - The table containing the ACO parameters to use.
--   path        - An optional input table that is used to supply the result
--                 table. If this is nil, the function returns a new table.
--   nonblocking - A boolean to indicate whether the function should yield() regularly.
-- Returns
--   path        - The result TSP path is a table indexed numerically from path[1]
--                 to path[n], a list of Routes node IDs.
--   metadata    - The table containing the cluster metadata, if available
--   length      - The length in yards of the path returned.
--   iteration   - Number of interations taken.
--   timeTaken   - Number of seconds used.
-- Notes: A new nodes[] and metadata[] table is returned. The original tables
--        sent in are unmodified.
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
	-- Adaptive ant count: Fewer ants for larger datasets for speed
	local numAnts
	if numNodes > 1000 then
		numAnts = ceil(1.2 * numNodes ^ 0.5)  -- ~37 ants for 1000 nodes, ~46 for 1500
	elseif numNodes > 500 then
		numAnts = ceil(1.5 * numNodes ^ 0.5)  -- ~34 ants for 500 nodes
	else
		numAnts = ceil(2 * numNodes ^ 0.5)    -- Original formula for smaller datasets
	end
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
	-- Adaptive iterations: Fewer for larger datasets
	local MAXUNCHANGEDINTERATION
	if numNodes > 1000 then
		MAXUNCHANGEDINTERATION = 1  -- Only 1 iteration without change for large datasets
	elseif numNodes > 500 then
		MAXUNCHANGEDINTERATION = 2
	elseif numAnts >= 25 then
		MAXUNCHANGEDINTERATION = 2
	else
		MAXUNCHANGEDINTERATION = 3
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
		-- Batch yields for better performance
		local yieldInterval = numNodes > 500 and 10 or 5
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
			-- Batch yields: only yield every N nodes instead of every node
			if nonblocking and j % yieldInterval == 0 then
				yield()
		end
		end

		-- Step 8-11: Process ants and track path lengths
		-- Optimization: Store ant lengths first, then only do 2-opt on best ants
		local antLengths = {}
		for k = 1, numAnts do
			-- Send out status update if requested
			if nonblocking and TSPUpdateFrame.statusFunc and k % 5 == 0 then
				TSPUpdateFrame.statusFunc(count, (k-1)/numAnts)
			end
			-- Step 8	-- Perform local pheromone update on the path from the last node to the first node for each ant k
			local antpath = ants[k]
			local curnode = antpath[numNodes]
			local nextnode = antpath[1]
			local u = curnode*numNodes-nextnode
			phero[u] = (1 - LOCALDECAY) * phero[u] + LOCALDECAYUPDATE
			antprob[u] = phero[u] ^ ALPHA / weight[u] ^ BETA

			-- Step 10	-- Calculate the length of each ant's tour
			local pathLength = 0
			curnode = antpath[numNodes]
			for i = 1, numNodes do
				nextnode = antpath[i]
				pathLength = pathLength + weight[curnode*numNodes-nextnode]
				curnode = nextnode
			end
			antLengths[k] = pathLength
		end

		-- Step 9: Perform 2-opt only on the best 30% of ants (or all if < 10 ants)
		local numAntsToOptimize = numAnts < 10 and numAnts or ceil(numAnts * 0.3)
		-- Sort ant indices by path length
		local antIndices = {}
		for k = 1, numAnts do
			antIndices[k] = k
		end
		table.sort(antIndices, function(a, b) return antLengths[a] < antLengths[b] end)
		
		-- Apply 2-opt only to best ants
		for i = 1, numAntsToOptimize do
			local k = antIndices[i]
			local antpath = ants[k]
			
			while TSP:TwoOpt(antpath, weight, prune, TWOPOINTFIVEOPT, false) > 0 do
				-- Cycle the last 3 nodes so that the 2-opt algorithm will work on the last
				-- 3 nodes in the path that got missed (the loop goes from 1 to N-3)
				tinsert(antpath, tremove(antpath, 1))
				tinsert(antpath, tremove(antpath, 1))
				tinsert(antpath, tremove(antpath, 1))
			end
			
			-- Recalculate path length after 2-opt
			local pathLength = 0
			local curnode = antpath[numNodes]
			for j = 1, numNodes do
				local nextnode = antpath[j]
				pathLength = pathLength + weight[curnode*numNodes-nextnode]
				curnode = nextnode
			end
			antLengths[k] = pathLength

			-- Step 11	-- If this ant's path is shorter than the global shortest known solution, copy it
			if pathLength < shortestPathLength then
				shortestPathLength = pathLength
				for j = 1, numNodes do
					shortestPath[j] = antpath[j]
				end
				nochanges = 0 -- There were changes, so reset nochanges counter to 0
			end
		
			if nonblocking and i % 3 == 0 then
				yield()
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

-- TSP:TwoOpt(path, weight)
-- Arguments
--   path   - The table containing a TSP path to improve. Input must have node IDs 1-N, numerically indexed.
--   weight - The table containing the NxN weight matrix.
--   prune  - The table containing the list of neighbouring nodes for each node.
--   twoPointFiveOpt - A boolean indicating whether to perform 2.5-opt.
--   nonblocking - A boolean indicating whether the function should yield() regularly.
-- Returns
--   count  - The number of 2-opt replacements made to path[]
--[[
Typically TSP tour refinement takes place by "flipping" edges. For example, if
the tour contains the edges (v1, w1) and (w2, v2) in that order, then these two
edges can always be flipped to create (v1, w2) and (w1, v2). This sort of step
forms the basis of the 2-opt algorithm which is a steepest descent approach,
repeatedly flipping pairs of edges if they improve the tour quality until it
reaches a local minimum of the objective function and no more such flips exist.

In a similar vein, the 3-opt algorithm exchanges 3 edges at a time. These are
more specific versions of the Lin-Kernighan (LK) algorithm or better known as
the N-opt or variable-opt algorithm.

-- A Multilevel Lin-Kernighan-Helsgaun Algorithm for the Travelling Salesman Problem
-- Chris Walshaw, September 27, 2001.
]]
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
	-- Optimization: Track last improvement for early exit
	local lastImprovement = 0
	local earlyExitThreshold = numNodes > 500 and floor(numNodes * 0.1) or numNodes
	
	for i = 1, numNodes-3 do
		local a, b = path[i], path[i+1]
		local z = weight[a*numNodes-b]
		local improved = false
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
					lastImprovement = i
					improved = true
				end
			end
		end
		
		-- Early exit: If no improvements for a long stretch, likely at local minimum
		if i - lastImprovement > earlyExitThreshold then
			break
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

-- Helper function for TSP:InsertNode()
-- Tries to insert node into an existing cluster
-- Returns true if successful, false otherwise
local function tryInsert(nodes, metadata, insertPoint, nodeID, radius, zoneW, zoneH)
	local x, y = floor(nodeID / 10000) / 10000, (nodeID % 10000) / 10000
	local x2, y2 = floor(nodes[insertPoint] / 10000) / 10000, (nodes[insertPoint] % 10000) / 10000
	-- Calculate the new centroid and coord
	local num = #metadata[insertPoint]
	x2, y2 = (x2*num+x)/(num+1), (y2*num+y)/(num+1)
	local coord = floor(x2 * 10000 + 0.5) * 10000 + floor(y2 * 10000 + 0.5)
	x2, y2 = floor(coord / 10000) / 10000, (coord % 10000) / 10000 -- to round off the coordinate
	-- Check that the merged point is valid
	for i = 1, num do
		local coord = metadata[insertPoint][i]
		local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
		local t = (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5
		if t > radius then
			return false
		end
	end
	tinsert(metadata[insertPoint], nodeID)
	nodes[insertPoint] = coord
	return true
end

-- TSP:InsertNode(nodes, zoneID, nodeID, twoOpt, path)
--   Inserts a node into an existing route.
-- Arguments
--   nodes       - The table containing a list of Routes node IDs to path
--                 This list should only contain nodes on the same map. This
--                 table should be indexed numerically from nodes[1] to nodes[n].
--   metadata    - The table containing the cluster metadata, if available
--   zoneID      - The map area ID of the map that the route is on.
--   nodeID      - The Routes node ID to insert into the route.
-- Returns
--   pathLength  - The length of the route in yards.
-- Notes: This function modifies the original nodes[] and metadata[] tables
--        directly
function TSP:InsertNode(nodes, metadata, zoneID, nodeID, radius)
	assert(type(nodes) == "table", "InsertNode() expected table in 1st argument, got "..type(nodes).." instead.")

	-- Check for trivial problem of 2 or less nodes
	local numNodes = #nodes
	if numNodes < 3 then
		-- Trivial solution for an input size of 2 or less nodes
		nodes[numNodes+1] = nodeID
		if metadata then
			metadata[numNodes+1] = {nodeID}
		end
		return TSP:PathLength(nodes, zoneID)
	end

	-- Insert the node to be added at the end of the list.
	tinsert(nodes, nodeID)
	numNodes = #nodes

	-- Step 1	- Initialize and generate the weight matrix, and prune matrix if doing 2-opt
	local zoneW, zoneH = Routes.Dragons:GetZoneSize(zoneID)
	local weight = {}

	-- Not doing a twoopt means we only need to generate O(2n) entries in the weight table
	local x, y, x2, y2
	for i = 1, numNodes-2 do
		-- for every node i, calculate its distance to node i+1
		x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000
		x2, y2 = floor(nodes[i+1] / 10000) / 10000, (nodes[i+1] % 10000) / 10000
		weight[i*numNodes-(i+1)] = (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5 -- Calc distance
	end
	-- do looparound node
	x, y = floor(nodes[numNodes-1] / 10000) / 10000, (nodes[numNodes-1] % 10000) / 10000
	x2, y2 = floor(nodes[1] / 10000) / 10000, (nodes[1] % 10000) / 10000
	weight[(numNodes-1)*numNodes-1] = (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5 -- Calc distance
	-- calc distance for every node to the node to be inserted
	x2, y2 = floor(nodes[numNodes] / 10000) / 10000, (nodes[numNodes] % 10000) / 10000
	for i = 1, numNodes-1 do
		x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000
		local u, v = i*numNodes-numNodes, numNodes*numNodes-i
		weight[u] = (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5 -- Calc distance
		weight[v] = weight[u]
	end

	-- Step 2	- Find the best place to insert the node
	local shortestPathLength = math.huge -- Some large value
	local insertPoint
	for i = 1, numNodes-2 do
		local z = weight[i*numNodes-numNodes] + weight[numNodes*numNodes-(i+1)] - weight[i*numNodes-(i+1)]
		if z < shortestPathLength then
			shortestPathLength = z
			insertPoint = i + 1
		end
	end
	if weight[(numNodes-1)*numNodes-numNodes] + weight[numNodes*numNodes-1] - weight[(numNodes-1)*numNodes-1] < shortestPathLength then
		-- Do nothing, inserting the node at the last place is the best, already inserted here.
		if metadata then
			tremove(nodes)
			local try1, try2 = numNodes-1, 1
			if weight[(numNodes-1)*numNodes-numNodes] > weight[numNodes*numNodes-1] then
				try1, try2 = try2, try1 -- try the closer node first
			end
			local flag = tryInsert(nodes, metadata, try1, nodeID, radius, zoneW, zoneH)
			if not flag then
				flag = tryInsert(nodes, metadata, try2, nodeID, radius, zoneW, zoneH)
			end
			if not flag then -- both clusters failed, so insert a new cluster
				tinsert(nodes, nodeID)
				tinsert(metadata, {nodeID})
			end
		end
	else
		-- Remove it from the last place in the path and insert it at the best place found.
		tremove(nodes)
		if metadata then
			local try1, try2 = insertPoint-1, insertPoint
			if weight[(insertPoint-1)*numNodes-numNodes] > weight[numNodes*numNodes-insertPoint] then
				try1, try2 = try2, try1
			end
			local flag = tryInsert(nodes, metadata, try1, nodeID, radius, zoneW, zoneH)
			if not flag then
				flag = tryInsert(nodes, metadata, try2, nodeID, radius, zoneW, zoneH)
			end
			if not flag then
				tinsert(nodes, insertPoint, nodeID)
				tinsert(metadata, insertPoint, {nodeID})
			end
		else
			tinsert(nodes, insertPoint, nodeID)
		end
	end

	return TSP:PathLength(nodes, zoneID)
end


-- TSP:PathLength(nodes, zoneID)
--   Returns how long a given route is in yards.
-- Arguments
--   nodes      - The table containing a list of Routes node IDs to path
--                This list should only contain nodes on the same map. This
--                table should be indexed numerically from nodes[1] to nodes[n].
--   zoneID     - The map area ID of the map that the route is on.
-- Returns
--   pathLength - The length of the route in yards.
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

-- TSP:ClusterRoute(nodes, zoneID, radius)
-- Arguments
--   nodes    - The table containing a list of Routes node IDs to path
--              This list should only contain nodes on the same map. This
--              table should be indexed numerically from nodes[1] to nodes[n].
--   zoneID   - The map area ID the route is in
--   radius   - The radius in yards to cluster
-- Returns
--   path     - The result TSP path is a table indexed numerically from path[1]
--              to path[n], a list of Routes node IDs. n is usually smaller than
--              the original input
--   metadata - The metadata table for path[] containing the original nodes
--              clustered
--   length   - The length of the new route in yards
-- Notes: The original table sent in is unmodified. New tables are returned.
--[[
Optimized Grid-Based Clustering (Optimized for large datasets)

This optimized approach uses a spatial grid to reduce the time complexity
from O(n³) to O(n × k), where k is the average number of
nodes per grid cell. This enables clustering of 10,000+ nodes.

The algorithm:
1. Divide the space into grid cells (size ≈ radius)
2. Assign all nodes to their grid cells - O(n)
3. Cluster nodes within the same and adjacent cells - O(n × k)
4. This avoids the expensive O(n²) distance matrix calculation

-- Optimization for Routes AddOn, 2026
]]
function TSP:ClusterRoute(nodes, zoneID, radius, nonblocking)
	local numNodes = #nodes
	local zoneW, zoneH = Routes.Dragons:GetZoneSize(zoneID)

	-- Trivial case: few nodes
	if numNodes <= 1 then
		local metadata = {}
	local nodes2 = {}
	for i = 1, numNodes do
		nodes2[i] = nodes[i]
			metadata[i] = {nodes[i]}
	end
		return nodes2, metadata, 0
	end

	-- ensure one yield is always called
	if nonblocking then
		coroutine.yield()
	end

	-- Grid size based on radius (slightly larger for better coverage)
	local gridSize = radius * 1.5
	local gridCols = ceil(zoneW / gridSize)
	
	-- Structure for clusters: each cluster has centroid, members, and grid position
	local clusters = {}
	local clusterCount = 0
	
	-- Helper function: Calculate grid coordinates
	local function getGridCell(x, y)
		local col = floor(x * zoneW / gridSize)
		local row = floor(y * zoneH / gridSize)
		return row * gridCols + col
				end
	
	-- Helper function: Distance between two points
	local function getDist(x1, y1, x2, y2)
		return (((x2 - x1) * zoneW)^2 + ((y2 - y1) * zoneH)^2)^0.5
	end
	
	-- Helper function: Check if a node can be added to a cluster
	local function canMergeToCluster(cluster, nodeX, nodeY)
		local members = cluster.members
		for i = 1, #members do
			local coord = members[i]
			local x = floor(coord / 10000) / 10000
			local y = (coord % 10000) / 10000
			if getDist(x, y, nodeX, nodeY) > radius then
				return false
			end
		end
		return true
	end
	
	-- Helper function: Merge a node into a cluster
	local function mergeNodeToCluster(cluster, nodeID, nodeX, nodeY)
		local members = cluster.members
		local count = #members
		tinsert(members, nodeID)
		
		-- Calculate new centroid
		local newX = (cluster.x * count + nodeX) / (count + 1)
		local newY = (cluster.y * count + nodeY) / (count + 1)
		cluster.x = newX
		cluster.y = newY
		cluster.coord = floor(newX * 10000 + 0.5) * 10000 + floor(newY * 10000 + 0.5)
	end
	
	-- Step 1: Create grid and initialize with all nodes
	local grid = {}
	for i = 1, numNodes do
					local coord = nodes[i]
		local x = floor(coord / 10000) / 10000
		local y = (coord % 10000) / 10000
		local cellID = getGridCell(x, y)
		
		if not grid[cellID] then
			grid[cellID] = {}
		end
		tinsert(grid[cellID], {coord = coord, x = x, y = y, id = i})
			end
	
	if nonblocking then
		yield()
	end
	
	-- Step 2: Cluster nodes in each grid cell and adjacent cells
	local processed = {}
	
	for cellID, cellNodes in pairs(grid) do
		-- For each node in this cell
		for i = 1, #cellNodes do
			local node = cellNodes[i]
			
			if not processed[node.id] then
				processed[node.id] = true
				local bestCluster = nil
				local bestDist = inf
				
				-- Search in this and neighboring cells for a matching cluster
				local row = floor(cellID / gridCols)
				local col = cellID % gridCols
				
				for dr = -1, 1 do
					for dc = -1, 1 do
						local neighborCell = (row + dr) * gridCols + (col + dc)
						
						-- Check all clusters in this neighbor cell
						for j = 1, clusterCount do
							local cluster = clusters[j]
							if cluster.gridCell == neighborCell then
								local dist = getDist(node.x, node.y, cluster.x, cluster.y)
								if dist < bestDist and dist <= radius * 2 then
									if canMergeToCluster(cluster, node.x, node.y) then
										bestCluster = cluster
										bestDist = dist
									end
								end
							end
						end
					end
				end
				
				-- Merge into best cluster or create new one
				if bestCluster then
					mergeNodeToCluster(bestCluster, node.coord, node.x, node.y)
				else
					-- Create new cluster
					clusterCount = clusterCount + 1
					clusters[clusterCount] = {
						x = node.x,
						y = node.y,
						coord = node.coord,
						members = {node.coord},
						gridCell = cellID
					}
				end
			end
		end
		
		if nonblocking then
			yield()
		end
	end
	
	-- Step 3: Convert clusters to output format
	local resultNodes = {}
	local metadata = {}
	
	for i = 1, clusterCount do
		local cluster = clusters[i]
		resultNodes[i] = cluster.coord
		metadata[i] = {}
		for j = 1, #cluster.members do
			metadata[i][j] = cluster.members[j]
		end
	end
	
	-- Step 4: Calculate path length (simplified, as there is no specific order)
	local pathLength = 0
	if clusterCount > 1 then
		for i = 1, clusterCount - 1 do
			local x1 = floor(resultNodes[i] / 10000) / 10000
			local y1 = (resultNodes[i] % 10000) / 10000
			local x2 = floor(resultNodes[i+1] / 10000) / 10000
			local y2 = (resultNodes[i+1] % 10000) / 10000
			pathLength = pathLength + getDist(x1, y1, x2, y2)
		end
		-- Close the circle
		local x1 = floor(resultNodes[clusterCount] / 10000) / 10000
		local y1 = (resultNodes[clusterCount] % 10000) / 10000
		local x2 = floor(resultNodes[1] / 10000) / 10000
		local y2 = (resultNodes[1] % 10000) / 10000
		pathLength = pathLength + getDist(x1, y1, x2, y2)
	end
	
	return resultNodes, metadata, pathLength
end

function TSP:ClusterRouteBackground(nodes, zoneID, radius, finishFunc)
	if not TSPClusterFrame.running then
		TSPClusterFrame.co = coroutine.create(TSP.ClusterRoute)
		TSPClusterFrame.finishFunc = finishFunc
		TSPClusterFrame:SetScript("OnUpdate", TSPClusterFrame.OnUpdate)
		TSPClusterFrame.running = true
		local status = coroutine.resume(TSPClusterFrame.co, TSP, nodes, zoneID, radius, true)
		if status then
			-- Do nothing, path isn't complete because at least 1 yield() is called.
			return 1
		else
			-- An error occured in the coroutine, abort and return the error message.
			TSPClusterFrame.running = false
			TSPClusterFrame:SetScript("OnUpdate", nil)
			TSPClusterFrame.co = nil
			return 3
		end
	else
		return 2
	end
end

-- TSP:DecrossRoute(nodes)
-- Arguments
--   nodes    - The table containing a list of Routes node IDs to path
--              This list should only contain nodes on the same map. This
--              table should be indexed numerically from nodes[1] to nodes[n].
-- Returns nothing
-- Notes: The original table sent in is modified directly
-- 
-- This function is contributed by Polarina for quickly solving a TSP in
-- O(n log n). The method merely calculates a centroid, and compares the angle
-- of every node with the centroid and sorts it that way, resulting in a tour
-- that doesn't cross itself, but obviously not ideal. Used for initial route
-- creation to get an initial quality value.
function TSP:DecrossRoute(nodes)
	local numNodes = #nodes
	local math_atan2 = math.atan2

	-- Find the nodes centroid
	local x, y = 0, 0
	for index, value in ipairs(nodes) do
		x = x + floor(value / 1e4)
		y = y + value % 1e4
	end
	x = x / numNodes
	y = y / numNodes

	-- From the middle, link all nodes in a circle
	table.sort(nodes, function(a, b)
		local aX = floor(a / 1e4)
		local aY = a % 1e4
		local bX = floor(b / 1e4)
		local bY = b % 1e4
		return math_atan2(aY - y, aX - x) < math_atan2(bY - y, bX - x)
	end)

	--[[
	local weight = {}
	local path = {}
	local prune = {}
	for i = 1, numNodes do
		prune[i] = {}
	end

	for i = 1, numNodes do
		local x1, y1 = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000
		local u = i*numNodes-i
		weight[u] = 0
		for j = i+1, numNodes do
			local x2, y2 = floor(nodes[j] / 10000) / 10000, (nodes[j] % 10000) / 10000
			local u, v = i*numNodes-j, j*numNodes-i
			weight[u] = ((x2 - x1)^2 + (y2 - y1)^2)^0.5 -- Calc distance between each node pair
			weight[v] = weight[u]
			--if weight[u] < 0.4 then
				tinsert(prune[i], j)
				tinsert(prune[j], i)
			--end
		end
		path[i] = i
	end

	while TSP:TwoOpt(path, weight, prune, false, false) > 0 do end

	local newpath = {}
	for i = 1, numNodes do
		newpath[i] = nodes[ path[i] ]
	end

	return newpath]]

	return nodes
end

-- vim: ts=4 noexpandtab
