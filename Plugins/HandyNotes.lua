local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes", 1)
if not Routes then return end

local SourceName = "HandyNotes"
local L = LibStub("AceLocale-3.0"):GetLocale("Routes")
--local LN = LibStub("AceLocale-3.0"):GetLocale("HandyNotes", true)

------------------------------------------
-- setup
Routes.plugins[SourceName] = {}
local source = Routes.plugins[SourceName]

do
	local loaded = true
	local function IsActive() -- Can we gather data?
		return HandyNotes and loaded
	end
	source.IsActive = IsActive

	-- stop loading if the addon is not enabled, or
	-- stop loading if there is a reason why it can't be loaded ("MISSING" or "DISABLED")
	local enabled = C_AddOns.GetAddOnEnableState(SourceName, UnitName("player")) > 0
	local name, title, notes, loadable, reason, security = C_AddOns.GetAddOnInfo(SourceName)
	if not enabled or (reason ~= nil and reason ~= "" and reason ~= "DEMAND_LOADED") then
		loaded = false
		return
	end
end

------------------------------------------
-- functions

local amount_of = {}
local function Summarize(data, zone)
	-- reuse table
	for k in pairs(amount_of) do amount_of[k] = nil end

	local HN = HandyNotes:GetModule("HandyNotes")
	local zoneID = Routes.LZName[zone]
	for coord, zoneID2, iconpath, scale, alpha in HandyNotes.plugins["HandyNotes"]:GetNodes2(zoneID) do
		local title = HN.db.global[zoneID2 or zoneID][coord].title
		if not title then title = "" end -- For improperly imported notes into HandyNotes
		amount_of[title] = (amount_of[title] or 0) + 1
	end
	for node, count in pairs(amount_of) do
		data[ ("%s;%s;%s;%s"):format(SourceName, "Note", node, count) ] = ("%s (%d)"):format(node, count)
	end
	return data
end
source.Summarize = Summarize

-- returns the english name, translated name for the node so we can store it was being requested
-- also returns the type of db for use with auto show/hide route
local function AppendNodes(node_list, zone, db_type, node_type)
	-- Find all of the notes
	local HN = HandyNotes:GetModule("HandyNotes")
	local zoneID = Routes.LZName[zone]
	for coord, zoneID2, iconpath, scale, alpha in HandyNotes.plugins["HandyNotes"]:GetNodes2(zoneID) do
		local title = HN.db.global[zoneID2 or zoneID][coord].title
		if not title then title = "" end -- For improperly imported notes into HandyNotes
		if title == node_type then
			tinsert(node_list, coord)
		end
	end
	return node_type, node_type, "Note"
end
source.AppendNodes = AppendNodes

local function InsertNode(event, zone, nodeType, coord, node_name)
	--Routes:InsertNode(zone, coord, node_name)
end

local function DeleteNode(event, zone, nodeType, coord, node_name)
	--Routes:DeleteNode(zone, coord, node_name)
end

local function AddCallbacks()
end
source.AddCallbacks = AddCallbacks

local function RemoveCallbacks()
end
source.RemoveCallbacks = RemoveCallbacks

-- vim: ts=4 noexpandtab
