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
	DPS = m.T[ "DPS" ],
	Tank = m.T[ "Tank" ],
	Healer = m.T[ "Healer" ]
}

M.Roles = Roles

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

-----@alias PlayerClass
-----| "DRUID"
-----| "HUNTER"
-----|
local PlayerClass = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }

M.PlayerClass = PlayerClass

---@alias MessageCommand
---| "VERC"
---| "VER"
---| "GC"
---| "GD"
---| "QP"
---| "QG"
---| "DQ"
local MessageCommand = {
	VersionCheck = "VERC",
	GroupConfirm = "GC",
	GroupDecline = "GD",
	EnqueuePlayer = "QP",
	EnqueueGroup = "QG",
	Dequeue = "DQ",
}

M.MessageCommand = MessageCommand



m.Types = M
return M
