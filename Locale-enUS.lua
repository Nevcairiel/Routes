-- Cartographer_Routes
-- enUS and enGB Localization file

local L = LibStub("AceLocale-3.0"):NewLocale("Routes", "enUS", true)


L["Routes"] = true
L["routes"] = true -- slash command

L["Add"] = true
L['Routes in %s'] = true

-- route config
L["Line settings"] = true
L["These settings control the visibility and look of the drawn route."] = true
L["Width (Map)"] = true
L["Width of the line in the map"] = true
L["Width (Minimap)"] = true
L["Width of the line in the Minimap"] = true
L["Width (Zone Map)"] = true
L["Width of the line in the Zone Map"] = true
L["Line Color"] = true
L["Change the line color"] = true
L["Hide Route"] = true
L["Hide the route from being shown on the maps"] = true
L["Delete"] = true
L["Permanently delete a route"] = true
L["Reset"] = true
L["Reset the line settings to defaults"] = true
L["Optimize route [%d nodes, %d yards]"] = true
L["Extra optimization"] = true
L["ExtraOptDesc"] = "Turning on this option will make optimizing the route take approximately 40% longer, but will generate -slightly- better routes. Recommended setting is OFF."

-- vim: ts=4 noexpandtab
