-- This addon is in Alpha status and is probably not usable

Routes = LibStub("AceAddon-3.0"):NewAddon("Routes", "AceConsole-3.0", "AceEvent-3.0")
local Routes = Routes
local L = LibStub("AceLocale-3.0"):GetLocale("Routes", false)
local BZ = LibStub("LibBabble-Zone-3.0"):GetUnstrictLookupTable()
local BZR = LibStub("LibBabble-Zone-3.0"):GetReverseLookupTable()
local G = {} -- was Graph-1.0, but we removed the dependency



-- database defaults
local db
local defaults = {
	global = {
		routes = {
			['*'] = { -- zone name
				['*'] = { -- route name
					route           = {},    -- point, point, point
					color           = nil,   -- defaults to db.defaults.color if nil
					width           = nil,   -- defaults to db.defaults.width if nil
					width_minimap   = nil,   -- defaults to db.defaults.width_minimap if nil
					width_battlemap = nil,   -- defaults to db.defaults.width_battlemap if nil
					hidden          = false, -- boolean
					looped          = 1,     -- looped? 1 is used (instead of true) because initial early code used 1 inside route creation code
					visible         = true,  -- visible?
					length          = 0,     -- length
					source          = {
						['**'] = {         -- Database
							['**'] = false -- Node
						},
					},
				},
			},
		},
		defaults = {            --    r,    g,    b,   a
			color           = {   1, 0.75, 0.75,   1 },
			hidden_color    = {   1,    1,    1, 0.5 },
			width           = 35,
			width_minimap   = 30,
			width_battlemap = 15,
			show_hidden     = false,
			update_distance = 1,
			fake_point      = -1,
			fake_data       = 'dummy',
			draw_minimap    = 1,
			draw_worldmap   = 1,
			draw_battlemap  = 1,
			tsp = {
				initial_pheromone  = 0,     -- Initial pheromone trail value
				alpha              = 1,     -- Likelihood of ants to follow pheromone trails (larger value == more likely)
				beta               = 6,     -- Likelihood of ants to choose closer nodes (larger value == more likely)
				local_decay        = 0.2,   -- Governs local trail decay rate [0, 1]
				local_update       = 0.4,   -- Amount of pheromone to reinforce local trail update by
				global_decay       = 0.2,   -- Governs global trail decay rate [0, 1]
				twoopt_passes      = 3,		-- Number of times to perform 2-opt passes
				two_point_five_opt = false, -- Perform optimized 2-opt pass
			},
		},
	}
}

-- Ace Options Table for our addon
local options = {
	type = "group",
	name = L["Routes"],
	get = function(k) return db.defaults[k.arg]	end,
	set = function(k, v) db.defaults[k.arg] = v; Routes:DrawWorldmapLines(); Routes:DrawMinimapLines(); end,
	args = {
		add_group = {
			type = "group",
			name = L["Add"],
			desc = L["Add"],
			order = 100,
			args = {},
		},
		routes_group = {
			type = "group",
			name = L["Routes"],
			desc = L["Routes"],
			order = 200,
			args = {},
		}
	}
}


-- localize some globals
local pairs, ipairs, next = pairs, ipairs, next
local tinsert, tremove = tinsert, tremove
local floor = floor
local WorldMapButton = WorldMapButton

-- other locals we use
local zoneNames = {} -- cache of localized zone names by continent and zoneID from WoW API
local zoneNamesReverse = {}


------------------------------------------------------------------------------------------------------
-- General event functions

function Routes:OnInitialize()
	-- Initialize database
	self.db = LibStub("AceDB-3.0"):New("RoutesDB", defaults)
	db = self.db.global

	-- Initialize the ace options table
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("Routes", options)
	self:RegisterChatCommand(L["routes"], function() LibStub("AceConfigDialog-3.0"):Open("Routes") end)

	-- Initialize zone names into a table
	for index, zname in ipairs({GetMapZones(1)}) do
		zoneNames[100 + index] = zname
	end
	for index, zname in ipairs({GetMapZones(2)}) do
		zoneNames[200 + index] = zname
	end
	for index, zname in ipairs({GetMapZones(3)}) do
		zoneNames[300 + index] = zname
	end
	for k, v in pairs(zoneNames) do
		zoneNamesReverse[v] = k
	end

	-- Generate ace options table for each route
	local opts = options.args.routes_group.args
	for zone, zone_table in pairs(db.routes) do
		-- do not show unless we have routes.
		-- This because lua cant do '#' on hash-tables
		if next(zone_table) ~= nil then
			local localizedZoneName = BZ[zone] or zone
			local key = tostring(zoneNamesReverse[localizedZoneName])
			opts[key] = { -- use a 3 digit string which is alphabetically sorted zone names by continent
				type = "group",
				name = localizedZoneName,
				desc = L['Routes in %s']:format(localizedZoneName),
				args = {},
			}
			for route in pairs(zone_table) do
				local routekey = route:gsub("%s", "") -- can't have spaces in the key
				opts[key].args[routekey] = self:CreateAceOptRouteTable(zone, route)
			end
		end
	end
end

function Routes:OnEnable()
	self:RegisterEvent("WORLD_MAP_UPDATE", "DrawWorldmapLines")
end

function Routes:OnDisable()
	-- Ace3 unregisters all events and hooks for us on disable
end

------------------------------------------------------------------------------------------------------
-- Core Routes functions

--[[ Our coordinate format for Routes
Warning: These are convenience functions, most of the :getXY() and :getID()
code are inlined in critical code paths in various functions, changing
the coord storage format requires changing the inlined code in numerous
locations in addition to these 2 functions
]]
function Routes:getID(x, y)
	return floor(x * 10000 + 0.5) * 10000 + floor(y * 10000 + 0.5)
end
function Routes:getXY(id)
	return floor(id / 10000) / 10000, (id % 10000) / 10000
end

function Routes:DrawWorldmapLines()
	-- setup locals
	local zone = zoneNames[GetCurrentMapContinent()*100 + GetCurrentMapZone()]
	if BZR[zone] then zone = BZR[zone] end
	local BattlefieldMinimap = BattlefieldMinimap  -- local reference if it exists
	local fh, fw = WorldMapButton:GetHeight(), WorldMapButton:GetWidth()
	local bfh, bfw  -- BattlefieldMinimap height and width
	local defaults = db.defaults

	-- clear all the lines
	G:HideLines(WorldMapButton)
	if (BattlefieldMinimap) then
		-- The Blizzard addon "Blizzard_BattlefieldMinimap" is loaded
		G:HideLines(BattlefieldMinimap)
		bfh, bfw = BattlefieldMinimap:GetHeight(), BattlefieldMinimap:GetWidth()
	end

	-- check for conditions not to draw the world map lines
	if not zone then return end -- player is not viewing a zone map of a continent
	local flag1 = defaults.draw_worldmap and WorldMapFrame:IsShown() -- Draw worldmap lines?
	local flag2 = defaults.draw_battlemap and BattlefieldMinimap and BattlefieldMinimap:IsShown() -- Draw battlemap lines?
	if (not flag1) and (not flag2) then	return end 	-- Nothing to draw

	for route_name, route_data in pairs( db.routes[zone] ) do
		if type(route_data) == "table" and type(route_data.route) == "table" and #route_data.route > 1 then
			local width = route_data.width or defaults.width
			local halfwidth = route_data.width_battlemap or defaults.width_battlemap
			local color = route_data.color or defaults.color

			if (not route_data.hidden and (route_data.visible or not defaults.use_auto_showhide)) or defaults.show_hidden then
				if route_data.hidden then color = defaults.hidden_color end
				local last_point
				local sx, sy
				if route_data.looped then
					last_point = route_data.route[ #route_data.route ]
					sx, sy = floor(last_point / 10000) / 10000, (last_point % 10000) / 10000
					sy = (1 - sy)
				end
				for i = 1, #route_data.route do
					local point = route_data.route[i]
					if point == defaults.fake_point then
						point = nil
					end
					if last_point and point then
						local ex, ey = floor(point / 10000) / 10000, (point % 10000) / 10000
						ey = (1 - ey)
						if (flag1) then
							G:DrawLine(WorldMapButton, sx*fw, sy*fh, ex*fw, ey*fh, width, color , "OVERLAY")
						end
						if (flag2) then
							G:DrawLine(BattlefieldMinimap, sx*bfw, sy*bfh, ex*bfw, ey*bfh, halfwidth, color , "OVERLAY")
						end
						sx, sy = ex, ey
					end
					last_point = point
				end
			end
		end
	end
end

function Routes:DrawMinimapLines()
end

------------------------------------------------------------------------------------------------------
-- Ace options table stuff

local ConfigHandler = {}

-- These tables are referenced inside CreateAceOptRouteTable() defined right below this
local two_point_five_opt_table = {
	name = L["Extra optimization"],
	desc = L["ExtraOptDesc"],
	type  = "toggle",
	order = 1301,
	get   = function() return db.defaults.tsp.two_point_five_opt end,
	set   = function(k, v) db.defaults.tsp.two_point_five_opt = v end,
}
--[[local blank_line_table = {
	type  = "description",
	name  = "",
	order = 225,
}]]

function Routes:CreateAceOptRouteTable(zone, route)
	local t = db.routes[zone][route]

	-- Yes, return this huge table for given zone/route
	return {
		type = "group",
		name = route,
		desc = route,
		args = {
			setting_group = {
				type = "group",
				name = L["Line settings"],
				desc = L["Line settings"],
				inline = true,
				order = 100,
				args = {
					desc = {
						type  = "description",
						name  = L["These settings control the visibility and look of the drawn route."],
						order = 0,
					},
					color = {
						name  = L["Line Color"], type = "color",
						desc  = L["Change the line color"],
						get   = function()
							local c = db.routes[zone][route].color or db.defaults.color
							return unpack( c )
						end,
						set   = function(k,r,g,b,a) db.routes[zone][route].color = {r,g,b,a}; self:DrawWorldmapLines(); self:DrawMinimapLines(true) end,
						order = 100,
						hasAlpha = true,
					},
					hidden = {
						name  = L["Hide Route"], type = "toggle",
						desc  = L["Hide the route from being shown on the maps"],
						get   = function() return db.routes[zone][route].hidden end,
						set   = function(k, v) db.routes[zone][route].hidden = v; self:DrawWorldmapLines(); self:DrawMinimapLines(true) end,
						order = 200,
					},
					width = {
						name  = L["Width (Map)"], type = "range",
						desc  = L["Width of the line in the map"],
						min   = 10,
						max   = 100,
						step  = 1,
						get   = function() return db.routes[zone][route].width or db.defaults.width end,
						set   = function(k, v) db.routes[zone][route].width = v; self:DrawWorldmapLines() end,
						order = 300,
					},
					width_minimap = {
						name  = L["Width (Minimap)"], type = "range",
						desc  = L["Width of the line in the Minimap"],
						min   = 10,
						max   = 100,
						step  = 1,
						get   = function() return db.routes[zone][route].width_minimap or db.defaults.width_minimap end,
						set   = function(k, v) db.routes[zone][route].width_minimap = v; self:DrawMinimapLines(true) end,
						order = 310,
					},
					width_battlemap = {
						name  = L["Width (Zone Map)"], type = "range",
						desc  = L["Width of the line in the Zone Map"],
						min   = 10,
						max   = 100,
						step  = 1,
						get   = function() return db.routes[zone][route].width_battlemap or db.defaults.width_battlemap end,
						set   = function(k, v) db.routes[zone][route].width_battlemap = v; self:DrawWorldmapLines() end,
						order = 320,
					},
					--blankline = blank_line_table,
					--[[delete = {
						name  = L["Delete"], type = "execute",
						desc  = L["Permanently delete a route"],
						func  = function()
							local is_running, route_table = self.TSP:IsTSPRunning()
							if is_running and route_table == db.routes[zone][route].route then
								self:Print(L["You may not delete a route that is being optimized in the background."])
								return
							end
							db.routes[zone][route] = nil
							aceopts[zone].args[route] = nil
							if db.edit_routes[zone] == route then
								db.edit_routes[zone] = nil
							end
							if next(db.routes[zone]) == nil then
								aceopts[zone] = nil
							end
							DrawWorldmapLines()
							DrawMinimapLines(true)
						end,
						confirmText = L["Are you sure?"],
						buttonText = L["Delete"],
						order = 400,
					},]]
					reset_all = {
						name  = L["Reset"], type = "execute",
						desc  = L["Reset the line settings to defaults"],
						func  = function()
							db.routes[zone][route].color = nil
							db.routes[zone][route].width = nil
							db.routes[zone][route].width_minimap = nil
							db.routes[zone][route].width_battlemap = nil
							self:DrawWorldmapLines()
							self:DrawMinimapLines(true)
						end,
						order = 500,
					},
				},
			},
			optimize_group = {
				type = "group",
				inline = true,
				order = 200,
				name = function()
					return L["Optimize route [%d nodes, %d yards]"]:format(#db.routes[zone][route].route, db.routes[zone][route].length)
				end,
				args = {
					two_point_five_opt = two_point_five_opt_table,
					--[[foreground = {
						name  = L['Foreground'], type = 'execute',
						desc  = L['Foreground Disclaimer'],
						func  = function()
							local output, length, iter, timetaken = self.TSP:SolveTSP(db.routes[zone][route].route, zone, db.defaults.tsp)
							db.routes[zone][route].route = output
							db.routes[zone][route].length = length
							self:Print(L["Path with %d nodes found with length %.2f yards after %d iterations in %.2f seconds."]:format(#output, length, iter, timetaken))

							-- redraw lines
							DrawWorldmapLines()
							DrawMinimapLines(true)
						end,
						confirmText = L["Are you sure?"],
						buttonText = L["Optimize"],
						order = 1310,
					},
					background = {
						name  = L['Background'], type = 'execute',
						desc  = L['Background Disclaimer'],
						func  = function()
							local running, errormsg = self.TSP:SolveTSPBackground(db.routes[zone][route].route, zone, db.defaults.tsp)
							if (running == 1) then
								self:Print(L["Now running TSP in the background..."])
								self.TSP:SetFinishFunction(function(output, length, iter, timetaken)
									db.routes[zone][route].route = output
									db.routes[zone][route].length = length
									self:Print(L["Path with %d nodes found with length %.2f yards after %d iterations in %.2f seconds."]:format(#output, length, iter, timetaken))
									-- redraw lines
									DrawWorldmapLines()
									DrawMinimapLines(true)
								end)
							elseif (running == 2) then
								self:Print(L["There is already a TSP running in background. Wait for it to complete first."])
							elseif (running == 3) then
								-- This should never happen, but is here as a fallback
								self:Print(L["The following error occured in the background path generation coroutine, please report to Grum or Xinhuan:"]);
								self:Print(errormsg);
							end
						end,
						buttonText = L['Optimize'],
						order = 1320,
					},]]
				},
			},
		},
	}
end

------------------------------------------------------------------------------------------------------
-- The following function is used with permission from Daniel Stephens <iriel@vigilance-committee.org>
-- with reference to TaxiFrame.lua in Blizzard's UI and Graph-1.0 Ace2 library (by Cryect) which I now
-- maintain after porting it to LibGraph-2.0 LibStub library -- Xinhuan
local TAXIROUTE_LINEFACTOR = 128/126; -- Multiplying factor for texture coordinates
local TAXIROUTE_LINEFACTOR_2 = TAXIROUTE_LINEFACTOR / 2; -- Half of that

-- T        - Texture
-- C        - Canvas Frame (for anchoring)
-- sx,sy    - Coordinate of start of line
-- ex,ey    - Coordinate of end of line
-- w        - Width of line
-- relPoint - Relative point on canvas to interpret coords (Default BOTTOMLEFT)
function G:DrawLine(C, sx, sy, ex, ey, w, color, layer)
	local relPoint = "BOTTOMLEFT"
	
	if not C.Routes_Lines then
		C.Routes_Lines={}
		C.Routes_Lines_Used={}
	end

	local T = tremove(C.Routes_Lines) or C:CreateTexture(nil, "ARTWORK")
	T:SetTexture("Interface\\AddOns\\Routes\\line")
	tinsert(C.Routes_Lines_Used,T)

	T:SetDrawLayer(layer or "ARTWORK")

	T:SetVertexColor(color[1],color[2],color[3],color[4]);
	-- Determine dimensions and center point of line
	local dx,dy = ex - sx, ey - sy;
	local cx,cy = (sx + ex) / 2, (sy + ey) / 2;

	-- Normalize direction if necessary
	if (dx < 0) then
		dx,dy = -dx,-dy;
	end

	-- Calculate actual length of line
	local l = sqrt((dx * dx) + (dy * dy));

	-- Sin and Cosine of rotation, and combination (for later)
	local s,c = -dy / l, dx / l;
	local sc = s * c;

	-- Calculate bounding box size and texture coordinates
	local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy;
	if (dy >= 0) then
		Bwid = ((l * c) - (w * s)) * TAXIROUTE_LINEFACTOR_2;
		Bhgt = ((w * c) - (l * s)) * TAXIROUTE_LINEFACTOR_2;
		BLx, BLy, BRy = (w / l) * sc, s * s, (l / w) * sc;
		BRx, TLx, TLy, TRx = 1 - BLy, BLy, 1 - BRy, 1 - BLx; 
		TRy = BRx;
	else
		Bwid = ((l * c) + (w * s)) * TAXIROUTE_LINEFACTOR_2;
		Bhgt = ((w * c) + (l * s)) * TAXIROUTE_LINEFACTOR_2;
		BLx, BLy, BRx = s * s, -(l / w) * sc, 1 + (w / l) * sc;
		BRy, TLx, TLy, TRy = BLx, 1 - BRx, 1 - BLx, 1 - BLy;
		TRx = TLy;
	end

	-- Set texture coordinates and anchors
	T:ClearAllPoints();
	T:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy);
	T:SetPoint("BOTTOMLEFT", C, relPoint, cx - Bwid, cy - Bhgt);
	T:SetPoint("TOPRIGHT",   C, relPoint, cx + Bwid, cy + Bhgt);
	T:Show()
	return T
end

function G:HideLines(C)
	if C.Routes_Lines then
		for i = #C.Routes_Lines_Used, 1, -1 do
			C.Routes_Lines_Used[i]:Hide()
			tinsert(C.Routes_Lines,tremove(C.Routes_Lines_Used))
		end
	end
end

-- vim: ts=4 noexpandtab
