-- Routes
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
L["Line gaps"] = true
L["Draw line gaps"] = true
L["Shorten the lines drawn on the minimap slightly so that they do not overlap the icons and minimap tracking blips."] = true
L["Skip clustered node points"] = true
L["Do not draw gaps for clustered node points in routes."] = true

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
-- M for Mining, H for Herbs, F for fishing, G for Gas, T for Treasure
L["CartographerHerbalism"] = "H"
L["CartographerMining"] = "M"
L["CartographerFishing"] = "F"
L["CartographerTreasure"] = "T"
L["CartographerExtractGas"] = "G"
L["GatherMateHerb Gathering"] = "H"
L["GatherMateMining"] = "M"
L["GatherMateFishing"] = "F"
L["GatherMateExtract Gas"] = "G"
L["GatherMateTreasure"] = "T"
L["GathererMINE"] = "M"
L["GathererHERB"] = "H"
L["GathererOPEN"] = "T"

-- Node types
L["Herbalism"] = true
L["Mining"] = true
L["Fishing"] = true
L["Treasure"] = true
L["ExtractGas"] = "Gas"

-- Route Config
L["When the following data sources add or delete node data, update my routes automatically by inserting or removing the same node in the relevant routes."] = true
L[" Gatherer currently does not support callbacks, so this is impossible for Gatherer."] = true
L["You have |cFFFFFFFF%d|r route(s) in |cFFFFFFFF%s|r."] = true
L["Information"] = true
L["This route has |cFFFFFFFF%d|r nodes and is |cFFFFFFFF%d|r yards long."] = true
L["This route has nodes that belong to the following categories:"] = true
L["This route contains the following nodes:"] = true
L["This route is not a clustered route."] = true
L["This route is a clustered route, down from the original |cFFFFFFFF%d|r nodes."] = true
L["|cFFFFFFFF     %d|r node(s) are between |cFFFFFFFF%d|r-|cFFFFFFFF%d|r yards of a cluster point"] = true
L["|cFFFFFFFF     %d|r node(s) are at |cFFFFFFFF0|r yards of a cluster point"] = true
L["The cluster radius of this route is |cFFFFFFFF%d|r yards."] = true

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
L["Route Optimizing"] = true
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

L["Route Clustering"] = true
L["CLUSTER_DESC"] = "Clustering a route makes Routes take all the nodes that are near each other and combine then into a single node as a travel point. This process takes a while, but is reasonably fast."
L["Cluster Radius"] = true
L["CLUSTER_RADIUS_DESC"] = "The maximum distance a node will be away from its cluster node point. The default is 60 yards because the detection radius of tracking skills is 80 yards."
L["Cluster"] = true
L["Cluster this route"] = true
L["Uncluster"] = true
L["Uncluster this route"] = true

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

-- Taboo stuff
L["Routes Node Menu"] = true
L["Delete node"] = true
L["Add node before (red)"] = true
L["Add node after (green)"] = true
L["You may not delete a taboo that is being edited."] = true
L["TABOO_EDIT_DESC"] = "To edit a taboo region, click on the |cFFFFFFFFEdit|r button. The taboo region will be drawn on the World Map. Drag the vertexes to position them. Right click on the vertexes to add or delete vertexes. After editing, you may click the |cFFFFFFFFSave|r button to save your changes, or the |cFFFFFFFFCancel|r button to discard your changes."
L["Edit taboo region"] = true
L["Edit this taboo region on the world map"] = true
L["Save taboo edit"] = true
L["Stop editing this taboo region on the world map and save the edits"] = true
L["Cancel taboo edit"] = true
L["Stop editing this taboo region on the world map and abandon changes made"] = true
L["Delete Taboo"] = true
L["Delete this taboo region permanently. This will also remove it from all routes that use it."] = true
L["Are you sure you want to delete this taboo? This action will also remove the taboo from all routes that use it."] = true
L["TABOO_DESC"] = "Taboo regions are areas which you can define to exclude nodes. Once you have created a taboo region, you can attach the taboo region to an existing route, and all nodes inside this region will be removed and no new ones will be added to it."
L["Name of Taboo"] = true
L["Name of taboo region to add"] = true
L["No name given for new taboo region"] = true
L["Zone to create taboo in"] = true
L["Create Taboo"] = true
L["Taboos in %s"] = true
L["A taboo with that name already exists. Overwrite?"] = true
L["This route has the following taboo regions:"] = true
L["This route has no taboo regions."] = true
L["This route contains |cFFFFFFFF%d|r nodes that have been tabooed."] = true
L["TABOO_DESC2"] = "Taboo regions are areas you specify for a route to ignore. Nodes in these taboo regions are ignored and not included in a route. Additionally when optimizing a route, the generated route will attempt to avoid crossing any taboo regions if possible."
L["Taboos"] = true
L["Select taboo regions to apply:"] = true
L["You have |cFFFFFFFF%d|r taboo region(s) in |cFFFFFFFF%s|r."] = true

-- FAQ
L["FAQ"] = true
L["Frequently Asked Questions"] = true
L["FAQ_TEXT"] = [[
|cFFFFFFFF
When I try to create a route, it says no data is found. What am I doing wrong?
|r
It means exactly that: No data is found, mostly because the addon is not loaded or in standby mode. If you are using any of the |cffffff78Cartographer_<Profession>|r modules, then these modules must be loaded and active for data to be available.

Note that |cffffff78Cartographer_<Profession>|r modules are all Load on Demand addons and require |cffffff78Cartographer_Professions|r to be enabled as it is the loading stub.
|cFFFFFFFF
I made a route with Rich Adamantite Ore in it. When I find normal Adamantite Ore in the same place, GatherMate/Cartographer deletes the rich node and replaces it with a normal node. This removes the node from my route since it is contructed out of only rich nodes. What can I do?
|r
1. You can make a route with both rich and normal Adamantite Ore in it.

2. You can tell Routes not to automatically insert/delete nodes. This option is found in the root options of the Routes tree in the config screen.
|cFFFFFFFF
Can you make a progress indicator on how long a background route optimization would take?
|r
A progress bar is not possible for the optimization process as it is a non-linear algorithm. It works on a "multiple pass" basis, each pass improving on the previous pass until it reaches a point where the improvement made is too minimal and then it will stop.

This is somewhat like the |cffffff78Windows XP Disk Defragmentation|r utility, and its progress bar is worthless because its only showing you the % of each pass, but it doesn't know how many passes it will take, it could be 3 passes, it could be 10 passes, it stops only when it thinks it has done enough. This is why in the |cffffff78Vista|r version, it no longer shows you a progress bar at all.
|cFFFFFFFF
Do you plan on adding Gatherer support or perhaps questing addons node support?
|r
This is most likely a yes for |cffffff78Gatherer|r, and a maybe for questing.
|cFFFFFFFF
How does Routes perform its route optimization?
|r
Routes uses an algorithm called |cffffff78Ant Colony Optimization|r (ACO) which is a heuristic/probabilistic method of calculating optimal graphs based on observed real life ant behavior.

ACO algorithms have been used to produce near-optimal solutions to the |cffffff78Traveling Salesman Problem|r (TSP). For more information, consult Google or Wikipedia.
|cFFFFFFFF
What does the "Extra Optimization" option do?
|r
By default, we only used ACO along with the standard |cffffff782-opt algorithm|r to optimize routes. Turning on "extra optimization" tells Routes to also use 2.5-opt, which is a specific subset of 3-opt. 2-opt is the process where pairs of edges are exchanged (A-B and C-D becomes A-C and B-D) in order to produce shorter routes.
|cFFFFFFFF
What algorithm does node clustering use?
|r
We employ a Hierarchical Agglomerative Clustering algorithm using a greedy approach, so the output is deterministic.
|cFFFFFFFF
I created a taboo region, attached it to a route, and optimized it. My route still flies through the taboo region. Why?
|r
It is not possible to always find a route that does not fly through a taboo region or sometimes highly unfeasible to do so.

The user could potentially create taboo regions that split the map into impassable sections and regions, so the algorithm is simply biased not to pass through them if it is possible.
|cFFFFFFFF
I've found a bug! Where do I report it?
|r
You can report bugs or give suggestions at |cffffff78http://www.wowace.com/forums/index.php?topic=10992.0|r

Alternatively, you can also find us on |cffffff78irc://irc.freenode.org/wowace|r

When reporting a bug, make sure you include the |cffffff78steps on how to reproduce the bug|r, supply any |cffffff78error messages|r with stack traces if possible, give the |cffffff78revision number|r of Routes the problem occured in and state whether you are using an |cffffff78English client or otherwise|r.
|cFFFFFFFF
Who wrote this cool addon?
|r
|cffffff78Xaros|r on EU Doomhammer Alliance & |cffffff78Xinhuan|r on US Blackrock Alliance did.
]]

-- vim: ts=4 noexpandtab
