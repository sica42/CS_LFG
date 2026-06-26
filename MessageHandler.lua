CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

if m.MessageHandler then return end

---@class MessageHandler
---@field version_check fun()
---@field lfg_list fun( min_lvl: integer?, max_lvl: integer? )
---@field lfg_add fun( msg: string )
---@field lfg_remove fun()
---@field group_response fun( response: boolean )
---@field enqueue_player fun( roles: table<number, Role>, dungeons: table<number, string> )
---@field enqueue_group fun( group: table)
---@field dequeue fun()
---@field on_command fun( command: string, data: string, sender: string )

local M = {}

local MessageCommand = m.Types.MessageCommand


function M.new()
	---@param command MessageCommand
	---@param data table?
	local function message( command, data )
		local _data = data and m.flatten( data ) or ""
		if (m.isModern) then
			m.info( "Sending command: " .. command )
			m.info( "data: " .. _data )
			C_ChatInfo.SendAddonMessage( m.short, command .. "::" .. _data, "WHISPER", m.bot )
		else
			m.info( "Sending command: " .. command )
			SendAddonMessage( m.short, command .. "::" .. _data, "WHISPER", m.bot )
		end
	end

	---@param min_lvl integer?
	---@param max_lvl integer?
	local function lfg_list( min_lvl, max_lvl )
		local cmd = ".lfg"
		if min_lvl then
			cmd = cmd .. " " .. tostring( min_lvl )
			if max_lvl then cmd = cmd .. "-" .. tostring( max_lvl ) end
		end

		SendChatMessage( cmd, "SAY" )
	end

	local function lfg_add( msg )
		SendChatMessage( ".lfg list " .. msg, "SAY" )
	end

	local function lfg_remove()
		SendChatMessage( ".lfg remove", "SAY" )
	end

	local function group_response( response )
		if response then
			message( MessageCommand.GroupConfirm )
		else
			message( MessageCommand.GroupDecline )
		end
	end

	---@param roles table<number, Role>
	local function enqueue_player( roles, dungeons )
		local _, class_id = m.find( m.player_class, m.Types.PlayerClass )
		local r = {}
		if roles[ m.Types.Roles.DPS ] then tinsert( r, 1 ) end
		if roles[ m.Types.Roles.Tank ] then tinsert( r, 2 ) end
		if roles[ m.Types.Roles.Healer ] then tinsert( r, 3 ) end

		local data = {
			l = m.player_level,
			c = class_id,
			r = r,
			d = m.get_keys( dungeons )
		}
		message( MessageCommand.EnqueuePlayer, data )
	end

	local function enqueue_group( data )
		message( MessageCommand.EnqueueGroup, data )
	end

	local function dequeue()
		message( MessageCommand.Dequeue )
	end

	local function version_check()
		message( m.Types.MessageCommand.VersionCheck )
	end

	local function on_command( command, data, sender )
		m.info( "Received " .. command .. " from " .. sender )
	end

	---@type MessageHandler
	return {
		lfg_list = lfg_list,
		lfg_add = lfg_add,
		lfg_remove = lfg_remove,
		group_response = group_response,
		enqueue_player = enqueue_player,
		enqueue_group = enqueue_group,
		dequeue = dequeue,
		version_check = version_check,
		on_command = on_command
	}
end

m.MessageHandler = M
return M
