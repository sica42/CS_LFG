CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

---@class LFGPopup
---@field show fun()
---@field hide fun()
---@field toggle fun()
---@field set_lfg fun()
---@field update fun()

---@class GroupEntryButton : Button
---@field bg Texture
---@field title FontString
---@field leader FontString
---@field description FontString
---@field dataIndex integer
---@field data table
---@field DPS_frame RoleFrame
---@field Tank_frame RoleFrame
---@field Healer_frame RoleFrame

---@class GroupInfo
---@field type GroupType
---@field code string
---@field heroic boolean?
---@field raid boolean?
---@field description string?
---@field leader PlayerInfo?
---@field players table<PlayerInfo>

---@class PlayerEntryButton: Button
---@field player FontString
---@field text FontString

---@class PlayerInfo
---@field [1] string  # Name
---@field [2] number  # Class ID
---@field [3] number  # Level


local M = {}

---@param options table
function M.new( options )
	---@type LFGFrame
	local popup

	local dungeonType = options.dungeonType
	local dungeonTypes = { m.T[ "All Available Dungeons" ], m.T[ "Suggested Dungeons" ], m.T[ "Heroic Only" ] }
	local selectedDungeons = {}
	local currentTab = "LFG"
	local currentView = 1

	---@type table<number, DungeonInfo>
	local dungeonsData
	local dungeonEntryFrames = {}
	local dungeonEntryHeight = 21
	local dungeonsDisplayed = 12

	local groupsData = {}
	---@type table<number, GroupEntryButton>
	local groupEntryFrames = {}
	local groupEntryHeight = 55.5
	local groupsDisplayed = 6
	local selectedGroup

	---@type table<number, PlayerEntryButton>
	local playerEntryFrames = {}
	local playerEntryHeight = 42
	local playersDisplayed = 8
	local selectedPlayer

	--local hide

	local function sort_by_level( a, b )
		if a.minLevel == b.minLevel then
			if a.maxLevel == b.maxLevel then
				return a.name < b.name
			end
			return a.maxLevel > b.maxLevel
		end
		return a.minLevel > b.minLevel
	end

	---@param level number
	local function sort_dungeons( level )
		local sorted = {}
		for k, v in pairs( m.dungeons ) do
			--if getn(sorted) >= 14 then break end
			if level >= v.minLevel then
				v.code = k
				if dungeonType ~= 3 then
					if dungeonType == 1 or (level >= v.minLevel and level <= v.maxLevel) then
						tinsert( sorted, v )
					end
				end
				if v.heroic then
					tinsert( sorted, {
						[ "name" ] = "(" .. m.T[ "HC" ] .. ") " .. v.name,
						[ "code" ] = k .. "hc",
						[ "reqLevel" ] = 70,
						[ "minLevel" ] = 70,
						[ "maxLevel" ] = 70
					} )
				end
			end
		end

		sort( sorted, sort_by_level )
		return sorted
	end

	local function get_dungeons()
		local level = UnitLevel( "player" )
		local gcount = m.isModern and GetNumGroupMembers() or GetNumPartyMembers()
		if gcount then
			for i = 1, 4 do
				local unit = "party" .. i
				if UnitIsConnected( unit ) then
					level = min( level, UnitLevel( unit ) )
				end
			end
		end

		dungeonsData = sort_dungeons( level )
	end

	local function update_dungeons()
		for _, frame in pairs( dungeonEntryFrames ) do
			frame:Hide()
			frame.checkButton:SetChecked( false )
		end

		local level = UnitLevel( "player" )
		local gcount = m.isModern and GetNumGroupMembers() or GetNumPartyMembers()
		if gcount then
			for i = 1, 4 do
				local unit = "party" .. i
				if UnitIsConnected( unit ) then
					level = min( level, UnitLevel( unit ) )
				end
			end
		end

		local offset = popup.lfg_scrollbar:GetValue()

		for i = 1, dungeonsDisplayed do
			---@class DungeonEntryFrame
			local entry = dungeonEntryFrames[ i ]
			local dungeonIndex = i + offset
			local dungeon = dungeonsData[ dungeonIndex ]
			if dungeon and dungeon.code then
				if dungeonIndex <= getn( dungeonsData ) then
					entry.name:SetText( dungeon.name )
					entry.levels:SetText( "(" .. dungeon.minLevel .. " - " .. dungeon.maxLevel .. ")" )

					local isSelected = selectedDungeons[ dungeon.code ]
					entry.checkButton:SetChecked( isSelected )
					if m.isQueued then
						entry.checkButton:Disable()
						entry:SetAlpha( 0.5 )
					else
						entry.checkButton:Enable()
						entry:SetAlpha( 1 )
					end

					local r, g, b = m.get_dungeon_color( dungeon, level )
					entry.name:SetTextColor( r, g, b )
					entry.levels:SetTextColor( r, g, b )
					entry.highlight:SetVertexColor( r, g, b, 0.7 )
					entry.r, entry.g, entry.b = r, g, b
					entry.instance = dungeon.code

					entry:Show()
				else
					entry:Hide()
				end
			end
		end

		popup.lfg_scrollbar.set_max_value( getn( dungeonsData ) - dungeonsDisplayed )
		popup.lfg_scrollbar.set_value( offset )
	end

	local function sort_groups( level )
		local sorted = {}
		for _, group in pairs( groupsData ) do
			local dungeon = m.dungeons[ group.code ]
			if level >= dungeon.minLevel then
				if group.heroic then
					group.minLevel = 70
					group.maxLevel = 70
					group.name = "(Heroic) " .. dungeon.name
				else
					group.minLevel = dungeon.minLevel
					group.maxLevel = dungeon.maxLevel
					group.name = dungeon.name
				end
				tinsert( sorted, group )
			end
		end

		sort( sorted, sort_by_level )
		return sorted
	end

	local function get_groups()
		m.debug( "get_groups" )

		---@type table<number, GroupInfo>
		groupsData = {
			{
				type = m.Types.GroupTypes.LFG,
				code = "dm",
				description = "",
				players = {
					[ m.Types.Roles.DPS ] = { { "Sica", 2, 70 }, { "Marina", 3, 66 } },
					[ m.Types.Roles.Healer ] = { { "Borazor", 7, 70 } },
					[ m.Types.Roles.Tank ] = { { "Lynn", 4, 70 } }
				}
			},
			{
				type = m.Types.GroupTypes.LFG,
				code = "zf",
				description = "",
				players = {
					[ m.Types.Roles.DPS ] = { { "Sica", 2, 70 }, { "Marina", 3, 66 } },
					[ m.Types.Roles.Healer ] = { { "Borazor", 7, 70 }, { "Kyrisha", 5, 70 } },
				}
			},
			{
				type = m.Types.GroupTypes.LFM,
				code = "dm",
				description = "This is a test descriptions. Lets see how much text I can put here before things get up. bla bla bla to much text we don't want!",
				leader = { "Sica", 2, 70 },
				players = {
					[ m.Types.Roles.DPS ] = { { "Sica", 2, 70 }, { "Marina", 3, 66 } },
					[ m.Types.Roles.Healer ] = { { "Borazor", 7, 70 } },
				}
			},
			{
				type = m.Types.GroupTypes.LFM,
				code = "bm",
				leader = { "Sica", 2, 70 },
				heroic = true,
				players = {
					[ m.Types.Roles.DPS ] = { { "Sica", 2, 70 }, { "Marina", 3, 66 }, { "Muttekalf", 7, 70 } },
					[ m.Types.Roles.Healer ] = { { "Borazor", 7, 70 } },
				}
			},
			{
				type = m.Types.GroupTypes.LFM,
				code = "mara",
				leader = { "Lynn", 4, 70 },
				players = {
					[ m.Types.Roles.Tank ] = { { "Lynn", 4, 70 } },
					[ m.Types.Roles.DPS ] = { { "Sica", 2, 70 } }
				}
			},
			{
				type = m.Types.GroupTypes.LFM,
				code = "bfd",
				leader = { "Lynn", 4, 70 },
				players = {
					[ m.Types.Roles.Tank ] = { { "Lynn", 4, 70 } },
					[ m.Types.Roles.DPS ] = { { "Sica", 2, 70 } }
				}
			},
			{
				type = m.Types.GroupTypes.LFM,
				code = "rfd",
				leader = { "Lynn", 4, 70 },
				players = {
					[ m.Types.Roles.Tank ] = { { "Lynn", 4, 70 } },
					[ m.Types.Roles.DPS ] = { { "Sica", 2, 70 } }
				}
			}
		}

		groupsData = sort_groups( m.player_level )
	end

	local function build_groups_data()
		groupsData = {}
		for _, player in pairs( m.lfg_list ) do
			if player.lfg then
				if next( player.dungeons ) and next( player.roles ) then
					for _, player_dungeon in pairs( player.dungeons ) do
						local code = player_dungeon
						local heroic = false
						if strfind( code, "hc$" ) then
							code = string.sub( code, 1, -3 )
							heroic = true
						end

						local dungeon, dIndex = m.find( code, groupsData, "code" )
						if dungeon and dungeon.heroic ~= heroic then dungeon = nil end

						if not dungeon then
							groupsData[ #groupsData + 1 ] = {
								type = m.Types.GroupTypes.LFG,
								code = code,
								heroic = heroic,
								players = {}
							}
							dungeon = groupsData[ #groupsData ]
							dIndex = #groupsData
						end

						for _, role in pairs( player.roles ) do
							if not dungeon.players[ role ] then dungeon.players[ role ] = {} end
							table.insert( groupsData[ dIndex ].players[ role ], player.player )
						end
					end
				end
			elseif player.lfm then
			end
		end

		m.groupsData = groupsData

		groupsData = sort_groups( m.player_level )
	end

	local function update_groups()
		m.debug("update_groups")
		for _, frame in pairs( groupEntryFrames ) do
			frame:Hide()
		end

		local offset = popup.search_scrollbar:GetValue()

		for i = 1, groupsDisplayed do
			local entry = groupEntryFrames[ i ]
			local index = i + offset

			local data = groupsData[ index ]
			if data and index <= getn( groupsData ) then
				local dungeon = m.dungeons[ data.code ]
				local r, g, b = m.get_dungeon_color( dungeon, m.player_level, data.heroic )
				local title = data.heroic and (dungeon.name .. " (Heroic)") or dungeon.name

				entry.title:SetText( title )
				entry.title:SetWidth( 200 )
				entry.title:SetTextColor( r, g, b )
				entry.title:SetWidth( entry.title:GetStringWidth() + 5 )
				entry.bg:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\background\]] .. (dungeon.background or "") )

				if data.type == m.Types.GroupTypes.LFG then
					entry.leader:SetText( "" )
					entry.description:SetText( "" )

					for role in pairs( m.Types.Roles ) do
						local count = data.players[ role ] and getn( data.players[ role ] ) or 0
						entry[ role .. "_frame" ].number:SetText( tostring( count ) )
					end
				elseif data.type == m.Types.GroupTypes.LFM then
					entry.leader:SetText( m.T[ "Lead by " ] .. m.player_to_colorized_string( data.leader ) )
					entry.description:SetText( data.description or "" )

					for role in pairs( m.Types.Roles ) do
						local count = data.players[ role ] and getn( data.players[ role ] ) or 0
						local max = role == m.Types.Roles.DPS and 3 or 1
						entry[ role .. "_frame" ].number:SetText( tostring( count ) .. "/" .. tostring( max ) )
					end
				end
				entry.data = data
				entry.dataIndex = index
				entry:Show()
			else
				entry:Hide()
			end
		end

		popup.search_scrollbar.set_max_value( getn( groupsData ) - groupsDisplayed )
		popup.search_scrollbar.set_value( offset )
	end

	local function update_players()
		m.debug("update_groups")
		for _, frame in pairs( playerEntryFrames ) do
			frame:Hide()
		end

		local offset = popup.search_scrollbar:GetValue()

		if getn( m.lfg_list ) == 0 then
			popup.empty:Show()
		else
			popup.empty:Hide()

			for i = 1, playersDisplayed do
				local entry = playerEntryFrames[ i ]
				local index = i + offset

				local data = m.lfg_list[ index ]

				if data and index <= getn( m.lfg_list ) then
					entry.player:SetText( string.format( "%s (%d %s)",
						m.player_to_colorized_string( data.player ),
						data.player[ 3 ],
						m.capitalize( m.Types.PlayerClass[ data.player[ 2 ] ] ) )
					)

					entry.text:SetText( data.message )
					entry:Show()
				else
					entry:Hide()
				end
			end
		end

		popup.search_scrollbar.set_max_value( getn( m.lfg_list ) - playersDisplayed )
		popup.search_scrollbar.set_value( offset )
	end

	local function update_list()
		if currentView == 1 then
			if groupEntryFrames[ 1 ]:IsVisible() then
				for _, frame in pairs( groupEntryFrames ) do
					frame:Hide()
				end
			end
			update_players()
		else
			if playerEntryFrames[ 1 ]:IsVisible() then
				for _, frame in pairs( playerEntryFrames ) do
					frame:Hide()
				end
			end
			--if getn(groupsData) == 0 then
			build_groups_data()
			--end
			update_groups()
		end
	end

	local function update_status()
		m.debug( "update_status" )
		if currentTab == "Browse" then
			if selectedGroup and groupsData[ selectedGroup ].type == m.Types.GroupTypes.LFM then
				for role in pairs( m.Types.Roles ) do
					local max = role == m.Types.Roles.DPS and 3 or 1
					local count = groupsData[ selectedGroup ].players[ role ] and getn( groupsData[ selectedGroup ].players[ role ] ) or 0

					if m.find( m.Types.Roles[ role ], m.classRoles[ m.player_class ] ) and count < max then
						popup[ "btn_join_" .. string.lower( role ) ]:Enable()
					else
						popup[ "btn_join_" .. string.lower( role ) ]:Disable()
					end
				end
			else
				popup[ "btn_join_dps" ]:Disable()
				popup[ "btn_join_tank" ]:Disable()
				popup[ "btn_join_healer" ]:Disable()
			end
		elseif currentTab == "LFG" then
			local dCount = m.count( selectedDungeons )
			local rCount = m.count( options.dungeonRoles )

			if popup then
				if dCount > 0 and rCount > 0 then
					popup.btn_find:Enable()
				else
					popup.btn_find:Disable()
				end
			end
		end
	end

	local function btn_find_on_click( self )
		if m.isQueued then
			m.message_handler.lfg_remove()
		else
			local msg = ""
			for role in pairs( options.dungeonRoles ) do
				msg = msg .. (msg ~= "" and "/" or "") .. role
			end

			msg = msg .. " LFG "

			local count = 0
			for dungeon in pairs( selectedDungeons ) do
				msg = msg .. (count > 0 and "/" or "") .. string.upper( dungeon )

				count = count + 1
			end

			m.message_handler.lfg_add( msg )
		end
	end

	local function btn_view_on_click( self )
		currentView = currentView == 1 and 2 or 1
		update_list()
	end

	local function dd_dungeon_type_init( self )
		local info = {
			notCheckable = true,
			text = "",
			value = "",
			func = function( selected )
				if m.isModern then
					dungeonType = selected.value
					UIDropDownMenu_SetText( self, dungeonTypes[ dungeonType ] )
				else
					dungeonType = selected
					UIDropDownMenu_SetText( dungeonTypes[ dungeonType ], popup.dropdown_dungeon_type )
				end
				m.db.options.dungeonType = dungeonType
				get_dungeons()
				update_dungeons()
			end
		}

		local c = m.player_level == 70 and 3 or 2
		for i = 1, c do
			info.text = dungeonTypes[ i ]
			info.value = i
			info.arg1 = i
			UIDropDownMenu_AddButton( info )
		end
	end

	---@param self EditBox
	local function handle_lvl_text_changed( self )
		local num = tonumber( self:GetText() )

		if num and num > 0 and num < 71 then
			self:SetTextColor( 1, 1, 1, 1 )
		else
			self:SetTextColor( 1, 0, 0, 1 )
		end
	end

	---@param self EditBox
	local function handle_lvl_enter_pressed( self )
		local num = tonumber( self:GetText() )

		if num and num > 0 and num < 71 then
			local name = self:GetName()
			if name == "CSLFGMinLevel" then
				options.lvlmin = num
			else
				options.lvlmax = num
			end
			self:ClearFocus()
			m.message_handler.lfg_list( options.lvlmin, options.lvlmax )
		end
	end

	local function on_role_enter( self, role )
		local data = self:GetParent().data
		if data.players[ role ] then
			local tooltip = ""

			for _, p in pairs( data.players[ role ] ) do
				tooltip = tooltip ..
						string.format( "%s %d %s\n", m.player_to_colorized_string( p ), p[ 3 ], m.capitalize( m.Types.PlayerClass[ p[ 2 ] ] ) )
			end

			GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )
			GameTooltip:SetText( tooltip, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, nil, false )
			GameTooltip:Show()
		end
	end

	local function on_role_leave( self )
		GameTooltip:Hide()
	end

	---@param parent Frame
	---@return DungeonEntryFrame
	local function create_dungeon_entry( parent )
		---@class DungeonEntryFrame: Frame
		local frame = CreateFrame( "Frame", nil, parent )
		frame:SetWidth( 293 )
		frame:SetHeight( 21 )

		local highlight = frame:CreateTexture( nil, "BACKGROUND" )
		highlight:SetAllPoints()
		highlight:SetTexture( [[Interface\Buttons\UI-Listbox-Highlight2]] )
		highlight:Hide()
		frame.highlight = highlight

		local name = frame:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
		name:SetJustifyH( "LEFT" )
		name:SetWidth( 200 )
		name:SetHeight( 24 )
		name:SetPoint( "LEFT", frame, "LEFT", 20, 0 )
		frame.name = name

		local levels = frame:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
		levels:SetWidth( 72 )
		levels:SetHeight( 24 )
		levels:SetPoint( "RIGHT", frame, "RIGHT", -6, 0 )
		frame.levels = levels

		local cb = CreateFrame( "CheckButton", nil, frame, "UICheckButtonTemplate" )
		cb:SetWidth( 20 )
		cb:SetHeight( 20 )
		cb:SetPoint( "TOPLEFT", frame, "TOPLEFT", 0, 0 )
		cb:SetHitRectInsets( 0, -280, 0, 0 )
		frame.checkButton = cb

		cb:SetScript( "OnClick", function( self )
			if self:GetChecked() then
				selectedDungeons[ frame.instance ] = true
			else
				selectedDungeons[ frame.instance ] = nil
			end
			update_status()
		end )

		cb:SetScript( "OnEnter", function( self )
			frame.highlight:Show()
			frame.name:SetTextColor( 1, 1, 1 )
			frame.levels:SetTextColor( 1, 1, 1 )
		end )

		cb:SetScript( "OnLeave", function( self )
			frame.highlight:Hide()
			frame.name:SetTextColor( frame.r, frame.g, frame.b )
			frame.levels:SetTextColor( frame.r, frame.g, frame.b )
		end )

		tinsert( dungeonEntryFrames, frame )
		return frame
	end

	---@param parent Frame
	---@return GroupEntryButton
	local function create_group_entry( parent )
		---@type GroupEntryButton
		local frame = CreateFrame( "Button", nil, parent )
		frame:SetWidth( 300 )
		frame:SetHeight( groupEntryHeight - 1 )
		frame:SetHighlightTexture( [[Interface\QuestFrame\UI-QuestTitleHighlight]], "ADD" )
		frame:Hide()

		local bg = frame:CreateTexture( nil, "BACKGROUND" )
		bg:SetAllPoints()
		bg:SetTexCoord( 0, 1, 0.1, 0.46333333 )
		frame.bg = bg

		local title = frame:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
		title:SetJustifyH( "LEFT" )
		title:SetWidth( 200 )
		title:SetHeight( 22 )
		title:SetPoint( "TOPLEFT", frame, "TOPLEFT", 5, 2 )
		frame.title = title

		local leader = frame:CreateFontString( nil, "OVERLAY", "GameFontHighlight" )
		leader:SetJustifyH( "LEFT" )
		leader:SetWidth( 132 )
		leader:SetHeight( 22 )
		leader:SetPoint( "LEFT", title, "RIGHT", 5, 0 )
		frame.leader = leader

		local desc = frame:CreateFontString( nil, "OVERLAY", "GameFontNormalSmall" )
		desc:SetJustifyH( "LEFT" )
		desc:SetJustifyV( "TOP" )
		desc:SetWidth( 290 )
		desc:SetHeight( 25 )
		desc:SetPoint( "TOPLEFT", frame, "TOPLEFT", 5, -18 )
		frame.description = desc

		for role in pairs( m.Types.Roles ) do
			---@class RoleFrame: Frame
			local f = CreateFrame( "Frame", nil, frame )
			f:SetHeight( 12 )
			f:SetWidth( 40 )
			f:EnableMouse( true )

			f.icon = f:CreateTexture( nil, "ARTWORK" )
			f.icon:SetWidth( 12 )
			f.icon:SetHeight( 12 )
			f.icon:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ready_]] .. string.lower( role ) )
			f.icon:SetPoint( "LEFT", f, "LEFT", 0, 0 )

			f.number = f:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
			f.number:SetHeight( 24 )
			f.number:SetPoint( "LEFT", f.icon, "RIGHT", 3, 0 )

			f:SetScript( "OnEnter", function( self )
				on_role_enter( self, role )
			end )

			f:SetScript( "OnLeave", function( self )
				on_role_leave( self )
			end )

			frame[ role .. "_frame" ] = f
		end

		frame.DPS_frame:SetPoint( "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 1 )
		frame.Healer_frame:SetPoint( "RIGHT", frame[ "DPS_frame" ], "LEFT", 0, 0 )
		frame.Tank_frame:SetPoint( "RIGHT", frame[ "Healer_frame" ], "LEFT", 0, 0 )

		frame:SetScript( "OnClick", function( self )
			if selectedGroup and selectedGroup == self.dataIndex then
				selectedGroup = nil
				self:UnlockHighlight()
			else
				for i = 1, groupsDisplayed do
					local entry = groupEntryFrames[ i ]
					entry:UnlockHighlight()
				end
				selectedGroup = self.dataIndex
				self:LockHighlight()
			end

			update_status()
		end )

		tinsert( groupEntryFrames, frame )
		return frame
	end

	---@param parent Frame
	---@return PlayerEntryButton
	local function create_player_entry( parent )
		---@type PlayerEntryButton
		local frame = CreateFrame( "Button", nil, parent )
		frame:SetWidth( 300 )
		frame:SetHeight( playerEntryHeight - 1 )
		frame:SetHighlightTexture( [[Interface\QuestFrame\UI-QuestTitleHighlight]], "ADD" )
		frame:Hide()

		local player = frame:CreateFontString( nil, "OVERLAY", "GameFontNormal" )
		player:SetJustifyH( "LEFT" )
		player:SetJustifyV( "TOP" )
		player:SetWidth( 280 )
		player:SetHeight( 24 )
		player:SetPoint( "LEFT", frame, "LEFT", 20, 6 )
		frame.player = player

		local text = frame:CreateFontString( nil, "OVERLAY", "GameFontHighlightSmall" )
		text:SetJustifyH( "LEFT" )
		text:SetJustifyV( "MIDDLE" )
		text:SetWidth( 280 )
		text:SetHeight( 30 )
		text:SetPoint( "LEFT", frame, "LEFT", 20, -6 )
		frame.text = text

		tinsert( playerEntryFrames, frame )
		return frame
	end

	local function create_frame()
		-- ##########################################
		-- Main Frame
		-- ##########################################
		---@class LFGFrame: Frame
		local frame = CreateFrame( "Frame", "CSLFGPopup", UIParent )
		frame:SetWidth( 384 )
		frame:SetHeight( 512 )
		frame:EnableMouse( true )
		frame:SetMovable( true )
		frame:RegisterForDrag( "LeftButton" )
		frame:SetPoint( "CENTER", UIParent, "CENTER", 0, 0 )
		tinsert( UISpecialFrames, frame:GetName() )

		frame:SetScript( "OnDragStart", function( self )
			if not self:IsMovable() then return end
			self:StartMoving()
		end )

		frame:SetScript( "OnDragStop", function( self )
			if not self:IsMovable() then return end
			self:StopMovingOrSizing()
		end )

		frame:SetScript( "OnHide", function()
			m.hide_lfg_messages = 0
		end )

		local portrait = frame:CreateTexture( nil, "BACKGROUND" )
		portrait:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-lfg-portrait]] )
		portrait:SetWidth( 64 )
		portrait:SetHeight( 64 )
		portrait:SetPoint( "TOPLEFT", frame, "TOPLEFT", 12, -6 )

		local btnClose = CreateFrame( "Button", nil, frame, "UIPanelCloseButton" )
		btnClose:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", -27, -8 )

		-- ##########################################
		-- LFG Frame
		-- ##########################################
		---@class Frame
		local frame_lfg = CreateFrame( "Frame", nil, frame )
		frame_lfg:SetAllPoints( frame )

		local title = frame_lfg:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		title:SetPoint( "TOP", frame_lfg, "TOP", 0, -18 )
		title:SetText( m.T[ 'Group Finder' ] )

		local bgwall = frame_lfg:CreateTexture( nil, "BACKGROUND" )
		bgwall:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-lfg-background-dungeonwall]] )
		bgwall:SetWidth( 512 )
		bgwall:SetHeight( 256 )
		bgwall:SetPoint( "TOP", frame_lfg, "TOP", 85, -155 )

		local bgframe = frame_lfg:CreateTexture( nil, "ARTWORK" )
		bgframe:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-lfg-frame]] )
		bgframe:SetWidth( 512 )
		bgframe:SetHeight( 512 )
		bgframe:SetPoint( "TOPLEFT", frame_lfg, "TOPLEFT", 0, 0 )

		local btn_find = CreateFrame( "Button", nil, frame_lfg, "UIPanelButtonTemplate" )
		btn_find:SetWidth( 109 )
		btn_find:SetHeight( 21 )
		btn_find:SetPoint( "BOTTOM", frame_lfg, "BOTTOM", -9, 80 )
		btn_find:SetText( m.T[ "Find Group" ] )
		btn_find:Disable()
		btn_find:SetScript( "OnClick", btn_find_on_click )
		frame.btn_find = btn_find

		local role1 = m.create_role_button( frame_lfg, m.Types.Roles.DPS, options, update_status )
		role1:SetPoint( "TOPLEFT", frame_lfg, "TOPLEFT", 74, -52 )

		local role2 = m.create_role_button( frame_lfg, m.Types.Roles.Tank, options, update_status )
		role2:SetPoint( "LEFT", role1, "RIGHT", 44, 0 )

		local role3 = m.create_role_button( frame_lfg, m.Types.Roles.Healer, options, update_status )
		role3:SetPoint( "LEFT", role2, "RIGHT", 44, 0 )



		-- ##########################################
		-- Dungeon Type Dropdown
		local dd = CreateFrame( "Button", "CSLFGDungeonTypeDropDown", frame_lfg, "UIDropDownMenuTemplate" )
		dd:SetPoint( "TOPRIGHT", frame_lfg, "TOPRIGHT", -24, -125 )
		if m.isModern then
			UIDropDownMenu_SetWidth( dd, 150 )
			UIDropDownMenu_SetText( dd, dungeonTypes[ dungeonType ] )
		else
			UIDropDownMenu_SetWidth( 150, dd )
			UIDropDownMenu_SetText( dungeonTypes[ dungeonType ], dd )
		end
		UIDropDownMenu_Initialize( dd, dd_dungeon_type_init )
		frame.dropdown_dungeon_type = dd

		local dd_label = frame_lfg:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		dd_label:SetPoint( "RIGHT", dd, "LEFT", 10, 1 )
		dd_label:SetText( m.T[ "Type:" ] )

		-- ##########################################
		-- Dungeons ScrollFrame
		local scroll_frame = m.create_scroll_bar( frame_lfg, "CSLFGScrollBar", 317, 252, function()
			update_dungeons()
		end )
		scroll_frame:SetPoint( "TOPLEFT", frame_lfg, "TOPLEFT", 25, -158 )
		scroll_frame.set_mousewheel_step( 5 )
		frame.lfg_scrollbar = scroll_frame.scroll_bar

		-- ##########################################
		-- Dungeon Entries
		for i = 1, dungeonsDisplayed do
			local entry = create_dungeon_entry( frame_lfg )
			entry:SetPoint( "TOPLEFT", frame_lfg, "TOPLEFT", 25, -dungeonEntryHeight * (i - 1) - 157 )
		end

		-- ##########################################
		-- Search Frame
		-- ##########################################
		---@class Frame
		local frame_search = CreateFrame( "Frame", nil, frame )
		frame_search:SetAllPoints( frame )
		frame_search:Hide()

		title = frame_search:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		title:SetPoint( "TOP", frame_search, "TOP", 0, -18 )
		title:SetText( m.T[ 'Search Groups' ] )

		bgframe = frame_search:CreateTexture( nil, "ARTWORK" )
		bgframe:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-lfm-frame]] )
		bgframe:SetWidth( 512 )
		bgframe:SetHeight( 512 )
		bgframe:SetPoint( "TOPLEFT", frame_search, "TOPLEFT", 0, 0 )

		local label_level = frame_search:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		label_level:SetPoint( "TOPLEFT", frame_search, "TOPLEFT", 80, -48 )
		label_level:SetText( "Level" )

		local edit_min = CreateFrame( "EditBox", "CSLFGMinLevel", frame_search, "InputBoxTemplate" )
		edit_min:SetPoint( "TOPLEFT", frame_search, "TOPLEFT", 120, -43 )
		edit_min:SetWidth( 20 )
		edit_min:SetHeight( 20 )
		edit_min:SetAutoFocus( false )
		edit_min:SetText( tostring( options.lvlmin ) )
		edit_min:SetScript( "OnTextChanged", handle_lvl_text_changed )
		edit_min:SetScript( "OnEnterPressed", handle_lvl_enter_pressed )

		local label_dash = frame_search:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		label_dash:SetPoint( "TOPLEFT", frame_search, "TOPLEFT", 143, -48 )
		label_dash:SetText( "-" )

		local edit_max = CreateFrame( "EditBox", "CSLFGMaxLevel", frame_search, "InputBoxTemplate" )
		edit_max:SetPoint( "TOPLEFT", frame_search, "TOPLEFT", 156, -43 )
		edit_max:SetWidth( 20 )
		edit_max:SetHeight( 20 )
		edit_max:SetAutoFocus( false )
		edit_max:SetText( tostring( options.lvlmax ) )
		edit_max:SetScript( "OnTextChanged", handle_lvl_text_changed )
		edit_max:SetScript( "OnEnterPressed", handle_lvl_enter_pressed )

		local btn_view = CreateFrame( "Button", nil, frame_search, "UIPanelButtonTemplate" )
		btn_view:SetPoint( "TOPRIGHT", frame_search, "TOPRIGHT", -40, -44 )
		btn_view:SetWidth( 80 )
		btn_view:SetHeight( 21 )
		btn_view:SetText( m.T[ "Change view" ] )
		btn_view:SetScript( "OnClick", btn_view_on_click )
		--[[
		local cb = CreateFrame( "CheckButton", "CSLFG_cb_search_group", frame_search, "UICheckButtonTemplate" )
		cb:SetPoint( "TOPLEFT", frame_search, "TOPLEFT", 260, -40 )
		local cbText = _G[ "CSLFG_cb_search_groupText" ]
		cbText:SetText( m.T[ "Groups only" ] )
]]
		-- ##########################################
		-- Groups ScrollFrame
		scroll_frame = m.create_scroll_bar( frame_search, "CSLFGSearchScrollBar", 317, 333, function()
			update_list()
		end )
		scroll_frame:SetPoint( "TOPLEFT", frame_search, "TOPLEFT", 25, -76 )
		frame.search_scrollbar = scroll_frame.scroll_bar

		-- ##########################################
		-- Group Entries
		for i = 1, groupsDisplayed do
			local entry = create_group_entry( frame_search )
			entry:SetPoint( "TOPLEFT", frame_lfg, "TOPLEFT", 25, -groupEntryHeight * (i - 1) - 76 )
		end

		-- ##########################################
		-- Player Entries
		for i = 1, playersDisplayed do
			local entry = create_player_entry( frame_search )
			entry:SetPoint( "TOPLEFT", frame_lfg, "TOPLEFT", 25, -playerEntryHeight * (i - 1) - 75 )
		end

		-- Empty message
		local empty = frame_search:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		empty:SetPoint( "CENTER", frame_lfg, "CENTER", -10, 20 )
		empty:SetText( m.T[ 'No players are currently Looking for Group' ] )
		empty:Hide()
		frame.empty = empty


		-- Buttons
		for role in pairs( m.Types.Roles ) do
			local btn = CreateFrame( "Button", nil, frame_search, "UIPanelButtonTemplate" )
			btn:SetWidth( 109 )
			btn:SetHeight( 21 )
			btn:SetText( m.T[ "Join as " ] .. role )
			btn:Disable()
			btn:SetScript( "OnClick", function()

			end )

			frame[ "btn_join_" .. string.lower( role ) ] = btn
		end

		frame[ "btn_join_dps" ]:SetPoint( "BOTTOM", frame_lfg, "BOTTOM", -118, 80 )
		frame[ "btn_join_tank" ]:SetPoint( "BOTTOM", frame_lfg, "BOTTOM", -9, 80 )
		frame[ "btn_join_healer" ]:SetPoint( "BOTTOM", frame_lfg, "BOTTOM", 100, 80 )


		btnClose:SetFrameLevel( frame_lfg:GetFrameLevel() + 1 )
		-- ##########################################
		-- Tabs
		-- ##########################################
		local tab1 = CreateFrame( "Button", "CSLFGPopupTab1", frame, "CharacterFrameTabButtonTemplate" )
		tab1:SetID( 1 )
		tab1:SetPoint( "BOTTOMLEFT", frame, "BOTTOMLEFT", 13, 42 )
		tab1:SetText( m.T[ "Dungeons" ] )
		tab1:SetScript( "OnClick", function()
			currentTab = "LFG"
			frame_search:Hide()
			frame_lfg:Show()
			PanelTemplates_SetTab( frame, 1 )
			m.play_sound( "igCharacterInfoTab" )
		end )

		if m.isModern then
			PanelTemplates_TabResize( tab1, 5, 100 )
		else
			PanelTemplates_TabResize( 5, tab1, 100 )
		end

		local tab2 = CreateFrame( "Button", "CSLFGPopupTab2", frame, "CharacterFrameTabButtonTemplate" )
		tab2:SetID( 2 )
		tab2:SetPoint( "LEFT", tab1, "RIGHT", -17, 0 )
		tab2:SetText( m.T[ "Browse" ] )
		tab2:SetScript( "OnClick", function()
			currentTab = "Browse"
			frame_lfg:Hide()
			frame_search:Show()
			m.message_handler.lfg_list( options.lvlmin, options.lvlmax )

			PanelTemplates_SetTab( frame, 2 )
			m.play_sound( "igCharacterInfoTab" )
		end )

		if m.isModern then
			PanelTemplates_TabResize( tab2, 5, 100 )
		else
			PanelTemplates_TabResize( 5, tab2, 100 )
		end

		PanelTemplates_SetNumTabs( frame, 2 )
		PanelTemplates_SetTab( frame, 1 )

		return frame
	end

	local function set_lfg()
		if popup then
			if m.isQueued then
				popup.btn_find:SetText( m.T[ "Leave Queue" ] )
			else
				popup.btn_find:SetText( m.T[ "Find Group" ] )
			end

			if popup:IsVisible() then
				update_dungeons()
				update_status()
			end
		end
	end

	local function check_lfg_status()
		if not next( selectedDungeons ) then
			for _, entry in pairs( m.lfg_list ) do
				if entry.player[ 1 ] == m.player_name then
					for _, dungeon in pairs( entry.dungeons ) do
						selectedDungeons[ dungeon ] = true
					end
					set_lfg()
					break
				end
			end
		end
	end

	local function show()
		if not popup then
			popup = create_frame()
		end

		get_dungeons()
		check_lfg_status()
		--get_groups()
		update_dungeons()
		m.hide_lfg_messages = 1
		popup:Show()
	end

	local function hide()
		if popup then
			popup:Hide()
		end
	end

	local function toggle()
		if popup and popup:IsVisible() then
			hide()
		else
			show()
		end
	end

	local function update()
		if popup and popup:IsVisible() then
			update_list()
		end
	end

	---@type LFGPopup
	return {
		show = show,
		hide = hide,
		toggle = toggle,
		set_lfg = set_lfg,
		update = update
	}
end

m.LFGPopup = M
return M
