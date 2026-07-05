CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

if m.MessageHandler then return end

---@class MessageHandler
---@field lfg_list fun( min_lvl: integer?, max_lvl: integer?, force: boolean? )
---@field lfg_add fun( msg: string )
---@field lfg_remove fun()
---@field ping_player fun( player_name: string )
---@field ping_group fun()
---@field confirm_roles fun( dungeon: string )
---@field role_confirm fun( roles: Role[] )
---@field role_decline fun()
---@field enqueue_group fun( dungeon: string )
---@field dequeue_group fun()
---@field version_check fun( channel: string )
---@field on_command fun( command: string, data: string, channel: string, sender: string )

local M = {}

function M.new()
	local group_leader

	---@param message string
	---@param chatType string
	---@param target string?
	local function send_addon_message( message, chatType, target )
		if (m.isModern) then
			C_ChatInfo.SendAddonMessage( m.short, message, chatType, target )
		else
			SendAddonMessage( m.short, message, chatType, target )
		end
	end

	---@param dungeon string
	local function enqueue_group( dungeon )
		send_addon_message( "ENQUEUE#" .. dungeon, "RAID" )
	end

	local function dequeue_group()
		send_addon_message( "DEQUEUE#", "RAID" )
	end

	---@param min_lvl integer?
	---@param max_lvl integer?
	---@param force boolean?
	local function lfg_list( min_lvl, max_lvl, force )
		if not force and m.lfg_list_timestamp and time() - m.lfg_list_timestamp < 31 then return end

		local cmd = ".lfg"
		if min_lvl then
			cmd = cmd .. " " .. tostring( min_lvl )
			if max_lvl then cmd = cmd .. "-" .. tostring( max_lvl ) end
		end

		m.hide_pending_lfg_response = m.hide_pending_lfg_response + 1
		SendChatMessage( cmd, "WHISPER", nil, m.player_name )
	end

	---@param msg string
	local function lfg_add( msg )
		m.hide_pending_lfg_response = m.hide_pending_lfg_response + 1
		SendChatMessage( ".lfg list " .. msg, "WHISPER", nil, m.player_name )

		lfg_list( m.db.options.lvlmin, m.db.options.lvlmax, true )
	end

	local function lfg_remove()
		if m.isGrouped then	dequeue_group()	end

		m.hide_pending_lfg_response = m.hide_pending_lfg_response + 1
		SendChatMessage( ".lfg remove", "WHISPER", nil, m.player_name )

		lfg_list( m.db.options.lvlmin, m.db.options.lvlmax, true )
	end

	---@param player_name string
	local function ping_player( player_name )
		send_addon_message( "PING#", "WHISPER", player_name )
	end

	local function ping_group()
		send_addon_message( "PING#", "RAID" )
	end

	---@param dungeon string
	local function confirm_roles( dungeon )
		send_addon_message( "CROLE#" .. dungeon, "RAID" )
	end

	---@param roles Role[]
	local function role_confirm( roles )
		if not group_leader then
			m.error( "No group leader found. Cannot confirm role." )
			return
		end

		local str_roles = ""
		for i, role in pairs( roles ) do
			str_roles = str_roles .. (i > 1 and "," or "") .. role
		end

		send_addon_message( "ROLECONFIRM#" .. str_roles, "WHISPER", group_leader )
	end

	local function role_decline()
		if not group_leader then
			m.error( "No group leader found. Cannot decline role." )
			return
		end

		send_addon_message( "ROLEDECLINE#", "WHISPER", group_leader )
	end

	local function version_check( channel )
		send_addon_message( "VERC#", channel )
	end

	local function on_command( command, data, channel, sender )
		m.debug( "Received " .. command .. " from " .. sender )

		if command == "PING" then
			-- #################
			-- Ping
			-- #################
			send_addon_message( "PONG#", "WHISPER", sender )
		elseif command == "PONG" then
			-- #################
			-- Pong
			-- #################
			local index = m.find( sender, m.group.members, "name" )
			if index then
				m.group.members[ index ].addon = true
			end
		elseif command == "CROLE" then
			-- #################
			-- Check role
			-- #################
			group_leader = sender
			m.role_check_popup.show( sender, data )
		elseif command == "ROLECONFIRM" then
			-- #################
			-- Confirm role
			-- #################
			local roles = {}
			for _, role in pairs( m.split( data, "," ) ) do
				roles[ role ] = true
			end

			m.roles_status_popup.update_player_role( sender, roles )
		elseif command == "ROLEDECLINE" then
			-- #################
			-- Decline role
			-- #################
			m.roles_status_popup.decline_player_role( sender )
		elseif command == "ENQUEUE" then
			-- #################
			-- Enqueue group
			-- #################
			m.set_lfg( true )
			if not m.group then m.scan_party() end
			m.group.dungeon = data
			m.info( string.format( "Group has been enqueued for |cffffffff%s|r.", m.dungeons[ data ].name ), true )
		elseif command == "DEQUEUE" then
			-- #################
			-- Dequeue group
			-- #################
			m.set_lfg( false )
			m.info( "Group has been removed from queue.", true )
		elseif command == "VERC" then
			-- #################
			-- Version Check
			-- #################
			local c = channel == "PARTY" and "RAID" or channel
			send_addon_message( "VER#" .. c .. ":" .. m.version, "WHISPER", sender )
		elseif command == "VER" then
			-- #################
			-- Version Response
			-- #################
			local ch, version = strsplit( ':', data )
			local entry = "lastVersionCheck" .. ch
			if not m.db[ entry ] or time() - m.db[ entry ] > m.version_interval then
				m.db[ entry ] = time()

				if tonumber( version ) > tonumber( m.version ) then
					local url = "https://github.com/sica42/CS_LFG/releases/latest/download/CS_LFG.zip"
					m.info( string.format( "New version (%s) is available!", version ), true )
					m.info( string.format( "|Hurl:%s|h[%s]|h", url, url ), true )
				end
			end
		end
	end

	---@type MessageHandler
	return {
		lfg_list = lfg_list,
		lfg_add = lfg_add,
		lfg_remove = lfg_remove,
		ping_player = ping_player,
		ping_group = ping_group,
		confirm_roles = confirm_roles,
		role_confirm = role_confirm,
		role_decline = role_decline,
		enqueue_group = enqueue_group,
		dequeue_group = dequeue_group,
		version_check = version_check,
		on_command = on_command
	}
end

m.MessageHandler = M
return M
