---@class CSLFG
CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

m.name = "CS_LFG"
m.short = "CSLFG"
m.tagcolor = "FF60BB16"
m.version_interval = 3600 * 24
m.events = {}
m.isModern = C_ChatInfo and true or false
m.translations = (CSLFG_translation[ GetLocale() or "enUS" ])
m.api = getfenv()
m.debug_enabled = false

---@class LFGEntry
---@field lfg boolean
---@field lfm boolean
---@field player PlayerInfo
---@field message string
---@field dungeons table<number, string>
---@field roles table<string>
---@field members table

---@type table<number, LFGEntry>
m.lfg_list = {}

---@class PartyMember
---@field name string
---@field class string
---@field level integer
---@field unit string
---@field roles table<Role, boolean>
---@field online boolean
---@field addon boolean?
---@field leader boolean?
---@field status CheckStatus?

---@class PartyInfo
---@field count integer
---@field online integer
---@field dungeon string?
---@field members table<number, PartyMember>

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
local strgmatch = string.gmatch
local strlower = string.lower
local strupper = string.upper
local strgsub = string.gsub
local strformat = string.format

function CSLFG:init()
	m.frame = CreateFrame( "Frame" )
	m.frame:SetScript( "OnEvent", function( _, event, ... )
		if m.events[ event ] then
			return m.events[ event ]( ... )
		end
	end )

	for k, _ in pairs( m.events ) do
		if not (k == "PARTY_MEMBERS_CHANGED" and m.isModern) then
			m.frame:RegisterEvent( k )
		end
	end

	ChatFrame_AddMessageEventFilter( "CHAT_MSG_SYSTEM", function( arg1, event, message )
		if not m.isModern then message = arg1 end

		if message and m.check_lfg_messages( message ) then
			if m.hide_pending_lfg_response > 0 then
				m.hide_pending_lfg_response = m.hide_pending_lfg_response - 1
				return true
			end
		end

		if m.db and m.db.options.hideBG and message and m.check_bg_messages( message ) then
			return true
		end

		return false
	end )

	SLASH_CSLFG1 = "/lfg"
	SlashCmdList.CSLFG = function( args )
		if not args or args == "" then
			m.info( string.format( "(Version %s) Usage:", m.version ), true )
			--m.info ( "|cffaaaaaa/lfg icon_animate|r - Toggle minimap icon animation when Looking for Group.", true )
			m.info ( "|cffaaaaaa/lfg bg|r - Toggle BG announcements.", true )
			m.info ( "|cffaaaaaa/lfg debug|r - Toggle debug messages.", true )
		elseif args == "icon_animate" then
		elseif args == "bg" then
			m.db.options.hideBG = not m.db.options.hideBG
			m.info( "BG Queue Announcements are now " .. (m.db.options.hideBG and "hidden." or "shown.") )
		elseif args == "debug" then
			m.debug_enabled = not m.debug_enabled
			m.info( "Debug messages is " .. (m.debug_enabled and "enabled." or "disabled."), true )
		end
	end
end

function CSLFG.events.PLAYER_LOGIN()
	CS_LFGOptions = CS_LFGOptions or {}
	m.db = CS_LFGOptions
	m.db.minimap_icon = m.db.minimap_icon or {}
	m.db.options = m.db.options or {
		dungeonType = 1,
		lvlmin = 1,
		lvlmax = 70,
		hideBG = false
	}

	m.player_name = UnitName( "player" )
	m.player_level = UnitLevel( "player" )
	_, m.player_class = UnitClass( "player" )
	m.isLeader = m.is_group_leader( "player" )
	m.isGrouped = m.is_grouped()
	m.isQueued = false
	m.selectedDungeons = {}
	m.hide_pending_lfg_response = 0
	m.version = GetAddOnMetadata( m.name, "Version" )

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

	-- Override default I keybinding it not set to anything else
	if not GetBindingKey( "CSLFG_TOGGLE" ) and (not GetBindingAction( "I" ) or GetBindingAction( "I" ) == "") then
		SetBinding( "I", "CSLFG_TOGGLE" )
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

	---@class RolesStatusPopup
	m.roles_status_popup = m.RolesStatusPopup.new()

	---@class MessageHandler
	m.message_handler = m.MessageHandler.new()

	m.message_handler.lfg_list( m.db.options.lvlmin, m.db.options.lvlmax, true )

	m.check_new_version()
end

function CSLFG.events.CHAT_MSG_ADDON( prefix, message, channel, sender )
	if prefix ~= m.short or sender == m.player_name then return end

	local cmd_pat = "^([_%u%d]-)#"
	local command = strmatch( message, cmd_pat )
	local data_str = strgsub( message, cmd_pat, "" )

	if command then
		m.message_handler.on_command( command, data_str, channel, sender )
	else
		m.debug( "Addon message missing command!?" )
	end
end

function CSLFG.events.PARTY_MEMBERS_CHANGED()
	m.debug( "PARTY_MEMBERS_CHANGED" )
	m.group_changed()
end

function CSLFG.events.GROUP_ROSTER_UPDATE()
	m.debug( "GROUP_ROSTER_UPDATE" )
	m.group_changed()
end

function CSLFG.group_changed()
	m.isGrouped = m.is_grouped()
	m.isLeader = m.is_group_leader( "player" )

	if not m.isGrouped then
		m.group = nil
	end

	if m.isQueued and (not m.isGrouped or (m.group and m.group.count ~= m.get_num_group_members())) then
		m.isQueued = false
		m.message_handler.lfg_remove()
	end

	if m.lfg_popup.is_visible() then
		if m.isLeader then
			m.delayed_scan_party( function()
				m.lfg_popup.update()
			end )
		else
			m.lfg_popup.update()
		end
	end

	m.check_new_version( true )
end

---@param on_complete function
function CSLFG.delayed_scan_party( on_complete )
	local max_delay = 1
	m.frame:SetScript( "OnUpdate", function( _, elapsed )
		max_delay = max_delay - elapsed
		if (not m.isGrouped or UnitIsConnected( "party1" )) or max_delay <= 0 then
			m.frame:SetScript( "OnUpdate", nil )
			m.scan_party()
			if on_complete then on_complete() end
		end
	end )
end

function CSLFG.scan_party()
	m.debug( "scan_party" )

	---@type PartyMember
	local player = {
		addon = true,
		leader = m.is_group_leader( "player" ),
		online = true,
		name = m.player_name,
		class = m.player_class,
		level = m.player_level,
		unit = "player",
		roles = m.db.options.dungeonRoles
	}

	---@type PartyInfo
	m.group = {
		count = m.get_num_group_members(),
		online = 1,
		members = { player }
	}

	for i = 1, m.group.count - 1 do
		local unit = "party" .. i
		local level = UnitLevel( unit )
		local name = UnitName( unit )
		local _, class = UnitClass( unit )

		if name and class then
			local online = false
			if UnitIsConnected( unit ) then
				m.group.online = m.group.online + 1
				online = true
			end

			---@type PartyMember
			local member = {
				name = name,
				class = class,
				level = level,
				leader = m.is_group_leader( unit ),
				unit = unit,
				roles = {},
				online = online
			}

			m.group.members[ #m.group.members + 1 ] = member
		end
	end

	table.sort( m.group.members, function( a, b )
		return a.leader and not b.leader
	end )

	m.message_handler.ping_group()
end

---@param message string
---@return boolean
function CSLFG.check_lfg_messages( message )
	if strfind( message, "Looking for Group", nil, true ) then
		if strfind( message, "You are now listed as Looking for Group.", nil, true ) then
			m.set_lfg( true )
			if m.hide_pending_lfg_response > 0 then
				m.hide_pending_lfg_response = m.hide_pending_lfg_response + 1
			end
			return true
		elseif strfind( message, "You are no longer Looking for Group.", nil, true ) then
			m.set_lfg( false )
			return true
		elseif strfind( message, "You were not Looking for Group.", nil, true ) then
			m.set_lfg( false )
			return true
		elseif strfind( message, "No players", nil, true ) then
			m.lfg_list = {}
			m.lfg_popup.update()
			return true
		elseif strfind( message, "Players Looking for Group.-%(" ) then
			m.lfg_count = tonumber( strmatch( message, "%((%d+)%)" ) )
			m.lfg_list = {}
			if m.hide_pending_lfg_response > 0 then
				m.hide_pending_lfg_response = m.hide_pending_lfg_response + m.lfg_count
			end
			return true
		end
	elseif strfind( message, "Use '.lfg remove' to delist.", nil, true ) then
		return true
	end

	local player, level, class, msg = strmatch( message, "|Hplayer:%w+|h%[(%w+)%]|h|r%s%((%d+)%s(%w+)%)%s%-%s(.*)" )
	if player then
		local lower = strlower( msg )
		local lfm = strfind( lower, "lf%d?m" ) and true or false
		local class_id = m.find( strupper( class ), m.Types.PlayerClass )
		local dungeons = m.parse_dungeons( lower )
		level = tonumber( level )

		if lfm then
			local player_roles = strmatch( lower, "§(%d+)," )

			if strfind( msg, "§", nil, true ) then
				msg = strsub( msg, 1, strfind( msg, "§", nil, true ) - 1 )
			end

			table.insert( m.lfg_list, {
				lfg = false,
				lfm = true,
				player = { player, class_id, level },
				roles = player_roles and m.bitmask_to_roles( tonumber( player_roles ) ),
				dungeons = dungeons,
				members = m.parse_group_members( lower ),
				message = msg
			} )
		else
			table.insert( m.lfg_list, {
				lfg = true,
				lfm = false,
				player = { player, class_id, level },
				roles = m.parse_roles( lower ),
				dungeons = dungeons,
				message = msg
			} )
		end

		if player == m.player_name then
			if not next( m.selectedDungeons ) then
				for _, dungeon in pairs( dungeons ) do
					m.selectedDungeons[ dungeon ] = true
				end
			end
			m.set_lfg( true )
		end

		if #m.lfg_list == m.lfg_count then
			m.lfg_list_timestamp = time()
			m.debug( strformat( "Received %d LFG entries.", m.lfg_count ) )

			m.lfg_popup.update()
		end

		return true
	end

	return false
end

function CSLFG.check_bg_messages( message )
	if strfind( message, "BG Queue Announcer", nil, true ) then
		return true
	elseif strfind( message, "Arena Queue Announcer", nil, true ) then
		return true
	elseif strfind( message, "PvP is in progress.", nil, true ) then
			-- (%w) PvP is in progress.
		return true
	end

	return false
end

---@param msg string
---@return table
function CSLFG.parse_dungeons( msg )
	local dungeons = {}

	-- Replace some dungeons names with abbreviations
	msg = strgsub( msg, "black morass", "bm" )
	msg = " " .. msg .. " " -- pad for easy pattern matching

	for _, dungeon in pairs( m.dungeons_by_length ) do
		local match = strfind( msg, "%W" .. dungeon .. "%W" )
		local match_hc = strfind( msg, "%W" .. dungeon .. "hc%W" )

		if match or match_hc then
			if match_hc then
				dungeon = dungeon .. "hc"
			else
				if string.find( msg, "%W" .. dungeon .. "%shc?%s" ) then
					dungeon = dungeon .. "hc"
				end
			end

			table.insert( dungeons, dungeon )
		end
	end

	return dungeons
end

---@param msg string
---@return table
function CSLFG.parse_roles( msg )
	local roles = {}

	for _, role in pairs( m.Types.Roles ) do
		if strfind( msg, strlower( role ), nil, true ) then
			table.insert( roles, role )
		end
	end

	if strfind( msg, "resto", nil, true ) then
		table.insert( roles, "Healer" )
	end

	if not next( roles ) then
		table.insert( roles, "DPS" )
	end

	return roles
end

function CSLFG.parse_group_members( msg )
	local members = {}

	for roles, player, class_id, level in string.gmatch( msg, "(%d)(%a+)(%d)(%d+)" ) do
		members[ #members + 1 ] = {
			player = { m.capitalize( player ), tonumber( class_id ), tonumber( level ) },
			roles = m.bitmask_to_roles( tonumber( roles ) )
		}
	end

	return members
end

---@param state boolean
function CSLFG.set_lfg( state )
	m.isQueued = state

	if state then
		m.minimap_icon.animate( true )
	else
		m.minimap_icon.animate( false )
	end

	m.lfg_popup.update()
end

---@param dungeons table|string
---@return string
function CSLFG.generate_message( dungeons )
	local msg = ""
	local dungeon_list = {}

	if type( dungeons ) == "string" then
		dungeon_list = { strupper( dungeons ) }
	else
		for dungeon in pairs( dungeons ) do
			dungeon_list[ #dungeon_list + 1 ] = strupper( dungeon )
		end
	end

	if m.isGrouped then
		msg = "LF" .. (5 - m.get_num_group_members()) .. "M "
		msg = msg .. table.concat( dungeon_list, "/" )

		local missing = m.get_missing_roles_message( m.group.members )
		msg = strformat( "%s %s§", msg, missing )

		for _, member in pairs( m.group.members ) do
			local roles = m.roles_to_bitmask( member.roles )

			if member.leader then
				msg = msg .. roles
			else
				local class_id = m.find( member.class, m.Types.PlayerClass )
				local player = strformat( "%d%s%d%d", roles, member.name, class_id, member.level )
				msg = msg .. "," .. player
			end
		end
	else
		for role in pairs( m.db.options.dungeonRoles ) do
			msg = msg .. (msg == "" and "" or "/") .. role
		end

		msg = msg .. " LFG "
		msg = msg .. table.concat( dungeon_list, "/" )
	end

	return msg
end

function CSLFG.get_missing_roles_message( group_members )
	local req = { Tank = 1, Healer = 1, DPS = 3 }
	local assigned = { Tank = 0, Healer = 0, DPS = 0 }

	local members = {}
	for _, member in pairs( group_members ) do
		local r = {}
		for role, val in pairs( member.roles ) do if val then table.insert( r, role ) end end
		table.insert( members, { name = member.name, roles = r, count = #r, assigned = false } )
	end

	table.sort( members, function( a, b )
		if a.count ~= b.count then
			return a.count < b.count
		end
		-- If both are equally flexible, prioritize based on Tank > Healer > DPS
		local p = { Tank = 1, Healer = 2, DPS = 3 }
		local pA = p[ a.roles[ 1 ] ] or 4
		local pB = p[ b.roles[ 1 ] ] or 4
		return pA < pB
	end )

	-- Assign Roles
	local priorities = { "Tank", "Healer", "DPS" }
	for _, role in ipairs( priorities ) do
		for _, member in ipairs( members ) do
			if not member.assigned and assigned[ role ] < req[ role ] then
				-- Check if this role is in their allowed roles
				for _, pRole in ipairs( member.roles ) do
					if pRole == role then
						assigned[ role ] = assigned[ role ] + 1
						member.assigned = true
						break
					end
				end
			end
		end
	end

	local missing = {}
	for _, role in ipairs( priorities ) do
		local gap = req[ role ] - assigned[ role ]
		if gap > 0 then table.insert( missing, (gap > 1 and gap .. " " or "") .. role ) end
	end

	return "need " .. table.concat( missing, ", " )
end

---@param raid boolean?
function CSLFG.check_new_version( raid )
	local channel

	if raid and (not m.db.lastVersionCheckRAID or time() - m.db.lastVersionCheckRAID > m.version_interval) then
		channel = "RAID"
	elseif not m.db.lastVersionCheckGUILD or time() - m.db.lastVersionCheckGUILD > m.version_interval then
		channel = "GUILD"
	end

	if channel then
		m.message_handler.version_check( channel )
	end
end

CSLFG:init()
