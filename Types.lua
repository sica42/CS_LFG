CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

if m.Types then return end

local M = {}

---@alias Role
---| "DPS"
---| "Tank"
---| "Healer"
local Roles = {
	DPS = 1,
	Tank = 2,
	Healer = 4
}

M.Roles = Roles

---@alias LFGView
---| "Intro"
---| "Dungeons"
---| "Custom"
local LFGView = {
	Intro = "Intro",
	Dungeons = "Dungeons",
	Custom = "Custom"
}

M.LFGView = LFGView

---@alias BrowseView
---| "All"
---| "Dungeon"
---| "Group"
local BrowseView = {
	All = "All",
	Dungeon = "Dungeon",
	Group = "Group"
}

M.BrowseView = BrowseView

---@alias Tab
---| "LFG"
---| "Browse"
local Tab = {
	LFG = "LFG",
	Browse = "Browse"
}

M.Tab = Tab

---@alias CheckStatus
---| "Waiting"
---| "Ready"
---| "NotReady"
local CheckStatus = {
	Waiting = "Waiting",
	Ready = "Ready",
	NotReady = "Not Ready"
}

M.CheckStatus = CheckStatus

---@alias GroupType
---| "LFG"
---| "LFM"
local GroupTypes = {
	LFG = "LFG",
	LFM = "LFM"
}

M.GroupTypes = GroupTypes

local PlayerClass = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }

M.PlayerClass = PlayerClass

m.Types = M
return M
