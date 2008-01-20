-- This addon is in Alpha status and is probably not usable

Routes = LibStub("AceAddon-3.0"):NewAddon("Routes", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
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
					selection       = {
						['**'] = false  -- Node we're interested in tracking
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
				twoopt_passes      = 3,     -- Number of times to perform 2-opt passes
				two_point_five_opt = false, -- Perform optimized 2-opt pass
			},
			prof_options = {
				Herbalism = "Always",
				Mining = "Always",
				Fishing = "Always",
				Treasure = "Always",
				ExtractGas = "Always",
			},
			use_auto_showhide = false,
			waypoint_hit_distance = 50,
		},
	}
}

local prof_options = {
	["Always"] = L["Always show"],
	["With Profession"] = L["Only with profession"],
	["When active"] = L["Only while tracking"],
	["Never"] = L["Never show"],
}
local prof_options2 = { -- For Treasure, which isn't a profession
	["Always"] = L["Always show"],
	["When active"] = L["Only while tracking"],
	["Never"] = L["Never show"],
}
local prof_options3 = { -- For Gas, which doesn't have tracking as a skill
	["Always"] = L["Always show"],
	["With Profession"] = L["Only with profession"],
	["Never"] = L["Never show"],
}

-- Ace Options Table for our addon
local options
options = {
	type = "group",
	name = L["Routes"],
	get = function(k) return db.defaults[k.arg] end,
	set = function(k, v) db.defaults[k.arg] = v; Routes:DrawWorldmapLines(); Routes:DrawMinimapLines(true); end,
	args = {
		options_group = {
			type = "group",
			name = L["Options"],
			desc = L["Options"],
			order = 0,
			args = {
				update_distance = {
					name = L["Update distance"], type = "range",
					desc = L["Yards to move before triggering a minimap update"],
					min = 0, max = 10, step = 0.1,
					arg = "update_distance",
					order = 1,
				},
				-- Mapdrawing menu entry
				drawing = {
					name = L["Map Drawing"], type = "group",
					desc = L["Map Drawing"],
					order = 100,
					args = {
						linedisplay_group = {
							name = L["Toggle drawing on each of the maps."], type = "group",
							desc = L["Toggle drawing on each of the maps."],
							inline = true,
							order = 100,
							args = {
								worldmap_toggle = {
									name = L["Worldmap"],
									desc = L["Worldmap drawing"],
									type = "toggle",
									order = 100,
									arg = "draw_worldmap",
								},
								minimap_toggle = {
									name = L["Minimap"],
									desc = L["Minimap drawing"],
									type  = "toggle",
									order = 200,
									get  = function(info) return db.defaults.draw_minimap end,
									set  = function(info, v)
										db.defaults.draw_minimap = v
										--if v then
											--Cartographer_Routes:AddEventListener("MINIMAP_UPDATE_ZOOM")
											--Cartographer_Routes:AddEventListener("CVAR_UPDATE")
											--Cartographer_Routes:AddRepeatingTimer("Cartographer-Routes-MinimapRoutes", 0, DrawMinimapLines)
											--Cartographer_Routes:AddEventListener("MINIMAP_ZONE_CHANGED", DrawMinimapLines, nil, true)
											--minimap_rotate = GetCVar("rotateMinimap") == "1"
											--Cartographer_Routes:MINIMAP_UPDATE_ZOOM()
										--else
											--Cartographer_Routes:RemoveEventListener("MINIMAP_UPDATE_ZOOM")
											--Cartographer_Routes:RemoveEventListener("CVAR_UPDATE")
											--Cartographer_Routes:RemoveTimer("Cartographer-Routes-MinimapRoutes")
											--Cartographer_Routes:RemoveEventListener("MINIMAP_ZONE_CHANGED")
											--clearMinimap()
										--end
									end,
								},
								battlemap_toggle = {
									name = L["Zone Map"],
									desc = L["Zone Map drawing"],
									type  = "toggle",
									order = 300,
									arg = "draw_battlemap",
								},
							},
						},
						default_group = {
							name = L["Set the width of lines on each of the maps."], type = "group",
							desc = L["Normal lines"],
							inline = true,
							order = 200,
							args = {
								width = {
									name = L["Worldmap"], type = "range",
									desc = L["Width of the line in the Worldmap"],
									min = 10, max = 100, step = 1,
									arg = "width",
									order = 100,
								},
								width_minimap = {
									name = L["Minimap"], type = "range",
									desc = L["Width of the line in the Minimap"],
									min = 10, max = 100, step = 1,
									arg = "width_minimap",
									order = 110,
								},
								width_battlemap = {
									name = L["Zone Map"], type = "range",
									desc = L["Width of the line in the Zone Map"],
									min = 10, max = 100, step = 1,
									arg = "width_battlemap",
									order = 120,
								},
							},
						},
						color_group = {
							name = L["Color of lines"], type = "group",
							desc = L["Color of lines"],
							inline = true,
							order = 300,
							get = function(info) return unpack(db.defaults[info.arg]) end,
							set = function(info, r, g, b, a)
								local c = db.defaults[info.arg]
								c[1] = r; c[2] = g; c[3] = b; c[4] = a
								Routes:DrawWorldmapLines()
								Routes:DrawMinimapLines(true)
							end,
							args = {
								color = {
									name = L["Default route"], type = "color",
									desc = L["Change default route color"],
									arg  = "color",
									hasAlpha = true,
									order = 200,
								},
								hidden_color = {
									name = L["Hidden route"], type = "color",
									desc = L["Change default hidden route color"],
									arg  = "hidden_color",
									hasAlpha = true,
									order = 400,
								},
							},
						},
						show_hidden = {
							name = L["Show hidden routes"], type = "toggle",
							desc = L["Show hidden routes?"],
							arg  = "show_hidden",
							order = 400,
						},
					},
				},
				auto_group = {
					name = L["Auto show/hide"], type = "group",
					desc = L["Auto show and hide routes based on your professions"],
					--groupType = "inline",
					order = 200,
					args = {
						use_auto_showhide = {
							name = L["Use Auto Show/Hide"],
							desc = L["Use Auto Show/Hide"],
							type = "toggle",
							arg = "use_auto_showhide",
							order = 210,
							set = function(info, v)
								db.defaults.use_auto_showhide = v
								local t = options.args.options_group.args.auto_group.args.auto_group.args
								if v then
									--Cartographer_Routes:AddEventListener("SKILL_LINES_CHANGED")
									--Cartographer_Routes:AddEventListener("MINIMAP_UPDATE_TRACKING")
									--Cartographer_Routes:MINIMAP_UPDATE_TRACKING()
									--Cartographer_Routes:SKILL_LINES_CHANGED()
									t.fishing.disabled = nil
									t.herbalism.disabled = nil
									t.mining.disabled = nil
									t.treasure.disabled = nil
									t.gas.disabled = nil
								else
									--Cartographer_Routes:RemoveEventListener("SKILL_LINES_CHANGED")
									--Cartographer_Routes:RemoveEventListener("MINIMAP_UPDATE_TRACKING")
									t.fishing.disabled = true
									t.herbalism.disabled = true
									t.mining.disabled = true
									t.treasure.disabled = true
									t.gas.disabled = true
								end
							end,
						},
						auto_group = {
							name = L["Auto Show/Hide per route type"], type = "group",
							desc = L["Auto Show/Hide settings"],
							inline = true,
							order = 300,
							disabled = function(info) return not db.defaults.use_auto_showhide end,
							set = function(info, v)
								db.defaults.prof_options[info.arg] = v
								--Routes:ApplyVisibility()
							end,
							get = function(info) return db.defaults.prof_options[info.arg] end,
							args = {
								fishing = {
									name = L["Fish"], type = "select",
									desc = L["Routes with Fish"],
									order = 100,
									values = prof_options,
									arg = "Fishing",
								},
								gas = {
									name = L["Gas"], type = "select",
									desc = L["Routes with Gas"],
									order = 200,
									values = prof_options3,
									arg = "ExtractGas",
								},
								herbalism = {
									name = L["Herbs"], type = "select",
									desc = L["Routes with Herbs"],
									order = 300,
									values = prof_options,
									arg = "Herbalism",
								},
								mining = {
									name = L["Ore"], type = "select",
									desc = L["Routes with Ore"],
									order = 400,
									values = prof_options,
									arg = "Mining",
								},
								treasure = {
									name = L["Treasure"], type = "select",
									desc = L["Routes with Treasure"],
									order = 500,
									values = prof_options2,
									arg = "Treasure",
								},
							},
						},
					},
				},
				waypoints = {
					name = L["Waypoints"], type = "group",
					desc = L["Integrated support options for Cartographer_Waypoints"],
					disabled = function() return not (Cartographer and Cartographer:HasModule("Waypoints") and Cartographer:IsModuleActive("Waypoints")) end,
					order = 300,
					args = {
						hit_distance = {
							name = L["Waypoint hit distance"], type = "range",
							desc = L["This is the distance in yards away from a waypoint to consider as having reached it so that the next node in the route can be added as the waypoint"],
							min  = 5,
							max  = 80, -- This is the maximum range of node detection for "Find X" profession skills
							step = 1,
							order = 700,
							arg = "waypoint_hit_distance",
						},
						direction = {
							name  = L["Change direction"], type = "execute",
							desc  = L["Change the direction of the nodes in the route being added as the next waypoint"],
							func  = function()
								--Cartographer_Routes:ChangeWaypointDirection()
							end,
							order = 720,
						},
						start = {
							name  = L["Start using Waypoints"], type = "execute",
							desc  = L["Start using Cartographer_Waypoints by finding the closest visible route/node in the current zone and using that as the waypoint"],
							func  = function()
								--Cartographer_Routes:QueueFirstNode()
							end,
							order = 710,
						},
						stop = {
							name  = L["Stop using Waypoints"], type = "execute",
							desc  = L["Stop using Cartographer_Waypoints by clearing the last queued node"],
							func  = function()
								--Cartographer_Routes:RemoveQueuedNode()
							end,
							order = 730,
						},
					},
				},
			},
		},
		add_group = {
			type = "group",
			name = L["Add"],
			desc = L["Add"],
			order = 100,
			--args = {}, -- defined later
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
local format = string.format
local math_abs = math.abs
local math_sin = math.sin
local math_cos = math.cos
local WorldMapButton = WorldMapButton
local Minimap = Minimap

-- other locals we use
local zoneNames = {} -- cache of localized zone names by continent and zoneID from WoW API
local zoneNamesReverse = {}


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

local MinimapShapes = {
	-- quadrant booleans (same order as SetTexCoord)
	-- {upper-left, lower-left, upper-right, lower-right}
	-- true = rounded, false = squared
	["ROUND"]                 = { true,  true,  true,  true},
	["SQUARE"]                = {false, false, false, false},
	["CORNER-TOPLEFT"]        = { true, false, false, false},
	["CORNER-TOPRIGHT"]       = {false, false,  true, false},
	["CORNER-BOTTOMLEFT"]     = {false,  true, false, false},
	["CORNER-BOTTOMRIGHT"]    = {false, false, false,  true},
	["SIDE-LEFT"]             = { true,  true, false, false},
	["SIDE-RIGHT"]            = {false, false,  true,  true},
	["SIDE-TOP"]              = { true, false,  true, false},
	["SIDE-BOTTOM"]           = {false,  true, false,  true},
	["TRICORNER-TOPLEFT"]     = { true,  true,  true, false},
	["TRICORNER-TOPRIGHT"]    = { true, false,  true,  true},
	["TRICORNER-BOTTOMLEFT"]  = { true,  true, false,  true},
	["TRICORNER-BOTTOMRIGHT"] = {false,  true,  true,  true},
}

local minimap_radius
local minimap_rotate
local indoors = 'outdoor'

local MinimapSize = { -- radius of minimap
	indoor = {
		[0] = 150,
		[1] = 120,
		[2] = 90,
		[3] = 60,
		[4] = 40,
		[5] = 25,
	},
	outdoor = {
		[0] = 233 + 1/3,
		[1] = 200,
		[2] = 166 + 2/3,
		[3] = 133 + 1/3,
		[4] = 100,
		[5] = 66 + 2/3,
	},
}

local function is_round( dx, dy )
	local map_shape = GetMinimapShape and GetMinimapShape() or "ROUND"

	local q = 1
	if dx > 0 then q = q + 2 end -- right side
	-- XXX Tripple check this
	if dy > 0 then q = q + 1 end -- bottom side

	return MinimapShapes[map_shape][q]
end

local function is_inside( sx, sy, cx, cy, radius )
	local dx = sx - cx
	local dy = sy - cy

	if is_round( dx, dy ) then
		return dx*dx+dy*dy <= radius*radius
	else
		return math_abs( dx ) <= radius and math_abs( dy ) <= radius
	end
end

local last_X, last_Y, last_facing = 1/0, 1/0, 1/0

-- implementation of cache - use zone in the key for an unique identifier
-- because every zone has a different X/Y location and possible yardsizes
local X_cache = {}
local Y_cache = {}
local XY_cache_mt = {
	__index = function(t, key)
		local zone, coord = (';'):split( key )
		zone = BZ[zone]
		local X = Routes.zoneData[zone][1] * floor(coord / 10000) / 10000
		local Y = Routes.zoneData[zone][2] * (coord % 10000) / 10000
		X_cache[key] = X
		Y_cache[key] = Y

		-- figure out which one to return
		if t == X_cache then return X else return Y end
	end
}

setmetatable( X_cache, XY_cache_mt )
setmetatable( Y_cache, XY_cache_mt )

function Routes:DrawMinimapLines(forceUpdate)
	if not db.defaults.draw_minimap then
		G:HideLines(Minimap)
		return
	end

	local _x, _y = GetPlayerMapPosition("player")

	-- invalid coordinates - clear map
	if not _x or not _y or _x < 0 or _x > 1 or _y < 0 or _y > 1 then
		G:HideLines(Minimap)
		return
	end

	local zone = GetRealZoneText()

	-- instance/indoor .. no routes
	if not zone or not self.zoneData[zone] or indoors == "indoor" then
		G:HideLines(Minimap)
		return
	end

	local defaults = db.defaults
	local zoneW, zoneH = self.zoneData[zone][1], self.zoneData[zone][2]
	if not zoneW then return end
	local cx, cy = zoneW * _x, zoneH * _y

	local facing, sin, cos
	if minimap_rotate then
		facing = -MiniMapCompassRing:GetFacing()
	end

	if (not forceUpdate) and facing == last_facing and (last_X-cx)^2 + (last_Y-cy)^2 < defaults.update_distance^2 then
		-- no update!
		return
	end

	last_X = cx
	last_Y = cy
	last_facing = facing

	if minimap_rotate then
		sin = math_sin(facing)
		cos = math_cos(facing)
	end

	minimap_radius = MinimapSize[indoors][Minimap:GetZoom()]
	local radius = minimap_radius
	local radius2 = radius * radius

	local minX = cx - radius
	local maxX = cx + radius
	local minY = cy - radius
	local maxY = cy + radius

	local div_by_zero_nudge = 0.000001

	G:HideLines(Minimap)

	if BZR[zone] then
		zone = BZR[zone]
	end

	local minimap_w = Minimap:GetWidth()
	local minimap_h = Minimap:GetHeight()
	local scale_x = minimap_w / (radius*2)
	local scale_y = minimap_h / (radius*2)

	for route_name, route_data in pairs( db.routes[zone] ) do
		if type(route_data) == "table" and type(route_data.route) == "table" and #route_data.route > 1 then
			-- store color/width
			local width = route_data.width_minimap or defaults.width_minimap
			local color = route_data.color or defaults.color

			-- unless we show hidden
			if (not route_data.hidden and (route_data.visible or not defaults.use_auto_showhide)) or defaults.show_hidden then
				-- use this special color
				if route_data.hidden then
					color = defaults.hidden_color
				end

				-- some state data
				local last_x = nil
				local last_y = nil
				local last_inside = nil

				-- if we loop - make sure the 'last' gets filled with the right info
				if route_data.looped and route_data.route[ #route_data.route ] ~= defaults.fake_point then
					local key = format("%s;%s", zone, route_data.route[ #route_data.route ])
					last_x, last_y = X_cache[key], Y_cache[key]
					if minimap_rotate then
						local dx = last_x - cx
						local dy = last_y - cy
						last_x = cx + dx*cos - dy*sin
						last_y = cy + dx*sin + dy*cos
					end
					last_inside = is_inside( last_x, last_y, cx, cy, radius )
				end

				-- loop over the route
				for i = 1, #route_data.route do
					local point = route_data.route[i]
					local cur_x, cur_y, cur_inside

					-- if we have a 'fake point' (gap) - clear current values
					if point == defaults.fake_point then
						cur_x = nil
						cur_y = nil
						cur_inside = false
					else
						local key = format("%s;%s", zone, point)
						cur_x, cur_y = X_cache[key], Y_cache[key]
						if minimap_rotate then
							local dx = cur_x - cx
							local dy = cur_y - cy
							cur_x = cx + dx*cos - dy*sin
							cur_y = cy + dx*sin + dy*cos
						end
						cur_inside = is_inside( cur_x, cur_y, cx, cy, radius )
					end

					-- check if we have any nil values (we cant draw) and check boundingbox
					if cur_x and cur_y and last_x and last_y and not (
						( cur_x < minX and last_x < minX ) or
						( cur_x > maxX and last_x > maxX ) or
						( cur_y < minY and last_y < minY ) or
						( cur_y > maxY and last_y > maxY )
					)
					then
						-- default all to not drawing
						local draw_sx = nil
						local draw_sy = nil
						local draw_ex = nil
						local draw_ey = nil

						-- both inside - easy! draw
						if cur_inside and last_inside then
							draw_sx = last_x
							draw_sy = last_y
							draw_ex = cur_x
							draw_ey = cur_y
						else
							-- direction of line
							local dx = last_x - cur_x
							local dy = last_y - cur_y

							-- calculate point on perpendicular line
							local zx = cx - dy
							local zy = cy + dx

							-- nudge it a bit so we dont get div by 0 problems
							if dx == 0 then dx = div_by_zero_nudge end
							if dy == 0 then dy = div_by_zero_nudge end

							-- calculate intersection point
							local nd = ((cx   -last_x)*(cy-zy) - (cx-zx)*(cy   -last_y)) /
									   ((cur_x-last_x)*(cy-zy) - (cx-zx)*(cur_y-last_y))

							-- perpendicular point (closest to center on the line given)
							local px = last_x + nd * -dx
							local py = last_y + nd * -dy

							-- check range of intersect point
							local dpc_x = cx - px
							local dpc_y = cy - py

							-- distance^2 of the perpendicular point
							local lenpc = dpc_x*dpc_x + dpc_y*dpc_y

							-- the line can only intersect if the perpendicular point is at
							-- least closer than the furthest away point (one of the corners)
							if lenpc < 2*radius2 then

								-- if inside - ready to draw
								if cur_inside then
									draw_ex = cur_x
									draw_ey = cur_y
								else
									-- if we're not inside we can still be in the square - if so dont do any intersection
									-- calculations yet
									if math_abs( cur_x - cx ) < radius and math_abs( cur_y - cy ) < radius then
										draw_ex = cur_x
										draw_ey = cur_y
									else
										-- need to intersect against the square
										-- likely x/y to intersect with
										local minimap_cur_x  = cx + radius * (dx < 0 and 1 or -1)
										local minimap_cur_y  = cy + radius * (dy < 0 and 1 or -1)

										-- which intersection is furthest?
										local delta_cur_x = (minimap_cur_x - cur_x) / -dx
										local delta_cur_y = (minimap_cur_y - cur_y) / -dy

										-- dark magic - needs to be changed to positive signs whenever i can care about it
										if delta_cur_x < delta_cur_y and delta_cur_x < 0 then
											draw_ex = minimap_cur_x
											draw_ey = cur_y + -dy*delta_cur_x
										else
											draw_ex = cur_x + -dx*delta_cur_y
											draw_ey = minimap_cur_y
										end

										-- check if we didn't calculate some wonky offset - has to be inside with
										-- some slack on accuracy
										if math_abs( draw_ex - cx ) > radius*1.01 or
										   math_abs( draw_ey - cy ) > radius*1.01
										then
											draw_ex = nil
											draw_ey = nil
										end
									end

									-- we might have a round corner here - lets see if the quarter with the intersection is round
									if draw_ex and draw_ey and is_round( draw_ex - cx, draw_ey - cy ) then
										-- if we are also within the circle-range
										if lenpc < radius2 then
											-- circle intersection
											local dcx = cx - cur_x
											local dcy = cy - cur_y
											local len_dc = dcx*dcx + dcy*dcy

											local len_d = dx*dx + dy*dy
											local len_ddc = dx*dcx + dy*dcy

											-- discriminant
											local d_sqrt = ( len_ddc*len_ddc - len_d * (len_dc - radius2) )^0.5

											-- calculate point
											draw_ex = cur_x - dx * (-len_ddc + d_sqrt) / len_d
											draw_ey = cur_y - dy * (-len_ddc + d_sqrt) / len_d

											-- have to be on the *same* side of the perpendicular point else it's fake
											if (draw_ex - px)/math_abs(draw_ex - px) ~= (cur_x- px)/math_abs(cur_x - px) or
											   (draw_ey - py)/math_abs(draw_ey - py) ~= (cur_y- py)/math_abs(cur_y - py)
											then
												draw_ex = nil
												draw_ey = nil
											end
										else
											draw_ex = nil
											draw_ey = nil
										end
									end
								end

								-- if inside - ready to draw
								if last_inside then
									draw_sx = last_x
									draw_sy = last_y
								else
									-- if we're not inside we can still be in the square - if so dont do any intersection
									-- calculations yet
									if math_abs( last_x - cx ) < radius and math_abs( last_y - cy ) < radius then
										draw_sx = last_x
										draw_sy = last_y
									else
										-- need to intersect against the square
										-- likely x/y to intersect with
										local minimap_last_x = cx + radius * (dx > 0 and 1 or -1)
										local minimap_last_y = cy + radius * (dy > 0 and 1 or -1)

										-- which intersection is furthest?
										local delta_last_x = (minimap_last_x - last_x) / dx
										local delta_last_y = (minimap_last_y - last_y) / dy

										-- dark magic - needs to be changed to positive signs whenever i can care about it
										if delta_last_x < delta_last_y and delta_last_x < 0 then
											draw_sx = minimap_last_x
											draw_sy = last_y + dy*delta_last_x
										else
											draw_sx = last_x + dx*delta_last_y
											draw_sy = minimap_last_y
										end

										-- check if we didn't calculate some wonky offset - has to be inside with
										-- some slack on accuracy
										if math_abs( draw_sx - cx ) > radius*1.01 or
										   math_abs( draw_sy - cy ) > radius*1.01
										then
											draw_sx = nil
											draw_sy = nil
										end
									end

									-- we might have a round corner here - lets see if the quarter with the intersection is round
									if draw_sx and draw_sy and is_round( draw_sx - cx, draw_sy - cy ) then
										-- if we are also within the circle-range
										if lenpc < radius2 then
											-- circle intersection
											local dcx = cx - cur_x
											local dcy = cy - cur_y
											local len_dc = dcx*dcx + dcy*dcy

											local len_d = dx*dx + dy*dy
											local len_ddc = dx*dcx + dy*dcy

											-- discriminant
											local d_sqrt = ( len_ddc*len_ddc - len_d * (len_dc - radius2) )^0.5

											-- calculate point
											draw_sx = cur_x - dx * (-len_ddc - d_sqrt) / len_d
											draw_sy = cur_y - dy * (-len_ddc - d_sqrt) / len_d

											-- have to be on the *same* side of the perpendicular point else it's fake
											if (draw_sx - px)/math_abs(draw_sx - px) ~= (last_x- px)/math_abs(last_x - px) or
											   (draw_sy - py)/math_abs(draw_sy - py) ~= (last_y- py)/math_abs(last_y - py)
											then
												draw_sx = nil
												draw_sy = nil
											end
										else
											draw_sx = nil
											draw_sy = nil
										end
									end
								end
							end
						end

						if draw_sx and draw_sy and draw_ex and draw_ey then
							-- translate to left bottom corner and apply scale
							draw_sx =			 (draw_sx - minX) * scale_x
							draw_sy = minimap_h - (draw_sy - minY) * scale_y
							draw_ex =			 (draw_ex - minX) * scale_x
							draw_ey = minimap_h - (draw_ey - minY) * scale_y

							-- draw the line
							G:DrawLine( Minimap, draw_sx, draw_sy, draw_ex, draw_ey, width, color , "ARTWORK")
						end
					end

					-- store last point
					last_x = cur_x
					last_y = cur_y
					last_inside = cur_inside
				end
			end
		end
	end
end


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
			local zonekey = tostring(zoneNamesReverse[localizedZoneName])
			opts[zonekey] = { -- use a 3 digit string which is alphabetically sorted zone names by continent
				type = "group",
				name = localizedZoneName,
				desc = L["Routes in %s"]:format(localizedZoneName),
				args = {},
			}
			for route in pairs(zone_table) do
				local routekey = route:gsub("%s", "") -- can't have spaces in the key
				opts[zonekey].args[routekey] = self:CreateAceOptRouteTable(zone, route)
			end
		end
	end
end

local function SetZoomHook()
	Routes:DrawMinimapLines(true)
end

function Routes:MINIMAP_UPDATE_ZOOM()
	self:Unhook(Minimap, "SetZoom")
	local zoom = Minimap:GetZoom()
	if GetCVar("minimapZoom") == GetCVar("minimapInsideZoom") then
		Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1)
	end
	indoors = GetCVar("minimapZoom")+0 == Minimap:GetZoom() and "outdoor" or "indoor"
	Minimap:SetZoom(zoom)
	self:DrawMinimapLines(true)
	self:SecureHook(Minimap, "SetZoom", SetZoomHook)
end

function Routes:CVAR_UPDATE(event, cvar, value)
	if cvar == "ROTATE_MINIMAP" then
		minimap_rotate = value == "1"
	end
end

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame.elapsed = 0
timerFrame:SetScript("OnUpdate", function(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed > 0.025 then -- throttle to a max of 40 redraws per sec
		self.elapsed = 0         -- kinda unnecessary since at default 1 yard refresh, its limited to 36 redraws/sec
		Routes:DrawMinimapLines()
	end
end)

function Routes:OnEnable()
	-- World Map line drawing
	self:RegisterEvent("WORLD_MAP_UPDATE", "DrawWorldmapLines")
	-- Minimap line drawing
	self:SecureHook(Minimap, "SetZoom", SetZoomHook)
	if db.defaults.draw_minimap then
		self:RegisterEvent("MINIMAP_UPDATE_ZOOM")
		self:RegisterEvent("CVAR_UPDATE")
		timerFrame:Show()
		self:RegisterEvent("MINIMAP_ZONE_CHANGED", "DrawMinimapLines", true)
		minimap_rotate = GetCVar("rotateMinimap") == "1"
		self:MINIMAP_UPDATE_ZOOM()  -- This has a DrawMinimapLines(true) call in it, and sets an "indoors" variable
	end
end

function Routes:OnDisable()
	-- Ace3 unregisters all events and hooks for us on disable
	timerFrame:Hide()
end


------------------------------------------------------------------------------------------------------
-- Ace options table stuff

-- Set of functions we use to edit route configs
local ConfigHandler = {}

function ConfigHandler:GetColor(info)
	return unpack(db.routes[info.arg.zone][info.arg.route].color or db.defaults.color)
end
function ConfigHandler:SetColor(info, r, g, b, a)
	local t = db.routes[info.arg.zone][info.arg.route]
	t.color = t.color or {}
	t = t.color
	t[1] = r; t[2] = g; t[3] = b; t[4] = a;
	Routes:DrawWorldmapLines()
	Routes:DrawMinimapLines(true)
end

function ConfigHandler:GetHidden(info)
	return db.routes[info.arg.zone][info.arg.route].hidden
end
function ConfigHandler:SetHidden(info, v)
	db.routes[info.arg.zone][info.arg.route].hidden = v
	Routes:DrawWorldmapLines()
	Routes:DrawMinimapLines(true)
end

function ConfigHandler:GetWidth(info)
	return db.routes[info.arg.zone][info.arg.route].width or db.defaults.width
end
function ConfigHandler:SetWidth(info, v)
	db.routes[info.arg.zone][info.arg.route].width = v
	Routes:DrawWorldmapLines()
end

function ConfigHandler:GetWidthMinimap(info)
	return db.routes[info.arg.zone][info.arg.route].width_minimap or db.defaults.width_minimap
end
function ConfigHandler:SetWidthMinimap(info, v)
	db.routes[info.arg.zone][info.arg.route].width_minimap = v
	Routes:DrawMinimapLines(true)
end

function ConfigHandler:GetWidthBattleMap(info)
	return db.routes[info.arg.zone][info.arg.route].width_battlemap or db.defaults.width_battlemap
end
function ConfigHandler:SetWidthBattleMap(info, v)
	db.routes[info.arg.zone][info.arg.route].width_battlemap = v
	Routes:DrawWorldmapLines()
end

function ConfigHandler:DeleteRoute(info)
	local zone, route = info.arg.zone, info.arg.route
	local is_running, route_table = Routes.TSP:IsTSPRunning()
	if is_running and route_table == db.routes[zone][route].route then
		self:Print(L["You may not delete a route that is being optimized in the background."])
		return
	end
	db.routes[zone][route] = nil
	local zonekey = tostring(zoneNamesReverse[BZ[zone] or zone]) -- use a 3 digit string which is alphabetically sorted zone names by continent
	local routekey = route:gsub("%s", "") -- can't have spaces in the key
	options.args.routes_group.args[zonekey].args[routekey] = nil -- delete route from aceopt
	if next(db.routes[zone]) == nil then
		options.args.routes_group.args[zonekey] = nil -- delete zone from aceopt if no routes remaining
	end
	Routes:DrawWorldmapLines()
	Routes:DrawMinimapLines(true)
end

function ConfigHandler:ResetLineSettings(info)
	local t = db.routes[info.arg.zone][info.arg.route]
	t.color = nil
	t.width = nil
	t.width_minimap = nil
	t.width_battlemap = nil
	Routes:DrawWorldmapLines()
	Routes:DrawMinimapLines(true)
end

function ConfigHandler.GetRouteDesc(info)
	local t = db.routes[info.arg.zone][info.arg.route]
	return L["This route has %d nodes and is %d yards long."]:format(#t.route, t.length)
end

function ConfigHandler:GetTwoPointFiveOpt()
	return db.defaults.tsp.two_point_five_opt
end
function ConfigHandler:SetTwoPointFiveOpt(info, v)
	db.defaults.tsp.two_point_five_opt = v
end

function ConfigHandler:DoForeground(info)
	local t = db.routes[info.arg.zone][info.arg.route]
	local output, length, iter, timetaken = Routes.TSP:SolveTSP(t.route, info.arg.zone, db.defaults.tsp)
	t.route = output
	t.length = length
	Routes:Print(L["Path with %d nodes found with length %.2f yards after %d iterations in %.2f seconds."]:format(#output, length, iter, timetaken))

	-- redraw lines
	Routes:DrawWorldmapLines()
	Routes:DrawMinimapLines(true)
end

function ConfigHandler:DoBackground(info)
	local t = db.routes[info.arg.zone][info.arg.route]
	local running, errormsg = Routes.TSP:SolveTSPBackground(t.route, info.arg.zone, db.defaults.tsp)
	if (running == 1) then
		Routes:Print(L["Now running TSP in the background..."])
		Routes.TSP:SetFinishFunction(function(output, length, iter, timetaken)
			t.route = output
			t.length = length
			Routes:Print(L["Path with %d nodes found with length %.2f yards after %d iterations in %.2f seconds."]:format(#output, length, iter, timetaken))
			-- redraw lines
			Routes:DrawWorldmapLines()
			Routes:DrawMinimapLines(true)
		end)
	elseif (running == 2) then
		Routes:Print(L["There is already a TSP running in background. Wait for it to complete first."])
	elseif (running == 3) then
		-- This should never happen, but is here as a fallback
		Routes:Print(L["The following error occured in the background path generation coroutine, please report to Grum or Xinhuan:"]);
		Routes:Print(errormsg);
	end
end

-- These tables are referenced inside CreateAceOptRouteTable() defined right below this
local blank_line_table = {
	name = "", type = "description",
	order = 325,
}
local two_point_five_group_table = {
	type = "group",
	order = 100,
	name = L["Extra optimization"],
	inline = true,
	args = {
		two_point_five_opt_disc = {
			name = L["ExtraOptDesc"], type = "description",
			order = 0,
		},
		two_point_five_opt = {
			name = L["Extra optimization"], type = "toggle",
			desc = L["ExtraOptDesc"],
			get = "GetTwoPointFiveOpt", set = "SetTwoPointFiveOpt",
			order = 100,
		},
	},
}
local foreground_table = {
	type  = "description",
	name  = L["Foreground Disclaimer"],
	order = 0,
}
local background_table = {
	type  = "description",
	name  = L["Background Disclaimer"],
	order = 0,
}

function Routes:CreateAceOptRouteTable(zone, route)
	local zone_route_table = {zone = zone, route = route}

	-- Yes, return this huge table for given zone/route
	return {
		type = "group",
		name = route,
		desc = route,
		childGroups = "tab",
		handler = ConfigHandler,
		args = {
			setting_group = {
				type = "group",
				name = L["Line settings"],
				desc = L["Line settings"],
				order = 100,
				args = {
					desc = {
						type = "description",
						name = L["These settings control the visibility and look of the drawn route."],
						order = 0,
					},
					color = {
						name = L["Line Color"], type = "color",
						desc = L["Change the line color"],
						get = "GetColor", set = "SetColor",
						arg = zone_route_table,
						order = 100,
						hasAlpha = true,
					},
					hidden = {
						name = L["Hide Route"], type = "toggle",
						desc = L["Hide the route from being shown on the maps"],
						get = "GetHidden", set = "SetHidden",
						arg = zone_route_table,
						order = 200,
					},
					width = {
						name = L["Width (Map)"], type = "range",
						desc = L["Width of the line in the map"],
						min = 10, max = 100, step = 1,
						get = "GetWidth", set = "SetWidth",
						arg = zone_route_table,
						order = 300,
					},
					width_minimap = {
						name = L["Width (Minimap)"], type = "range",
						desc = L["Width of the line in the Minimap"],
						min = 10, max = 100, step = 1,
						get = "GetWidthMinimap", set = "SetWidthMinimap",
						arg = zone_route_table,
						order = 310,
					},
					width_battlemap = {
						name = L["Width (Zone Map)"], type = "range",
						desc = L["Width of the line in the Zone Map"],
						min = 10, max = 100, step  = 1,
						get = "GetWidthBattleMap", set = "SetWidthBattleMap",
						arg = zone_route_table,
						order = 320,
					},
					blankline = blank_line_table,
					delete = {
						name = L["Delete"], type = "execute",
						desc = L["Permanently delete a route"],
						func = "DeleteRoute",
						arg = zone_route_table,
						confirm = true,
						confirmText = L["Are you sure you want to delete this route?"],
						order = 400,
					},
					reset_all = {
						name = L["Reset"], type = "execute",
						desc = L["Reset the line settings to defaults"],
						func = "ResetLineSettings",
						arg = zone_route_table,
						order = 500,
					},
				},
			},
			optimize_group = {
				type = "group",
				order = 200,
				name = L["Optimize route"],
				args = {
					desc = {
						type = "description",
						name = ConfigHandler.GetRouteDesc,
						arg = zone_route_table,
						order = 0,
					},
					two_point_five_group = two_point_five_group_table,
					foreground_group = {
						type = "group",
						order = 200,
						name = L["Foreground"],
						inline = true,
						args = {
							foreground_disc = foreground_table,
							foreground = {
								name = L["Foreground"], type = "execute",
								desc = L["Foreground Disclaimer"],
								func = "DoForeground",
								arg = zone_route_table,
								order = 100,
							},
						},
					},
					background_group = {
						type = "group",
						order = 300,
						name = L["Background"],
						inline = true,
						args = {
							background_disc = background_table,
							background = {
								name = L["Background"], type = "execute",
								desc = L["Background Disclaimer"],
								func = "DoBackground",
								arg = zone_route_table,
								order = 100,
							},
						},
					},
				},
			},
		},
	}
end

-- AceOpt config table for route creation
do
	-- Some upvalues used in the aceopts[] table for creating new routes
	local outland_zones = {
		"Blade's Edge Mountains",
		"Hellfire Peninsula",
		"Nagrand",
		"Netherstorm",
		"Shadowmoon Valley",
		"Shattrath City",
		"Terokkar Forest",
		"Zangarmarsh",
	}
	local create_name = ""
	local create_zones = {}
	local create_zone
	local last_zone
	local create_choices = {}
	local create_data = {}
	local empty_table = {}
	local translate_type = {}
	local function deep_copy_table(a, b)
		for k, v in pairs(b) do
			if type(v) == "table" then
				--a[k] = {} -- no need this, AceDB defaults should handle it
				deep_copy_table(a[k], v)
			else
				a[k] = v
			end
		end
	end
	function Routes:UpdateTranslationTables()
		-- See if these libraries exist
		translate_type.CartHerbalism = LibStub:GetLibrary("Babble-Herbs-2.2", 1)
		translate_type.CartMining = LibStub:GetLibrary("Babble-Ore-2.2", 1)
		translate_type.CartFishing = LibStub:GetLibrary("Babble-Fish-2.2", 1)
		local AL = LibStub:GetLibrary("AceLocale-2.2", 1)
		if AL then
			translate_type.CartTreasure = AL:new("Cartographer_Treasure") -- Get the AceLocale registered translation table for Treasure
		end
		translate_type.CartExtractGas = LibStub("Babble-Gas-2.2", 1)
	end
	options.args.add_group.args = {
		route_name = {
			type = "input",
			name = L["Name of Route"],
			desc = L["Name of the route to add"],
			validate = function(info, name)
				if name == "" or strtrim(name) == "" then
					return L["No name given for new route"]
				end
				return true
			end,
			get = function() return create_name end,
			set = function(info, v) create_name = strtrim(v) end,
			order = 100,
		},
		zone_choice = {
			name = L["Select Zone"], type = "select",
			desc = L["Zone to create route in"],
			order = 200,
			values = function()
				-- reuse table
				for k in pairs(create_zones) do create_zones[k] = nil end
				-- setup zones to show
				for i = 1, #outland_zones do
					create_zones[ outland_zones[i] ] = BZ[ outland_zones[i] ]
				end
				-- add current player zone
				local zone = GetRealZoneText()
				zone = BZR[zone] or zone
				if zone then
					create_zones[zone] = BZ[zone]
					if not create_zone then create_zone = zone end
				end
				-- add current viewed map zone
				local zone = zoneNames[GetCurrentMapContinent()*100 + GetCurrentMapZone()]
				if BZR[zone] then zone = BZR[zone] end
				if zone then
					create_zones[zone] = BZ[zone]
					if not create_zone then create_zone = zone end
				end
				return create_zones
			end,
			get = function() return create_zone end,
			set = function(info, key) create_zone = key end,
			style = "radio",
		},
		data_choices = {
			name = L["Select data to use"], type = "multiselect",
			desc = L["Select data to use in the route creation"],
			order = 300,
			values = function()
				if not create_zone then return empty_table end
				if last_zone == create_zone then return create_data end
				-- reuse table
				for k in pairs(create_data) do create_data[k] = nil end
				-- update translation tables
				Routes:UpdateTranslationTables()
				-- check for cartographer
				local CN = (Cartographer and Cartographer:HasModule("Notes")) and Cartographer:GetModule("Notes")
				if CN then
					for db_type,db_data in pairs(CN.externalDBs) do
						-- get the babble localization for this db type
						local LN = translate_type["Cart"..db_type]
						-- if this is a valid node db as specified in translate_type[]
						if LN then
							local amount_of = {}
							-- only look for data for this currentzone
							if db_data[create_zone] then
								-- count the unique values (structure is: location => item)
								if db_type == "Treasure" then
									for _,node in pairs(db_data[create_zone]) do
										amount_of[node.title] = (amount_of[node.title] or 0) + 1
									end
								else
									for _,node in pairs(db_data[create_zone]) do
										amount_of[node] = (amount_of[node] or 0) + 1
									end
								end
								-- XXX Localize these strings
								-- store combinations with all information we have
								for node,count in pairs(amount_of) do
									local translatednode = LN:HasTranslation(node) and LN[node] or node
									create_data[ ("%s;%s;%s;%s"):format("Cart", db_type, node, count) ] = ("%s - %s - %d"):format(L["Cart"..db_type],translatednode,count)
								end
							end
						end
					end
				end
				-- check for gathermate data
				if GatherMate then
					local LN = LibStub("AceLocale-3.0"):GetLocale("GatherMateNodes", true)
					for db_type, db_data in pairs(GatherMate.gmdbs) do
						local amount_of = {}
						-- only look for data for this currentzone
						if db_data[GatherMate.zoneData[BZ[create_zone]][3]] then
							-- count the unique values (structure is: location => itemID)
							for _,node in pairs(db_data[GatherMate.zoneData[BZ[create_zone]][3]]) do
								amount_of[node] = (amount_of[node] or 0) + 1
							end
							-- XXX Localize these strings
							-- store combinations with all information we have
							for node,count in pairs(amount_of) do
								local translatednode = GatherMate.reverseNodeIDs[node]
								create_data[ ("%s;%s;%s;%s"):format("GM", db_type, node, count) ] = ("%s - %s - %d"):format(L["GM"..db_type],translatednode,count)
							end
						end
					end
				end
				-- found no data - insert dummy message
				if not next(create_data) then
					create_data[ db.defaults.fake_data ..";;;" ] = L["No data found"]
				end
				last_zone = create_zone
				return create_data
			end,
			get = function(info, key)
				--Routes:Print(("Getting choice for: %s"):format(key or "nil"));
				if not create_zone then return end
				if key == db.defaults.fake_data then return end
				if not create_choices[create_zone] then create_choices[create_zone] = {} end
				return create_choices[create_zone][key]
			end,
			set = function(info, key, value)
				if not create_zone then return end
				if key == db.defaults.fake_data then return end
				if not create_choices[create_zone] then create_choices[create_zone] = {} end
				create_choices[create_zone][key] = value
				--:Print(("Setting choice: %s to %s"):format(key or "nil", value and "true" or "false"));
			end,
		},
		add_route = {
			name = L["Create Route"], type = "execute",
			desc = L["Create Route"],
			order = 400,
			func = function()
				create_name = strtrim(create_name)
				if not create_name or create_name == "" then
					Routes:Print(L["No name given for new route"])
					return
				end
				--the real 'action', we use a temporary table in case of data corruption and only commit this to the db if successful
				local new_route = { route = {}, selection = {} }
				-- check for cartographer
				local CN = (Cartographer and Cartographer:HasModule("Notes")) and Cartographer:GetModule("Notes")
				local GatherMate = GatherMate
				-- if for every selected nodetype on this map
				if type(create_choices[create_zone]) == "table" then
					for data_string,wanted in pairs(create_choices[create_zone]) do
						-- if we want em
						if (wanted) then
							local db_src, db_type, node_type, amount = (';'):split( data_string );
							--Routes:Print(("found %s %s %s %s"):format( db_src,db_type,node_type,amount ))

							-- ignore any fake data
							if db_type ~= db.defaults.fake_data then
								-- check if the db_type exists (could be disabled via _Professions)
								if db_src == "Cart" and CN and CN.externalDBs[db_type] then
									-- store the node_type we're interested in so we can auto-add them
									new_route.selection[node_type] = true

									-- Find all of the notes
									for loc, t in pairs(CN.externalDBs[db_type][create_zone]) do
										-- convert coordID from Cart format to GM format
										local x, y = (loc % 10001)/10000, floor(loc / 10001)/10000
										loc = floor(x * 10000 + 0.5) * 10000 + floor(y * 10000 + 0.5)
										-- And are of a selected type - store
										if db_type == "Treasure" and t.title == node_type then
											tinsert( new_route.route, loc )
										elseif t == node_type then
											tinsert( new_route.route, loc )
										end
									end
								elseif db_src == "GM" and GatherMate and GatherMate.gmdbs[db_type] then
									node_type = tonumber(node_type)
									-- store the node_type we're interested in so we can auto-add them
									local LN = LibStub("AceLocale-3.0"):GetLocale("GatherMateNodes", true)
									local translatednode = GatherMate.reverseNodeIDs[node_type]
									for k, v in pairs(LN) do
										if v == translatednode then
											translatednode = k -- get the english name
											break
										end
									end
									new_route.selection[translatednode] = true
								
									-- Find all of the notes
									--for loc, t in GatherMate:GetNodesForZone(BZ[create_zone], db_type) do
									for loc, t in pairs(GatherMate.gmdbs[db_type][GatherMate.zoneData[BZ[create_zone]][3]]) do
										-- And are of a selected type - store
										if t == node_type then
											tinsert( new_route.route, loc )
										end
									end
								end
							end
						end
					end
				end

				if #new_route.route == 0 then
					Routes:Print(L["No data selected for new route"])
					return
				end
Routes:Print(#new_route.route)
				-- Perform a deep copy instead so that db defaults apply
				db.routes[create_zone][create_name] = nil -- overwrite old route
				deep_copy_table(db.routes[create_zone][create_name], new_route)

				-- TODO Check if we can do a one-pass TSP run here as well if the user selected it.
				db.routes[create_zone][create_name].length = Routes.TSP:PathLength(new_route.route, create_zone)

				-- Create the aceopts table entry for our new route
				local opts = options.args.routes_group.args
				local localizedZoneName = BZ[create_zone] or create_zone
				local zonekey = tostring(zoneNamesReverse[localizedZoneName])
				if not opts[zonekey] then
					opts[zonekey] = { -- use a 3 digit string which is alphabetically sorted zone names by continent
						type = "group",
						name = localizedZoneName,
						desc = L["Routes in %s"]:format(localizedZoneName),
						args = {},
					}
				end
				local routekey = create_name:gsub("%s", "") -- can't have spaces in the key
				opts[zonekey].args[routekey] = Routes:CreateAceOptRouteTable(create_zone, create_name)

				-- Draw it
				Routes:DrawWorldmapLines()
				Routes:DrawMinimapLines(true)

				-- clear stored name
				create_name = ""
				create_zone = nil
			end,
			disabled = function()
				return not create_name or strtrim(create_name) == ""
			end,
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
