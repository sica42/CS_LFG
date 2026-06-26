---@class CSLFG
CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

-- /console scriptErrors 1

m.name = "CS_LFG"
m.short = "CSLFG"
m.bot = "Foxraider"
m.tagcolor = "FFEBC315"
m.events = {}
m.isModern = C_ChatInfo and true or false
m.translations = (CSLFG_translation[ GetLocale() or "enUS" ])
m.api = getfenv()
m.debug_enabled = true

---@class LFGEntry
---@field lfg boolean
---@field lfm boolean
---@field player PlayerInfo
---@field message string
---@field dungeons table<number, string>
---@field roles table<string>

---@type table<number, LFGEntry>
m.lfg_list = {}

-- use table index key as translation fallback
m.T = setmetatable( m.translations, {
	---@return string
	__index = function( tab, key )
		local value = tostring( key )
		rawset( tab, key, value )
		return value
	end
} )

BINDING_CATEGORY_CRUSADERSTORM = m.T[ "Crusader Storm" ]
BINDING_HEADER_CSLFG = m.T[ "Group Finder" ]
BINDING_NAME_CSLFG_TOGGLE = m.T[ "Toggle Group Finder" ]

local strfind = string.find
local strmatch = string.match
local strlower = string.lower
local strupper = string.upper
local strgsub = string.gsub

function CSLFG:init()
	m.frame = CreateFrame( "Frame" )
	m.frame:SetScript( "OnEvent", function( _, event, ... )
		if m.events[ event ] then
			return m.events[ event ]( ... )
		end
	end )

	for k, _ in pairs( m.events ) do
		if not ((k == "GROUP_JOINED" and not m.isModern) or (k == "PARTY_MEMBERS_CHANGED" and m.isModern)) then
			m.frame:RegisterEvent( k )
		end
	end

	-- Override default I keybinding it not set to anything else
	if not GetBindingKey( "CSLFG_TOGGLE" ) then
		SetBinding( "I", "CSLFG_TOGGLE" )
	end

	for i = 1, NUM_CHAT_WINDOWS do
		if i ~= 2 then
			--m.hookChatFrame( _G[ "ChatFrame" .. i ] )
		end
	end

	ChatFrame_AddMessageEventFilter( "CHAT_MSG_SYSTEM", function( arg1, event, message )
		if not m.isModern then message = arg1 end

		if message and m.checkMessage( message ) > 0 then
			if m.hide_lfg_messages == 2 then m.hide_lfg_messages = 0 end
			return true
		end

		return false
	end )
end

function CSLFG.events.PLAYER_LOGIN()
	CS_LFGOptions = CS_LFGOptions or {}
	m.db = CS_LFGOptions
	m.db.minimap_icon = m.db.minimap_icon or {}
	m.db.options = m.db.options or {
		dungeonType = 1,
		lvlmin = 1,
		lvlmax = 70
	}

	m.player_name = UnitName( "player" )
	m.player_level = UnitLevel( "player" )
	_, m.player_class = UnitClass( "player" )
	m.isQueued = false
	m.hide_lfg_messages = 0

	if not m.db.options.dungeonRoles then
		m.db.options.dungeonRoles = {}

		-- Preselect role if only 1 is available
		local roles = m.classRoles[ m.player_class ]
		if m.count( roles ) == 1 then
			m.db.options.dungeonRoles[ roles[ 1 ] ] = true
		end
	end

	if m.isModern then
		C_ChatInfo.RegisterAddonMessagePrefix( m.short )
	end

	---@class MinimapIcon
	m.minimap_icon = m.MinimapIcon.new()

	---@class LFGPopup
	m.lfg_popup = m.LFGPopup.new( m.db.options )

	---@class GroupReadyPopup
	m.group_ready_popup = m.GroupReadyPopup.new()

	---@class GroupStatusPopup
	m.group_status_popup = m.GroupStatusPopup.new()

	---@class RoleCheckPopup
	m.role_check_popup = m.RoleCheckPopup.new( m.db.options )

	---@class MessageHandler
	m.message_handler = m.MessageHandler.new()

	m.version = GetAddOnMetadata( m.name, "Version" )
	m.info( string.format( "(v%s) Loaded", m.version ) )

	m.hide_lfg_messages = 3           -- Only hide during scan
	m.hide_no_guild_message = 1       -- Hide "You are not in a guild" messages during this phase
	SendChatMessage( ".lfg", "GUILD" ) -- SAY is restricted, have to use GUILD here
end

function CSLFG.events.CHAT_MSG_ADDON( prefix, message, type, sender )
	if prefix ~= m.short then return end --or sender == m.player_name

	m.info( "type:" .. type )
	local cmd_pat = "^([_%u%d]-)::"
	local command = string.match( message, cmd_pat )
	local data_str = string.gsub( message, cmd_pat, "" )

	if command then
		m.message_handler.on_command( command, data_str, sender )
	else
		m.debug( "Addon message missing command!?" )
	end
end

function CSLFG.events.GROUP_JOINED()
	if m.isQueued then
		m.message_handler.lfg_remove()
	end
end

function CSLFG.events.PARTY_MEMBERS_CHANGED()
	if m.isQueued then
		m.message_handler.lfg_remove()
	end
end

---@param frame MessageFrame
function CSLFG.hookChatFrame( frame )
	if not frame then return end

	local originalAddMessage = frame.AddMessage

	frame.AddMessage = function( self, message, ... )
		if message and m.checkMessage( message ) > 0 then -- and m.hide_lfg_messages
			if m.hide_lfg_messages == 2 then m.hide_lfg_messages = 0 end
			return originalAddMessage( self, "", ... )
		end

		return originalAddMessage( self, message, ... )
	end
end

---@param message string
---@return integer
function CSLFG.checkMessage( message )
	if strfind( message, "Looking for Group", nil, true ) then
		m.hide_no_guild_message = 0
		if strfind( message, "You are now listed as Looking for Group.", nil, true ) then
			m.setLFG( true )
			return m.hide_lfg_messages
		elseif strfind( message, "You are no longer Looking for Group.", nil, true ) then
			m.setLFG( false )
			return m.hide_lfg_messages
		elseif strfind( message, "You were not Looking for Group.", nil, true ) then
			m.setLFG( false )
			return m.hide_lfg_messages
		elseif strfind( message, "No players", nil, true ) then
			m.lfg_list = {}
			if m.hide_lfg_messages == 3 then m.hide_lfg_messages = 2 end
			m.lfg_popup.update()
			return m.hide_lfg_messages
		elseif strfind( message, "Players Looking for Group.-%(" ) then
			m.lfg_count = tonumber( strmatch( message, "%((%d+)%)" ) )
			m.lfg_list = {}
			return m.hide_lfg_messages
		end
	elseif strfind( message, "Use '.lfg remove' to delist.", nil, true ) then
		return m.hide_lfg_messages
	elseif strfind( message, "You are not in a guild", nil, true ) then
		return m.hide_no_guild_message
	end

	local player, level, class, msg = strmatch( message, "|Hplayer:%w+|h%[(%w+)%]|h|r%s%((%d+)%s(%w+)%)%s%-%s(.*)" )
	if player then
		local lower = strlower( msg )
		local dungeons = m.parseDungeons( lower )
		local roles = m.parseRoles( lower )
		local lfm = strfind( lower, "lfm", nil, true ) and true or false
		local _, class_id = m.find( strupper( class ), m.Types.PlayerClass )

		table.insert( m.lfg_list, {
			lfg = not lfm,
			lfm = lfm,
			player = { player, class_id, level },
			roles = roles,
			dungeons = dungeons,
			message = msg
		} )

		if player == m.player_name then
			m.setLFG( true )
		end

		if getn( m.lfg_list ) == m.lfg_count then
			m.debug( string.format( "Received %d LFG entries.", m.lfg_count ) )

			-- TEST DATA
			table.insert( m.lfg_list, {
				lfg = true,
				lfm = false,
				player = { "Sica", 2, 70 },
				dungeons = { "sv" },
				roles = { m.Types.Roles.DPS },
				message = "Test entry with a very long description to test the ui for looong string. how long can this be? this is way to long"
			} )

			table.insert( m.lfg_list, {
				lfg = true,
				lfm = false,
				player = { "Borazor", 7, 70 },
				dungeons = { "sv" },
				roles = { m.Types.Roles.Healer },
				message = "Test entry with a very long description to test the ui for looong string. how long can this be? this is way to long"
			} )

			table.insert( m.lfg_list, {
				lfg = true,
				lfm = false,
				player = { "Lynn", 4, 70 },
				dungeons = { "sv" },
				roles = { m.Types.Roles.Tank, m.Types.Roles.DPS },
				message = "Test entry with a very long description to test the ui for looong string. how long can this be? this is way to long"
			} )

			table.insert( m.lfg_list, {
				lfg = true,
				lfm = false,
				player = { "Muttekalf", 7, 70 },
				dungeons = { "sv" },
				roles = { m.Types.Roles.Healer, m.Types.Roles.DPS },
				message = "Test entry with a very long description to test the ui for looong string. how long can this be? this is way to long"
			} )

			table.insert( m.lfg_list, {
				lfg = true,
				lfm = false,
				player = { "Nomisunrider", 3, 70 },
				dungeons = { "sv" },
				roles = { m.Types.Roles.DPS },
				message = "Test entry with a very long description to test the ui for looong string. how long can this be? this is way to long"
			} )



			if m.hide_lfg_messages == 3 then m.hide_lfg_messages = 2 end
			m.lfg_popup.update()
		end

		return m.hide_lfg_messages
	end

	return 0
end

---@param msg string
---@return table
function CSLFG.parseDungeons( msg )
	local dungeons = {}

	-- Remove/fix stuff that can be mistakes and dungeon codes
	msg = strgsub( msg, "shaman", "" )
	msg = strgsub( msg, "black morass", "bm" )
	msg = " " .. msg .. " " -- pad for easy patter matching

	for dungeon in pairs( m.dungeons ) do
		if strfind( msg, dungeon, nil, true ) then
			local hc = ""
			if strfind( msg, "hc", nil, true ) or strfind( msg, "%sh%s" ) then
				hc = "hc"
			end
			table.insert( dungeons, dungeon .. hc )
		end
	end

	return dungeons
end

---@param msg string
---@return table
function CSLFG.parseRoles( msg )
	local roles = {}

	for _, role in pairs( m.Types.Roles ) do
		if strfind( msg, strlower( role ), nil, true ) then
			table.insert( roles, role )
		end
	end

	if strfind( msg, "resto", nil, true ) then
		table.insert( roles, m.Types.Roles.Healer )
	end

	if not next( roles ) then
		table.insert( roles, m.Types.Roles.DPS )
	end

	return roles
end

-- /dump CSLFG.lfgList
-- /script CSLFG.hide_lfg_messages = false

---@param state boolean
function CSLFG.setLFG( state )
	m.isQueued = state

	if state then
		m.minimap_icon.animate( true )
	else
		m.minimap_icon.animate( false )
	end

	m.lfg_popup.set_lfg()
end

CSLFG:init()
