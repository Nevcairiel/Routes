-- Routes
-- zhCN Localization file

local L = LibStub("AceLocale-3.0"):NewLocale("Routes", "zhCN")
if not L then return end

L["Routes"] = "采集路线"
L["routes"] = true -- slash command

-- Options Config
L["Options"] = "选项"
L["Update distance"] = "更新距离"
L["Yards to move before triggering a minimap update"] = "移动多少码才引起小地图更新"

-- Map drawing
L["Map Drawing"] = "地图绘制"
L["Toggle drawing on each of the maps."] = "切换绘制各个地图" 
L["Worldmap"] = "世界地图"
L["Worldmap drawing"] = "世界地图绘制"
L["Minimap"] = "小地图"
L["Minimap drawing"] = "小地图绘制"
L["Zone Map"] = "区域地图"
L["Zone Map drawing"] = "区域地图绘制"
L["Set the width of lines on each of the maps."] = "设置各个地图上的线条宽度"
L["Normal lines"] = "标准线条"
L["Width of the line in the Worldmap"] = "世界地图上的线条宽度"
L["Width of the line in the Minimap"] = "小地图上的线条宽度"
L["Width of the line in the Zone Map"] = "区域地图上的线条宽度"
L["Color of lines"] = "线条的颜色"
L["Default route"] = "默认路线"
L["Change default route color"] = "改变默认路线颜色"
L["Hidden route"] = "隐藏路线"
L["Change default hidden route color"] = "改变默认隐藏路线颜色"
L["Show hidden routes"] = "显示隐藏路线"
L["Show hidden routes?"] = "显示隐藏路线?"
L["Line gaps"] = "线条间断"
L["Draw line gaps"] = "绘制线条间断"
L["Shorten the lines drawn on the minimap slightly so that they do not overlap the icons and minimap tracking blips."] = "适当的缩短小地图上的路线线条,以使他们不会重叠遮挡住采集图标和小地图上的采集跟踪点"
L["Skip clustered node points"] = "跳过聚合的航线结点"  
L["Do not draw gaps for clustered node points in routes."] = "线路上聚合的航线结点不绘制间断" 

-- Auto show/hide
L["Auto show/hide"] = "自动 显示/隐藏"
L["Auto show and hide routes based on your professions"] = "根据你的专业技能自动显示和隐藏路线"
L["Use Auto Show/Hide"] = "启用自动 显示/隐藏"
L["Auto Show/Hide per route type"] = "自动 显示/隐藏每条路线类型"
L["Auto Show/Hide settings"] = "自动 显示/隐藏设置"
L["Routes with Fish"] = "钓鱼路线"
L["Routes with Gas"] = "气体云路线"
L["Routes with Herbs"] = "草药路线"
L["Routes with Ore"] = "矿石路线"
L["Routes with Treasure"] = "宝藏路线"
L["Always show"] = "总是显示"
L["Only with profession"] = "只在具备专业技能时显示"
L["Only while tracking"] = "只在跟踪技能启动时显示"
L["Never show"] = "从不显示"

-- Waypoints
L["Waypoints (Carto)"] = "路径点(Carto)"
L["Integrated support options for Cartographer_Waypoints"] = "Cartographer_Waypoints路径点模块综合支持选项"
L["This section implements Cartographer_Waypoints support for Routes. Click Start to find the nearest node in a visible route in the current zone.\n"] = "这部分提供Routes对于Cartographer_Waypoints的支持.点击开始在当前区域搜寻最接近可见路线的结点.\n"
L["Waypoint hit distance"] = "到达路线结点的距离"
L["This is the distance in yards away from a waypoint to consider as having reached it so that the next node in the route can be added as the waypoint"] = "到达本设定距离以后,路径点模块将添加下一个结点到航线中"
L["Change direction"] = "改变方向"
L["Change the direction of the nodes in the route being added as the next waypoint"] = "改变方向,航线方向将在到达下一个结点后改变"
L["Start using Waypoints"] = "开始使用路径点"
L["Start using Cartographer_Waypoints by finding the closest visible route/node in the current zone and using that as the waypoint"] = "开始使用Cartographer_Waypoints路径点模块在当前区域搜寻最接近路线或结点,并加入到路径点航线指示"
L["Stop using Waypoints"] = "停止使用路径点"
L["Stop using Cartographer_Waypoints by clearing the last queued node"] = "停止使用Cartographer_Waypoints模块指示同时清除最后队列的结点"

-- Add Route Config
L["Add"] = "添加"
L["Routes in %s"] = "%s 中的路线"
L["Name of Route"] = "路线名称"
L["Name of the route to add"] = "请为添加的路线输入名称"
L["No name given for new route"] = "新的路线未输入名称"
L["Select Zone"] = "选择区域"
L["Zone to create route in"] = "创建路线区域"
L["Select sources of data"] = "选择数据源"
L[" Data"] = "数据"
L["Select data to use"] = "选择数据使用"
L["Select data to use in the route creation"] = "选择数据用于路线创建"
L["No data found"] = "无相关数据"
L["Create Route"] = "创建路线"
L["No data selected for new route"] = "新路线没有选择数据"
L["A route with that name already exists. Overwrite?"] = "同名路线已存在.是否进行覆盖?"

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
L["Herbalism"] = "草药"
L["Mining"] = "采矿"
L["Fishing"] = "钓鱼"
L["Treasure"] = "宝藏"
L["ExtractGas"] = "气体云"

-- Route Config
L["When the following data sources add or delete node data, update my routes automatically by inserting or removing the same node in the relevant routes."] = "当下列数据源添加或删除结点数据时，自动更新我的相关路线,插入或删除相同的结点."
L[" Gatherer currently does not support callbacks, so this is impossible for Gatherer."] = "Gatherer当前不支持数据回收,所以本操作无法作用于Gatherer."
L["You have |cFFFFFFFF%d|r route(s) in |cFFFFFFFF%s|r."] = "你已有 |cFFFFFFFF%d|r 路线于 |cFFFFFFFF%s|r."
L["Information"] = "信息"
L["This route has |cFFFFFFFF%d|r nodes and is |cFFFFFFFF%d|r yards long."] = "本路线包括 |cFFFFFFFF%d|r 结点和总长 |cFFFFFFFF%d|r 码距离."
L["This route has nodes that belong to the following categories:"] = "本路线包含结点属于以下类型:"
L["This route contains the following nodes:"] = "本路线包含下列结点:"
L["This route is not a clustered route."] = "本路线不是聚合路线"    
L["This route is a clustered route, down from the original |cFFFFFFFF%d|r nodes."] = "这个路线是聚合路线, 源自原始路线的 |cFFFFFFFF%d|r 结点."
L["|cFFFFFFFF     %d|r node(s) are between |cFFFFFFFF%d|r-|cFFFFFFFF%d|r yards of a cluster point"] = "|cFFFFFFFF     %d|r 结点距离航线点在 |cFFFFFFFF%d|r-|cFFFFFFFF%d|r 码之间"
L["|cFFFFFFFF     %d|r node(s) are at |cFFFFFFFF0|r yards of a cluster point"] = "|cFFFFFFFF     %d|r 结点距离航线点 |cFFFFFFFF0|r 码"
L["The cluster radius of this route is |cFFFFFFFF%d|r yards."] = "本条路线的聚合半径为 |cFFFFFFFF%d|r 码."

L["Line settings"] = "线条设置"
L["These settings control the visibility and look of the drawn route."] = "这些设置控制路线可视性以及绘制路线的外观"
L["Width (Map)"] = "宽度(地图)"
L["Width of the line in the map"] = "世界地图上的线条宽度"
L["Width (Minimap)"] = "宽度(小地图)"
L["Width of the line in the Minimap"] = "小地图上的线条宽度"
L["Width (Zone Map)"] = "宽度(区域地图)"
L["Width of the line in the Zone Map"] = "区域地图上的线条宽度"
L["Line Color"] = "线条颜色"
L["Change the line color"] = "改变线条颜色"
L["Hide Route"] = "隐藏路线"
L["Hide the route from being shown on the maps"] = "隐藏已经显示在地图上的路线"
L["Delete"] = "删除"
L["Permanently delete a route"] = "永久删除线路"
L["Are you sure you want to delete this route?"] = "确定删除这条路线吗?"
L["You may not delete a route that is being optimized in the background."] = "由于线路正在后台优化,你可能不能删除线路"
L["Reset"] = "重置"
L["Reset the line settings to defaults"] = "重置线条设置为默认"

L["Optimize route"] = "优化路线"
L["Route Optimizing"] = "路线优化"   
L["Extra optimization"] = "额外优化"
L["ExtraOptDesc"] = "打开这个选项将会使优化路线需时增加约40 ％,但会产生略好的路线.建议的设定是关闭"
L["Foreground"] = "前台工作"
L["Foreground Disclaimer"] = "生成接近最优的结点路线,不过请注意：这样做可能会使你的客户端卡死一段时间,视你的结点数量和CPU速度决定，如果需时过长,有可能使你掉线."
L["Background"] = "后台工作"
L["Background Disclaimer"] = "本功能会执行优化于后台进行，不会卡死你的WOW，不过这样做仍然需要你的电脑有强劲的性能。"
L["Path with %d nodes found with length %.2f yards after %d iterations in %.2f seconds."] =  "本路线共处理 %d 结点，全长 %.2f 码 经过 %d 次运算，共耗时 %.2f 秒"
L["Now running TSP in the background..."] = "现在后台运行TSP..."
L["There is already a TSP running in background. Wait for it to complete first."] = "TSP已经运行于后台,请等待完成."
L["The following error occured in the background path generation coroutine, please report to Grum or Xinhuan:"] = "以下错误发生在后台路线生成过程,请报告Grum或Xinhuan:"

L["Route Clustering"] = "路线聚合"   --聚合的翻译需推敲
L["CLUSTER_DESC"] = "聚合路线，使路线采取一切结点接近对方，然后结合成一个单一结点作为一个航线点。通常来说这个过程需要一段时间."
L["Cluster Radius"] = "聚合半径"
L["CLUSTER_RADIUS_DESC"] = "聚合附近结点的最大距离,由于跟踪探测技能有效距离为80码,所以默认值为60码."
L["Cluster"] = "聚合"
L["Cluster this route"] = "聚合这条路线"
L["Uncluster"] = "反聚合"
L["Uncluster this route"] = "反聚合本路线"   

-- Profession Names in the skills tab in the character frame
-- Doing these 4 localizations specifically to avoid using Babble-Spell
L["Skill-Fishing"] = "钓鱼"
L["Skill-Herbalism"] = "草药学"
L["Skill-Mining"] = "采矿"
L["Skill-Engineering"] = "工程学"

-- Cartographer_Waypoints support
L["Cartographer_Waypoints module is missing or disabled"] = "Cartographer_Waypoints 模块未安装或损坏"
L["%s - Node %d"] = "%s - 结点 %d"
L["Direction changed"] = "方向已改变"

-- Taboo stuff
L["Routes Node Menu"] = "路线结点菜单"
L["Delete node"] = "删除结点"
L["Add node before (red)"] = "添加顶点于本顶点前(红色)"
L["Add node after (green)"] = "添加顶点于本顶点后(绿色)"
L["You may not delete a taboo that is being edited."] = "由于本禁区正在编辑,你可能无法删除他"
L["TABOO_EDIT_DESC"] = "点击 |cFFFFFFFF编辑|r 按钮以开始编辑禁忌区域. 禁忌区域将绘制在世界地图上. 绘制顶点以确定其位置(可以使用鼠标拖动). 右键点击顶点以添加或删除顶点. 编辑完毕后,你可以点击 |cFFFFFFFF保存|r 按钮来保存你的变更, 或点击 |cFFFFFFFF取消|r 按钮来放弃变更."
L["Edit taboo region"] = "编辑禁忌区域"
L["Edit this taboo region on the world map"] = "在世界地图上编辑本禁忌区域"
L["Save taboo edit"] = "保存禁区编辑"
L["Stop editing this taboo region on the world map and save the edits"] = "停止编辑并保存编辑"
L["Cancel taboo edit"] = "取消禁区编辑"
L["Stop editing this taboo region on the world map and abandon changes made"] = "停止编辑并取消已做变更"
L["Delete Taboo"] = "删除禁区"
L["Delete this taboo region permanently. This will also remove it from all routes that use it."] = "永久删除本禁忌区域,同时也将解除本禁区对于所有路线的限制"
L["Are you sure you want to delete this taboo? This action will also remove the taboo from all routes that use it."] = "确定要删除本禁区?这个操作同时也将解除本禁区对于所有路线的限制"
L["TABOO_DESC"] = "禁忌区域是一个你可以自定义用来排除结点标记的范围。一旦你创建了禁忌区域，你可以将其作用于现有的采集路线上，所有位于这个区域的结点都将被移除同时也不会有新的结点被添加，采集路线被有目的的调整，这些区域将不会被通过。"
L["Name of Taboo"] = "禁区名称"
L["Name of taboo region to add"] = "添加的禁忌区域于"
L["No name given for new taboo region"] = "请为新的禁忌区域输入名称"
L["Zone to create taboo in"] = "创建禁区于"
L["Create Taboo"] = "创建禁区"
L["Taboos in %s"] = "禁区于 %s"
L["A taboo with that name already exists. Overwrite?"] = "同名禁区已存在.是否进行覆盖?"
L["This route has the following taboo regions:"] = "本路线包含下列禁忌区域:"
L["This route has no taboo regions."] = "本路线不包含禁忌区域"
L["This route contains |cFFFFFFFF%d|r nodes that have been tabooed."] = "本路线包含的 |cFFFFFFFF%d|r 结点已被禁区限制"
L["TABOO_DESC2"] = "禁忌区域可以对于你指定的路线范围进行忽视. 这些禁区内的结点标记被忽视同时也不被包含进路线中. 在你优化路线时,得到的最优路线会尽最大的可能避免穿越任何禁忌区域."
L["Taboos"] = "禁区"
L["Select taboo regions to apply:"] = "选择应用禁忌区域:"
L["You have |cFFFFFFFF%d|r taboo region(s) in |cFFFFFFFF%s|r."] = "共有 |cFFFFFFFF%d|r 禁忌区域于 |cFFFFFFFF%s|r."

-- FAQ
L["FAQ"] = true
L["Frequently Asked Questions"] = "常见问答"
L["FAQ_TEXT"] = [[
|cffce0a11当我试着创建一个路线时, 他说没有数据. 我那些地方做错了?|r
正确的意思: 没有找到相关数据, 主要是由于插件没有载入或在待命状态. 如果你使用 |cffffff78Cartographer_<Profession>|r 模块, 这些模块必须被载入同时启用相关数据库,也就是说你必须有相关的数据库的支持. 

需要注意的是 |cffffff78Cartographer_Professions|r 模块一般都为按需载入，同时 |cffffff78Cartographer_<Profession>|r 需设定为启用。

|cffce0a11我使用富精金矿石数据创建了一条采集路线，但当我在某同一地点发现普通的精金矿石时, GatherMate/Cartographer会删除富精金矿结点标记同时替换为普通精金矿，这样会使路线上的这个结点被删除，我该怎么做? 
|r 
1.你可以创建一条同时包括富矿和普通精金矿的采集路线. 

2.你可以设定ROUTES不自动插入/删除结点点.该选项可以在ROUTES的根配置菜单找到。

|cffce0a11可以做一个关于后台优化路线所需时间的进度指示器吗?|r
路线优化过程的进度指示器是不可能实现的，因为它是一个非线性算法。 他工作在 "多重遍数" 的基础上, 插件持续进行校对直到达到最小的改变,插件终止进程. 

这个有点类似于 |cffffff78Windows XP 磁盘碎片整理|r 程序, 他的进度条是无价值的由于他只显示每一遍的%, 可是他不知道他要做多少遍, 可能是3遍,也可能是10遍, 他直到他以为可以时才停止. 这也是为什么 |cffffff78Vista|r 版本不再显示进度条的原因.

|cffce0a11你打算添加对于 Gatherer 或其他新扩充插件结点的支持吗?|r
本插件目前已经支持 |cffffff78Gatherer|r, 同时还会添加更多的支持.

|cffce0a11ROUTES插件是如何执行路线优化的? |r
Routes插件使用的算法叫做 |cffffff78Ant Colony Optimization|r (ACO) 这是一个启发式/概率计算方法，优化图表的基础来自与现实生活中蚂蚁的行为。

ACO 算法使用一种叫 |cffffff78Traveling Salesman Problem|r (TSP)的最佳靠近算法. 更多信息请访问 Google 或 Wikipedia.

|cffce0a11关于 "额外优化" 选项是怎么回事?|r
默认状态下, 我们优化路线时使用的 ACO 算法标准只有 |cffffff782-opt|r. 开启 "额外优化" 后路线将使用 2.5-opt, 有些细节部位将使用 3-opt. 可以获得更好的路线,同时资源占用增加.

|cffce0a11关于聚合结点使用了什么样的算法?|r
我们采用了一种 Hierarchical Agglomerative Clustering 算法 ,所以他的输出是确定的.

|cffce0a11我创建了一个禁忌区域, 使他作用于采集路线, 同时对路线进行了优化. 可是我的采集路线还是穿越了禁忌区域. 这是为什么?|r
本插件并不是总能找到不穿越禁区或高难度的路线的.

用户有可能创造禁忌地区分裂地图为不可逾越的路段和地区，所以该算法只是简单的计算不通过他们，如果是有可能的.

|cffce0a11我发现了一个错误!我去那提交他们?|r
你可以报告错误或提供意见于 |cffffff78http://www.wowace.com/forums/index.php?topic=10992.0|r

二选一, 同样的你还可以在这找到我们: |cffffff78irc://irc.freenode.org/wowace|r

关于中文版本的翻译问题请访问 |cffffff78http://bbs.cwowaddon.com/thread-3568-1-1.html|r 或 EMAIL至|cffffff78Onlyfly@gmail.com|r


当你要报告一个BUG时, 请确信包含 |cffffff78如何生成的BUG|r, 如果可能请提供一些 |cffffff78错误信息|r , 提供出现问题Routes的 |cffffff78版本号|r 和你使用的是 |cffffff78英文客户端还是其他|r.
|cffce0a11是谁编写了这么酷的插件?|r
|cffffff78Xaros|r on EU Doomhammer Alliance & |cffffff78Xinhuan|r on US Blackrock Alliance .
]]


-- vim: ts=4 noexpandtab
