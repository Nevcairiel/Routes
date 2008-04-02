-- Routes
-- zhCN Localization file

local L = LibStub("AceLocale-3.0"):NewLocale("Routes", "zhCN")
if not L then return end

L["Routes"] = "线路图"
L["routes"] = "routes" -- slash command

-- Options Config
L["Options"] = "选项"
L["Update distance"] = "更新距离"
L["Yards to move before triggering a minimap update"] = "在什么距离下迷你地图才开始更新(按码计算)"

-- Map drawing
L["Map Drawing"] = "地图绘制"
L["Toggle drawing on each of the maps."] = "设置在所有地图上绘制。"
L["Worldmap"] = "世界地图"
L["Worldmap drawing"] = "世界地图绘制"
L["Minimap"] = "迷你地图"
L["Minimap drawing"] = "迷你地图绘制"
L["Zone Map"] = "地区地图"
L["Zone Map drawing"] = "地区地图绘制"
L["Set the width of lines on each of the maps."] = "设置地图上绘制的导航线的线宽。"
L["Normal lines"] = "普通导航线"
L["Width of the line in the Worldmap"] = "在世界地图上显示的线宽"
L["Width of the line in the Minimap"] = "在迷你地图上显示的线宽"
L["Width of the line in the Zone Map"] = "在地区地图上显示的线宽"
L["Color of lines"] = "导航线颜色"
L["Default route"] = "默认线路图"
L["Change default route color"] = "更改默认线路图颜色。"
L["Hidden route"] = "隐藏线路图"
L["Change default hidden route color"] = "更改默认隐藏线路图颜色。"
L["Show hidden routes"] = "显示隐藏线路图"
L["Show hidden routes?"] = "是否显示隐藏线路图？"
L["Line gaps"] = "线隔断"
L["Draw line gaps"] = "画线隔断"
L["Shorten the lines drawn on the minimap slightly so that they do not overlap the icons and minimap tracking blips."] = "当遇到图标和迷你地图追踪显示的时候把线隐藏，以使不把图标给遮盖住。"
L["Skip clustered node points"] = "跳过精简节点"
L["Do not draw gaps for clustered node points in routes."] = "对于精简节点不使用线隔断。"

-- Auto show/hide
L["Auto show/hide"] = "自动显示"
L["Auto show and hide routes based on your professions"] = "根据你的专业，自动显示或者隐藏线路图。"
L["Use Auto Show/Hide"] = "使用自动显示"
L["Auto Show/Hide per route type"] = "自动显示线路图类型"
L["Auto Show/Hide settings"] = "自动显示设置"
L["Routes with Fish"] = "鱼群线路图"
L["Routes with Gas"] = "气云线路图"
L["Routes with Herbs"] = "草药线路图"
L["Routes with Ore"] = "矿点线路图"
L["Routes with Treasure"] = "宝藏线路图"
L["Always show"] = "总是显示"
L["Only with profession"] = "仅当拥有相关技能"
L["Only while tracking"] = "仅当开启相关追踪"
L["Never show"] = "从不"

-- Waypoints
L["Waypoints (Carto)"] = "方向标(CA)"
L["Integrated support options for Cartographer_Waypoints"] = "Cartographer_Waypoints的一体化选项。"
L["This section implements Cartographer_Waypoints support for Routes. Click Start to find the nearest node in a visible route in the current zone.\n"] = "这个选项将使Cartographer_Waypoints支持Routes，点击开始寻找该地图当前线路图最近的节点。"
L["Waypoint hit distance"] = "到达范围"
L["This is the distance in yards away from a waypoint to consider as having reached it so that the next node in the route can be added as the waypoint"] = "设置一个距离，当你与节点的距离距离小于该码数时将使用下个节点作为方向标的目标。"
L["Change direction"] = "更改方向"
L["Change the direction of the nodes in the route being added as the next waypoint"] = "将新加入线路图的节点作为下个方向标的方向。"
L["Start using Waypoints"] = "启用方向标"
L["Start using Cartographer_Waypoints by finding the closest visible route/node in the current zone and using that as the waypoint"] = "启用Cartographer_Waypoints作为默认的方向标插件指示出最近的可采集节点的位置。"
L["Stop using Waypoints"] = "停用方向标"
L["Stop using Cartographer_Waypoints by clearing the last queued node"] = "停用方向标。"

-- Add Route Config
L["Add"] = "增加"
L["Routes in %s"] = "在 %s 的线路图"
L["Name of Route"] = "线路图名称"
L["Name of the route to add"] = "要增加的线路图的名称"
L["No name given for new route"] = "未给新线路图命名"
L["Select Zone"] = "选择地区"
L["Zone to create route in"] = "你想要创建线路图的地区"
L["Select sources of data"] = "选择数据类型"
L[" Data"] = " 数据"
L["Select data to use"] = "选择使用的数据"
L["Select data to use in the route creation"] = "选择在创建线路图中使用的数据"
L["No data found"] = "没有数据"
L["Create Route"] = "创建线路图"
L["No data selected for new route"] = "新的线路图没有任何数据被选择"
L["A route with that name already exists. Overwrite?"] = "发现同名线路图，覆盖？"

-- DB prefix abbreviations 
-- M for Mining, H for Herbs, F for fishing, G for Gas, T for Treasure
L["CartographerHerbalism"] = "药"
L["CartographerMining"] = "矿"
L["CartographerFishing"] = "鱼"
L["CartographerTreasure"] = "宝"
L["CartographerExtractGas"] = "气"
L["GatherMateHerb Gathering"] = "药"
L["GatherMateMining"] = "矿"
L["GatherMateFishing"] = "鱼"
L["GatherMateExtract Gas"] = "气"
L["GatherMateTreasure"] = "宝"
L["GathererMINE"] = "矿"
L["GathererHERB"] = "药"
L["GathererOPEN"] = "宝"

-- Node types
L["Herbalism"] = "草药"
L["Mining"] = "矿脉"
L["Fishing"] = "鱼群"
L["Treasure"] = "宝藏"
L["ExtractGas"] = "气云"

-- Route Config
L["When the following data sources add or delete node data, update my routes automatically by inserting or removing the same node in the relevant routes."] = "当下列数据源增加或者删除节点时，自动更新我的线路图。"
L[" Gatherer currently does not support callbacks, so this is impossible for Gatherer."] = " Gatherer当前不支持反馈，所以这个选项对Gatherer无效。"
L["You have |cFFFFFFFF%d|r route(s) in |cFFFFFFFF%s|r."] = "你现在有 |cFFFFFFFF%d|r 个线路图在 |cFFFFFFFF%s|r。"
L["Information"] = "信息"
L["This route has |cFFFFFFFF%d|r nodes and is |cFFFFFFFF%d|r yards long."] = "这个线路图有 |cFFFFFFFF%d|r 个节点，全长 |cFFFFFFFF%d|r 码。"
L["This route has nodes that belong to the following categories:"] = "这个线路图拥有下列类型的节点："
L["This route contains the following nodes:"] = "这个线路图拥有下列节点："
L["This route is not a clustered route."] = "这个线路图不是一个精简线路图。"
L["This route is a clustered route, down from the original |cFFFFFFFF%d|r nodes."] = "这个线路图是一个精简线路图，原始拥有 |cFFFFFFFF%d|r 个节点。"
L["|cFFFFFFFF     %d|r node(s) are between |cFFFFFFFF%d|r-|cFFFFFFFF%d|r yards of a cluster point"] = "|cFFFFFFFF     %d|r 个节点，在 |cFFFFFFFF%d|r-|cFFFFFFFF%d|r 码内的被精简为一个节点。"
L["|cFFFFFFFF     %d|r node(s) are at |cFFFFFFFF0|r yards of a cluster point"] = "|cFFFFFFFF     %d|r 个节点在 |cFFFFFFFF0|r 码内将被视为一个节点。"
L["The cluster radius of this route is |cFFFFFFFF%d|r yards."] = "该线路图的精简半径为 |cFFFFFFFF%d|r 码。"

L["Line settings"] = "绘图设置"
L["These settings control the visibility and look of the drawn route."] = "这里设置的是线路图绘制时采用的线的外观。"
L["Width (Map)"] = "宽度(世界地图)"
L["Width of the line in the map"] = "世界地图上线的宽度。"
L["Width (Minimap)"] = "宽度(迷你地图)"
L["Width of the line in the Minimap"] = "迷你地图上线的宽度。"
L["Width (Zone Map)"] = "宽度(地区地图)"
L["Width of the line in the Zone Map"] = "地区地图上线的宽度。"
L["Line Color"] = "颜色"
L["Change the line color"] = "设置线的颜色"
L["Hide Route"] = "隐藏线路图"
L["Hide the route from being shown on the maps"] = "隐藏显示在地图上的线路图。"
L["Delete"] = "删除"
L["Permanently delete a route"] = "完全删除一个线路图。"
L["Are you sure you want to delete this route?"] = "你确认你要删除该线路图么？"
L["You may not delete a route that is being optimized in the background."] = "你不能删除一个正在后台优化的线路。"
L["Reset"] = "重置"
L["Reset the line settings to defaults"] = "重置所有绘线设置为默认值。"

L["Optimize route"] = "线路图优化"
L["Route Optimizing"] = "优化线路图"
L["Extra optimization"] = "超级优化"
L["ExtraOptDesc"] = "启用该选项后，你会生成一个更加精确合理的线路图，但是会花费超过普通时长40%的时间。建议设置为 OFF。"
L["Foreground"] = "前台"
L["Foreground Disclaimer"] = "自动生成最优化路径线路图。请注意：有时候你会感觉你的WOW程序锁死了，但实际上是在进行复杂的运算！生成线路的时间依赖于节点的数目和你的CPU的强悍程度，但是太长时间的话会导致你的客户端掉线！"
L["Background"] = "后台"
L["Background Disclaimer"] = "这将会让TSP程序在后台允许，虽然比较慢，但是不会锁死WOW窗口。请注意：这时WOW会明显变慢(在TSP运行完成前)！"
L["Path with %d nodes found with length %.2f yards after %d iterations in %.2f seconds."] = "包含 %d 个节点的总成 %.2f 码的线路经过 %d 的迭代，在%.2f 秒后生成。"
L["Now running TSP in the background..."] = "现在在后台允许TSP……"
L["There is already a TSP running in background. Wait for it to complete first."] = "当前后台正在运行一个TSP，请等待结束后再试！"
L["The following error occured in the background path generation coroutine, please report to Grum or Xinhuan:"] = "在生成背景线路是发生错误，请给Grum或者Xinhuan发送报告："

L["Route Clustering"] = "线路图精简"
L["CLUSTER_DESC"] = "精简一个线路图的意义在于可以把一定范围内的资源精简为一个追踪点，这样可以使线路图的生成更加快捷和可靠。"
L["Cluster Radius"] = "精简半径"
L["CLUSTER_RADIUS_DESC"] = "一个节点距离其精简节点的最大距离。默认为60码，因为追踪技能的最大侦测范围为80码。"
L["Cluster"] = "精简"
L["Cluster this route"] = "对该线路图节点进行精简。"
L["Uncluster"] = "原始"
L["Uncluster this route"] = "不对该线路图节点进行精简。"

-- Profession Names in the skills tab in the character frame
-- Doing these 4 localizations specifically to avoid using Babble-Spell
L["Skill-Fishing"] = "钓鱼"
L["Skill-Herbalism"] = "草药学"
L["Skill-Mining"] = "采矿"
L["Skill-Engineering"] = "工程学"

-- Cartographer_Waypoints support
L["Cartographer_Waypoints module is missing or disabled"] = "Cartographer_Waypoints不存在或者未启用！"
L["%s - Node %d"] = "%s - 节点 %d"
L["Direction changed"] = "方向已改变"

-- Taboo stuff
L["Routes Node Menu"] = "线路图节点菜单"
L["Delete node"] = "删除节点"
L["Add node before (red)"] = "在之前增加节点(红)"
L["Add node after (green)"] = "在之后增加节点(绿)"
L["You may not delete a taboo that is being edited."] = "你不能删除一个正在编辑的禁区！"
L["TABOO_EDIT_DESC"] = "如果要编辑一个禁区，点击 |cFFFFFFFFEdit|r 按钮，开始在世界地图上绘制禁区位置，绘制角点以定位禁区大小。右键点击角点以增加或者删除一个角点。编辑完成后，你可以点击 |cFFFFFFFFSave|r 按钮已保存结果，或者点击 |cFFFFFFFFCancel|r 按钮放弃所作更改。"
L["Edit taboo region"] = "开始禁区编辑"
L["Edit this taboo region on the world map"] = "开始在世界地图上编辑禁区"
L["Save taboo edit"] = "保存禁区编辑"
L["Stop editing this taboo region on the world map and save the edits"] = "停止在世界地图上编辑禁区，并保存设置。"
L["Cancel taboo edit"] = "取消禁区编辑"
L["Stop editing this taboo region on the world map and abandon changes made"] = "停止在世界地图上编辑禁区，并放弃先前所作更改。"
L["Delete Taboo"] = "删除禁区"
L["Delete this taboo region permanently. This will also remove it from all routes that use it."] = "永久性删除该禁区，同时将从所有线路图中删除该禁区。"
L["Are you sure you want to delete this taboo? This action will also remove the taboo from all routes that use it."] = "你确定要删除该禁区么？该行为将从所有线路图中删除该禁区。"
L["TABOO_DESC"] = "禁区是一个你可以定义的包含节点的区域，一但你创建了一个禁区，你可以将禁区包含到已创建的线路图中，所有在该禁区内的节点将被删除，并且不会再次写入。"
L["Name of Taboo"] = "禁区名"
L["Name of taboo region to add"] = "给禁区命名"
L["No name given for new taboo region"] = "禁区未命名"
L["Zone to create taboo in"] = "创建禁区的地图名称"
L["Create Taboo"] = "创建禁区"
L["Taboos in %s"] = "%s内的禁区"
L["A taboo with that name already exists. Overwrite?"] = "该禁区名已包含，是否覆盖？"
L["This route has the following taboo regions:"] = "该线路图经过如下禁区："
L["This route has no taboo regions."] = "该线路图无禁区。"
L["This route contains |cFFFFFFFF%d|r nodes that have been tabooed."] = "这个线路图中有 |cFFFFFFFF%d|r 个节点处于禁区内。"
L["TABOO_DESC2"] = "禁区是一个你指定从线路图中忽略的区域。禁区内的所有节点将被忽略。"
L["Taboos"] = "禁区"
L["Select taboo regions to apply:"] = "选择禁区："
L["You have |cFFFFFFFF%d|r taboo region(s) in |cFFFFFFFF%s|r."] = "你有 |cFFFFFFFF%d|r 个禁区在 |cFFFFFFFF%s|r。"

-- FAQ
L["FAQ"] = "FAQ"
L["Frequently Asked Questions"] = "常见问题"
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
