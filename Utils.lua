CSLFG = CSLFG or {}

---@class CSLFG
local M = CSLFG

local Roles = M.Types.Roles
local soundMap = {
	[ "igCharacterInfoTab" ] = 841,
}

---@param type FrameType
---@param name string?
---@param parent Frame
---@return Frame
function M.create_backdrop_frame( type, name, parent )
	if M.isModern then
		return CreateFrame( type, name, parent, "BackdropTemplate" )
	else
		return CreateFrame( type, name, parent )
	end
end

function M.play_sound( sound )
	if M.isModern then
		PlaySound( soundMap[ sound ] )
	else
		---@diagnostic disable-next-line: param-type-mismatch
		PlaySound( sound )
	end
end

---@param parent Frame
---@param name string
---@param width number
---@param height number
---@param on_change function
---@return myScrollFrame
function M.create_scroll_bar( parent, name, width, height, on_change )
	---@class myScrollFrame: ScrollFrame
	local frame = CreateFrame( "Frame", nil, parent )
	frame:SetWidth( width )
	frame:SetHeight( height )
	frame:EnableMouseWheel( true )

	---@class LFGSlider: Slider
	local scroll_bar = CreateFrame( "Slider", name, frame, "UIPanelScrollBarTemplate" )
	scroll_bar:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", 0, -16 )
	scroll_bar:SetHeight( height - 32 )
	scroll_bar:SetValueStep( 1 )

	if on_change then
		scroll_bar:SetScript( "OnValueChanged", on_change )
	end

	local btn_up = M.api[ name .. "ScrollUpButton" ]
	btn_up:SetScript( "OnClick", function()
		scroll_bar.set_value( scroll_bar:GetValue() - scroll_bar:GetValueStep() )
	end )

	local btn_down = M.api[ name .. "ScrollDownButton" ]
	btn_down:SetScript( "OnClick", function()
		scroll_bar.set_value( scroll_bar:GetValue() + scroll_bar:GetValueStep() )
	end )

	frame:SetScript( "OnMouseWheel", function( self, delta )
		local step = scroll_bar.mousewheel_step or 1
		local value = scroll_bar:GetValue() - (delta * step)
		scroll_bar.set_value( value )
	end )

	scroll_bar.set_max_value = function( value )
		if value > 0 then
			M.api[ name .. "ScrollDownButton" ]:Enable()
			M.api[ name .. "ScrollUpButton" ]:Enable()
			M.api[ name .. "ThumbTexture" ]:Show()
			scroll_bar:SetMinMaxValues( 0, value )
		else
			M.api[ name .. "ScrollDownButton" ]:Disable()
			M.api[ name .. "ScrollUpButton" ]:Disable()
			M.api[ name .. "ThumbTexture" ]:Hide()
			scroll_bar:SetMinMaxValues( 0, 0 )
		end
	end

	scroll_bar.set_value = function( value )
		local min, max = scroll_bar:GetMinMaxValues()

		if value < min then value = min end
		if value > max then value = max end

		if not M.isModern and value % scroll_bar:GetValueStep() then
			value = value - value % scroll_bar:GetValueStep()
		end
		scroll_bar:SetValue( value )

		if value <= min then
			M.api[ name .. "ScrollUpButton" ]:Disable()
		else
			M.api[ name .. "ScrollUpButton" ]:Enable()
		end

		if value >= max then
			M.api[ name .. "ScrollDownButton" ]:Disable()
		else
			M.api[ name .. "ScrollDownButton" ]:Enable()
		end
	end

	frame.set_mousewheel_step = function( value )
		scroll_bar.mousewheel_step = value
	end

	frame.scroll_bar = scroll_bar
	return frame
end

---@param parent Frame
---@param role Role
---@param options table
---@param on_click function?
---@return Button
function M.create_role_button( parent, role, options, on_click )
	---@class RoleButton: Button
	local button = CreateFrame( "Button", nil, parent )
	button:SetWidth( 54 )
	button:SetHeight( 54 )
	button:SetHighlightTexture( [[Interface\Buttons\IconBorder-GlowRing]], "ADD" )

	local cb = CreateFrame( "CheckButton", nil, button, "UICheckButtonTemplate" )
	cb:SetWidth( 24 )
	cb:SetHeight( 24 )
	cb:SetPoint( "BOTTOMLEFT", button, "BOTTOMLEFT", 0, -5 )
	cb:EnableMouse( false )

	local icon = button:CreateTexture( nil, "BORDER" )
	icon:SetAllPoints( button )
	if role == Roles.DPS then
		icon:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\damage2]] )
		button.tooltip = M.T[ "Indicates that you are willing to take on the role of dealing damage to enemies." ]
	elseif role == Roles.Tank then
		icon:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\tank2]] )
		button.tooltip = M.T[ "Indicates that you are willing to protect allies from harm by ensuring that enemies are attacking you instead of them." ]
	elseif role == Roles.Healer then
		icon:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\healer2]] )
		button.tooltip = M.T[ "Indicates that you are willing to heal your allies when they take damage." ]
	end

	if M.find( role, M.classRoles[ M.player_class ] ) then
		if options.dungeonRoles[ role ] then
			cb:SetChecked( true )
		end
	else
		button:Disable()
		icon:SetDesaturated( true )
		cb:Hide()
	end

	button:SetScript( "OnClick", function( self )
		cb:SetChecked( not cb:GetChecked() )
		if cb:GetChecked() then
			options.dungeonRoles[ role ] = true
		else
			options.dungeonRoles[ role ] = nil
		end

		if on_click then
			on_click( self )
		end
	end )

	button:SetScript( "OnEnter", function( self )
		self:LockHighlight()
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )
		GameTooltip:SetText( self.tooltip, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, nil, true )
		GameTooltip:Show()
	end )

	button:SetScript( "OnLeave", function( self )
		self:UnlockHighlight()
		GameTooltip:Hide()
	end )

	return button
end

---@param parent Frame
---@return StatusBar
function M.create_timer_bar( parent )
	local timer = CreateFrame( "StatusBar", nil, parent )
	timer:SetWidth( 250 )
	timer:SetHeight( 10 )
	timer:SetStatusBarTexture( [[Interface\PaperDollInfoFrame\UI-Character-Skills-Bar]] )
	timer:SetStatusBarColor( 1, 1, 0 )
	timer:SetMinMaxValues( 0, 90 )

	local tex_timer = timer:CreateTexture( nil, "OVERLAY" )
	tex_timer:SetTexture( [[Interface\PaperDollInfoFrame\UI-Character-Skills-BarBorder]] )
	tex_timer:SetPoint( "LEFT", timer, "LEFT", -5, 0 )
	tex_timer:SetPoint( "RIGHT", timer, "RIGHT", 5, 0 )

	return timer
end

---@param dungeon DungeonInfo
---@param level integer
---@param heroic boolean?
---@return number, number, number
function M.get_dungeon_color( dungeon, level, heroic )
	local averageLevel = floor( (dungeon.maxLevel - dungeon.minLevel) / 2 ) + dungeon.minLevel
	local levelDiff = averageLevel - level
	local r, g, b
	if heroic then levelDiff = 3 end

	if levelDiff > 4 then
		r, g, b = 1, 0, 0        -- red
	elseif levelDiff > 2 then
		r, g, b = 1, 0.5, 0.25   -- orange
	elseif levelDiff > -3 then
		r, g, b = 1, 1, 0        -- yellow
	elseif levelDiff > -12 then
		r, g, b = 0.25, 0.75, 0.25 -- green
	else
		r, g, b = 0.5, 0.5, 0.5  -- gray
	end

	if dungeon.minLevel == dungeon.maxLevel then
		r, g, b = 1, 0.5, 0.25 -- orange
	end

	return r, g, b
end

---@param player PlayerInfo
function M.player_to_colorized_string( player )
	local color = RAID_CLASS_COLORS[ M.Types.PlayerClass[ player[ 2 ] ] ]
	if not color.colorStr then
		color.colorStr = string.format( "ff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255 )
	end

	return string.format( "|c%s%s|r", color.colorStr, player[ 1 ] )
end

---@param str string
---@return string
function M.capitalize( str )
	if #str == 0 then return "" end
	return string.upper( str:sub( 1, 1 ) ) .. string.lower( str:sub( 2 ) )
end

---@param t table
---@return number
function M.count( t )
	local count = 0
	for _ in pairs( t ) do
		count = count + 1
	end

	return count
end

---@param value string|number
---@param t table
---@param extract_field string?
function M.find( value, t, extract_field )
	if type( t ) ~= "table" or M.count( t ) == 0 then return nil end

	for i, v in pairs( t ) do
		local val = extract_field and v[ extract_field ] or v
		if val == value then return v, i end
	end

	return nil
end

---@param table table
---@return table
function M.get_keys( table )
	local list = {}
	for k in pairs( table ) do tinsert( list, k ) end

	return list
end

---@param t table
---@return boolean
function M.is_array( t )
	local count = 0
	for k, _ in pairs( t ) do
		if type( k ) ~= "number" then return false end
		count = count + 1
	end
	for i = 1, count do
		if t[ i ] == nil then return false end
	end
	return true
end

---@param value any
---@return string
function M.flatten( value )
	local value_type = type( value )

	if value_type == "table" then
		if M.is_array( value ) then
			-- JSON array
			local items = {}
			for i = 1, getn( value ) do
				table.insert( items, M.flatten( value[ i ] ) )
			end
			return "{" .. table.concat( items, ",	" ) .. "}"
		else
			-- JSON object
			local items = {}
			for k, v in pairs( value ) do
				table.insert( items, '["' .. tostring( k ) .. '"]=' .. M.flatten( v ) )
			end
			return "{" .. table.concat( items, "," ) .. "}"
		end
	elseif value_type == "string" then
		return '"' .. string.gsub( value, '"', '\\"' ) .. '"'
	elseif value_type == "number" or value_type == "boolean" then
		return tostring( value )
	elseif value_type == "nil" then
		return "null"
	end

	error( "Unsupported type: " .. value_type )
end

---@param message string
---@param short boolean?
function M.info( message, short )
	local tag = string.format( "|c%s%s|r", M.tagcolor, short and M.short or M.name )
	DEFAULT_CHAT_FRAME:AddMessage( string.format( "%s: %s", tag, message ) )
end

---@param message string
function M.error( message )
	local tag = string.format( "|c%s%s|r|cffff0000%s|r", M.tagcolor, M.short, "ERROR" )
	DEFAULT_CHAT_FRAME:AddMessage( string.format( "%s: %s", tag, message ) )
end

---@param message string
function M.debug( message )
	if M.debug_enabled then
		M.info( message, true )
	end
end
