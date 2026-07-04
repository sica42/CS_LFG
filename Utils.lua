CSLFG = CSLFG or {}

---@class CSLFG
local M = CSLFG

local soundMap = {
	[ "igCharacterInfoTab" ] = 841,
}

M.font_normal_bold = CreateFont( "CSLFGFontIntroButton" )
M.font_normal_bold:SetFont( "Fonts\\FRIZQT__.TTF", 13, "" )
M.font_normal_bold:SetTextColor( 1, 1, 0 )

M.font_normal = CreateFont( "CSLFGFontNormal" )
M.font_normal:SetFont( [[Interface\AddOns\CS_LFG\assets\fonts\PTSansNarrow.ttf]], 12, "" )
M.font_normal:SetTextColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b )

M.font_highlight = CreateFont( "CSLFGFontHighlight" )
M.font_highlight:SetFont( [[Interface\AddOns\CS_LFG\assets\fonts\PTSansNarrow.ttf]], 12, "" )
M.font_highlight:SetTextColor( HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b )

M.get_font = function()
	return [[Interface\AddOns\CS_LFG\assets\fonts\PTSansNarrow.ttf]], 12, ""
end

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

	frame.set_height = function( height )
		frame:SetHeight( height )
		scroll_bar:SetHeight( height - 32 )
	end

	frame.scroll_bar = scroll_bar
	return frame
end

---@param parent Frame
---@param max_letters integer?
---@param on_text_changed function?
---@return EditBoxFrame
function M.create_multiline_editbox( parent, max_letters, on_text_changed )
	---@class EditBoxFrame: Frame
	local frame_editbox
	if M.isModern then
		frame_editbox = CreateFrame( "Frame", nil, parent, "TooltipBackdropTemplate" )
	else
		frame_editbox = CreateFrame( "Frame", nil, parent )
		frame_editbox:SetBackdrop( {
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = {
				left = 4,
				right = 4,
				top = 4,
				bottom = 4,
			},
		} )
		frame_editbox:SetBackdropColor( 0, 0, 0, 1 )
		frame_editbox:SetBackdropBorderColor( 1, 1, 1, 1 )
	end
	local edit_box = CreateFrame( "EditBox", nil, frame_editbox )

	edit_box:SetFontObject( "CSLFGFontHighlight" )
	edit_box:SetPoint( "TOPLEFT", frame_editbox, "TOPLEFT", 5, -5 )
	edit_box:SetPoint( "BOTTOMRIGHT", frame_editbox, "BOTTOMRIGHT", -5, 5 )
	edit_box:SetMultiLine( true )
	edit_box:SetMaxLetters( max_letters or 255 )
	edit_box:SetAutoFocus( false )
	edit_box:SetScript( "OnEscapePressed", function( self )
		self:ClearFocus()
	end )

	local last_valid_text = ""

	edit_box:SetScript( "OnTextChanged", function( self )
		last_valid_text = self:GetText()
		if on_text_changed then
			on_text_changed( self )
		end
	end )

	edit_box:SetScript( "OnChar", function( self, char )
		if char == "\n" then
			self:SetText( last_valid_text )
		end
	end )

	---@return string
	frame_editbox.get_text = function()
		return edit_box:GetText()
	end

	frame_editbox.set_text = function( text )
		edit_box:SetText( text )
	end

	frame_editbox.orig_msg = ""

	return frame_editbox
end

---@param parent Frame
---@param title string
---@param bg_index integer
---@param on_click function?
---@return IntroButton
function M.create_intro_button( parent, title, bg_index, on_click )
	---@class IntroButton: Button
	local button = CreateFrame( "Button", nil, parent )
	button:SetWidth( 302 )
	button:SetHeight( 48 )

	local tex_bg = button:CreateTexture( nil, "BACKGROUND" )
	tex_bg:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-buttons]] )
	if bg_index == 1 then
		tex_bg:SetTexCoord( 0, 0.568359375, 0, 0.14453125 )
	elseif bg_index == 2 then
		tex_bg:SetTexCoord( 0, 0.568359375, 0.15234375, 0.296875 )
	elseif bg_index == 3 then
		tex_bg:SetTexCoord( 0, 0.568359375, 0.30078125, 0.4453125 )
	end
	tex_bg:SetWidth( 292 )
	tex_bg:SetHeight( 38 )
	tex_bg:SetPoint( "TOPLEFT", button, "TOPLEFT", 5, -5 )

	local tex_down = button:CreateTexture( nil, "BACKGROUND" )
	tex_down:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-buttons]] )
	tex_down:SetTexCoord( 0, 0.58984375, 0.6328125, 0.8203125 )
	tex_down:SetBlendMode( "ADD" )
	tex_down:SetAllPoints()
	tex_down:Hide()

	local tex_hover = button:CreateTexture( nil, "BACKGROUND" )
	tex_hover:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-buttons]] )
	tex_hover:SetTexCoord( 0, 0.58984375, 0.44921875, 0.6328125 )
	tex_hover:SetBlendMode( "ADD" )
	tex_hover:SetAllPoints()
	tex_hover:Hide()

	local label_title = button:CreateFontString( nil, "ARTWORK", "CSLFGFontIntroButton" )
	label_title:SetPoint( "LEFT", button, "LEFT", 15, 0 )
	label_title:SetAlpha( 0.9 )
	label_title:SetText( title )

	button:SetScript( "OnEnter", function()
		tex_hover:Show()
		label_title:SetAlpha( 1 )
	end )

	button:SetScript( "OnLeave", function()
		tex_hover:Hide()
		label_title:SetAlpha( 0.9 )
	end )

	button:SetScript( "OnMouseDown", function()
		tex_hover:Hide()
		tex_down:Show()

		label_title:SetPoint( "LEFT", button, "LEFT", 17, -2 )
	end )
	button:SetScript( "OnMouseUp", function()
		tex_hover:Show()
		tex_down:Hide()
		label_title:SetPoint( "LEFT", button, "LEFT", 15, 0 )
	end )

	if on_click then
		button:SetScript( "OnClick", on_click )
	end

	return button
end

---@param parent Frame
---@param role Role
---@param options table
---@param on_click function?
function M.create_player_role_button( parent, role, options, on_click )
	local button = M.create_role_button( parent, role )

	if M.find( role, M.classRoles[ M.player_class ] ) then
		if options.dungeonRoles[ role ] then
			button.cb:SetChecked( true )
		end
	else
		button:Disable()
		button.icon:SetDesaturated( true )
		button.cb:Hide()
	end

	button:SetScript( "OnClick", function()
		button.cb:SetChecked( not button.cb:GetChecked() )
		if button.cb:GetChecked() then
			options.dungeonRoles[ role ] = true
		else
			options.dungeonRoles[ role ] = nil
		end

		if on_click then
			on_click()
		end
	end )

	return button
end

---@param parent Frame
---@param role Role
---@return RoleButton
function M.create_role_button( parent, role )
	---@class RoleButton: Button
	local button = CreateFrame( "Button", nil, parent )
	button:SetWidth( 54 )
	button:SetHeight( 54 )
	button:SetHighlightTexture( [[Interface\Buttons\IconBorder-GlowRing]], "ADD" )
	button.role = role

	local cb = CreateFrame( "CheckButton", nil, button, "UICheckButtonTemplate" )
	cb:SetWidth( 24 )
	cb:SetHeight( 24 )
	cb:SetPoint( "BOTTOMLEFT", button, "BOTTOMLEFT", 0, -5 )
	cb:EnableMouse( false )
	button.cb = cb

	local icon = button:CreateTexture( nil, "BORDER" )
	icon:SetAllPoints( button )
	button.icon = icon

	if role == "DPS" then
		icon:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\damage2]] )
		button.tooltip = M.T[ "Indicates that you are willing to take on the role of dealing damage to enemies." ]
	elseif role == "Tank" then
		icon:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\tank2]] )
		button.tooltip = M.T[ "Indicates that you are willing to protect allies from harm by ensuring that enemies are attacking you instead of them." ]
	elseif role == "Healer" then
		icon:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\healer2]] )
		button.tooltip = M.T[ "Indicates that you are willing to heal your allies when they take damage." ]
	end

	button:SetScript( "OnEnter", function( self )
		if not self:IsEnabled() then return end

		self:LockHighlight()
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )
		GameTooltip:SetText( self.tooltip, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, nil, true )
		GameTooltip:Show()
	end )

	button:SetScript( "OnLeave", function( self )
		self:UnlockHighlight()
		GameTooltip:Hide()
	end )

	button.disable = function()
		button:Disable()
		icon:SetDesaturated( true )
		cb:Hide()
	end

	button.enable = function()
		button:Enable()
		icon:SetDesaturated( false )
		cb:Show()
	end

	return button
end

---@param parent Frame
---@param max integer?
---@return StatusBar
function M.create_timer_bar( parent, max )
	local timer = CreateFrame( "StatusBar", nil, parent )
	timer:SetWidth( 250 )
	timer:SetHeight( 10 )
	timer:SetStatusBarTexture( [[Interface\PaperDollInfoFrame\UI-Character-Skills-Bar]] )
	timer:SetStatusBarColor( 1, 1, 0 )
	timer:SetMinMaxValues( 0, max and max or 90 )

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
	return M.colorize_player_class( player[ 1 ], M.Types.PlayerClass[ player[ 2 ] ] )
end

---@param player string
---@param class string
---@return string
function M.colorize_player_class( player, class )
	local color = RAID_CLASS_COLORS[ class ]
	if not color.colorStr then
		color.colorStr = string.format( "ff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255 )
	end

	return string.format( "|c%s%s|r", color.colorStr, player )
end

---@return integer
function M.get_num_group_members()
	if M.isModern then
		return GetNumGroupMembers()
	else
		local num = GetNumPartyMembers()
		return num > 0 and num + 1 or 0
	end
end

---@return boolean
function M.is_grouped()
	return M.get_num_group_members() > 1 and true or false
end

---@param unit UnitToken?
---@return boolean
function M.is_group_leader( unit )
	return UnitIsGroupLeader( unit or "player" ) and true or false
end

---@param dungeon_code string
---@return string, boolean
function M.dungeon_code_hc( dungeon_code )
	local heroic = false

	if strfind( dungeon_code, "hc$" ) then
		dungeon_code = string.sub( dungeon_code, 1, -3 )
		heroic = true
	end

	return dungeon_code, heroic
end

---@param roles Role[]
---@return number
function M.roles_to_bitmask( roles )
	local mask = 0
	if roles[ "DPS" ] then mask = bit.bor( mask, M.Types.Roles.DPS ) end
	if roles[ "Tank" ] then mask = bit.bor( mask, M.Types.Roles.Tank ) end
	if roles[ "Healer" ] then mask = bit.bor( mask, M.Types.Roles.Healer ) end

	return mask
end

---@param mask number
---@return Role[]
function M.bitmask_to_roles( mask )
	local roles = {}
	if bit.band( mask, M.Types.Roles.DPS ) ~= 0 then roles[ #roles+1 ] = "DPS" end
	if bit.band( mask, M.Types.Roles.Tank ) ~= 0 then roles[ #roles+1 ] = "Tank" end
	if bit.band( mask, M.Types.Roles.Healer ) ~= 0 then roles[ #roles+1 ] = "Healer" end

	return roles
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
		if val == value then return i, v end
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

---@param inputstr string
---@param sep string?
---@return table
function M.split( inputstr, sep )
	local t = {}

	if sep == nil then sep = "," end

	for str in string.gmatch( inputstr, "([^" .. sep .. "]+)" ) do
		table.insert( t, str )
	end

	return t
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
