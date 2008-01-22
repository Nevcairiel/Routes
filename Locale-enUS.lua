-- Cartographer_Routes
-- enUS and enGB Localization file

local L = LibStub("AceLocale-3.0"):NewLocale("Routes", "enUS", true)


L["Routes"] = true
L["routes"] = true -- slash command

-- Options Config
L["Options"] = true
L["Update distance"] = true
L["Yards to move before triggering a minimap update"] = true

-- Map drawing
L["Map Drawing"] = true
L["Toggle drawing on each of the maps."] = true
L["Worldmap"] = true
L["Worldmap drawing"] = true
L["Minimap"] = true
L["Minimap drawing"] = true
L["Zone Map"] = true
L["Zone Map drawing"] = true
L["Set the width of lines on each of the maps."] = true
L["Normal lines"] = true
L["Width of the line in the Worldmap"] = true
L["Width of the line in the Minimap"] = true
L["Width of the line in the Zone Map"] = true
L["Color of lines"] = true
L["Default route"] = true
L["Change default route color"] = true
L["Hidden route"] = true
L["Change default hidden route color"] = true
L["Show hidden routes"] = true
L["Show hidden routes?"] = true

-- Auto show/hide
L["Auto show/hide"] = true
L["Auto show and hide routes based on your professions"] = true
L["Use Auto Show/Hide"] = true
L["Auto Show/Hide per route type"] = true
L["Auto Show/Hide settings"] = true
L["Routes with Fish"] = true
L["Routes with Gas"] = true
L["Routes with Herbs"] = true
L["Routes with Ore"] = true
L["Routes with Treasure"] = true
L["Always show"] = true
L["Only with profession"] = true
L["Only while tracking"] = true
L["Never show"] = true

-- Waypoints
L["Waypoints (Carto)"] = true
L["Integrated support options for Cartographer_Waypoints"] = true
L["This section implements Cartographer_Waypoints support for Routes. Click Start to find the nearest node in a visible route in the current zone.\n"] = true
L["Waypoint hit distance"] = true
L["This is the distance in yards away from a waypoint to consider as having reached it so that the next node in the route can be added as the waypoint"] = true
L["Change direction"] = true
L["Change the direction of the nodes in the route being added as the next waypoint"] = true
L["Start using Waypoints"] = true
L["Start using Cartographer_Waypoints by finding the closest visible route/node in the current zone and using that as the waypoint"] = true
L["Stop using Waypoints"] = true
L["Stop using Cartographer_Waypoints by clearing the last queued node"] = true

-- Add Route Config
L["Add"] = true
L["Routes in %s"] = true
L["Name of Route"] = true
L["Name of the route to add"] = true
L["No name given for new route"] = true
L["Select Zone"] = true
L["Zone to create route in"] = true
L["Select sources of data"] = true
L[" Data"] = true
L["Select data to use"] = true
L["Select data to use in the route creation"] = true
L["No data found"] = true
L["Create Route"] = true
L["No data selected for new route"] = true
L["A route with that name already exists. Overwrite?"] = true

-- DB prefix abbreviations 
L["CartographerHerbalism"] = "H"
L["CartographerMining"] = "M"
L["CartographerFishing"] = "F"
L["CartographerTreasure"] = "T"
L["CartographerExtractGas"] = "G"
L["GatherMateHerb Gathering"] = "H"
L["GatherMateMining"] = "M"
L["GatherMateFishing"] = "F"
L["GatherMateExtract Gas"] = "G"

-- Node types
L["Herbalism"] = true
L["Mining"] = true
L["Fishing"] = true
L["Treasure"] = true
L["ExtractGas"] = "Gas"

-- Route Config
L["Information"] = true
L["This route has |cFFFFFFFF%d|r nodes and is |cFFFFFFFF%d|r yards long."] = true
L["This route has nodes that belong to the following categories:\n"] = true
L["This route contains the following nodes:\n"] = true

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
L["Are you sure you want to delete this route?"] = true
L["You may not delete a route that is being optimized in the background."] = true
L["Reset"] = true
L["Reset the line settings to defaults"] = true

L["Optimize route"] = true
L["Extra optimization"] = true
L["ExtraOptDesc"] = "Turning on this option will make optimizing the route take approximately 40% longer, but will generate -slightly- better routes. Recommended setting is OFF."
L["Foreground"] = true
L["Foreground Disclaimer"] = "Generate close to optimal path for the set of nodes in this route. Please keep in mind that doing this will 'hang' your client for some time. Depending on the amount of nodes (more cause near exponential increase in time) and CPU speed you might even get a disconnect if it takes too long."
L["Background"] = true
L["Background Disclaimer"] = "This will perform the TSP route generation in the background much more slowly without locking up WoW. Please note that your WoW will still take a noticable performance hit."
L["Path with %d nodes found with length %.2f yards after %d iterations in %.2f seconds."] = true
L["Now running TSP in the background..."] = true
L["There is already a TSP running in background. Wait for it to complete first."] = true
L["The following error occured in the background path generation coroutine, please report to Grum or Xinhuan:"] = true

-- Profession Names in the skills tab in the character frame
-- Doing these 4 localizations specifically to avoid using Babble-Spell
L["Skill-Fishing"] = "Fishing"
L["Skill-Herbalism"] = "Herbalism"
L["Skill-Mining"] = "Mining"
L["Skill-Engineering"] = "Engineering"

-- Cartographer_Waypoints support
L["Cartographer_Waypoints module is missing or disabled"] = true
L["%s - Node %d"] = true
L["Direction changed"] = true


-- vim: ts=4 noexpandtab
