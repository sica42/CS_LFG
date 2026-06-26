CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

if m.MinimapIcon then return end

---@class MinimapIcon
---@field icon table
---@field animate fun( enabled: boolean)

local M = {}

function M.new()
	local ldb = LibStub:GetLibrary( "LibDataBroker-1.1" )
	local icon = LibStub:GetLibrary( "LibDBIcon-1.0" )

	local iconSize = 64
	local sheetWidth = 512
	local sheetHeight = 256

	local function GetTexCoords( frame )
		local col = frame % 8
		local row = math.floor( frame / 8 )

		local baseLeft = (col * iconSize) / sheetWidth
		local baseRight = ((col + 1) * iconSize) / sheetWidth
		local baseTop = (row * iconSize) / sheetHeight
		local baseBottom = ((row + 1) * iconSize) / sheetHeight

		local xOffset = 0.03125
		local yOffset = 0.0625

		local left = baseLeft + xOffset
		local right = baseRight - xOffset
		local top = baseTop + yOffset
		local bottom = baseBottom - yOffset

		return left, right, top, bottom
	end

	local obj = ldb:NewDataObject( "Broker_CSLFG", {
		type = "launcher",
		label = m.T[ 'LFG Tool' ],
		text = "",
		icon = [[Interface\AddOns\CS_LFG\assets\images\eye]],
		iconCoords = { GetTexCoords( 0 ) },
		tocname = m.name
	} ) ---[[@as LibDataBroker.DataDisplay]]

	---@param tooltip Tooltip
	function obj.OnTooltipShow( tooltip )
		tooltip:AddLine( m.T[ "CrusaderStormLFG" ] )
		tooltip:AddLine( m.T[ "Left-click to toggle." ], 0.5, 0.5, 0.5 )
	end

	function obj:OnClick( button )
		if button == "LeftButton" then
			m.lfg_popup.toggle()
		end
	end

	icon:Register( m.name, obj, m.db.minimap_icon )

	local function icon_on_update( self, elapsed )
		self.delta = self.delta or 0
		self.frameIndex = self.frameIndex or 0

		if self.delta > 0.1 then
			self.frameIndex = self.frameIndex < 28 and self.frameIndex + 1 or 0
			self.icon:SetTexCoord( GetTexCoords( self.frameIndex ) )
			self.delta = 0
		end

		self.delta = self.delta + elapsed
	end


	local function animate( enabled )
		local button = icon.objects[ m.name ]
		if enabled then
			button:SetScript( "OnUpdate", icon_on_update )
		else
			button:SetScript( "OnUpdate", nil )
			button.icon:SetTexCoord( GetTexCoords( 0 ) )
		end
	end

	---@type MinimapIcon
	return {
		icon = icon,
		animate = animate
	}
end

m.MinimapIcon = M
return M
