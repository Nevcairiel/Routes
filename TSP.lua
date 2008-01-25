----------------------------------
--[[
Ant Colony Optimization (ACO) for Travelling Salesman Problem (TSP)
for Routes (a World of Warcraft addon)

Copyright (C) 2007 Xinhuan

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

----------------------------------
-- Localize some globals
local pairs = pairs;
local random = random;
local floor = floor;
local coroutine = coroutine;
local tinsert, tremove = tinsert, tremove;

local pathR = {};
local lastpath;
local BZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable();

----------------------------------
-- Table Pool for recycling tables
local tablePool = {};
setmetatable(tablePool, {__mode = "kv"});	-- Weak table

-- Get a new table
local function newTable()
	local t = next(tablePool) or {};
	tablePool[t] = nil;
	return t;
end

-- Delete table and return to pool -- Recursive!! -- Use with care!!
local function delTable(t)
	if (type(t) == "table") then
		for k, v in pairs(t) do
			if (type(v) == "table") then
				delTable(v);	-- child tables get put into the pool
			end
			t[k] = nil;
		end
		t[true] = true;		-- resize table to 1 item
		t[true] = nil;
		setmetatable(t, nil);
		tablePool[t] = true;
	end
	return nil;	-- return nil to assign input reference
end

-- Empties a table of everything -- Non-recursive
local function clearTable(t)
	if (type(t) == "table") then
		for k, v in pairs(t) do
			t[k] = nil;
		end
		t[true] = true;
		t[true] = nil;
		setmetatable(t, nil);
	end
end

local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes");
local TSP = {};
Routes.TSP = TSP;

-----------------------------------------------------
-- Coroutine code to allow background pathing

local TSPUpdateFrame = CreateFrame("Frame");
TSPUpdateFrame.running = false;

function TSPUpdateFrame:OnUpdate(elapsed)
	local status, path, shortestPathLength, count, timetaken = coroutine.resume(self.co);
	if (status) then
		if (coroutine.status(self.co) == "dead") then
			-- Function finished, return results
			self:SetScript("OnUpdate", nil);
			self.running = false;
			self.finishFunc(path, shortestPathLength, count, timetaken);
			self.finishFunc = nil;
			self.co = nil;
			self.nodes = nil;
		end
	else
		-- An error occured in the coroutine, abort and print the error
		self:SetScript("OnUpdate", nil);
		self.running = false;
		self.co = nil;
		self.finishFunc = nil;
		self.nodes = nil;
		Routes:Print(Routes.L["The following error occured in the background path generation coroutine, please report to Grum or Xinhuan:"]);
		Routes:Print(path);
	end
end

function TSP:IsTSPRunning()
	return TSPUpdateFrame.running, TSPUpdateFrame.nodes;
end

function TSP:SolveTSPBackground(nodes, zonename, parameters, path)
	if (not TSPUpdateFrame.running) then
		TSPUpdateFrame.co = coroutine.create(TSP.SolveTSP);
		TSPUpdateFrame:SetScript("OnUpdate", TSPUpdateFrame.OnUpdate);
		TSPUpdateFrame.running = true;
		TSPUpdateFrame.nodes = nodes;
		local status = coroutine.resume(TSPUpdateFrame.co, TSP, nodes, zonename, parameters, path, true);
		if (status) then
			-- Do nothing, path isn't complete because at least 1 yield() is called.
			return 1;
		else
			-- An error occured in the coroutine, abort and return the error message.
			TSPUpdateFrame.running = false;
			TSPUpdateFrame:SetScript("OnUpdate", nil);
			TSPUpdateFrame.co = nil;
			return 3, path;
		end
	else
		-- There is already a TSP running
		return 2;
	end
end

function TSP:SetFinishFunction(func)
	assert(type(func) == "function", "SetFinishFunction() expected function in 1st argument, got "..type(func).." instead.");
	TSPUpdateFrame.finishFunc = func;
end

-----------------------------------
-- TSP:SolveTSP(nodes, zonename, parameters, path)
-- Arguments
--   nodes	- The table containing a list of Routes node IDs to path
--		  This list should only contain nodes on the same map. This
--		  table should be indexed numerically from nodes[1] to nodes[n].
--   zonename	- The English zone name of the map that the route to be
--		  generated is on.
--   parameters	- The table containing the ACO parameters to use.
--   path	- An optional input table that is used to supply the result
--		  table. If this is nil, the function returns a new table.
--   nonblocking- A boolean to indicate whether the function should yield() regularly.
-- Returns
--   path	- The result TSP path is a table indexed numerically from path[1]
--		  to path[n], a list of Routes node IDs.
--   length	- The length in yards of the path returned.
--   iteration  - Number of interations taken.
--   timeTaken  - Number of seconds used.
function TSP:SolveTSP(nodes, zonename, parameters, path, nonblocking)
	-- Notes: Some of these code might look convoluted, with seemingly unnecessary use of too many locals
	-- and make the code look longer. But they are for speed optimization.
	assert(type(nodes) == "table", "SolveTSP() expected table in 1st argument, got "..type(nodes).." instead.");
	assert(type(parameters) == "table", "SolveTSP() expected table in 3rd argument, got "..type(parameters).." instead.");
	if (type(path) == "table") then
		clearTable(path);
	else
		path = newTable();
	end

	if (nonblocking) then
		-- Ensure that at least 1 yield() is called in a nonblocking call
		coroutine.yield();
	end

	-- Check for trivial problem of 3 or less nodes
	local numNodes = #nodes;
	if (numNodes < 4) then
		-- Trivial solution for an input size of 3 or less nodes
		for i = 1, numNodes do
			path[i] = nodes[i];
		end
		-- TO DO: Calculate tour length here instead of returning 0
		return path, TSP:PathLength(path, zonename), 0, 0;
	end

	-- Create a copy of the nodes[] table and use this instead of the original because data could get changed
	local nodes2 = newTable()
	for i = 1, numNodes do
		nodes2[i] = nodes[i]
	end
	local nodes = nodes2
	
	-- Setup ACO parameters
	local startTime		= GetTime();
	local zoneW, zoneH	= Routes.zoneData[BZ[zonename]][1], Routes.zoneData[BZ[zonename]][2]

	local INITIAL_PHEROMONE = parameters.initial_pheromone or 0;     -- Parameter: Initial pheromone trail value
	local ALPHA             = parameters.alpha or 1;                 -- Parameter: Likelihood of ants to follow pheromone trails (larger value == more likely)
	local BETA              = parameters.beta or 6;                  -- Parameter: Likelihood of ants to choose closer nodes (larger value == more likely)
	local LOCALDECAY        = parameters.local_decay or 0.2;         -- Parameter: Governs local trail decay rate [0, 1]
	local LOCALUPDATE       = parameters.local_update or 0.4;        -- Parameter: Amount of pheromone to reinforce local trail update by
	local GLOBALDECAY       = parameters.global_decay or 0.2;        -- Parameter: Governs global trail decay rate [0, 1]
	local TWOOPTPASSES      = parameters.twoopt_passes or 3;         -- Parameter: Number of times to perform 2-opt passes
	local TWOPOINTFIVEOPT   = parameters.two_point_five_opt or false;-- Parameter: Run improved 2-opt pass?
	local QUALITY           = zoneH;                                 -- Parameter: Tunable parameter that should be somewhat close to 1/4 to 1/2 (distance) of a good solution
	local numAnts           = ceil(2 * numNodes ^ 0.5);              -- Parameter: Number of ants.
	local LOCALDECAYUPDATE  = LOCALDECAY * LOCALUPDATE;              -- Just a constant.
	-- If ALPHA = 0, the closest cities are more likely to be selected.
	-- If BETA = 0, only pheromone amplifications is at work.
	-- The number of ants will directly determine the speed of the algorithm proportionally. More ants will get more optimal results, but don't use more ants than the number of nodes.
	-- You need more ants when there are more nodes to have more chances to find a good path quickly. The usual default is numAnts = numNodes, but this takes too long in WoW.

	local shortestPathLength = 1e100;	-- Some large value
	local shortestPath = newTable();

	-- Step 1	- Initialize and generate the weight matrix, the pheromone matrix and the ants
	local weight = newTable();
	local phero = newTable();
	local ants = newTable();
	local prune = newTable();
	for i = 1, numNodes do
		prune[i] = newTable();
	end
	for i = 1, numNodes do
		local x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000;
		local u = i*numNodes-i;
		weight[u] = 0;
		phero[u] = INITIAL_PHEROMONE;
		for j = i+1, numNodes do
			local x2, y2 = floor(nodes[j] / 10000) / 10000, (nodes[j] % 10000) / 10000;
			local u, v = i*numNodes-j, j*numNodes-i;
			weight[u] = (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5;	-- Calc distance between each node pair
			weight[v] = weight[u];
			phero[u] = INITIAL_PHEROMONE;	-- All pheromone trails start
			phero[v] = INITIAL_PHEROMONE;	-- with a initial small value
			-- Table containing data for 2-opt pruning operations. This is just a list of nodes that are near each node.
			if (weight[u] < zoneW * 0.15) then
				tinsert(prune[i], j);
				tinsert(prune[j], i);
			end
		end
	end
	for k = 1, numAnts do
		ants[k] = newTable();
		local ant = ants[k];
		ant.path = newTable();	-- This table will stores both the partially constructed path (from 1 to j) and the remainder unvisited nodes (from j+1 to N)
		ant.prob = newTable();	-- This stores the probability to visit each node
		local antpath = ant.path;
		for j = 1, numNodes do
			antpath[j] = j;
		end
	end

	-- Step 2	- Loop until path has small to no changes over the last MAXUNCHANGEDINTERATION iterations
	local nochanges = 0;
	local count = 0
	local MAXUNCHANGEDINTERATION = 3;
	if (numAnts >= 25) then
		MAXUNCHANGEDINTERATION = 2;
	end
	while (nochanges < MAXUNCHANGEDINTERATION) do
		nochanges = nochanges + 1;
		count = count + 1;
		
		-- Step 3	- Each ant k starts at a randomly selected node
		for k = 1, numAnts do
			local antpath = ants[k].path;
			local p = random(numNodes);
			antpath[1], antpath[p] = antpath[p], antpath[1];
		end

		-- Step 4	- Construct/path the next N-1 nodes...
		for j = 1, numNodes-1 do
			-- Step 5	- ...for each ant k
			for k = 1, numAnts do
				-- Step 6	- Calculate the probability of visiting each remainder node, and the total probability
				local antpath = ants[k].path;
				local antprob = ants[k].prob;
				local curnode = antpath[j];	-- j is the "current node" index in the path
				local totalprob = 0;
				for i = j+1, numNodes do
					local u = curnode*numNodes-antpath[i];
					antprob[i] = phero[u] ^ ALPHA / weight[u] ^ BETA;
					totalprob = totalprob + antprob[i];
				end
				-- Step 7	- Now randomly choose one of these nodes to go to based on the calculated probabilities
				local p = totalprob * random();
				totalprob = 0;
				for i = j+1, numNodes do
					totalprob = totalprob + antprob[i];
					if (p <= totalprob) then
						local nextnode = antpath[i];
						antpath[j+1], antpath[i] = nextnode, antpath[j+1];
						local u = curnode*numNodes-nextnode;
						phero[u] = (1 - LOCALDECAY) * phero[u] + LOCALDECAYUPDATE;	-- Perform local pheromone update
						break;
					end
				end
			end
			if (nonblocking) then
				coroutine.yield();
			end
		end

		for k = 1, numAnts do
			-- Step 8	-- Perform local pheromone update on the path from the last node to the first node for each ant k
			local antpath = ants[k].path;
			local curnode = antpath[numNodes];
			local nextnode = antpath[1];
			local u = curnode*numNodes-nextnode;
			phero[u] = (1 - LOCALDECAY) * phero[u] + LOCALDECAYUPDATE;

			-- Step 9	-- Perform 2-opt on the path to improve it
			--[[for i = 1, TWOOPTPASSES do
				if (nonblocking) then
					coroutine.yield();
				end
				if (TSP:TwoOpt(antpath, weight, prune) == 0) then
					break;
				end
			end]]
			while (TSP:TwoOpt(antpath, weight, prune, TWOPOINTFIVEOPT, nonblocking) > 1) do
				if (nonblocking) then
					coroutine.yield();
				end
			end

			-- Step 10	-- At the same time, we also calculate the length of each ant's tour
			local pathLength = 0;
			curnode = antpath[numNodes];
			for i = 1, numNodes do
				nextnode = antpath[i];
				pathLength = pathLength + weight[curnode*numNodes-nextnode];
				curnode = nextnode;
			end

			-- Step 11	-- If this ant's path is shorter than the global shortest known solution, copy it
			if (pathLength < shortestPathLength) then
				shortestPathLength = pathLength;
				for i = 1, numNodes do
					shortestPath[i] = antpath[i];
				end
				nochanges = 0;	-- There were changes, so reset nochanges counter to 0
			end
		end
			
		-- Step 12	- Perform global pheromone trail update on the best known solution
		local curnode = shortestPath[numNodes];
		local tempConstant = GLOBALDECAY * QUALITY / shortestPathLength;
		for i = 1, numNodes do
			local nextnode = shortestPath[i];
			local u = curnode*numNodes-nextnode;
			phero[u] = (1 - GLOBALDECAY) * phero[u] + tempConstant;
			curnode = nextnode;
		end
	end

	-- Step 13	-- Check the length of the original tour that was sent in in nodes[]
	local pathLength = 0;
	for i = 2, numNodes do
		pathLength = pathLength + weight[(i-1)*numNodes-i];
	end
	pathLength = pathLength + weight[numNodes*numNodes-1];

	-- Step 14	-- Check solution with original that was sent in
	if (pathLength < shortestPathLength) then
		-- TSP didn't find a shorter solution, so copy the input to the output
		for i = 1, numNodes do
			path[i] = nodes[i];
		end
		shortestPathLength = pathLength;
	else
		-- TSP found a shorter path than the original, convert our shortest path to the output format wanted
		for i = 1, numNodes do
			path[i] = nodes[shortestPath[i]];
		end
	end

	-- Cleanup our used tables by recycling them
	delTable(weight);
	delTable(phero);
	delTable(ants);
	delTable(shortestPath);
	delTable(prune);
	delTable(nodes2);
	lastpath = nil;

	startTime = GetTime() - startTime;
	return path, shortestPathLength, count, startTime;
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
	local count = 0;
	local numNodes = #path;
	local pathR = pathR;

	-- Generate reverse lookup table
	if lastpath ~= path then
		for i = 1, numNodes do
			pathR[path[i]] = i;
		end
	end

	-- Perform normal 2-opt
	for i = 1, numNodes-3 do
		local a, b = path[i], path[i+1];
		local z = weight[a*numNodes-b];
		--for j = i+2, numNodes-1 do
		for m = 1, #prune[a] do
			local j = pathR[prune[a][m]];
			if j > i+1 and j ~= numNodes then
				local c, d = path[j], path[j+1];
				local currW = z + weight[c*numNodes-d];
				local newW = weight[a*numNodes-c] + weight[b*numNodes-d];
				if (newW < currW) then
					-- Swap these 2 edges to get a shorter path
					-- This is done by reversing the node order between i+1 to j
					local left = i+1;
					local right = j;
					while (left < right) do
						path[left], path[right] = path[right], path[left];
						pathR[path[left]], pathR[path[right]] = left, right;
						left = left + 1;
						right = right - 1;
					end
					b = path[i+1];
					z = weight[a*numNodes-b];
					count = count + 1;
				end
			end
		end
	end

	-- Then perform 2.5-opt
	if (twoPointFiveOpt) then
		if (nonblocking) then
			coroutine.yield();
		end
		for i = 1, numNodes-4 do
			local a, b, c = path[i], path[i+1], path[i+2];
			local z = weight[a*numNodes-b] + weight[b*numNodes-c];
			for m = 1, #prune[a] do
				local j = pathR[prune[a][m]];
				if j > i+2 and j ~= numNodes then
					local d, e = path[j], path[j+1];
					local currW = z + weight[d*numNodes-e];
					local newW = weight[a*numNodes-c] + weight[d*numNodes-b] + weight[b*numNodes-e];
					if (newW < currW) then
						-- Remove node b from the path, then reinsert it between d and e
						for q = i+1, j-1 do
							path[q] = path[q+1];
							pathR[path[q]] = q;
						end
						path[j] = b;
						pathR[b] = j;
						b, c = path[i+1], path[i+2];
						z = weight[a*numNodes-b] + weight[b*numNodes-c];
						count = count + 1;
					end
				end
			end
		end
	end

	lastpath = path;
	return count;
end


-- TSP:InsertNode(nodes, zonename, nodeID, twoOpt, path)
--   Inserts a node into an existing route.
-- Arguments
--   nodes	- The table containing a list of Routes node IDs to path
--		  This list should only contain nodes on the same map. This
--		  table should be indexed numerically from nodes[1] to nodes[n].
--   zonename	- The English zone name of the map that the route to be
--		  generated is on.
--   nodeID     - The Routes node ID to insert into the route.
--   twoOpt	- Boolean indicating whether to perform 2-Opt on the route after
--		  insertion.
--   path	- An optional input table that is used to supply the result
--		  table. If this is nil, the function returns a new table.
-- Returns
--   path	- The result TSP path is a table indexed numerically from path[1]
--		  to path[n], a list of Routes node IDs.
--   pathLength	- The length of the route in yards.
function TSP:InsertNode(nodes, zonename, nodeID, twoOpt, path)
	assert(type(nodes) == "table", "InsertNode() expected table in 1st argument, got "..type(nodes).." instead.");
	if (type(path) == "table") then
		clearTable(path);
	else
		path = newTable();
	end

	-- Check for trivial problem of 2 or less nodes
	local numNodes = #nodes;
	if (numNodes < 3) then
		-- Trivial solution for an input size of 2 or less nodes
		for i = 1, numNodes do
			path[i] = nodes[i];
		end
		path[numNodes+1] = nodeID;
		return path, TSP:PathLength(path, zonename);
	end

	-- Insert the node to be added at the end of the list.
	tinsert(nodes, nodeID);
	numNodes = #nodes;

	-- Step 1	- Initialize and generate the weight matrix, and prune matrix if doing 2-opt
	local zoneW, zoneH = Routes.zoneData[BZ[zonename]][1], Routes.zoneData[BZ[zonename]][2];
	local zoneW15 = zoneW * 0.15;
	local weight = newTable();
	local prune = newTable();
	for i = 1, numNodes do
		if (twoOpt) then
			prune[i] = newTable();
		end
		path[i] = i;
	end
	
	if twoOpt then
		-- Doing a twoopt requires the full weight table O(0.5n^2)
		for i = 1, numNodes do
			local x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000;
			local u = i*numNodes-i;
			weight[u] = 0;
			for j = i+1, numNodes do
				local x2, y2 = floor(nodes[j] / 10000) / 10000, (nodes[j] % 10000) / 10000;
				local u, v = i*numNodes-j, j*numNodes-i;
				weight[u] = (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5;	-- Calc distance between each node pair
				weight[v] = weight[u];
				-- Table containing data for 2-opt pruning operations. This is just a list of nodes that are near each node.
				if (weight[u] < zoneW15) then
					tinsert(prune[i], j);
					tinsert(prune[j], i);
				end
			end
		end
	else
		-- Not doing a twoopt means we only need to generate O(2n) entries in the weight table
		local i, j, x, y, x2, y2, u, v
		for a = 1, numNodes-2 do
			-- for every node path[i], calculate its distance to path[i+1]
			i, j = path[a], path[a+1];
			x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000;
			x2, y2 = floor(nodes[j] / 10000) / 10000, (nodes[j] % 10000) / 10000;
			u = i*numNodes-j;
			weight[u] = (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5;	-- Calc distance
		end
		-- do looparound node
		i, j = path[numNodes-1], path[1];
		x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000;
		x2, y2 = floor(nodes[j] / 10000) / 10000, (nodes[j] % 10000) / 10000;
		weight[i*numNodes-j] = (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5;	-- Calc distance
		-- calc distance for every node to the node to be inserted
		j = path[numNodes]
		x2, y2 = floor(nodes[j] / 10000) / 10000, (nodes[j] % 10000) / 10000;
		for a = 1, numNodes-1 do
			i = path[a];
			x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000;
			u, v = i*numNodes-j, j*numNodes-i;
			weight[u] = (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5;	-- Calc distance
			weight[v] = weight[u];
		end
	end

	-- Step 2	- Find the best place to insert the node
	local shortestPathLength = 1e100;	-- Some large value
	local insertPoint;
	for i = 1, numNodes-2 do
		local a, b = path[i], path[i+1];
		local z = weight[a*numNodes-numNodes] + weight[numNodes*numNodes-b] - weight[a*numNodes-b];
		if (z < shortestPathLength) then
			shortestPathLength = z;
			insertPoint = i + 1;
		end
	end
	if weight[(numNodes-1)*numNodes-numNodes] + weight[numNodes*numNodes-1] - weight[(numNodes-1)*numNodes-1] < shortestPathLength then
		-- Do nothing, inserting the node at the last place is the best, already inserted here.
	else
		-- Remove it from the last place in the path and insert it at the best place found.
		tremove(path);
		tinsert(path, insertPoint, numNodes);
	end

	-- Step 3	-- Now do 2-opt on it
	while (twoOpt and TSP:TwoOpt(path, weight, prune, true) > 0) do
	end

	-- Step 4	-- Calculate the length of the path
	local pathLength = 0;
	local curnode = path[numNodes];
	for i = 1, numNodes do
		local nextnode = path[i];
		pathLength = pathLength + weight[curnode*numNodes-nextnode];
		curnode = nextnode;
	end

	-- Step 5	-- Convert our path to the output format wanted
	for i = 1, numNodes do
		path[i] = nodes[path[i]];
	end

	-- Cleanup our used tables by recycling them
	delTable(weight);
	delTable(prune);
	lastpath = nil;
	-- Remove our modification to nodes[]
	tremove(nodes);

	return path, pathLength;
end


-- TSP:PathLength(nodes, zonename)
--   Returns how long a given route is in yards.
-- Arguments
--   nodes	- The table containing a list of Routes node IDs to path
--		  This list should only contain nodes on the same map. This
--		  table should be indexed numerically from nodes[1] to nodes[n].
--   zonename	- The English zone name of the map that the route to be
--		  generated is on.
-- Returns
--   pathLength	- The length of the route in yards.
function TSP:PathLength(nodes, zonename)
	assert(type(nodes) == "table", "PathLength() expected table in 1st argument, got "..type(nodes).." instead.");
	local zoneW, zoneH = Routes.zoneData[BZ[zonename]][1], Routes.zoneData[BZ[zonename]][2];
	local numNodes = #nodes;
	local pathLength = 0;

	-- Check for trivial problem of 1 or less nodes
	if numNodes <= 1 then
		return 0;
	end

	-- Get coordinate of last node
	local x2, y2 = floor(nodes[numNodes] / 10000) / 10000, (nodes[numNodes] % 10000) / 10000;
	for i = 1, #nodes do
		local x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000;
		pathLength = pathLength + (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5;
		x2, y2 = x, y;
	end

	return pathLength;
end

-- TSP:ClusterRoute(nodes)
-- Arguments
-- nodes    - The table containing a list of Routes node IDs to path
--            This list should only contain nodes on the same map. This
--            table should be indexed numerically from nodes[1] to nodes[n].
-- zonename - The English zone name of the route
-- radius   - The radius in yards to cluster
-- Returns
-- path     - The result TSP path is a table indexed numerically from path[1]
--            to path[n], a list of Routes node IDs. n is smaller than the
--            original input
-- metadata - The metadata table for path[] containing the original nodes
--            clustered
-- length   - The length of the new route in yards
--[[
Hierarchical Agglomerative Clustering

Data clustering algorithms can be hierarchical or partitional. Hierarchical
algorithms find successive clusters using previously established clusters,
whereas partitional algorithms determine all clusters at once. Hierarchical
algorithms can be agglomerative ("bottom-up") or divisive ("top-down").
Agglomerative algorithms begin with each element as a separate cluster and
merge them into successively larger clusters. Divisive algorithms begin with
the whole set and proceed to divide it into successively smaller clusters.

This method (Agglomerative) builds the hierarchy from the individual elements
by progressively merging clusters. The first step is to determine which
elements to merge in a cluster. Usually, we want to take the two closest
elements, according to the chosen distance.

Optionally, one can also construct a distance matrix at this stage, where the
number in the i-th row j-th column is the distance between the i-th and j-th
elements. Then, as clustering progresses, rows and columns are merged as the
clusters are merged and the distances updated. This is a common way to
implement this type of clustering, and has the benefit of catching distances
between clusters.

-- From Wikipedia, Cluster analysis
-- http://en.wikipedia.org/wiki/Cluster_analysis
-- 25 January 2008
]]
function TSP:ClusterRoute(nodes, zonename, radius)
	local weight = newTable() -- weight matrix
	local metadata = newTable() -- metadata after clustering

	local numNodes = #nodes
	local zoneW, zoneH = Routes.zoneData[BZ[zonename]][1], Routes.zoneData[BZ[zonename]][2]

	-- Create a copy of the nodes[] table and use this instead of the original because we want to modify this table
	local nodes2 = newTable()
	for i = 1, numNodes do
		nodes2[i] = nodes[i]
		weight[i] = newTable() -- make weight[] a 2-dimensional table
	end
	local nodes = nodes2

	-- Step 1: Generate the weight table
	for i = 1, numNodes do
		local x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000
		weight[i][i] = 0
		for j = i+1, numNodes do
			local x2, y2 = floor(nodes[j] / 10000) / 10000, (nodes[j] % 10000) / 10000
			weight[i][j] = (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5	-- Calc distance between each node pair
			weight[j][i] = true -- dummy value just to fill the lower half of the table so that tremove() will work on it
		end
	end

	-- Step 2: Generate the initial metadata tables
	for i = 1, numNodes do
		metadata[i] = newTable()
		metadata[i][1] = nodes[i]
	end

	-- Step 5: ...and loop until there is no such pair of nodes
	while true do
		-- Step 3: Find the closest pair of nodes within the merge radius
		local smallestDist = 1/0
		local node1, node2
		for i = 1, numNodes-1 do
			for j = i+1, numNodes do
				if weight[i][j] < radius and weight[i][j] < smallestDist then
					smallestDist = weight[i][j]
					node1 = i
					node2 = j
				end
			end
		end
		-- Step 4: Merge node2 into node1...
		if node1 then
			local node1num, node2num = #metadata[node1], #metadata[node2]
			-- Calculate the expanded centroid (x,y) for node1 and node2
			local node1x, node1y = floor(nodes[node1] / 10000) / 10000 * node1num, (nodes[node1] % 10000) / 10000 * node1num
			local node2x, node2y = floor(nodes[node2] / 10000) / 10000 * node2num, (nodes[node2] % 10000) / 10000 * node2num
			-- Merge the metadata of node2 into node1
			for i = 1, node2num do
				tinsert(metadata[node1], metadata[node2][i])
			end
			-- Calculate the new centroid of node1
			node1num = node1num + node2num
			node1x, node1y = (node1x + node2x) / node1num, (node1y + node2y) / node1num
			local coord = floor(node1x * 10000 + 0.5) * 10000 + floor(node1y * 10000 + 0.5)
			node1x, node1y = floor(coord / 10000) / 10000, (coord % 10000) / 10000 -- to round off the coordinate
			-- Set the new coord of node1
			nodes[node1] = coord
			-- Delete node2 from metadata[]
			delTable(tremove(metadata, node2))
			-- Delete node2 from nodes[]
			tremove(nodes, node2)
			-- Remove node2 from the weight table
			for i = 1, numNodes do
				tremove(weight[i], node2) -- remove column
			end
			delTable(tremove(weight, node2)) -- remove row
			-- Update number of nodes
			numNodes = numNodes - 1
			-- Update the weight table for all nodes relating to node1
			for i = 1, node1-1 do
				local x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000
				weight[i][node1] = (((node1x - x)*zoneW)^2 + ((node1y - y)*zoneH)^2)^0.5
			end
			for i = node1+1, numNodes do
				local x, y = floor(nodes[i] / 10000) / 10000, (nodes[i] % 10000) / 10000
				weight[node1][i] = (((node1x - x)*zoneW)^2 + ((node1y - y)*zoneH)^2)^0.5
			end
		else
			break -- loop termination
		end
	end

	-- Get the new pathLength
	local pathLength = self:PathLength(nodes, zonename)

	-- Cleanup our used tables by recycling them
	delTable(weight)

	return nodes, metadata, pathLength
end

-- vim: ts=4 noexpandtab

