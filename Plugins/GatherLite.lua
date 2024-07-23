local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes", 1)
if not Routes then
    return
end

local SourceName = "GatherLite"
-- setup
Routes.plugins[SourceName] = {}
local source = Routes.plugins[SourceName]

do
    local loaded = true
    local function IsActive()
        -- Can we gather data?
        return GatherLite and loaded
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

local amount_of = {}
local translate_db_type = {
    ["herbalism"] = "Herbalism",
    ["mining"] = "Mining",
}
local function Summarize(data, zone)
    local zoneID = Routes.LZName[zone]
    local nodes = {};
    for index, node in ipairs(GatherLite:GetNodes()) do
        if zoneID == node.mapID then
            table.insert(nodes, node);
        end
    end

    for index, node in ipairs(nodes) do
        amount_of[node.object] = (amount_of[node.object] or 0) + 1
    end

    for index, node in ipairs(nodes) do
        local object = GatherLite:GetNodeObject(node.object);

        if not object then
            break
        end

        local translatednode = GatherLite:translate("node." .. object.name);
        local count = amount_of[node.object];
        data[("%s;%s;%s;%s"):format(SourceName, node.type, object.name, count)] = ("%s - %s (%d)"):format(translate_db_type[node.type], translatednode, count)
    end
    return data
end

local function AppendNodes(node_list, zone, db_type, node_type)
    local zoneID = Routes.LZName[zone]

    for index, node in ipairs(GatherLite:GetNodes()) do
        if zoneID == node.mapID and node.type == db_type then
            local newLoc = Routes:getID(node.posX, node.posY)
            tinsert(node_list, newLoc)
        end
    end

    local translatednode = GatherLite:translate("node." .. node_type)
    return translatednode, translatednode, translate_db_type[db_type]
end

local function InsertNode(event, node)
    local newCoord = Routes:getID(node.posX, node.posY)
    local zoneLocalized = Routes.GetZoneName(node.mapID)
    if not zoneLocalized then return end

    local object = GatherLite:GetNodeObject(node.object);
    local translatednode = GatherLite:translate("node." .. object.name)

    Routes:InsertNode(zoneLocalized, newCoord, translatednode)
end

local function AddCallbacks()
    Routes:RegisterMessage("GatherLiteNodeAdded", InsertNode)
end

local function RemoveCallbacks()
    Routes:UnregisterMessage("GatherLiteNodeAdded")
end

source.Summarize = Summarize
source.AppendNodes = AppendNodes
source.AddCallbacks = AddCallbacks
source.RemoveCallbacks = RemoveCallbacks
