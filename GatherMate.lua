if not Routes then return end

local Routes = Routes
local L = Routes.L
local BZ = Routes.BZ
local BZR = Routes.BZR
local SourceName = "GatherMate"

if type(Routes.data_source) ~= "table" then Routes.data_source = {} end
if type(Routes.data_source[SourceName]) ~= "table" then Routes.data_source[SourceName] = {} end

local source = Routes.data_source[SourceName]

local function IsActive()
	-- Can we gather data?
	return not not GatherMate
end
source.IsActive = IsActive

local function Summarize( data, zone )
	for db_type, db_data in pairs(GatherMate.gmdbs) do
		local amount_of = {}
		-- only look for data for this currentzone
		if db_data[GatherMate.zoneData[BZ[zone]][3]] then
			-- count the unique values (structure is: location => itemID)
			for _,node in pairs(db_data[GatherMate.zoneData[ BZ[zone] ][3] ]) do
				amount_of[node] = (amount_of[node] or 0) + 1
			end
			-- XXX Localize these strings
			-- store combinations with all information we have
			for node,count in pairs(amount_of) do
				local translatednode = GatherMate.reverseNodeIDs[node]
				data[ ("%s;%s;%s;%s"):format(SourceName, db_type, node, count) ] = ("%s%s - %s - %d"):format(L[SourceName.."Prefix"], db_type, translatednode, count)
			end
		end
	end
	return data
end
source.Summarize = Summarize

-- returns the english name for the node so we can store it was being requested
local function AppendNodes( node_list, zone, db_type, node_type )
	if type(GatherMate.gmdbs[db_type]) == "table" then
		node_type = tonumber(node_type)

		-- Find all of the notes
		for loc, t in pairs(GatherMate.gmdbs[db_type][ GatherMate.zoneData[ BZ[zone] ][3] ]) do
			-- And are of a selected type - store
			if t == node_type then
				tinsert( node_list, loc )
			end
		end

		-- return the node_type for auto-adding
		local LN = LibStub("AceLocale-3.0"):GetLocale("GatherMateNodes", true)
		local translatednode = GatherMate.reverseNodeIDs[node_type]
		for k, v in pairs(LN) do
			if v == translatednode then
				return k -- get the english name
			end
		end
	end
end
source.AppendNodes = AppendNodes

local function AddHook()
	-- Hook calls for adding a node
end
source.AddHook = AddHook

local function RemoveHook()
	-- Hook calls for deleting of a node
end
source.RemoveHook = RemoveHook

-- vim: ts=4 noexpandtab
