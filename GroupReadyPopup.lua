CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

---@class GroupReadyPopup
---@field show fun( dungeon: DungeonInfo, role: Role)
---@field hide fun()

local M = {}

function M.new()
	---@type GroupReadyFrame
	local popup
	local timer
	local time_left

	local function on_btn_confirm()
		popup:Hide()
		--m.group_status_popup.show()
	end

	local function on_btn_decline()
		popup:Hide()
	end

	local function on_update( self, elapsed )
		if (time_left or 0) > 0 then
			time_left = time_left - elapsed
			if time_left <= 0 then
				time_left = 0
				on_btn_decline()
			end

			timer:SetValue( time_left )
		end
	end

	local function create_frame()
		---@class GroupReadyFrame: Frame, BackdropTemplate
		local frame = m.create_backdrop_frame( "Frame", "CSLFGGroupReadyPopup", UIParent )
		frame:SetPoint( "TOP", UIParent, "TOP", 0, -150 )
		frame:SetWidth( 308 )
		frame:SetHeight( 220 )
		frame:SetBackdrop( {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 }
		} )

		frame:SetScript( "OnUpdate", on_update )


		local sep = frame:CreateTexture( nil, "OVERLAY" )
		sep:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-lfg-separator]] )
		sep:SetWidth( 256 )
		sep:SetHeight( 128 )
		sep:SetPoint( "TOP", frame, "TOP", 40, -30 )

		local top = frame:CreateTexture( nil, "OVERLAY" )
		top:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-group-ready-top]] )
		top:SetWidth( 512 )
		top:SetHeight( 128 )
		top:SetPoint( "TOPLEFT", frame, "TOPLEFT", 12, -8 )

		local middle = frame:CreateTexture( nil, "ARTWORK" )
		middle:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-group-ready-middle]] )
		middle:SetWidth( 512 )
		middle:SetHeight( 128 )
		middle:SetPoint( "TOPLEFT", frame, "TOPLEFT", 10, -72 )

		local label_group = frame:CreateFontString( nil, "OVERLAY", "GameFontWhite" )
		label_group:SetWidth( 200 )
		label_group:SetHeight( 44 )
		label_group:SetPoint( "TOP", frame, "TOP", 0, -6 )
		label_group:SetText( m.T[ "A group has been formed for:" ] )

		local dungeon_name = frame:CreateFontString( nil, "OVERLAY", "GameFontNormalLarge" )
		dungeon_name:SetWidth( 300 )
		dungeon_name:SetHeight( 24 )
		dungeon_name:SetPoint( "TOP", frame, "TOP", 0, -37 )
		frame.dungeon_name = dungeon_name

		local label_role = frame:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" )
		label_role:SetWidth( 100 )
		label_role:SetHeight( 24 )
		label_role:SetPoint( "TOP", frame, "TOP", -85, -84 )
		label_role:SetText( m.T[ "Your Role" ] )

		local role_name = frame:CreateFontString( nil, "OVERLAY", "GameFontNormalLarge" )
		role_name:SetWidth( 100 )
		role_name:SetHeight( 24 )
		role_name:SetPoint( "TOP", frame, "TOP", -85, -100 )
		frame.role_name = role_name

		local role_icon = frame:CreateTexture( nil, "OVERLAY" )
		role_icon:SetWidth( 64 )
		role_icon:SetHeight( 64 )
		role_icon:SetPoint( "TOP", frame, "TOP", -2, -77 )
		frame.role_icon = role_icon

		local btn_confirm = CreateFrame( "BUTTON", nil, frame, "UIPanelButtonTemplate" )
		btn_confirm:SetWidth( 120 )
		btn_confirm:SetHeight( 28 )
		btn_confirm:SetPoint( "BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 24 )
		btn_confirm:SetText( m.T[ "Let's do this!" ] )
		btn_confirm:SetScript( "OnClick", on_btn_confirm )

		local btn_decline = CreateFrame( "BUTTON", nil, frame, "UIPanelButtonTemplate" )
		btn_decline:SetWidth( 120 )
		btn_decline:SetHeight( 28 )
		btn_decline:SetPoint( "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 24 )
		btn_decline:SetText( m.T[ "Leave Queue" ] )
		btn_decline:SetScript( "OnClick", on_btn_decline )

		timer = m.create_timer_bar( frame )
		timer:SetPoint( "BOTTOMLEFT", btn_confirm, "TOPLEFT", 4, 8 )

		return frame
	end

	---@param dungeon DungeonInfo
	---@param role Role
	local function update_frame( dungeon, role )
		popup:SetBackdrop( {
			bgFile = [[Interface\AddOns\CS_LFG\assets\images\background\ui-lfg-background-]] .. dungeon.background,
			edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
			tile = false,
			edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 }
		} )

		popup.dungeon_name:SetText( dungeon.name )
		popup.role_name:SetText( role == "DPS" and "Damage" or role )
		if role == "DPS" then
			popup.role_icon:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\damage2]] )
		elseif role == "Tank" then
			popup.role_icon:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\tank2]] )
		elseif role == "Healer" then
			popup.role_icon:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\healer2]] )
		end

		time_left = 90
		timer:SetValue( time_left )
	end

	local function show( dungeon, role )
		if not popup then
			popup = create_frame()
		end

		update_frame( dungeon, role )
		popup:Show()
	end

	local function hide()
		popup:Hide()
	end

	---@type GroupReadyPopup
	return {
		show = show,
		hide = hide
	}
end

m.GroupReadyPopup = M
return M
