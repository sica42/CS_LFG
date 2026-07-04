CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

---@class RoleCheckPopup
---@field show fun( leader: string, dungeon: string )
---@field hide fun()

local M = {}

---@class RoleCheckFrame : Frame, BackdropTemplate
---@field text_info FontString
---@field btn_confirm Button

---@param options table
function M.new( options )
	---@type RoleCheckFrame
	local popup
	local timer
	local time_left

	---@type RoleButton
	local role_dps, role_tank, role_healer

	local function btn_confirm_on_click()
		local roles = {}

		if role_dps.cb:GetChecked() then tinsert( roles, "DPS" ) end
		if role_tank.cb:GetChecked() then tinsert( roles, "Tank" ) end
		if role_healer.cb:GetChecked() then tinsert( roles, "Healer" ) end

		m.message_handler.role_confirm( roles )
		popup:Hide()
	end

	local function btn_decline_on_click()
		m.message_handler.role_decline()
		popup:Hide()
	end

	local function update_status()
		local rCount = m.count( options.dungeonRoles )
		if rCount > 0 then
			popup.btn_confirm:Enable()
		else
			popup.btn_confirm:Disable()
		end
	end

	local function on_update( self, elapsed )
		if (time_left or 0) > 0 then
			time_left = time_left - elapsed
			if time_left <= 0 then
				time_left = 0
				btn_decline_on_click()
			end

			timer:SetValue( time_left )
		end
	end

	---@return RoleCheckFrame
	local function create_frame()
		---@type RoleCheckFrame
		local frame = m.create_backdrop_frame( "Frame", "CSLFGGroupReadyPopup", UIParent )
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

		local label_title = frame:CreateFontString( nil, "OVERLAY", "GameFontWhite" )
		label_title:SetWidth( 200 )
		label_title:SetHeight( 48 )
		label_title:SetPoint( "TOP", frame, "TOP", 0, 0 )
		label_title:SetText( m.T[ "Role check" ] )

		local text_info = frame:CreateFontString( nil, "OVERLAY", "GameFontNormalSmall" )
		text_info:SetWidth( 200 )
		text_info:SetHeight( 24 )
		text_info:SetPoint( "TOP", frame, "TOP", 0, -104 )
		frame.text_info = text_info

		role_tank = m.create_player_role_button( frame, "Tank", options, update_status )
		role_tank:SetPoint( "TOP", frame, "TOP", 0, -42 )

		role_dps = m.create_player_role_button( frame, "DPS", options, update_status )
		role_dps:SetPoint( "RIGHT", role_tank, "LEFT", -8, 0 )

		role_healer = m.create_player_role_button( frame, "Healer", options, update_status )
		role_healer:SetPoint( "LEFT", role_tank, "RIGHT", 8, 0 )

		local btn_confirm = CreateFrame( "Button", nil, frame, "UIPanelButtonTemplate" )
		btn_confirm:SetWidth( 90 )
		btn_confirm:SetHeight( 24 )
		btn_confirm:SetPoint( "BOTTOM", frame, "BOTTOM", -50, 20 )
		btn_confirm:SetText( m.T[ "Confirm" ] )
		btn_confirm:SetScript( "OnClick", btn_confirm_on_click )
		frame.btn_confirm = btn_confirm

		local btn_decline = CreateFrame( "Button", nil, frame, "UIPanelButtonTemplate" )
		btn_decline:SetWidth( 90 )
		btn_decline:SetHeight( 24 )
		btn_decline:SetPoint( "BOTTOM", frame, "BOTTOM", 50, 20 )
		btn_decline:SetText( m.T[ "Decline" ] )
		btn_decline:SetScript( "OnClick", btn_decline_on_click )

		timer = m.create_timer_bar( frame )
		timer:SetPoint( "BOTTOMLEFT", btn_confirm, "TOPLEFT", 4, 8 )
		timer:SetWidth( 182 )

		return frame
	end

	local function update_frame( leader, dungeon )
		popup.text_info:SetText( string.format( "%s has initiated a role check for\n|cffffffff%s|r", leader, m.dungeons[ dungeon ].name ) )

		time_left = 90
		timer:SetValue( time_left )
	end

	local function show( leader, dungeon )
		if not popup then
			popup = create_frame()
		end

		update_frame( leader, dungeon )
		PlaySoundFile( [[Interface\AddOns\CS_LFG\assets\sounds\lfg_rolecheck.ogg]] )

		popup:Show()
	end

	local function hide()
		popup:Hide()
	end

	---@type RoleCheckPopup
	return {
		show = show,
		hide = hide
	}
end

m.RoleCheckPopup = M
return M
