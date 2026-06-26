CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

---@class GroupStatusPopup
---@field show fun()
---@field hide fun()

local M = {}

---@class GroupStatusFrame : Frame, BackdropTemplate


function M.new()
	local popup

	---@return GroupStatusFrame
	local function create_frame()
		---@class GroupStatusFrame: Frame, BackdropTemplate
		local frame = m.create_backdrop_frame( "Frame", "CSLFGGroupReadyPopup", UIParent )
		frame:SetPoint( "TOP", UIParent, "TOP", 0, -150 )
		frame:SetWidth( 360 )
		frame:SetHeight( 152 )
		frame:SetBackdrop( {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 12, right = 12, top = 12, bottom = 11 }
		} )

		local btn_close = CreateFrame( "BUTTON", nil, frame, "UIPanelCloseButton" )
		btn_close:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", -3, -3 )

		local label_rdy = frame:CreateFontString( nil, "OVERLAY", "GameFontWhite" )
		label_rdy:SetWidth( 100 )
		label_rdy:SetHeight( 44 )
		label_rdy:SetPoint( "TOP", frame, "TOP", 0, 0 )
		label_rdy:SetText( m.T[ "Ready check" ] )

		local checks = {}
		for slot = 1, 5, 1 do
			local tex_icon = frame:CreateTexture( nil, "ARTWORK" )
			tex_icon:SetWidth( 64 )
			tex_icon:SetHeight( 64 )
			tex_icon:SetPoint( "TOPLEFT", frame, "TOPLEFT", 20 + 64 * (slot - 1), -40 )
			tex_icon:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\]] .. (slot == 1 and "tank2" or slot == 2 and "healer2" or "damange2") )

			local tex_check = frame:CreateTexture( nil, "OVERLAY" )
			tex_check:SetWidth( 42 )
			tex_check:SetHeight( 42 )
			tex_check:SetPoint( "TOPLEFT", tex_icon, "TOPLEFT", 0, -30 )
			tex_check:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\readycheck-waiting]] )
			tinsert(checks, tex_check)
		end

		frame.set_slot_status = function( slot, status )
			if slot > 5 then return end

			if status == m.Types.CheckStatus.Waiting then
				checks[ slot ]:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\readycheck-waiting]] )
			elseif status == m.Types.CheckStatus.Ready then
				checks[ slot ]:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\readycheck-ready]] )
			elseif status == m.Types.CheckStatus.NotReady then
				checks[ slot ]:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\readycheck-notready]] )
			end
		end

		return frame
	end

	local function show()
		if not popup then
			popup = create_frame()
		end

		popup:Show()
	end

	local function hide()
		popup:Hide()
	end

	---@type GroupStatusPopup
	return {
		show = show,
		hide = hide
	}
end

m.GroupStatusPopup = M
return M
