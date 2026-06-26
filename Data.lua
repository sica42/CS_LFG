CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

---@class DungeonInfo
---@field name string
---@field reqLevel number
---@field minLevel number
---@field maxLevel number
---@field background string?
---@field heroic boolean?
---@field code string?

---@type table<string, DungeonInfo>
m.dungeons = {
	[ "rfc" ] = {
		name = m.T[ "Ragefire Chasm" ],
		reqLevel = 8,
		minLevel = 13,
		maxLevel = 22,
		background = "ragefirechasm",
	},
	[ "dm" ] = {
		name = m.T[ "The Deadmines" ],
		reqLevel = 10,
		minLevel = 16,
		maxLevel = 24,
		background = "deadmines"
	},
	[ "wc" ] = {
		name = m.T[ "Wailing Caverns" ],
		reqLevel = 10,
		minLevel = 15,
		maxLevel = 28,
		background = "wailingcaverns"
	},
	[ "bfd" ] = {
		name = m.T[ "Blackfathom Deeps" ],
		reqLevel = 18,
		minLevel = 20,
		maxLevel = 28,
		background = "blackfathomdeeps"
	},
	[ "rfk" ] = {
		name = m.T[ "Razorfen Kraul" ],
		reqLevel = 17,
		minLevel = 23,
		maxLevel = 31,
		background = "razorfenkraul"
	},
	[ "smgraveyard" ] = {
		name = m.T[ "Scarlet Monastery Graveyard" ],
		reqLevel = 20,
		minLevel = 26,
		maxLevel = 36,
		background = "scarletmonastery",
	},
	[ "smlib" ] = {
		name = m.T[ "Scarlet Monastery Library" ],
		reqLevel = 20,
		minLevel = 29,
		maxLevel = 39,
		background = "scarletmonastery",
	},
	[ "smarmory" ] = {
		name = m.T[ "Scarlet Monastery Armory" ],
		reqLevel = 20,
		minLevel = 32,
		maxLevel = 42,
		background = "scarletmonastery",
	},
	[ "smcath" ] = {
		name = m.T[ "Scarlet Monastery Cathedral" ],
		reqLevel = 20,
		minLevel = 35,
		maxLevel = 45,
		background = "scarletmonastery",
	},
	[ "rfd" ] = {
		name = m.T[ "Razorfen Downs" ],
		reqLevel = 25,
		minLevel = 33,
		maxLevel = 41,
		background = "razorfendowns"
	},
	[ "mara" ] = {
		name = m.T[ "Maraudon" ],
		reqLevel = 30,
		minLevel = 40,
		maxLevel = 52,
		background = "maraudon"
	},
	[ "zf" ] = {
		name = m.T[ "Zul'Farrak" ],
		reqLevel = 35,
		minLevel = 42,
		maxLevel = 50,
		background = "zulfarak"
	},
	[ "dme" ] = {
		name = m.T[ "Dire Maul (East)" ],
		reqLevel = 45,
		minLevel = 54,
		maxLevel = 61,
		background = "diremaul"
	},
	[ "dmn" ] = {
		name = m.T[ "Dire Maul (North)" ],
		reqLevel = 45,
		minLevel = 54,
		maxLevel = 61,
		background = "diremaul"
	},
	[ "dmw" ] = {
		name = m.T[ "Dire Maul (West)" ],
		reqLevel = 45,
		minLevel = 54,
		maxLevel = 61,
		background = "diremaul"
	},
	[ "brd" ] = {
		name = m.T[ "Blackrock Depths" ],
		reqLevel = 42,
		minLevel = 48,
		maxLevel = 60,
		background = "blackrockdepths"
	},
	[ "lbrs"] = {
		name = m.T[ "Lower Blackrock Spire" ],
		reqLevel = 45,
		minLevel = 52,
		maxLevel = 60,
		background = "blackrockspire"
	},
	[ "ubrs"] = {
		name = m.T[ "Upper Blackrock Spire" ],
		reqLevel = 45,
		minLevel = 56,
		maxLevel = 60,
		background = "blackrockspire"
	},
	[ "ramp" ] = {
		name = m.T[ "Hellfire Ramparts" ],
		reqLevel = 55,
		minLevel = 58,
		maxLevel = 62,
		heroic = true,
		background = "hellfire"
	},
	[ "bf" ] = {
		name = m.T[ "The Blood Furnace" ],
		reqLevel = 55,
		minLevel = 58,
		maxLevel = 63,
		heroic = true,
		background = "bloodfurnace"
	},
	[ "tsh" ] = {
		name = m.T[ "The Shattered Halls" ],
		reqLevel = 55,
		minLevel = 69,
		maxLevel = 70,
		heroic = true
	},
	[ "sp"] = {
		name = m.T[ "Slave Pens" ],
		reqLevel = 59,
		minLevel = 62,
		maxLevel = 64,
		heroic = true
	},
	[ "ub"] = {
		name = m.T[ "Underbog" ],
		reqLevel = 62,
		minLevel = 63,
		maxLevel = 65,
		heroic = true,
		background = "underbog"
	},
	[ "sv" ] = {
		name = m.T[ "Steamvault" ],
		reqLevel = 65,
		minLevel = 68,
		maxLevel = 70,
		heroic = true,
		background = "steamvault"
	},
	[ "mt" ] = {
		name = m.T[ "Mana-Tombs" ],
		reqLevel = 61,
		minLevel = 64,
		maxLevel = 66,
		heroic = true,
		background = "manatombs"
	},
	[ "ac" ] = {
		name = m.T[ "Auchenai Crypts" ],
		reqLevel = 62,
		minLevel = 64,
		maxLevel = 66,
		heroic = true
	},
	[ "sh" ] = {
		name = m.T[ "Sethekk Halls" ],
		reqLevel = 63,
		minLevel = 67,
		maxLevel = 69,
		heroic = true,
		background = "sethekk"
	},
	[ "sl" ] = {
		name = m.T[ "Shadow Labyrinth" ],
		reqLevel = 65,
		minLevel = 69,
		maxLevel = 70,
		heroic = true,
		background = "shadowlab"
	},
	[ "bot" ] = {
		name = m.T[ "The Botanica" ],
		reqLevel = 68,
		minLevel = 70,
		maxLevel = 70,
		heroic = true,
		background = "botanica"
	},
	[ "arc" ] = {
		name = m.T[ "The Arcatraz" ],
		reqLevel = 68,
		minLevel = 70,
		maxLevel = 70,
		heroic = true,
		background = "arcatraz"
	},
	[ "mec" ] = {
		name = m.T[ "The Mechanar" ],
		reqLevel = 68,
		minLevel = 70,
		maxLevel = 70,
		heroic = true,
		background = "mechanar"
	},
	[ "ohf" ] = {
		name = m.T[ "CoT: Old Hillsbrad Foothills" ],
		reqLevel = 66,
		minLevel = 66,
		maxLevel = 68,
		heroic = true
	},
	[ "bm" ] = {
		name = m.T[ "CoT: Black Morass" ],
		reqLevel = 68,
		minLevel = 68,
		maxLevel = 70,
		background = "cotbm",
		heoric = true
	}
}

m.classIndex = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }
m.classRoles = {
	[ "DRUID" ] = { "DPS", "Tank", "Healer" },
	[ "HUNTER" ] = { "DPS" },
	[ "MAGE" ] = { "DPS" },
	[ "PALADIN" ] = { "DPS", "Tank", "Healer" },
	[ "PRIEST" ] = { "DPS", "Healer" },
	[ "ROGUE" ] = { "DPS" },
	[ "SHAMAN" ] = { "DPS", "Tank", "Healer" },
	[ "WARLOCK" ] = { "DPS" },
	[ "WARRIOR" ] = { "DPS", "Tank" }
}
