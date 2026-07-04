CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

---@class RolesStatusPopup
---@field update_player_role fun( player: string, roles: Role[] )
---@field decline_player_role fun( player: string )
---@field is_visible fun(): boolean
---@field show fun()
---@field hide fun()

local M = {}

function M.new()
	---@type RolesStatusFrame
	local popup
	local timer
	local time_left

	---@type table<number, PlayerFrame>
	local playerFrames = {}

	local function btn_queue_on_click()
		local msg = m.generate_message( m.group.dungeon )

		m.message_handler.enqueue_group( m.group.dungeon )
		m.message_handler.lfg_add( msg )
		popup:Hide()
	end

	local function btn_cancel_on_click()
		popup:Hide()
	end

	local function on_update( self, elapsed )
		if (time_left or 0) > 0 then
			time_left = time_left - elapsed
			if time_left <= 0 then
				time_left = 0
				btn_cancel_on_click()
			end

			timer:SetValue( time_left )
		end
	end

	local function update_frame()
		popup.title:SetText( "About to queue for\n |cffffffff" .. m.dungeons[ m.group.dungeon ].name .. "|r" )
		local ready = 0

		for index, player in pairs( m.group.members ) do
			playerFrames[ index ].update( player )
			if player.status == m.Types.CheckStatus.Ready then
				ready = ready + 1
			end
		end

		if ready == #m.group.members then
			popup.btn_queue:Enable()
		else
			popup.btn_queue:Disable()
		end

		popup:SetHeight( 120 + m.group.count * 85 )
	end

	local function btn_role_on_click( self )
		if not self:IsEnabled() then return end

		local index = m.find( self.player_name, m.group.members, "name" )
		self.cb:SetChecked( not self.cb:GetChecked() )

		if index then
			if self.cb:GetChecked() then
				m.group.members[ index ].roles[ self.role ] = true
			else
				m.group.members[ index ].roles[ self.role ] = nil
			end

			update_frame()
		end
	end

	---@param parent Frame
	---@return PlayerFrame
	local function create_player_frame( parent )
		---@class PlayerFrame: Frame, BackdropTemplate
		local frame = m.create_backdrop_frame( "Frame", nil, parent )
		frame:SetWidth( 210 )
		frame:SetHeight( 80 )

		frame:SetBackdrop( {
			bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
			edgeFile = "Interface/Buttons/WHITE8x8",
			tile = true,
			tileSize = 32,
			edgeSize = 1,
			insets = { left = 1, right = 1, top = 1, bottom = 1 }
		} )
		frame:SetBackdropBorderColor( 1, 1, 1, 0.5 )
		frame:Hide()

		local label_title = frame:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		label_title:SetJustifyH( "LEFT" )
		label_title:SetPoint( "TOPLEFT", frame, "TOPLEFT", 7, 0 )
		label_title:SetWidth( 200 )
		label_title:SetHeight( 21 )

		local label_status = frame:CreateFontString( nil, "ARTWORK", "GameFontHighlight" )
		label_status:SetJustifyH( "LEFT" )
		label_status:SetFontObject( m.font_highlight )
		label_status:SetPoint( "TOPLEFT", frame, "TOPLEFT", 7, -14 )
		label_status:SetWidth( 200 )
		label_status:SetHeight( 21 )

		frame.btn_role_DPS = m.create_role_button( frame, "DPS" )
		frame.btn_role_DPS:SetPoint( "TOPLEFT", frame, "TOPLEFT", 60, -50 )
		frame.btn_role_DPS:SetScale( 0.7 )
		frame.btn_role_DPS:SetScript( "OnClick", btn_role_on_click )

		frame.btn_role_Tank = m.create_role_button( frame, "Tank" )
		frame.btn_role_Tank:SetPoint( "TOPLEFT", frame, "TOPLEFT", 120, -50 )
		frame.btn_role_Tank:SetScale( 0.7 )
		frame.btn_role_Tank:SetScript( "OnClick", btn_role_on_click )

		frame.btn_role_Healer = m.create_role_button( frame, "Healer" )
		frame.btn_role_Healer:SetPoint( "TOPLEFT", frame, "TOPLEFT", 180, -50 )
		frame.btn_role_Healer:SetScale( 0.7 )
		frame.btn_role_Healer:SetScript( "OnClick", btn_role_on_click )

		---@param player PartyMember
		frame.update = function( player )
			label_title:SetText( string.format( "%s %s %s", m.colorize_player_class( player.name, player.class ), player.level > 0 and player.level or "??",
				m.capitalize( player.class ) ) )

			for role in pairs( m.Types.Roles ) do
				frame[ "btn_role_" .. role ].disable()
				frame[ "btn_role_" .. role ].cb:SetChecked( false )
				frame[ "btn_role_" .. role ].player_name = player.name
			end

			if player.status == m.Types.CheckStatus.NotReady then
				label_status:SetText( m.T[ "Player is not ready." ] )
			else
				for _, role in pairs( m.classRoles[ player.class ] ) do
					frame[ "btn_role_" .. role ].enable()
				end
				--frame[ "btn_role_" .. "Tank" ].enable()
				--frame[ "btn_role_" .. "Healer" ].enable()

				if player.addon and player.online and not player.leader then
					for role in pairs( m.Types.Roles ) do
						frame[ "btn_role_" .. role ]:Disable()
					end
				end

				if next( player.roles ) then
					player.status = m.Types.CheckStatus.Ready
					if player.leader then
						label_status:SetText( m.T[ "You are ready." ] )
					else
						label_status:SetText( m.T[ "Player is ready." ] )
					end
					for role in pairs( player.roles ) do
						frame[ "btn_role_" .. role ].cb:SetChecked( true )
						if not player.leader and player.addon then
							frame[ "btn_role_" .. role ]:Disable()
						end
					end
				else
					player.status = m.Types.CheckStatus.Waiting
					if not player.online then
						label_status:SetText( m.T[ "Player is offline, please select roles(s)." ] )
					elseif player.addon then
						label_status:SetText( m.T[ "Waiting for role confirmation." ] )
					else
						label_status:SetText( m.T[ "No LFG AddOn, please select role(s)." ] )
					end
				end
			end

			frame:Show()
		end

		playerFrames[ #playerFrames + 1 ] = frame
		return frame
	end

	---@return RolesStatusFrame
	local function create_frame()
		---@class RolesStatusFrame: Frame, BackdropTemplate
		local frame = m.create_backdrop_frame( "Frame", "CSLFGRolesStatusPopup", UIParent )
		frame:SetPoint( "TOP", UIParent, "TOP", 0, -150 )
		frame:SetWidth( 250 )
		frame:SetHeight( 200 )
		frame:SetBackdrop( {
			bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
			edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 12, right = 12, top = 12, bottom = 11 }
		} )

		frame:SetScript( "OnUpdate", on_update )
		frame:SetScript( "OnHide", function()

		end )

		local label_title = frame:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		label_title:SetPoint( "TOP", frame, "TOP", 0, -15 )
		label_title:SetWidth( 240 )
		frame.title = label_title

		timer = m.create_timer_bar( frame )
		timer:SetPoint( "TOP", frame, "TOP", 0, -50 )
		timer:SetWidth( 182 )

		for i = 1, 5 do
			local frame_player = create_player_frame( frame )
			frame_player:SetPoint( "TOPLEFT", frame, "TOPLEFT", 20, 10 - i * 85 )
		end

		local btn_queue = CreateFrame( "Button", nil, frame, "UIPanelButtonTemplate" )
		btn_queue:SetPoint( "BOTTOM", frame, "BOTTOM", -56, 20 )
		btn_queue:SetWidth( 100 )
		btn_queue:SetHeight( 22 )
		btn_queue:SetText( m.T[ "Enter Queue" ] )
		btn_queue:SetScript( "OnClick", btn_queue_on_click )
		btn_queue:Disable()
		frame.btn_queue = btn_queue

		local btn_cancel = CreateFrame( "Button", nil, frame, "UIPanelButtonTemplate" )
		btn_cancel:SetPoint( "BOTTOM", frame, "BOTTOM", 56, 20 )
		btn_cancel:SetWidth( 100 )
		btn_cancel:SetHeight( 22 )
		btn_cancel:SetText( m.T[ "Cancel" ] )
		btn_cancel:SetScript( "OnClick", btn_cancel_on_click )

		return frame
	end

	---@param player string
	---@param roles Role[]
	local function update_player_role( player, roles )
		local index = m.find( player, m.group.members, "name" )
		if index then
			m.group.members[ index ].status = m.Types.CheckStatus.Ready
			m.group.members[ index ].roles = roles
			update_frame()
		else
			m.debug( player .. " not in group, unable to set role." )
		end
	end

	---@param player string
	local function decline_player_role( player )
		local index = m.find( player, m.group.members, "name" )
		if index then
			m.group.members[ index ].status = m.Types.CheckStatus.NotReady
			update_frame()
		end
	end

	local function is_visible()
		return popup and popup:IsVisible() or false
	end

	local function show()
		if not popup then
			popup = create_frame()
		end

		time_left = 90
		timer:SetValue( time_left )

		update_frame()
		PlaySoundFile( [[Interface\AddOns\CS_LFG\assets\sounds\lfg_rolecheck.ogg]] )

		popup:Show()
	end

	local function hide()
		popup:Hide()
	end

	---@type RolesStatusPopup
	return {
		update_player_role = update_player_role,
		decline_player_role = decline_player_role,
		is_visible = is_visible,
		show = show,
		hide = hide
	}
end

m.RolesStatusPopup = M
return M
