--[[
	FROZEN REFERENCE IMPLEMENTATION - DO NOT EDIT

	This is a verbatim copy of TSP:ClusterRoute() as of commit b2817f2 (the
	original O(n^3) time / O(n^2) memory matrix implementation). It is the
	oracle that the test suite compares the live implementation against:
	  - tests/cluster_gen.lua uses it to generate the *.expected.lua files
	  - tests/cluster_test.lua uses it for randomized differential testing

	Usage: local ref = loadfile("tests/cluster_reference.lua")(Routes)
	       ref:ClusterRoute(nodes, zoneID, radius)
]]
local Routes = ...
local floor = math.floor
local inf = math.huge
local tinsert, tremove = table.insert, table.remove
local coroutine = coroutine
local function yield() end
local TSP = {}

function TSP:ClusterRoute(nodes, zoneID, radius, nonblocking)
	local weight = {} -- weight matrix
	local metadata = {} -- metadata after clustering

	local numNodes = #nodes
	local zoneW, zoneH = Routes.Dragons:GetZoneSize(zoneID)
	local diameter = radius * 2
	--local taboo = 0

	-- Create a copy of the nodes[] table and use this instead of the original because we want to modify this table
	local nodes2 = {}
	for i = 1, numNodes do
		nodes2[i] = nodes[i]
		weight[i] = {} -- make weight[] a 2-dimensional table
	end
	local nodes = nodes2

	-- Step 1: Generate the weight table
	for i = 1, numNodes do
		local coord = nodes[i]
		local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
		local w = weight[i]
		w[i] = 0
		for j = i+1, numNodes do
			local coord = nodes[j]
			local x2, y2 = floor(coord / 10000) / 10000, (coord % 10000) / 10000
			w[j] = (((x2 - x)*zoneW)^2 + ((y2 - y)*zoneH)^2)^0.5 -- Calc distance between each node pair
			weight[j][i] = true -- dummy value just to fill the lower half of the table so that tremove() will work on it
		end
	end

	-- Step 2: Generate the initial metadata tables
	for i = 1, numNodes do
		metadata[i] = {}
		metadata[i][1] = nodes[i]
	end

	-- ensure one yield is always called
	if nonblocking then
		coroutine.yield()
	end

	-- Step 5: ...and loop until there is no such pair of nodes
	while true do
		-- Step 3: Find the closest pair of nodes within the merge radius
		local smallestDist = inf
		local node1, node2
		for i = 1, numNodes-1 do
			local w = weight[i]
			for j = i+1, numNodes do
				local w2 = w[j]
				if w2 <= diameter and w2 < smallestDist then
					smallestDist = w2
					node1 = i
					node2 = j
				end
			end
		end
		-- Step 4: Merge node2 into node1...
		if node1 then
			local m1, m2 = metadata[node1], metadata[node2]
			local node1num, node2num = #m1, #m2
			local totalnum = node1num + node2num
			-- Calculate the new centroid of node1
			local n1, n2 = nodes[node1], nodes[node2]
			local node1x = ( floor(n1 / 10000) / 10000 * node1num + floor(n2 / 10000) / 10000 * node2num ) / totalnum
			local node1y = ( (n1 % 10000) / 10000 * node1num + (n2 % 10000) / 10000 * node2num ) / totalnum
			-- Calculate the new coord from the new (x,y)
			local coord = floor(node1x * 10000 + 0.5) * 10000 + floor(node1y * 10000 + 0.5)
			node1x, node1y = floor(coord / 10000) / 10000, (coord % 10000) / 10000 -- to round off the coordinate
			-- Check that the merged point is valid
			for i = 1, node1num do
				local coord = m1[i]
				local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
				local t = (((node1x - x)*zoneW)^2 + ((node1y - y)*zoneH)^2)^0.5
				if t > radius then
					-- Merging this node will cause the merged point to be too far away
					-- from an original point, so taboo it by making the weight infinity
					-- And store a backup in the lower half of the table
					weight[node2][node1] = weight[node1][node2]
					weight[node1][node2] = inf
					--taboo = taboo + 1
					break
				end
			end
			if weight[node1][node2] ~= inf then
				for i = 1, node2num do
					local coord = m2[i]
					local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
					local t = (((node1x - x)*zoneW)^2 + ((node1y - y)*zoneH)^2)^0.5
					if t > radius then
						weight[node2][node1] = weight[node1][node2]
						weight[node1][node2] = inf
						--taboo = taboo + 1
						break
					end
				end
			end
			if weight[node1][node2] ~= inf then
				-- Merge the metadata of node2 into node1
				for i = 1, node2num do
					tinsert(m1, m2[i])
				end
				-- Set the new coord of node1
				nodes[node1] = coord
				-- Delete node2 from metadata[]
				tremove(metadata, node2)
				-- Delete node2 from nodes[]
				tremove(nodes, node2)
				-- Remove node2 from the weight table
				for i = 1, numNodes do
					tremove(weight[i], node2) -- remove column
				end
				tremove(weight, node2) -- remove row
				-- Update number of nodes
				numNodes = numNodes - 1
				-- Update the weight table for all nodes relating to node1, this can untaboo nodes
				for i = 1, node1-1 do
					local coord = nodes[i]
					local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
					weight[i][node1] = (((node1x - x)*zoneW)^2 + ((node1y - y)*zoneH)^2)^0.5
				end
				for i = node1+1, numNodes do
					local coord = nodes[i]
					local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
					weight[node1][i] = (((node1x - x)*zoneW)^2 + ((node1y - y)*zoneH)^2)^0.5
				end
			end
		else
			break -- loop termination
		end

		if nonblocking then
			yield()
		end
	end

	-- Get the new pathLength
	local pathLength = weight[1][numNodes]
	pathLength = pathLength == inf and weight[numNodes][1] or pathLength
	for i = 1, numNodes-1 do
		local w = weight[i][i+1]
		pathLength = pathLength + (w == inf and weight[i+1][i] or w) -- use the backup in the lower half of the triangle if it was tabooed
	end

	--ChatFrame1:AddMessage(taboo.." tabooed")
	return nodes, metadata, pathLength
end

return TSP
