local Routes = LibStub("AceAddon-3.0"):GetAddon("Routes", 1)
if not Routes then return end

local SourceName = "Gatherer"
local L = LibStub("AceLocale-3.0"):GetLocale("Routes")
local BZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()

------------------------------------------
-- setup
Routes.plugins[SourceName] = {}
local source = Routes.plugins[SourceName]

local GathererNodeReverse = {
-- Ore
	[   324] = "Small Thorium Vein",
	[  1610] = "Incendicite Mineral Vein",
	[  1731] = "Copper Vein",
	[  1732] = "Tin Vein",
	[  1733] = "Silver Vein",
	[  1734] = "Gold Vein",
	[  1735] = "Iron Deposit",
	[  2040] = "Mithril Deposit",
	[  2047] = "Truesilver Deposit",
	[  2653] = "Lesser Bloodstone Deposit",
	[ 19903] = "Indurium Mineral Vein",
	[ 73940] = "Ooze Covered Silver Vein",
	[ 73941] = "Ooze Covered Gold Vein",
	[123309] = "Ooze Covered Truesilver Deposit",
	[123310] = "Ooze Covered Mithril Deposit",
	[123848] = "Ooze Covered Thorium Vein",
	[165658] = "Dark Iron Deposit",
	[175404] = "Rich Thorium Vein",
	[177388] = "Ooze Covered Rich Thorium Vein",
	[180215] = "Hakkari Thorium Vein",
	[181555] = "Fel Iron Deposit",
	[181556] = "Adamantite Deposit",
	[181557] = "Khorium Vein",
	[181569] = "Rich Adamantite Deposit",
	[185877] = "Nethercite Deposit",

-- Herb
	[  1617] = "Silverleaf",
	[  1618] = "Peacebloom",
	[  1619] = "Earthroot",
	[  1620] = "Mageroyal",
	[  1621] = "Briarthorn",
	[  1622] = "Bruiseweed",
	[  1623] = "Wild Steelbloom",
	[  1624] = "Kingsblood",
	[  1628] = "Grave Moss",
	[  2041] = "Liferoot",
	[  2042] = "Fadeleaf",
	[  2043] = "Khadgar's Whisker",
	[  2044] = "Wintersbite",
	[  2045] = "Stranglekelp",
	[  2046] = "Goldthorn",
	[  2866] = "Firebloom",
	[142140] = "Purple Lotus",
	[142141] = "Arthas' Tears",
	[142142] = "Sungrass",
	[142143] = "Blindweed",
	[142144] = "Ghost Mushroom",
	[142145] = "Gromsblood",
	[176583] = "Golden Sansam",
	[176584] = "Dreamfoil",
	[176586] = "Mountain Silversage",
	[176587] = "Plaguebloom",
	[176588] = "Icecap",
	[176589] = "Black Lotus",
	[181166] = "Bloodthistle",
	[181270] = "Felweed",
	[181271] = "Dreaming Glory",
	[181275] = "Ragveil",
	[181276] = "Flame Cap",
	[181277] = "Terocone",
	[181278] = "Ancient Lichen",
	[181279] = "Netherbloom",
	[181279] = "Netherbloom",
	[181280] = "Nightmare Vine",
	[181281] = "Mana Thistle",
	[185881] = "Netherdust Bush",

--[[
-- Should not be used - mostly TYPE == OPEN
	[2039  ] = "Hidden Strongbox",
	[2744  ] = "Giant Clam",
	[2843  ] = "Battered Chest",
	[2844  ] = "Tattered Chest",
	[2850  ] = "Solid Chest",
	[3658  ] = "Water Barrel",
	[3659  ] = "Barrel of Melon Juice",
	[3660  ] = "Armor Crate",
	[3661  ] = "Weapon Crate",
	[3662  ] = "Food Crate",
	[3705  ] = "Barrel of Milk",
	[3706  ] = "Barrel of Sweet Nectar",
	[3714  ] = "Alliance Strongbox",
	[19019 ] = "Box of Assorted Parts",
	[28604 ] = "Scattered Crate",
	[74447 ] = "Large Iron Bound Chest",
	[74448 ] = "Large Solid Chest",
	[75293 ] = "Large Battered Chest",
	[123330] = "Buccaneer's Strongbox",
	[131978] = "Large Mithril Bound Chest",
	[131979] = "Large Darkwood Chest",
	[142191] = "Horde Supply Crate",
	[157936] = "Un'Goro Dirt Pile",
	[164658] = "Blue Power Crystal",
	[164659] = "Green Power Crystal",
	[164660] = "Red Power Crystal",
	[164661] = "Yellow Power Crystal",
	[164958] = "Bloodpetal Sprout",
	[176213] = "Blood of Heroes",
	[176582] = "Shellfish Trap",
	[178244] = "Practice Lockbox",
	[179486] = "Battered Footlocker",
	[179487] = "Waterlogged Footlocker",
	[179492] = "Dented Footlocker",
	[179493] = "Mossy Footlocker",
	[179498] = "Scarlet Footlocker",
	[181665] = "Burial Chest",
	[181798] = "Fel Iron Chest",
	[181800] = "Heavy Fel Iron Chest",
	[181802] = "Adamantite Bound Chest",
	[181804] = "Felsteel Chest",
	[182053] = "Glowcap",
	[184740] = "Wicker Chest",
	[184793] = "Primitive Chest",
	[184930] = "Solid Fel Iron Chest",
	[184931] = "Bound Fel Iron Chest",
	[184936] = "Bound Adamantite Chest",
	[185915] = "Netherwing Egg",
	[164881] = "Cleansed Night Dragon",
	[164882] = "Cleansed Songflower",
	[164884] = "Cleansed Windblossom",
	[174622] = "Cleansed Whipper Root",
--]]
}

do
	local loaded = true
	local function IsActive() -- Can we gather data?
		return Gatherer and loaded
	end
	source.IsActive = IsActive

	-- stop loading if the addon is not enabled, or
	-- stop loading if there is a reason why it can't be loaded ("MISSING" or "DISABLED")
	local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(SourceName)
	if not enabled or (reason ~= nil) then
		loaded = false
		return
	end
end

------------------------------------------
-- functions

local amount_of = {}
local function Summarize(data, zone)
	return data
end
source.Summarize = Summarize

-- returns the english name, translated name for the node so we can store it was being requested
-- also returns the type of db for use with auto show/hide route
local function AppendNodes(node_list, zone, db_type, node_type)
end
source.AppendNodes = AppendNodes

local function InsertNode(event, zone, nodeType, coord, node_name)
	Routes:InsertNode(zone, coord, node_name)
end

local function DeleteNode(event, zone, nodeType, coord, node_name)
	Routes:DeleteNode(zone, coord, node_name)
end

local function AddCallbacks()
end
source.AddCallbacks = AddCallbacks

local function RemoveCallbacks()
end
source.RemoveCallbacks = RemoveCallbacks

-- vim: ts=4 noexpandtab
