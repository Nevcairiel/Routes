local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes", 1)
if not Routes then return end

local SourceName = "Gatherer"
local L = LibStub("AceLocale-3.0"):GetLocale("Routes")
local BZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()

local zoneNamesReverse = Routes.zoneNamesReverse
Routes.zoneNamesReverse = nil

------------------------------------------
-- setup
Routes.plugins[SourceName] = {}
local source = Routes.plugins[SourceName]

do
	local loaded = true
	local function IsActive() -- Can we gather data?
		return Gatherer and loaded
	end
	source.IsActive = IsActive

	-- stop loading if the addon is not enabled, or
	-- stop loading if there is a reason why it can't be loaded ("MISSING" or "DISABLED")
	local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(SourceName)
	if not enabled or (reason ~= nil) then
		loaded = false
		return
	end
end

------------------------------------------
-- functions

local amount_of = {}
local function Summarize(data, zone)
	local continent = zoneNamesReverse[zone]
	continent, zone = floor(continent / 100), continent % 100

	for node, db_type, count in Gatherer.Storage.ZoneGatherNames(continent, zone) do
		local translatednode
		for k, v in pairs(Gatherer.Nodes.Names) do
			if v == node then
				translatednode = k
				break
			end
		end
		data[ ("%s;%s;%s;%s"):format(SourceName, db_type, node, count) ] = ("%s - %s - %d"):format(L[SourceName..db_type], translatednode, count)
	end

	return data
end
source.Summarize = Summarize

-- returns the english name, translated name for the node so we can store it was being requested
-- also returns the type of db for use with auto show/hide route
local translate_db_type = {
	["HERB"] = "Herbalism",
	["MINE"] = "Mining",
	["OPEN"] = "Treasure",
}
local function AppendNodes(node_list, zone, db_type, node_type)
	local continent = zoneNamesReverse[zone]
	continent, zone = floor(continent / 100), continent % 100

	for _, x, y in Gatherer.Storage.ZoneGatherNodes(continent, zone, node_type) do
		tinsert( node_list, floor(x * 10000 + 0.5) * 10000 + floor(y * 10000 + 0.5) )
	end

	-- return the node_type for auto-adding
	local translatednode
	for k, v in pairs(Gatherer.Nodes.Names) do
		if v == node_type then
			translatednode = k
			break
		end
	end
	return translatednode, translatednode, translate_db_type[db_type]
end
source.AppendNodes = AppendNodes

local function InsertNode(event, zone, nodeType, coord, node_name)
	--Routes:InsertNode(zone, coord, node_name)
end

local function DeleteNode(event, zone, nodeType, coord, node_name)
	--Routes:DeleteNode(zone, coord, node_name)
end

local function AddCallbacks()
	--Functions to add Gatherer callbacks
end
source.AddCallbacks = AddCallbacks

local function RemoveCallbacks()
	--Functions to remove Gatherer callbacks
end
source.RemoveCallbacks = RemoveCallbacks

-- vim: ts=4 noexpandtab
