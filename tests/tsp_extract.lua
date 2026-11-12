--[[
	Extracts a route from a Routes saved variables file into test cases for
	the route optimizer, so that it can be tested on real routes.

	Usage (from the addon root):
		lua5.1 tests/tsp_extract.lua <file> <zoneID> <route name> <case name> [<zone width> <zone height>]

	<file> is WTF/Account/<account>/SavedVariables/Routes.lua. The route should
	be a clustered route. This writes 3 cases to tests/data/tsp/:
		real_<case name>            the clusters of the route with its taboos,
		                            in the order a new route has
		real_<case name>_optimized  the same in the order the route has now
		real_<case name>_raw        the nodes of the route, not clustered

	The size of the zone in yards is not in the saved variables. If it is not
	given, it is calculated from the stored length of the route, assuming the
	zone map is 3:2 like most are. Clustering the nodes again must then give
	the clusters of the route, which is checked.

	The cases are not listed in the data set automatically: add them to the
	list of real routes in tests/tsp_gen.lua and run it for them
	(lua5.1 tests/tsp_gen.lua real_).
]]

local root = (arg[0]:gsub("\\", "/"):match("^(.*)/tests/[^/]*$")) or "."
local shims = dofile(root .. "/tests/wow_shims.lua")(root)
shims.LoadAddonFile("TSP.lua")
local TSP = shims.Routes.TSP
local util = dofile(root .. "/tests/tsp_util.lua")

local file, zoneID, routeName, caseName = arg[1], tonumber(arg[2]), arg[3], arg[4]
local zoneW, zoneH = tonumber(arg[5]), tonumber(arg[6])
assert(file and zoneID and routeName and caseName, "usage: tsp_extract.lua <file> <zoneID> <route name> <case name> [<zone width> <zone height>]")

-- Saved variables are Lua code. Run it in an empty environment so that it can
-- do nothing but define its tables.
local f = assert(io.open(file, "rb"))
local source = f:read("*a"):gsub("^\239\187\191", "")
f:close()
local env = {}
local chunk = assert(loadstring(source, "@" .. file))
setfenv(chunk, env)
chunk()
local global = assert(env.RoutesDB and env.RoutesDB.global, "no RoutesDB.global in " .. file)
local route = assert(global.routes[zoneID] and global.routes[zoneID][routeName], "no such route in that zone")
assert(route.metadata, "the route is not clustered")

if not zoneW then
	zoneH = route.length / util.RouteLength(route.route, 1.5, 1)
	zoneW = zoneH * 1.5
	print(("zone size from the stored length of the route: %.3f x %.3f yards"):format(zoneW, zoneH))
end
shims.SetZoneSize(1, zoneW, zoneH)

local taboos = {}
for name, used in pairs(route.taboos or {}) do
	if used and global.taboo[zoneID] and global.taboo[zoneID][name] then
		taboos[#taboos + 1] = global.taboo[zoneID][name].route
	end
end
table.sort(taboos, function(a, b) return a[1] < b[1] end) -- pairs() has no defined order

-- all nodes of the route, in the order a new route has
local raw = {}
for i = 1, #route.metadata do
	for j = 1, #route.metadata[i] do raw[#raw + 1] = route.metadata[i][j] end
end
raw = TSP:DecrossRoute(raw)

-- check the zone size: clustering the nodes again must give the same clusters
local clusters = TSP:ClusterRoute(raw, 1, route.cluster_dist or 65)
local stored, same = {}, 0
for i = 1, #route.route do stored[route.route[i]] = true end
for i = 1, #clusters do
	if stored[clusters[i]] then same = same + 1 end
end
print(("%d nodes, %d clusters, %d taboos"):format(#raw, #route.route, #taboos))
if #clusters ~= #route.route or same ~= #clusters then
	print(("WARNING: clustering the nodes again gives %d clusters of which %d are clusters of the route."):format(#clusters, same))
	print("The zone size is probably wrong, or the route was changed after it was clustered.")
end

-- the clusters in the order a new route has
local index = {}
for i = 1, #route.route do index[route.route[i]] = i end
local unoptimized = {}
for i = 1, #route.route do unoptimized[i] = route.route[i] end
unoptimized = TSP:DecrossRoute(unoptimized)
local unoptimizedMeta = {}
for i = 1, #unoptimized do unoptimizedMeta[i] = route.metadata[index[unoptimized[i]]] end

local function writeLists(f, lists)
	for i = 1, #lists do
		local s = {}
		for j = 1, #lists[i] do s[j] = ("%d"):format(lists[i][j]) end
		f:write("\t\t{ ", table.concat(s, ", "), " },\n")
	end
end

local function write(name, note, nodes, metadata)
	local path = ("%s/tests/data/tsp/real_%s.lua"):format(root, name)
	local f = assert(io.open(path, "wb"))
	f:write("-- Extracted from a saved variables file by tests/tsp_extract.lua, do not edit\n")
	f:write("return {\n")
	f:write(("\tname = %q,\n\tnote = %q,\n"):format("real_" .. name, note))
	f:write(("\tzoneW = %.17g,\n\tzoneH = %.17g,\n"):format(zoneW, zoneH))
	f:write("\tnodes = {\n")
	local line = {}
	for i = 1, #nodes do
		line[#line + 1] = ("%d"):format(nodes[i])
		if #line == 12 or i == #nodes then
			f:write("\t\t", table.concat(line, ", "), ",\n")
			line = {}
		end
	end
	f:write("\t},\n")
	if metadata then
		f:write("\tmetadata = {\n")
		writeLists(f, metadata)
		f:write("\t},\n")
	end
	if #taboos > 0 then
		f:write("\ttaboos = {\n")
		writeLists(f, taboos)
		f:write("\t},\n")
	end
	f:write("}\n")
	f:close()
	print("wrote " .. path)
end

local what = ("route %q in zone %d"):format(routeName, zoneID)
write(caseName, what .. ": its clusters in the order a new route has", unoptimized, unoptimizedMeta)
write(caseName .. "_optimized", what .. ": its clusters in the order it was saved in", route.route, route.metadata)
write(caseName .. "_raw", what .. ": its nodes, not clustered", raw)
