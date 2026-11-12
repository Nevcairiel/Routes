----------------------------------
--[[
Travelling Salesman Problem (TSP) solver
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
The Travelling Salesman Problem

The Travelling Salesman Problem (TSP) consists of finding the shortest tour
between n cities visiting each once only and ending at the starting point.

Finding the shortest tour is not feasible for more than a handful of cities,
so the solver in this file looks for a good tour instead, by local search: it
starts with a tour and keeps making small changes to it that make it shorter,
until it finds no such change anymore. The changes it tries are

  2-opt:  Remove 2 links from the tour and reconnect the 2 parts the other way
          around, which reverses the direction of one part. For example, if
          the tour contains the links (a, b) and (c, d) in that order, they
          are replaced by (a, c) and (b, d). This is what removes crossings.

  Or-opt: Take a segment of 1 to 3 consecutive cities out of the tour and
          insert it somewhere else, in either direction.

Trying all combinations of links would take O(n^2) time for every pass over
the tour. Instead, only changes that link a city to one of its few nearest
neighbours are tried, as a good tour consists almost only of such links. For
the same reason there is no matrix with the distances between all cities,
distances are calculated when they are needed. Both the time and the memory
needed are therefore roughly proportional to the number of cities.

-- An Effective Implementation of the Lin-Kernighan Traveling Salesman Heuristic
-- by K. Helsgaun, 2000 (on neighbour lists and local search in general)
-- Experimental Analysis of Heuristics for the STSP
-- by D. S. Johnson & L. A. McGeoch, 2002
]]

-- Note:
-- The functions in this file are written specifically for use with Routes
-- in mind and is not a general TSP library.

----------------------------------
-- Localize some globals
local ipairs, pairs, type = ipairs, pairs, type
local random = random
local floor, abs = floor, abs
local coroutine = coroutine
local tinsert, tremove = tinsert, tremove
local debugprofilestop = debugprofilestop
local inf = math.huge

local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes")
local TSP = {}
Routes.TSP = TSP


--------------------------------
-- Background execution

-- Milliseconds of work a background task may do per frame before it yields
local YIELD_BUDGET = 10
local sliceStart = 0
local function yieldNow()
	coroutine.yield()
	-- measure the budget from when we are resumed, not from when we
	-- yielded, so the time spent rendering the frame doesn't count
	sliceStart = debugprofilestop()
end
local function yield()
	local t = debugprofilestop()
	-- t < sliceStart means someone called debugprofilestart() and reset the
	-- timer, yield anyway in that case
	if t - sliceStart >= YIELD_BUDGET or t < sliceStart then
		yieldNow()
	end
end


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
			local finishFunc = self.finishFunc
			self.finishFunc = nil
			self.statusFunc = nil
			self.co = nil
			self.nodes = nil
			self.stop = nil
			finishFunc(path, meta, shortestPathLength, count, timetaken)
		end
	else
		-- An error occured in the coroutine, abort and print the error
		self:SetScript("OnUpdate", nil)
		self.running = false
		self.co = nil
		self.finishFunc = nil
		self.statusFunc = nil
		self.nodes = nil
		self.stop = nil
		Routes:Print(Routes.L["The following error occured in the background path generation coroutine, please report to the addon authors:"])
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
			local finishFunc = self.finishFunc
			self.finishFunc = nil
			self.co = nil
			self.nodes = nil
			finishFunc(nodes, metadata, pathLength)
		end
	else
		-- An error occured in the coroutine, abort and print the error
		self:SetScript("OnUpdate", nil)
		self.running = false
		self.co = nil
		self.finishFunc = nil
		self.nodes = nil
		Routes:Print(Routes.L["The following error occured in the background clustering coroutine, please report to the addon authors:"])
		Routes:Print(nodes)
	end
end

function TSP:IsTSPRunning()
	return TSPUpdateFrame.running, TSPUpdateFrame.nodes
end

-- Tells the TSP running in the background to finish now, with the best path
-- it has found so far
function TSP:StopTSP()
	if TSPUpdateFrame.running then
		TSPUpdateFrame.stop = true
	end
end

function TSP:IsClusterRunning()
	return TSPClusterFrame.running, TSPClusterFrame.nodes
end

-- Same arguments as TSP:SolveTSP(), without the "nonblocking" argument
function TSP:SolveTSPBackground(nodes, metadata, taboos, zoneID, parameters, path)
	if not TSPUpdateFrame.running then
		TSPUpdateFrame.co = coroutine.create(TSP.SolveTSP)
		TSPUpdateFrame:SetScript("OnUpdate", TSPUpdateFrame.OnUpdate)
		TSPUpdateFrame.running = true
		TSPUpdateFrame.stop = nil
		TSPUpdateFrame.nodes = nodes
		local status, errormsg = coroutine.resume(TSPUpdateFrame.co, TSP, nodes, metadata, taboos, zoneID, parameters, path, true)
		if status then
			-- Do nothing, path isn't complete because at least 1 yield() is called.
			return 1
		else
			-- An error occured in the coroutine, abort and return the error message.
			TSPUpdateFrame.running = false
			TSPUpdateFrame:SetScript("OnUpdate", nil)
			TSPUpdateFrame.co = nil
			TSPUpdateFrame.nodes = nil
			return 3, errormsg
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
-- TSP:SolveTSP(nodes, metadata, taboos, zoneID, parameters, path, nonblocking)
-- Arguments
--   nodes       - The table containing a list of Routes node IDs to path
--                 This list should only contain nodes on the same map. This
--                 table should be indexed numerically from nodes[1] to nodes[n].
--   metadata    - The table containing the cluster metadata, if available
--   taboos      - A table containing a table of taboo regions to use.
--   zoneID      - The map area ID of the map that the route is to be generated on.
--   parameters  - The table containing the parameters to use:
--                   kicks_per_node    - Number of attempts to improve the route
--                                       further, per node. The default is 10.
--                   patience_per_node - If set, stop early if this many
--                                       attempts per node in a row did not
--                                       improve the route.
--   path        - An optional input table that is used to supply the result
--                 table. If this is nil, the function returns a new table.
--   nonblocking - A boolean to indicate whether the function should yield() regularly.
-- Returns
--   path        - The result TSP path is a table indexed numerically from path[1]
--                 to path[n], a list of Routes node IDs.
--   metadata    - The table containing the cluster metadata, if available
--   length      - The length in yards of the path returned.
--   iteration   - Number of attempts to improve the route further that were made.
--   timeTaken   - Number of seconds used.
-- Notes: A new nodes[] and metadata[] table is returned. The original tables
--        sent in are unmodified. The path returned is never worse than the
--        order of the nodes that were sent in. A nonblocking call can be
--        told to finish early with TSP:StopTSP().

-- Number of nearest neighbours of each node that are considered as the new
-- neighbour of that node in the route
local NEIGHBOURS = 10
-- Of those, the number of nodes that are the nearest ones in each of the 4
-- directions, rather than the nearest ones overall. Without these, the nodes
-- of a dense group of nodes would only have each other as neighbours.
local QUADRANT_NEIGHBOURS = 2
-- Number of nodes to look at before giving up on finding those
local QUADRANT_SCAN_LIMIT = 150
-- The grid that is used to find the neighbours gets finer cells until no cell
-- has more nodes than this, as far as that is possible
local GRID_CELL_LIMIT = 64
-- Number of nodes to look at before settling for the neighbours found so far.
-- This is only reached for nodes that are (almost) on the same spot.
local NEIGHBOUR_SCAN_LIMIT = 1000
-- Improvements smaller than this (in yards) are ignored, so that rounding
-- errors can't make the search run in circles
local EPSILON = 1e-7
-- Number of kicks to try per node of the route
local KICKS_PER_NODE = 10
-- Maximum length of the 2 segments that a kick swaps
local KICK_SEGMENT = 30

function TSP:SolveTSP(nodes, metadata, taboos, zoneID, parameters, path, nonblocking)
	assert(type(nodes) == "table", "SolveTSP() expected table in 1st argument, got "..type(nodes).." instead.")
	assert(type(taboos) == "table", "SolveTSP() expected table in 3rd argument, got "..type(taboos).." instead.")
	assert(type(parameters) == "table", "SolveTSP() expected table in 5th argument, got "..type(parameters).." instead.")
	if type(path) == "table" then
		wipe(path)
	else
		path = {}
	end

	-- Create a copy of the nodes[] table and use this instead of the original because data could get changed
	local numNodes = #nodes
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

	if nonblocking then
		-- Ensure that at least 1 yield() is called in a nonblocking call. This
		-- must be after copying the input, it may be modified while we run.
		yieldNow()
	end

	-- Check for trivial problem of 3 or less nodes
	if numNodes < 4 then
		for i = 1, numNodes do
			path[i] = nodes[i]
		end
		return path, metadata, TSP:PathLength(path, zoneID), 0, 0
	end

	local startTime
	if nonblocking then
		startTime = GetTime()
	else
		startTime = debugprofilestop()
	end
	local zoneW, zoneH = Routes.Dragons:GetZoneSize(zoneID)

	-- Status for the status function: the pass we are in, how far it is, and
	-- the cost of the route so far (nil while it is unknown)
	local pass, progress, cost = 1, 0, nil
	-- In a nonblocking call this is called regularly to give control back
	-- once we have used up our time for this frame
	local function tick()
		local t = debugprofilestop()
		if t - sliceStart >= YIELD_BUDGET or t < sliceStart then
			if TSPUpdateFrame.statusFunc then
				TSPUpdateFrame.statusFunc(pass, progress, cost)
			end
			yieldNow()
		end
	end

	-- Step 1	- Positions of the nodes in yards
	local X, Y = {}, {}
	for i = 1, numNodes do
		local c = nodes[i]
		X[i], Y[i] = floor(c / 10000) / 10000 * zoneW, (c % 10000) / 10000 * zoneH
	end

	-- Step 2	- The cost function D(a, b) of travelling between nodes a and b
	-- This is the distance in yards, unless the line between the nodes crosses
	-- the outline of a taboo region. There is no NxN matrix of these, they are
	-- calculated when needed.
	local D
	-- The outlines of all taboo regions as one list of lines (x1,y1)-(x2,y2)
	local lineX1, lineY1, lineX2, lineY2 = {}, {}, {}, {}
	-- The lines and the bounding box of each taboo region
	local tabooFirst, tabooLast, tabooMinX, tabooMaxX, tabooMinY, tabooMaxY = {}, {}, {}, {}, {}, {}
	local numTaboos, numLines = 0, 0
	for m = 1, #taboos do
		local outline = taboos[m].route
		local numPoints = #outline
		if numPoints >= 2 then
			numTaboos = numTaboos + 1
			tabooFirst[numTaboos] = numLines + 1
			local last = outline[numPoints]
			local sx, sy = floor(last / 10000) / 10000 * zoneW, (last % 10000) / 10000 * zoneH
			local minX, maxX, minY, maxY = sx, sx, sy, sy
			for n = 1, numPoints do
				local point = outline[n]
				local ex, ey = floor(point / 10000) / 10000 * zoneW, (point % 10000) / 10000 * zoneH
				numLines = numLines + 1
				lineX1[numLines], lineY1[numLines], lineX2[numLines], lineY2[numLines] = sx, sy, ex, ey
				if ex < minX then minX = ex elseif ex > maxX then maxX = ex end
				if ey < minY then minY = ey elseif ey > maxY then maxY = ey end
				sx, sy = ex, ey
			end
			tabooLast[numTaboos] = numLines
			tabooMinX[numTaboos], tabooMaxX[numTaboos], tabooMinY[numTaboos], tabooMaxY[numTaboos] = minX, maxX, minY, maxY
		end
	end
	if numTaboos == 0 then
		D = function(a, b)
			local dx, dy = X[a] - X[b], Y[a] - Y[b]
			return (dx*dx + dy*dy)^0.5
		end
	else
		-- Does the line between nodes a and b cross (or touch) the outline of a taboo region?
		local function crossesTaboo(a, b)
			local ax, ay, bx, by = X[a], Y[a], X[b], Y[b]
			if ax == bx and ay == by then
				return false
			end
			local minX, maxX, minY, maxY = ax, bx, ay, by
			if minX > maxX then minX, maxX = maxX, minX end
			if minY > maxY then minY, maxY = maxY, minY end
			for m = 1, numTaboos do
				if maxX >= tabooMinX[m] and minX <= tabooMaxX[m] and maxY >= tabooMinY[m] and minY <= tabooMaxY[m] then
					for n = tabooFirst[m], tabooLast[m] do
						local sx, sy, ex, ey = lineX1[n], lineY1[n], lineX2[n], lineY2[n]
						-- on which side of the line s-e are a and b...
						local d1 = (ex - sx)*(ay - sy) - (ey - sy)*(ax - sx)
						local d2 = (ex - sx)*(by - sy) - (ey - sy)*(bx - sx)
						if not ((d1 > 0 and d2 > 0) or (d1 < 0 and d2 < 0)) then
							-- ...and on which side of the line a-b are s and e
							local d3 = (bx - ax)*(sy - ay) - (by - ay)*(sx - ax)
							local d4 = (bx - ax)*(ey - ay) - (by - ay)*(ex - ax)
							if not ((d3 > 0 and d4 > 0) or (d3 < 0 and d4 < 0)) then
								if d1 ~= 0 or d2 ~= 0 or d3 ~= 0 or d4 ~= 0 then
									return true
								end
								-- All 4 points are on one line, they cross if they overlap
								local sMinX, sMaxX, sMinY, sMaxY = sx, ex, sy, ey
								if sMinX > sMaxX then sMinX, sMaxX = sMaxX, sMinX end
								if sMinY > sMaxY then sMinY, sMaxY = sMaxY, sMinY end
								if maxX >= sMinX and minX <= sMaxX and maxY >= sMinY and minY <= sMaxY then
									return true
								end
							end
						end
					end
				end
			end
			return false
		end
		-- Remember the answers, the same pairs of nodes get asked for all the time
		local crossing, numCrossing = {}, 0
		local pairBase = numNodes + 1
		D = function(a, b)
			local dx, dy = X[a] - X[b], Y[a] - Y[b]
			local d = (dx*dx + dy*dy)^0.5
			local pair = a < b and a * pairBase + b or b * pairBase + a
			local c = crossing[pair]
			if c == nil then
				-- always ask with the nodes in the same order, rounding errors
				-- can make the answer depend on it if the line touches an outline
				if a < b then
					c = crossesTaboo(a, b)
				else
					c = crossesTaboo(b, a)
				end
				if numCrossing >= 400000 then
					-- don't let the cache grow forever
					crossing, numCrossing = {}, 0
				end
				crossing[pair] = c
				numCrossing = numCrossing + 1
			end
			if c then
				-- we increase/bias the cost by a constant factor and by the zone width, since it passes thru a taboo region
				return d * 2 + zoneW
			end
			return d
		end
	end

	-- Step 3	- Sort the nodes into a grid
	local minX, maxX, minY, maxY = X[1], X[1], Y[1], Y[1]
	for i = 2, numNodes do
		local x, y = X[i], Y[i]
		if x < minX then minX = x elseif x > maxX then maxX = x end
		if y < minY then minY = y elseif y > maxY then maxY = y end
	end
	local width, height = maxX - minX, maxY - minY
	local cellSize = (2 * width * height / numNodes)^0.5
	local extent = width > height and width or height
	-- no more than numNodes/2 cells per axis, even if all nodes are on a line
	if not (cellSize > 2 * extent / numNodes) then cellSize = 2 * extent / numNodes end
	if not (cellSize > 0) then cellSize = 1 end
	-- That is about 2 nodes per cell if the nodes are spread evenly. If most of
	-- them are in a small part of the zone they end up in a few cells though,
	-- so halve the size of the cells until no cell has too many nodes. That
	-- doesn't help if they are on the very same spot, keep the first grid then.
	local numColumns, numRows
	local cells                  -- column * numRows + row -> list of nodes in the cell
	local cellColumn, cellRow
	local cellPos                -- node -> index in the list of its cell
	do
		local size, fewest = cellSize, inf
		for attempt = 0, 10 do
			local columns, rows = floor(width / size) + 1, floor(height / size) + 1
			local newCells, newColumn, newRow, newPos = {}, {}, {}, {}
			local most = 0
			for i = 1, numNodes do
				local column, row = floor((X[i] - minX) / size), floor((Y[i] - minY) / size)
				local key = column * rows + row
				local cell = newCells[key]
				if not cell then
					cell = {}
					newCells[key] = cell
				end
				local n = #cell + 1
				cell[n] = i
				newColumn[i], newRow[i], newPos[i] = column, row, n
				if n > most then most = n end
			end
			if most < fewest then
				fewest, cellSize, numColumns, numRows = most, size, columns, rows
				cells, cellColumn, cellRow, cellPos = newCells, newColumn, newRow, newPos
			end
			if most <= GRID_CELL_LIMIT then
				break
			end
			size = size / 2
			if nonblocking then
				tick()
			end
		end
	end
	-- Looking for something in the grid ring by ring gets more expensive than
	-- just looking at every node after this many rings
	local ringLimit = floor(numNodes^0.5 / 2) + 2

	-- Calls func(node) for every node in the cells that are exactly "ring"
	-- cells away from the given cell. Stops and returns true if func does.
	local function scanRing(column, row, ring, func)
		local c1, c2, r1, r2 = column - ring, column + ring, row - ring, row + ring
		for c = c1 < 0 and 0 or c1, c2 >= numColumns and numColumns - 1 or c2 do
			if c == c1 or c == c2 then
				for r = r1 < 0 and 0 or r1, r2 >= numRows and numRows - 1 or r2 do
					local cell = cells[c * numRows + r]
					if cell then
						for n = 1, #cell do
							if func(cell[n]) then return true end
						end
					end
				end
			else
				if r1 >= 0 then
					local cell = cells[c * numRows + r1]
					if cell then
						for n = 1, #cell do
							if func(cell[n]) then return true end
						end
					end
				end
				if r2 < numRows and r2 ~= r1 then
					local cell = cells[c * numRows + r2]
					if cell then
						for n = 1, #cell do
							if func(cell[n]) then return true end
						end
					end
				end
			end
		end
	end

	-- Step 4	- Find the nearest neighbours of every node
	-- neighbour[(a-1)*numNeighbours + 1 .. a*numNeighbours] is the list of the
	-- neighbours of node a, the cheapest to travel to first
	local numNeighbours = NEIGHBOURS < numNodes - 1 and NEIGHBOURS or numNodes - 1
	local neighbour = {}
	do
		local nearNode, nearDist = {}, {}
		local numNear, worst, self, selfX, selfY, numScanned, scanLimit
		-- the nearest nodes in each of the 4 directions (quadrants) are kept in
		-- quadNode[quadrant * QUADRANT_NEIGHBOURS + 1 .. + quadCount[quadrant]]
		local quadNode, quadDist, quadCount = {}, {}, {}
		local function consider(node)
			if node ~= self then
				numScanned = numScanned + 1
				local dx, dy = X[node] - selfX, Y[node] - selfY
				local d = (dx*dx + dy*dy)^0.5
				if numNear < numNeighbours or d < worst then
					-- insert it into the sorted list, the worst one drops out if the list is full
					local n = numNear
					if n < numNeighbours then
						n = n + 1
						numNear = n
					end
					while n > 1 and nearDist[n - 1] > d do
						nearDist[n], nearNode[n] = nearDist[n - 1], nearNode[n - 1]
						n = n - 1
					end
					nearDist[n], nearNode[n] = d, node
					if numNear == numNeighbours then
						worst = nearDist[numNear]
					end
				end
				if QUADRANT_NEIGHBOURS > 0 then
					-- the same for the list of its quadrant
					local quadrant = (dx >= 0 and 1 or 0) + (dy >= 0 and 2 or 0)
					local base = quadrant * QUADRANT_NEIGHBOURS
					local n = quadCount[quadrant]
					if n < QUADRANT_NEIGHBOURS or d < quadDist[base + n] then
						if n < QUADRANT_NEIGHBOURS then
							n = n + 1
							quadCount[quadrant] = n
						end
						while n > 1 and quadDist[base + n - 1] > d do
							quadDist[base + n], quadNode[base + n] = quadDist[base + n - 1], quadNode[base + n - 1]
							n = n - 1
						end
						quadDist[base + n], quadNode[base + n] = d, node
					end
				end
				-- enough is enough
				return numScanned >= scanLimit and numNear == numNeighbours
			end
		end
		local maxRing = numColumns > numRows and numColumns or numRows
		local chosen, chosenCost = {}, {}
		for i = 1, numNodes do
			self, selfX, selfY = i, X[i], Y[i]
			numNear, worst, numScanned, scanLimit = 0, inf, 0, NEIGHBOUR_SCAN_LIMIT
			for quadrant = 0, 3 do
				quadCount[quadrant] = 0
			end
			local column, row = cellColumn[i], cellRow[i]
			for ring = 0, maxRing do
				if ring > ringLimit then
					-- This node is far away from the others compared to the size of
					-- the cells, start over and look at all nodes instead
					numNear, worst, numScanned, scanLimit = 0, inf, 0, inf
					for quadrant = 0, 3 do
						quadCount[quadrant] = 0
					end
					for node = 1, numNodes do
						consider(node)
					end
					break
				end
				if scanRing(column, row, ring, consider) then
					break
				end
				-- everything in the cells further out is at least ring * cellSize away
				local reach = ring * cellSize
				if numNear == numNeighbours and worst <= reach then
					-- that's the nearest ones, but keep going for the quadrants for a while
					local done = numScanned >= QUADRANT_SCAN_LIMIT
					if not done then
						done = true
						for quadrant = 0, 3 do
							local n = quadCount[quadrant]
							if n < QUADRANT_NEIGHBOURS or (n > 0 and quadDist[quadrant * QUADRANT_NEIGHBOURS + n] > reach) then
								done = false
								break
							end
						end
					end
					if done then
						break
					end
				end
			end
			-- Take the nodes of the quadrants, and fill the rest with the nearest nodes
			local numChosen = 0
			for quadrant = 0, 3 do
				local base = quadrant * QUADRANT_NEIGHBOURS
				for n = 1, quadCount[quadrant] do
					if numChosen < numNeighbours then
						numChosen = numChosen + 1
						chosen[numChosen] = quadNode[base + n]
					end
				end
			end
			local numQuadrant = numChosen
			for n = 1, numNear do
				if numChosen == numNeighbours then
					break
				end
				local node, found = nearNode[n], false
				for m = 1, numQuadrant do
					if chosen[m] == node then
						found = true
						break
					end
				end
				if not found then
					numChosen = numChosen + 1
					chosen[numChosen] = node
				end
			end
			-- and sort them by cost
			for n = 1, numChosen do
				local node = chosen[n]
				local d = D(i, node)
				local m = n
				while m > 1 and chosenCost[m - 1] > d do
					chosenCost[m], chosen[m] = chosenCost[m - 1], chosen[m - 1]
					m = m - 1
				end
				chosenCost[m], chosen[m] = d, node
			end
			local base = (i - 1) * numNeighbours
			for n = 1, numNeighbours do
				neighbour[base + n] = chosen[n]
			end
			if nonblocking and (i % 16 == 0 or numScanned > 200) then
				progress = 0.3 * i / numNodes
				tick()
			end
		end
	end

	-- Step 5	- Construct a route by always travelling to the nearest unvisited node
	local greedy = {}
	do
		local visited = {}
		local best, bestDist, selfX, selfY
		local function consider(node)
			local dx, dy = X[node] - selfX, Y[node] - selfY
			local d = dx*dx + dy*dy
			if d < bestDist then
				best, bestDist = node, d
			end
		end
		local maxRing = numColumns > numRows and numColumns or numRows
		local current = 1
		for i = 1, numNodes do
			greedy[i] = current
			visited[current] = true
			-- remove it from the grid, the last node in its cell takes its place there
			local cell, n = cells[cellColumn[current] * numRows + cellRow[current]], cellPos[current]
			local last = #cell
			local moved = cell[last]
			cell[n], cellPos[moved] = moved, n
			cell[last] = nil
			if i == numNodes then
				break
			end
			-- most of the time one of the neighbours is still unvisited...
			local nextNode
			local base = (current - 1) * numNeighbours
			for n = base + 1, base + numNeighbours do
				local node = neighbour[n]
				if not visited[node] then
					nextNode = node
					break
				end
			end
			if not nextNode then
				-- ...else look for the nearest unvisited node in the grid
				selfX, selfY = X[current], Y[current]
				best, bestDist = nil, inf
				local column, row = cellColumn[current], cellRow[current]
				local looked = false
				for ring = 0, maxRing do
					if ring > ringLimit then
						-- nothing nearby, look at all nodes instead
						for node = 1, numNodes do
							if not visited[node] then
								consider(node)
							end
						end
						looked = true
						break
					end
					scanRing(column, row, ring, consider)
					if best and bestDist <= (ring * cellSize)^2 then
						break
					end
				end
				nextNode = best
				if nonblocking and looked then
					tick()
				end
			end
			current = nextNode
			if nonblocking and i % 16 == 0 then
				progress = 0.3 + 0.1 * i / numNodes
				tick()
			end
		end
	end
	cells, cellColumn, cellRow, cellPos = nil, nil, nil, nil

	-- Step 6	- Start with that route, or with the route that was sent in if that is better
	-- tour[] is the route as a list of nodes, tourPos[] is where each node is in it
	local tour, tourPos = {}, {}
	do
		local inputCost, greedyCost = D(numNodes, 1), D(greedy[numNodes], greedy[1])
		for i = 1, numNodes - 1 do
			inputCost = inputCost + D(i, i + 1)
			greedyCost = greedyCost + D(greedy[i], greedy[i + 1])
		end
		if greedyCost < inputCost then
			cost = greedyCost
			for i = 1, numNodes do
				tour[i], tourPos[greedy[i]] = greedy[i], i
			end
		else
			cost = inputCost
			for i = 1, numNodes do
				tour[i], tourPos[i] = i, i
			end
		end
		greedy = nil
	end

	-- All changes to the route are done by reversing a part of it.
	-- Reverses the nodes at positions i to j (going forward, may wrap around).
	-- If that is more than half of the route, the other part is reversed
	-- instead, which results in the same route going the other direction.
	-- While journalSize is not nil, every reversal is written down in the
	-- journal so that the changes can be undone by doing them again backwards.
	local journalI, journalJ, journalLen = {}, {}, {}
	local journalSize
	local function flip(i, j, len)
		for n = 1, floor(len / 2) do
			local a, b = tour[i], tour[j]
			tour[i], tour[j] = b, a
			tourPos[b], tourPos[a] = i, j
			i = i + 1
			if i > numNodes then i = 1 end
			j = j - 1
			if j < 1 then j = numNodes end
		end
	end
	local function reverse(i, j)
		local len = j - i + 1
		if len <= 0 then
			len = len + numNodes
		end
		if len * 2 > numNodes then
			i, j = j + 1, i - 1
			if i > numNodes then i = 1 end
			if j < 1 then j = numNodes end
			len = numNodes - len
		end
		if len > 1 then
			if journalSize then
				journalSize = journalSize + 1
				journalI[journalSize], journalJ[journalSize], journalLen[journalSize] = i, j, len
			end
			flip(i, j, len)
		end
	end

	-- A 2-opt move: for nodes a and b that are next to each other, and nodes
	-- c and d that are next to each other in the same direction (the route is
	-- a b ... c d or d c ... b a), removes the links a-b and c-d and adds the
	-- links a-c and b-d
	local function exchange(a, b, c, d)
		local pa, pb = tourPos[a], tourPos[b]
		local nextPos = pa + 1
		if nextPos > numNodes then nextPos = 1 end
		if nextPos == pb then
			reverse(pb, tourPos[c])
		else
			reverse(tourPos[c], pb)
		end
	end

	-- The nodes whose surroundings in the route have changed and that need
	-- to be looked at (again)
	local queue, queued = {}, {}
	local queueHead, queueTail = 1, 0
	local function push(node)
		if not queued[node] then
			queueTail = queueTail + 1
			queue[queueTail] = node
			queued[node] = true
		end
	end

	-- Tries to find a change to the route around node a that makes the route
	-- shorter. Returns true if it found and made one.
	local function improve(a)
		local pa = tourPos[a]
		local base = (a - 1) * numNeighbours

		-- 2-opt: with b being the node after (or before) a, look for a
		-- neighbour c of a with d being the node after (or before) c, where
		-- the links a-c and b-d are shorter than a-b and c-d
		for dir = 1, -1, -2 do
			local pb = pa + dir
			if pb > numNodes then pb = 1 elseif pb < 1 then pb = numNodes end
			local b = tour[pb]
			local dab = D(a, b)
			for n = base + 1, base + numNeighbours do
				local c = neighbour[n]
				local gain = dab - D(a, c)
				if gain <= EPSILON then
					break
				end
				local pd = tourPos[c] + dir
				if pd > numNodes then pd = 1 elseif pd < 1 then pd = numNodes end
				local d = tour[pd]
				if c ~= b and d ~= a then
					gain = gain + D(c, d) - D(b, d)
					if gain > EPSILON then
						if dir == 1 then
							reverse(pb, tourPos[c])
						else
							reverse(tourPos[c], pb)
						end
						cost = cost - gain
						push(a) push(b) push(c) push(d)
						return true
					end
				end
			end
		end

		-- Or-opt: take a segment of 1 to 3 nodes that starts (or ends) at a
		-- out of the route, and insert it next to a neighbour c of one of its
		-- 2 ends, between c and the node d after (or before) c
		for dir = 1, -1, -2 do
			-- the segment is s1..s2 going forward, at positions ps1..ps2
			local s1, s2, ps1, ps2 = a, a, pa, pa
			for len = 1, 3 do
				if len > numNodes - 2 then
					break
				end
				if len > 1 then
					if dir == 1 then
						ps2 = ps2 + 1
						if ps2 > numNodes then ps2 = 1 end
						s2 = tour[ps2]
					else
						ps1 = ps1 - 1
						if ps1 < 1 then ps1 = numNodes end
						s1 = tour[ps1]
					end
				end
				-- p and q are the nodes before and after the segment
				local pp, pq = ps1 - 1, ps2 + 1
				if pp < 1 then pp = numNodes end
				if pq > numNodes then pq = 1 end
				local p, q = tour[pp], tour[pq]
				local remove = D(p, s1) + D(s2, q) - D(p, q)
				if remove > EPSILON then
					for segEnd = 1, len > 1 and 2 or 1 do
						-- s is the end of the segment that gets linked to c, o is the other end
						local s, o = s1, s2
						if segEnd == 2 then
							s, o = s2, s1
						end
						local sbase = (s - 1) * numNeighbours
						for n = sbase + 1, sbase + numNeighbours do
							local c = neighbour[n]
							local dsc = D(s, c)
							if remove - dsc <= EPSILON then
								break
							end
							local pc = tourPos[c]
							local offset = pc - ps1
							if offset < 0 then offset = offset + numNodes end
							if offset >= len then -- c is not in the segment
								for side = 1, -1, -2 do
									local pd = pc + side
									if pd > numNodes then pd = 1 elseif pd < 1 then pd = numNodes end
									offset = pd - ps1
									if offset < 0 then offset = offset + numNodes end
									if offset >= len then -- and neither is d
										local d = tour[pd]
										local gain = remove - dsc - D(o, d) + D(c, d)
										if gain > EPSILON then
											-- Move the segment with 2 exchanges, then turn it around with
											-- a third one if it ended up the wrong way around
											if side == 1 then
												-- p s1..s2 q ... c d
												exchange(p, s1, c, d) -- p c ... q s2..s1 d
												exchange(p, c, q, s2) -- p q ... c s2..s1 d
												if s ~= s2 then
													exchange(c, s2, s1, d)
												end
											else
												-- d c ... p s1..s2 q
												exchange(q, s2, c, d) -- d s2..s1 p ... c q
												exchange(q, c, p, s1) -- d s2..s1 c ... p q
												if s ~= s1 then
													exchange(c, s1, s2, d)
												end
											end
											cost = cost - gain
											push(p) push(q) push(c) push(d) push(s1) push(s2)
											return true
										end
									end
								end
							end
						end
					end
				end
			end
		end

		return false
	end

	-- Improves the route until there is no node left to look at
	local numLooked = 0
	local function localSearch()
		while queueHead <= queueTail do
			local a = queue[queueHead]
			queue[queueHead] = nil
			queueHead = queueHead + 1
			queued[a] = nil
			while improve(a) do end
			numLooked = numLooked + 1
			if nonblocking and numLooked % 8 == 0 then
				if pass == 1 then
					progress = 0.4 + 0.6 * (numLooked < numNodes and numLooked / numNodes or 1)
				end
				tick()
				if TSPUpdateFrame.stop then
					-- asked to finish now, the route is valid after every change
					break
				end
			end
		end
		queueHead, queueTail = 1, 0
	end

	-- Step 7	- Improve the route until no single change makes it any shorter
	for i = 1, numNodes do
		push(tour[i])
	end
	localSearch()
	local count = 0

	-- Step 8	- Kick the route out of the dead end it is in now
	-- A kick swaps 2 short segments of the route that are next to each other,
	-- which is a change that the local search can't make or undo with a single
	-- move. If the route is shorter after improving it again we keep it,
	-- otherwise the kick and everything after it is undone.
	local maxSegment = floor((numNodes - 2) / 2)
	if maxSegment > KICK_SEGMENT then maxSegment = KICK_SEGMENT end
	local numKicks = floor((parameters.kicks_per_node or KICKS_PER_NODE) * numNodes)
	local patience = parameters.patience_per_node and floor(parameters.patience_per_node * numNodes)
	local lastImprovement = 0
	pass, progress = 2, 0
	for kick = 1, numKicks do
		if patience and kick - lastImprovement > patience then
			break
		end
		if nonblocking and TSPUpdateFrame.stop then
			break
		end
		count = kick
		local costBefore = cost
		journalSize = 0
		-- the route is a a1..a2 b1..b2 c, change it to a b1..b2 a1..a2 c
		local pos = random(numNodes)
		local len1, len2 = random(maxSegment), random(maxSegment)
		local a = tour[pos]
		pos = pos + 1
		if pos > numNodes then pos = pos - numNodes end
		local a1 = tour[pos]
		pos = pos + len1 - 1
		if pos > numNodes then pos = pos - numNodes end
		local a2 = tour[pos]
		pos = pos + 1
		if pos > numNodes then pos = pos - numNodes end
		local b1 = tour[pos]
		pos = pos + len2 - 1
		if pos > numNodes then pos = pos - numNodes end
		local b2 = tour[pos]
		pos = pos + 1
		if pos > numNodes then pos = pos - numNodes end
		local c = tour[pos]
		cost = cost + D(a, b1) + D(b2, a1) + D(a2, c) - D(a, a1) - D(a2, b1) - D(b2, c)
		exchange(a, a1, b2, c)  -- a b2..b1 a2..a1 c
		exchange(a, b2, b1, a2) -- a b1..b2 a2..a1 c
		exchange(b2, a2, a1, c) -- a b1..b2 a1..a2 c
		push(a) push(a1) push(a2) push(b1) push(b2) push(c)
		localSearch()
		if cost < costBefore - EPSILON then
			lastImprovement = kick
		else
			-- no good, undo it
			for n = journalSize, 1, -1 do
				flip(journalI[n], journalJ[n], journalLen[n])
			end
			cost = costBefore
		end
		journalSize = nil
		if nonblocking and kick % 4 == 0 then
			-- how far we are, either with all the attempts or with giving up,
			-- but never going backwards
			local p = kick / numKicks
			if patience and (kick - lastImprovement) / patience > p then
				p = (kick - lastImprovement) / patience
			end
			if p > progress then
				progress = p
			end
			tick()
		end
	end

	-- Step 9	- Convert the route to the output format wanted
	local meta
	if metadata then
		meta = {}
	end
	for i = 1, numNodes do
		path[i] = nodes[tour[i]]
		if metadata then
			meta[i] = metadata[tour[i]]
		end
	end
	metadata = meta

	-- This step is necessary because our cost is calculated from biased data from taboos
	local pathLength = TSP:PathLength(path, zoneID)

	if nonblocking then
		startTime = GetTime() - startTime
	else
		startTime = debugprofilestop() - startTime
		startTime = startTime / 1000
	end
	return path, metadata, pathLength, count, startTime
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
--[[
Implementation notes:

The clusters are merged greedily: the two closest clusters within the cluster
diameter are merged if every node of both clusters is within the cluster
radius of the new (weighted) centroid, otherwise that pair is ignored until
one of the two clusters changes. Ties are broken by route order. This repeats
until there is no pair left that can be merged.

Only clusters within the cluster diameter of each other can ever be merged, so
instead of a full NxN distance matrix we keep
  - a spatial grid with a cell size of the cluster diameter, so the candidates
    for a cluster are found by looking at the 3x3 cells around it, and
  - a binary min-heap with all candidate pairs, ordered by distance.
Heap entries are never removed when a cluster changes or is merged away.
Instead every entry is stamped with the number of merges done at the time it
was added, and is ignored when it is popped if either cluster was changed
after that.

This takes O(P log P) time and O(P) memory, where P is the number of node
pairs within the cluster diameter of each other.
]]
function TSP:ClusterRoute(nodes, zoneID, radius, nonblocking)
	local numNodes = #nodes
	local zoneW, zoneH = Routes.Dragons:GetZoneSize(zoneID)
	local diameter = radius * 2

	-- Clusters are identified by the route index of their first node for the
	-- whole run, a cluster that is merged into another is just flagged as dead.
	local coord = {}    -- node ID of the cluster point
	local cx, cy = {}, {} -- decoded zone coordinate (0-1) of the cluster point
	local metadata = {} -- list of the original nodes in the cluster
	local changed = {}  -- number of merges done when the cluster last changed, inf if it is dead

	-- Step 1: Every node starts as its own cluster
	for i = 1, numNodes do
		local c = nodes[i]
		coord[i] = c
		cx[i], cy[i] = floor(c / 10000) / 10000, (c % 10000) / 10000
		metadata[i] = {c}
		changed[i] = 0
	end

	-- ensure one yield is always called. This must be after reading nodes[],
	-- the caller is free to modify it while we run in the background.
	if nonblocking then
		yieldNow()
	end

	-- Step 2: Sort the clusters into the grid
	-- The cells are slightly larger than the diameter so that rounding errors
	-- can never put 2 clusters within the diameter more than 1 cell apart.
	local cellSize = diameter * 1.001
	-- Limit the grid to 2^20 cells per axis so that the cell keys are always
	-- exact integers. Larger cells only mean more candidates per cell.
	local extent = abs(zoneW)
	if abs(zoneH) > extent then extent = abs(zoneH) end
	if not (cellSize > extent / 1048576) then cellSize = extent / 1048576 end
	if not (cellSize > 0) then cellSize = 1 end
	local scaleX, scaleY = zoneW / cellSize, zoneH / cellSize
	local stride = floor(abs(scaleY)) + 4 -- cell key is column * stride + row
	local cells = {}   -- cell key -> list of clusters in the cell
	local cellOf = {}  -- cluster -> cell key
	local cellPos = {} -- cluster -> index in the list of its cell
	for i = 1, numNodes do
		local key = floor(cx[i] * scaleX) * stride + floor(cy[i] * scaleY)
		local cell = cells[key]
		if not cell then
			cell = {}
			cells[key] = cell
		end
		local pos = #cell + 1
		cell[pos] = i
		cellOf[i], cellPos[i] = key, pos
	end

	-- Step 3: Find all pairs of nodes within the cluster diameter
	-- The heap is stored in 3 parallel arrays to save memory:
	local heapDist = {}  -- distance between the 2 clusters
	local heapPair = {}  -- low cluster * pairBase + high cluster
	local heapStamp = {} -- number of merges done when the entry was added
	local heapSize = 0
	local pairBase = numNodes + 1
	for i = 1, numNodes do
		local x, y, key = cx[i], cy[i], cellOf[i]
		for column = key - stride, key + stride, stride do
			for k = column - 1, column + 1 do
				local cell = cells[k]
				if cell then
					for n = 1, #cell do
						local j = cell[n]
						if j > i then
							local d = (((cx[j] - x)*zoneW)^2 + ((cy[j] - y)*zoneH)^2)^0.5
							if d <= diameter then
								heapSize = heapSize + 1
								heapDist[heapSize] = d
								heapPair[heapSize] = i * pairBase + j
								heapStamp[heapSize] = 0
							end
						end
					end
				end
			end
		end
		if nonblocking then
			yield()
		end
	end

	-- Moves the entry (d, p, s) down from position pos until the heap is valid.
	-- An entry is smaller if its distance is smaller, or on equal distance if
	-- it comes first in route order.
	local function siftDown(pos, d, p, s)
		local child = pos * 2
		while child <= heapSize do
			local cd, cp = heapDist[child], heapPair[child]
			if child < heapSize then
				local rd, rp = heapDist[child + 1], heapPair[child + 1]
				if rd < cd or (rd == cd and rp < cp) then
					child, cd, cp = child + 1, rd, rp
				end
			end
			if cd < d or (cd == d and cp < p) then
				heapDist[pos], heapPair[pos], heapStamp[pos] = cd, cp, heapStamp[child]
				pos, child = child, child * 2
			else
				break
			end
		end
		heapDist[pos], heapPair[pos], heapStamp[pos] = d, p, s
	end

	-- Turn the unsorted list of pairs into a heap
	for pos = floor(heapSize / 2), 1, -1 do
		siftDown(pos, heapDist[pos], heapPair[pos], heapStamp[pos])
		if nonblocking and pos % 256 == 0 then
			yield()
		end
	end

	-- Step 4: Keep merging the closest pair of clusters until there is none left
	local merges = 0
	while heapSize > 0 do
		-- Take the closest pair off the heap
		local pair, stamp = heapPair[1], heapStamp[1]
		local d, p, s = heapDist[heapSize], heapPair[heapSize], heapStamp[heapSize]
		heapDist[heapSize], heapPair[heapSize], heapStamp[heapSize] = nil, nil, nil
		heapSize = heapSize - 1
		if heapSize > 0 then
			siftDown(1, d, p, s)
		end

		local node1 = floor(pair / pairBase)
		local node2 = pair - node1 * pairBase
		-- Ignore the pair if either cluster has changed or died since
		if stamp >= changed[node1] and stamp >= changed[node2] then
			local m1, m2 = metadata[node1], metadata[node2]
			local node1num, node2num = #m1, #m2
			local totalnum = node1num + node2num
			-- Calculate the new centroid of node1
			local node1x = ( cx[node1] * node1num + cx[node2] * node2num ) / totalnum
			local node1y = ( cy[node1] * node1num + cy[node2] * node2num ) / totalnum
			-- Calculate the new coord from the new (x,y)
			local newCoord = floor(node1x * 10000 + 0.5) * 10000 + floor(node1y * 10000 + 0.5)
			node1x, node1y = floor(newCoord / 10000) / 10000, (newCoord % 10000) / 10000 -- to round off the coordinate
			-- Check that the merged point is valid: merging must not cause the
			-- merged point to be too far away from any of the original nodes
			local valid = true
			for i = 1, node1num do
				local c = m1[i]
				local x, y = floor(c / 10000) / 10000, (c % 10000) / 10000
				if (((node1x - x)*zoneW)^2 + ((node1y - y)*zoneH)^2)^0.5 > radius then
					valid = false
					break
				end
			end
			if valid then
				for i = 1, node2num do
					local c = m2[i]
					local x, y = floor(c / 10000) / 10000, (c % 10000) / 10000
					if (((node1x - x)*zoneW)^2 + ((node1y - y)*zoneH)^2)^0.5 > radius then
						valid = false
						break
					end
				end
			end
			if valid then
				merges = merges + 1
				-- Merge the metadata of node2 into node1
				for i = 1, node2num do
					m1[node1num + i] = m2[i]
				end
				-- Delete node2, the last cluster in its cell takes its place there
				metadata[node2] = false
				changed[node2] = inf
				local cell, pos = cells[cellOf[node2]], cellPos[node2]
				local last = #cell
				local moved = cell[last]
				cell[pos], cellPos[moved] = moved, pos
				cell[last] = nil
				-- Set the new coord of node1
				coord[node1], cx[node1], cy[node1] = newCoord, node1x, node1y
				changed[node1] = merges
				-- Move node1 to another cell if necessary
				local key = floor(node1x * scaleX) * stride + floor(node1y * scaleY)
				if key ~= cellOf[node1] then
					cell, pos = cells[cellOf[node1]], cellPos[node1]
					last = #cell
					moved = cell[last]
					cell[pos], cellPos[moved] = moved, pos
					cell[last] = nil
					cell = cells[key]
					if not cell then
						cell = {}
						cells[key] = cell
					end
					pos = #cell + 1
					cell[pos] = node1
					cellOf[node1], cellPos[node1] = key, pos
				end
				-- Add the new distances from node1 to all clusters around it
				for column = key - stride, key + stride, stride do
					for k = column - 1, column + 1 do
						cell = cells[k]
						if cell then
							for n = 1, #cell do
								local j = cell[n]
								if j ~= node1 then
									d = (((node1x - cx[j])*zoneW)^2 + ((node1y - cy[j])*zoneH)^2)^0.5
									if d <= diameter then
										p = j > node1 and node1 * pairBase + j or j * pairBase + node1
										-- Insert it into the heap, moving it up from the end
										heapSize = heapSize + 1
										pos = heapSize
										while pos > 1 do
											local parent = floor(pos / 2)
											local pd, pp = heapDist[parent], heapPair[parent]
											if d < pd or (d == pd and p < pp) then
												heapDist[pos], heapPair[pos], heapStamp[pos] = pd, pp, heapStamp[parent]
												pos = parent
											else
												break
											end
										end
										heapDist[pos], heapPair[pos], heapStamp[pos] = d, p, merges
									end
								end
							end
						end
					end
				end
			end
		end

		if nonblocking then
			yield()
		end
	end

	-- Step 5: Collect the remaining clusters in route order and get the new pathLength
	local newNodes, newMetadata = {}, {}
	local numClusters = 0
	local pathLength = 0
	local firstX, firstY, lastX, lastY
	for i = 1, numNodes do
		if changed[i] ~= inf then
			numClusters = numClusters + 1
			newNodes[numClusters] = coord[i]
			newMetadata[numClusters] = metadata[i]
			local x, y = cx[i], cy[i]
			if lastX then
				pathLength = pathLength + (((x - lastX)*zoneW)^2 + ((y - lastY)*zoneH)^2)^0.5
			else
				firstX, firstY = x, y
			end
			lastX, lastY = x, y
		end
	end
	if numClusters > 1 then
		pathLength = pathLength + (((lastX - firstX)*zoneW)^2 + ((lastY - firstY)*zoneH)^2)^0.5
	end

	return newNodes, newMetadata, pathLength
end

function TSP:ClusterRouteBackground(nodes, zoneID, radius, finishFunc)
	if not TSPClusterFrame.running then
		TSPClusterFrame.co = coroutine.create(TSP.ClusterRoute)
		TSPClusterFrame.finishFunc = finishFunc
		TSPClusterFrame:SetScript("OnUpdate", TSPClusterFrame.OnUpdate)
		TSPClusterFrame.running = true
		TSPClusterFrame.nodes = nodes
		local status, errormsg = coroutine.resume(TSPClusterFrame.co, TSP, nodes, zoneID, radius, true)
		if status then
			-- Do nothing, path isn't complete because at least 1 yield() is called.
			return 1
		else
			-- An error occured in the coroutine, abort and return the error message.
			TSPClusterFrame.running = false
			TSPClusterFrame:SetScript("OnUpdate", nil)
			TSPClusterFrame.co = nil
			TSPClusterFrame.finishFunc = nil
			TSPClusterFrame.nodes = nil
			return 3, errormsg
		end
	else
		-- There is already a clustering running
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
