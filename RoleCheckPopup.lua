CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

---@class RoleCheckPopup
---@field show fun()
---@field hide fun()

local M = {}

--CSLFG.role_check_popup.show()

---@class RoleCheckFrame : Frame, BackdropTemplate
---@field text_instances FontString

---@param options table
function M.new( options )
	local popup
	local btn_confirm
	local role_dps, role_tank, role_healer

	local function on_confirm()
		popup:Hide()
	end

	local function on_decline()
		popup:Hide()
	end

	local function update_status()
		local rCount = m.count( options.dungeonRoles )
		m.info("RoleCheck:update_status rCount:" .. tostring(rCount))
		if rCount > 0 then
			btn_confirm:Enable()
		else
			btn_confirm:Disable()
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

		local label_title = frame:CreateFontString( nil, "OVERLAY", "GameFontWhite" )
		label_title:SetWidth( 200 )
		label_title:SetHeight( 48 )
		label_title:SetPoint( "TOP", frame, "TOP", 0, 0 )
		label_title:SetText( m.T[ "Role check" ] )

		local text_instances = frame:CreateFontString( nil, "OVERLAY", "GameFontNormalSmall" )
		text_instances:SetWidth( 200 )
		text_instances:SetHeight( 24 )
		text_instances:SetPoint( "TOP", frame, "TOP", 0, -110 )
		frame.text_instances = text_instances


		role_tank = m.create_role_button( frame, m.Types.Roles.Tank, options, update_status )
		role_tank:SetPoint( "TOP", frame, "TOP", 0, -42 )

		role_dps = m.create_role_button( frame, m.Types.Roles.DPS, options, update_status )
		role_dps:SetPoint( "RIGHT", role_tank, "LEFT", -8, 0 )

		role_healer = m.create_role_button( frame, m.Types.Roles.Healer, options, update_status )
		role_healer:SetPoint( "LEFT", role_tank, "RIGHT", 8, 0 )

		btn_confirm = CreateFrame( "Button", nil, frame, "UIPanelButtonTemplate" )
		btn_confirm:SetWidth( 90 )
		btn_confirm:SetHeight( 24 )
		btn_confirm:SetPoint( "BOTTOM", frame, "BOTTOM", -50, 20 )
		btn_confirm:SetText( m.T[ "Confirm" ] )
		btn_confirm:SetScript( "OnClick", on_confirm )

		local btn_decline = CreateFrame( "Button", nil, frame, "UIPanelButtonTemplate" )
		btn_decline:SetWidth( 90 )
		btn_decline:SetHeight( 24 )
		btn_decline:SetPoint( "BOTTOM", frame, "BOTTOM", 50, 20 )
		btn_decline:SetText( m.T[ "Decline" ] )
		btn_decline:SetScript( "OnClick", on_decline )

		local frame_instances = CreateFrame( "Frame", nil, frame )
		frame_instances:SetWidth( 240 )
		frame_instances:SetHeight( 24 )
		frame_instances:SetPoint( "TOP", frame, "TOP", 0, -110 )
		frame_instances:CreateFontString( nil, "OVERLAY", "GameFontNormalSmall" )
		frame_instances:SetAllPoints()

		frame_instances:SetScript( "OnEnter", function()

		end )

		frame_instances:SetScript( "OnLeave", function()
			GameTooltip:Hide()
		end )

		local timer = m.create_timer_bar( frame )
		timer:SetPoint( "BOTTOMLEFT", btn_confirm, "TOPLEFT", 4, 8 )
		timer:SetWidth( 182 )

		return frame
	end

	local function show()
		if not popup then
			popup = create_frame()
		end

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
