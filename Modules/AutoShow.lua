local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes")
local AutoShow = Routes:NewModule("AutoShow", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Routes")

-- Aceopt table, defined later
local options
-- Our db
local db

local have_prof = {
	Herbalism  = false,
	Mining     = false,
	Fishing    = false,
	ExtractGas = false, -- Engineering
	Archaeology= false,
}
local active_tracking = {}
local profession_to_skill = {}
local classic_spell_ids = {}

if GetProfessions then
	profession_to_skill[GetSpellInfo(170691)] = "Herbalism"
	profession_to_skill[GetSpellInfo(2575)] = "Mining"
	profession_to_skill[GetSpellInfo(7620) or GetSpellInfo(131476)] = "Fishing"
	profession_to_skill[GetSpellInfo(4036)] = "ExtractGas"
	if GetSpellInfo(78670) then
		profession_to_skill[GetSpellInfo(78670)] = "Archaeology"
	end
else
	classic_spell_ids = {
		Herbalism = { 2366, 2368, 3570, 11993, 28695 },
		Mining = { 2575, 2576, 3564, 10248, 29354 },
		Fishing = { 7620, 7731, 7732, 18248, 33095 },
		ExtractGas = { 30350 }, -- From Master Engineering
	}
end

local tracking_spells = {}
tracking_spells[(GetSpellInfo(2580))] = "Mining"
tracking_spells[(GetSpellInfo(2383))] = "Herbalism"
tracking_spells[(GetSpellInfo(2481))] = "Treasure"

if GetSpellInfo(43308) then
	tracking_spells[(GetSpellInfo(43308))] = "Fishing"
end

if GetSpellInfo(167898) then
	tracking_spells[(GetSpellInfo(167898))] = "Logging"
end

function AutoShow:SKILL_LINES_CHANGED()
	for k, v in pairs(have_prof) do
		have_prof[k] = false
	end
	if GetProfessions then
		for index, key in pairs({GetProfessions()}) do
			local name, icon, rank, maxrank, numspells, spelloffset, skillline = GetProfessionInfo(key)
			if profession_to_skill[name] then
				have_prof[profession_to_skill[name]] = true
			end
		end
	else
		for professionName, spellIds in pairs(classic_spell_ids) do
			for k, spellId in pairs(spellIds) do
				if IsPlayerSpell(spellId) then
					have_prof[professionName] = true
					break
				end
			end
		end
	end
	self:ApplyVisibility()
end

function AutoShow:MINIMAP_UPDATE_TRACKING()
	for i = 1, GetNumTrackingTypes() do
		local name, texture, active, category  = GetTrackingInfo(i)
		if tracking_spells[name] then
			if active then
				active_tracking[tracking_spells[name]] = true
			else
				active_tracking[tracking_spells[name]] = false
			end
		end
	end
	self:ApplyVisibility()
end

function AutoShow:UNIT_AURA()
	local miningName = GetSpellInfo(2580)
	local herbalismName = GetSpellInfo(2383)
	local treasureName = GetSpellInfo(2481)
	local trackingTex = GetTrackingTexture()
	if trackingTex then
		if trackingTex == 136025 then -- Mining
			active_tracking[tracking_spells[miningName]] = true
			active_tracking[tracking_spells[herbalismName]] = false
			active_tracking[tracking_spells[treasureName]] = false
		elseif trackingTex == 133939 then -- Herbalism
			active_tracking[tracking_spells[miningName]] = false
			active_tracking[tracking_spells[herbalismName]] = true
			active_tracking[tracking_spells[treasureName]] = false
		elseif trackingTex == 135725 then -- Treasure
			active_tracking[tracking_spells[miningName]] = false
			active_tracking[tracking_spells[herbalismName]] = false
			active_tracking[tracking_spells[treasureName]] = true
		end
	else
		active_tracking = {}
	end
	self:ApplyVisibility()
end

function AutoShow:ApplyVisibility()
	local modified = false
	for zone, zone_table in pairs(db.routes) do -- for each zone
		if next(zone_table) ~= nil then
			for route_name, route_data in pairs(zone_table) do -- for each route
				if route_data.db_type then
					local visible = false
					for db_type in pairs(route_data.db_type) do -- for each db type used
						local status = db.defaults.prof_options[db_type]
						if status == "Always" then
							visible = true
						elseif status == "With Profession" and have_prof[db_type] then
							visible = true
						elseif status == "When active" and active_tracking[db_type] then
							visible = true
						--elseif status == "Never" then
						--	visible = false
						end
						if visible == not route_data.visible then
							modified = true
						end
						route_data.visible = visible
					end
				end
			end
		end
	end
	if modified then
		-- redraw worldmap + minimap
		Routes:DrawWorldmapLines()
		Routes:DrawMinimapLines(true)
	end
end

function AutoShow:SetupAutoShow()
	if db.defaults.use_auto_showhide then
		self:RegisterEvent("SKILL_LINES_CHANGED")
		self:SKILL_LINES_CHANGED()

		if GetTrackingInfo then
			self:RegisterEvent("MINIMAP_UPDATE_TRACKING")
			self:MINIMAP_UPDATE_TRACKING()
		else
			self:RegisterEvent("UNIT_AURA")
			self:UNIT_AURA()
		end
	end
end

function AutoShow:OnInitialize()
	db = Routes.db.global
	Routes.options.args.options_group.args.auto_group = options
end

function AutoShow:OnEnable()
	self:SetupAutoShow()
end


local prof_options = {
	["Always"]          = L["Always show"],
	["With Profession"] = L["Only with profession"],
	["When active"]     = L["Only while tracking"],
	["Never"]           = L["Never show"],
}
local prof_options2 = { -- For Treasure, which isn't a profession
	["Always"]          = L["Always show"],
	["When active"]     = L["Only while tracking"],
	["Never"]           = L["Never show"],
}
local prof_options3 = { -- For Gas/Archaeology, which doesn't have tracking as a skill
	["Always"]          = L["Always show"],
	["With Profession"] = L["Only with profession"],
	["Never"]           = L["Never show"],
}
local prof_options4 = { -- For Note, which isn't a profession or tracking skill
	["Always"]          = L["Always show"],
	["Never"]           = L["Never show"],
}

options = {
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
				AutoShow:SetupAutoShow()
				Routes:DrawWorldmapLines()
				Routes:DrawMinimapLines(true)
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
				AutoShow:ApplyVisibility()
			end,
			get = function(info) return db.defaults.prof_options[info.arg] end,
			args = {
				fishing = {
					name = L["Fishing"], type = "select",
					desc = L["Routes with Fish"],
					order = 100,
					values = GetTrackingInfo and prof_options or prof_options3,
					arg = "Fishing",
				},
				gas = {
					name = L["ExtractGas"], type = "select",
					desc = L["Routes with Gas"],
					order = 200,
					hidden = not GetSpellInfo(30427),
					values = prof_options3,
					arg = "ExtractGas",
				},
				herbalism = {
					name = L["Herbalism"], type = "select",
					desc = L["Routes with Herbs"],
					order = 300,
					values = prof_options,
					arg = "Herbalism",
				},
				mining = {
					name = L["Mining"], type = "select",
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
				archaeology = {
					name = L["Archaeology"], type = "select",
					desc = L["Routes with Archaeology"],
					order = 600,
					hidden = not GetSpellInfo(78670),
					values = prof_options3,
					arg = "Archaeology",
				},
				note = {
					name = L["Note"], type = "select",
					desc = L["Routes with Notes"],
					order = 700,
					values = prof_options4,
					arg = "Note",
				},
				logging = {
					name = L["Logging"], type = "select",
					desc = L["Routes with Timber"],
					order = 800,
					hidden = not GetSpellInfo(167898),
					values = prof_options2,
					arg = "Logging",
				},
			},
		},
	},
}

-- vim: ts=4 noexpandtab
