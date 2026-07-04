CSLFG = CSLFG or {}

---@class CSLFG
local m = CSLFG

---@class LFGPopup
---@field show fun()
---@field hide fun()
---@field toggle fun()
---@field is_visible fun(): boolean
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
---@field player_name string
---@field text FontString

---@class PlayerInfo
---@field [1] string Name
---@field [2] number Class ID
---@field [3] number Level

local Types = m.Types

local M = {}

---@param options table
function M.new( options )
	---@type LFGFrame
	local popup

	local dungeonType = options.dungeonType
	local dungeonTypes = { m.T[ "All Available Dungeons" ], m.T[ "Suggested Dungeons" ], m.T[ "Heroic Only" ] }
	local selectedDungeons = m.selectedDungeons
	local selectDungeonLimit = 5
	local currentTab = Types.Tab.LFG
	local browseTypes = { m.T[ "Show all" ], m.T[ "Dungeons only" ], m.T[ "Groups only" ] }
	local currentBrowseView = 1

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
			if level >= v.minLevel then
				v.code = k
				if dungeonType ~= 3 then
					if dungeonType == 1 or (level >= v.minLevel and level <= v.maxLevel) then
						tinsert( sorted, v )
					end
				end
				if v.heroic and level >= 70 then
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
		if m.isGrouped then
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
		local gcount = m.get_num_group_members()
		if gcount then
			for i = 1, 4 do
				local unit = "party" .. i
				if UnitIsConnected( unit ) then
					level = min( level, UnitLevel( unit ) )
				end
			end
		end

		local offset = popup.lfg_dungeons_scrollbar:GetValue()

		for i = 1, dungeonsDisplayed do
			---@class DungeonEntryFrame
			local entry = dungeonEntryFrames[ i ]
			local dungeonIndex = i + offset
			local dungeon = dungeonsData[ dungeonIndex ]
			if dungeon and dungeon.code then
				if dungeonIndex <= #dungeonsData then
					entry.name:SetText( dungeon.name )
					entry.levels:SetText( "(" .. dungeon.minLevel .. " - " .. dungeon.maxLevel .. ")" )

					local isSelected = selectedDungeons[ dungeon.code ]
					entry.checkButton:SetChecked( isSelected )
					if m.isQueued or (not entry.checkButton:GetChecked() and m.count( selectedDungeons ) == selectDungeonLimit) then
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

		popup.lfg_dungeons_scrollbar.set_max_value( #dungeonsData - dungeonsDisplayed )
		popup.lfg_dungeons_scrollbar.set_value( offset )
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

	---@param groupType GroupType
	local function build_groups_data( groupType )
		groupsData = {}

		for _, entry in pairs( m.lfg_list ) do
			if entry.lfg and groupType == m.Types.GroupTypes.LFG then
				if next( entry.dungeons ) and next( entry.roles ) then
					for _, dungeon_code in pairs( entry.dungeons ) do
						local code, heroic = m.dungeon_code_hc( dungeon_code )
						local dIndex, groupData

						for i, d in pairs( groupsData ) do
							if d.code == code and d.heroic == heroic then
								dIndex = i
								groupData = d
							end
						end
						--local dIndex, dungeon = m.find( code, groupsData, "code" )
						--if dungeon and dungeon.heroic ~= heroic then dungeon = nil end


						if not groupData then
							groupsData[ #groupsData + 1 ] = {
								type = Types.GroupTypes.LFG,
								code = code,
								heroic = heroic,
								players = {}
							}
							groupData = groupsData[ #groupsData ]
							dIndex = #groupsData
						end

						for _, role in pairs( entry.roles ) do
							if not groupData.players[ role ] then groupData.players[ role ] = {} end
							table.insert( groupData.players[ role ], CopyTable( entry.player ) )
							--table.insert( groupsData[ dIndex ].players[ role ], CopyTable( entry.player ) )
						end
					end
				end
			elseif entry.lfm and groupType == m.Types.GroupTypes.LFM then
				if next( entry.dungeons ) and next( entry.roles ) and next( entry.members ) then
					--					local code = entry.dungeons[ 1 ]
					--local heroic = false
					--if strfind( code, "hc$" ) then
					--						code = string.sub( code, 1, -3 )
					--heroic = true
					--end

					local code, heroic = m.dungeon_code_hc( entry.dungeons[ 1 ] )
					local groupData = {
						type = Types.GroupTypes.LFM,
						code = code,
						heroic = heroic,
						description = entry.message,
						leader = CopyTable( entry.player ),
						players = {}
					}

					for _, role in pairs( entry.roles ) do
						if not groupData.players[ role ] then groupData.players[ role ] = {} end
						table.insert( groupData.players[ role ], CopyTable( entry.player ) )
					end

					for _, member in pairs( entry.members ) do
						for _, role in pairs( member.roles ) do
							if not groupData.players[ role ] then groupData.players[ role ] = {} end
							table.insert( groupData.players[ role ], CopyTable( member.player ) )
						end
					end

					groupsData[ #groupsData + 1 ] = groupData
				end
			end
		end

		groupsData = sort_groups( m.player_level )
	end

	local function update_groups()
		m.debug( "update_groups" )
		for _, frame in pairs( groupEntryFrames ) do
			frame:Hide()
		end

		local offset = popup.search_scrollbar:GetValue()

		if #groupsData == 0 then
			if #m.lfg_list == 0 then
				popup.empty:SetText( m.T[ 'No players are currently Looking for Group' ] )
			else
				if currentBrowseView == 2 then
					popup.empty:SetText( string.format( m.T[ "No players looking for dungeon runs found\nSelect Show all to show %d entries" ], #m.lfg_list ) )
				else
					popup.empty:SetText( string.format( m.T[ "No groups looking for members found\nSelect Show all to show %d entries" ], #m.lfg_list ) )
				end
			end
			popup.empty:Show()
		else
			for i = 1, groupsDisplayed do
				local entry = groupEntryFrames[ i ]
				local index = i + offset

				local data = groupsData[ index ]
				if data and index <= #groupsData then
					local dungeon = m.dungeons[ data.code ]
					local r, g, b = m.get_dungeon_color( dungeon, m.player_level, data.heroic )
					local title = data.heroic and (dungeon.name .. " (Heroic)") or dungeon.name

					entry.title:SetText( title )
					entry.title:SetWidth( 200 )
					entry.title:SetTextColor( r, g, b )
					entry.title:SetWidth( entry.title:GetStringWidth() + 5 )
					entry.bg:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\background\]] .. (dungeon.background or "") )

					if data.type == Types.GroupTypes.LFG then
						entry.leader:SetText( "" )
						entry.description:SetText( "" )

						for role in pairs( Types.Roles ) do
							local count = data.players[ role ] and #data.players[ role ] or 0
							entry[ role .. "_frame" ].number:SetText( tostring( count ) )
						end
					elseif data.type == Types.GroupTypes.LFM then
						entry.leader:SetText( m.T[ "Lead by " ] .. m.player_to_colorized_string( data.leader ) )
						entry.description:SetText( data.description or "" )

						for role in pairs( Types.Roles ) do
							local count = data.players[ role ] and #data.players[ role ] or 0
							local max = role == "DPS" and 3 or 1
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
		end

		popup.search_scrollbar.set_max_value( #groupsData - groupsDisplayed )
		popup.search_scrollbar.set_value( offset )
	end

	local function update_players()
		m.debug( "update_players" )
		for _, frame in pairs( playerEntryFrames ) do
			frame:Hide()
		end

		local offset = popup.search_scrollbar:GetValue()

		if #m.lfg_list == 0 then
			popup.empty:SetText( m.T[ 'No players are currently Looking for Group' ] )
			popup.empty:Show()
		else
			popup.empty:Hide()

			for i = 1, playersDisplayed do
				local entry = playerEntryFrames[ i ]
				local index = i + offset

				local data = m.lfg_list[ index ]

				if data and index <= #m.lfg_list then
					entry.player:SetText( string.format( "%s (%d %s)",
						m.player_to_colorized_string( data.player ),
						data.player[ 3 ],
						m.capitalize( Types.PlayerClass[ data.player[ 2 ] ] ) )
					)

					entry.text:SetText( data.message )
					entry.player_name = data.player[ 1 ]
					entry:Show()
				else
					entry:Hide()
				end
			end
		end

		popup.search_scrollbar.set_max_value( #m.lfg_list - playersDisplayed )
		popup.search_scrollbar.set_value( offset )
	end

	local function update_browse_list()
		if currentBrowseView == 1 then
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

			build_groups_data( currentBrowseView == 2 and Types.GroupTypes.LFG or Types.GroupTypes.LFM )
			update_groups()
		end
	end

	local function update_message()
		if dungeonsDisplayed == 9 then
			local msg = m.generate_message( selectedDungeons )
			local old_msg = popup.editbox_message.get_text()
			local diff

			if old_msg == popup.editbox_message.orig_msg then
				diff = " - "
			else
				diff = string.gsub( old_msg, popup.editbox_message.orig_msg, "" )
			end

			popup.editbox_message.orig_msg = msg
			popup.editbox_message.set_text( msg .. diff )
		end
	end

	local function confirm_roles()
		local got_addon = 0
		for _, member in pairs( m.group.members ) do
			member.status = m.Types.CheckStatus.Waiting
			if member.addon then
				got_addon = got_addon + 1
			end
		end

		m.group.dungeon = m.get_keys( selectedDungeons )[ 1 ]

		if got_addon > 1 then
			m.message_handler.confirm_roles( m.group.dungeon )
		end

		if got_addon ~= #m.group.members then

		end

		popup:Hide()
		m.roles_status_popup.show()
	end

	---@param tab Tab?
	local function update_layout( tab )
		if tab then currentTab = tab end
		m.debug( "update_layout - " .. currentTab )

		if currentTab == Types.Tab.Browse then
			popup.frame_lfg:Hide()
			popup.frame_search:Show()

			if selectedGroup and groupsData[ selectedGroup ].type == Types.GroupTypes.LFM then
				for role in pairs( Types.Roles ) do
					local max = role == "DPS" and 3 or 1
					local count = groupsData[ selectedGroup ].players[ role ] and #groupsData[ selectedGroup ].players[ role ] or 0

					if m.find( Types.Roles[ role ], m.classRoles[ m.player_class ] ) and count < max then
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
		elseif currentTab == Types.Tab.LFG then
			popup.frame_search:Hide()
			popup.frame_lfg:Show()
			popup.btn_list:SetText( m.isQueued and m.T[ "Leave Queue" ] or m.isGrouped and m.T[ "List Group" ] or m.T[ "List Self" ] )

			if m.isGrouped then
				selectDungeonLimit = 1
				if m.count( selectedDungeons ) > 1 then selectedDungeons = {} end

				if not m.isLeader then
					popup.lfg_dungeons:Hide()
					popup.btn_message:Disable()
					popup.btn_list:Disable()
					popup.not_leader:Show()
					return
				end
			else
				selectDungeonLimit = 5
			end
			popup.lfg_dungeons:Show()
			popup.not_leader:Hide()
			popup.btn_message:Enable()

			update_message()

			local dCount = m.count( selectedDungeons )
			local rCount = m.count( options.dungeonRoles )

			if (dCount > 0 and rCount > 0) or m.isQueued then
				popup.btn_list:Enable()
				--if m.isGrouped and m.group.count ~= m.group.online then
				--		popup.btn_list:Disable()
				--end
			else
				popup.btn_list:Disable()
			end
		end
	end

	local function btn_list_on_click()
		if m.isQueued then
			m.message_handler.lfg_remove()
		else
			if m.isGrouped then
				confirm_roles()
				return
			end

			local msg = m.generate_message( selectedDungeons )
			if dungeonsDisplayed == 9 then
				msg = popup.editbox_message.get_text()
			end

			m.message_handler.lfg_add( msg )
		end
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
				options.dungeonType = dungeonType
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

	local function dd_search_type_init( self )
		local info = {
			notCheckable = true,
			text = "",
			value = "",
			func = function( selected )
				if m.isModern then
					currentBrowseView = selected.value
					UIDropDownMenu_SetText( self, browseTypes[ currentBrowseView ] )
				else
					currentBrowseView = selected
					UIDropDownMenu_SetText( browseTypes[ currentBrowseView ], popup.dropdown_search_type )
				end
				options.currentBrowseView = currentBrowseView
				update_browse_list()
			end
		}

		for i = 1, 3 do
			info.text = browseTypes[ i ]
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
			m.message_handler.lfg_list( options.lvlmin, options.lvlmax, true )
		end
	end

	local function on_role_enter( self, role )
		local data = self:GetParent().data
		if data.players[ role ] then
			local tooltip = ""

			for _, p in pairs( data.players[ role ] ) do
				tooltip = tooltip ..
						string.format( "%s %d %s\n", m.player_to_colorized_string( p ), p[ 3 ], m.capitalize( Types.PlayerClass[ p[ 2 ] ] ) )
			end
			tooltip = string.sub( tooltip, 1, -2 )

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
			update_dungeons()
			update_layout()
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

		for role in pairs( Types.Roles ) do
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
				self:GetParent():LockHighlight()
				on_role_enter( self, role )
			end )

			f:SetScript( "OnLeave", function( self )
				self:GetParent():UnlockHighlight()
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

			update_layout()
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

		frame:SetScript( "OnDoubleClick", function()
			ChatFrame_SendTell( frame.player_name )
		end )

		tinsert( playerEntryFrames, frame )
		return frame
	end

	local function create_frame()
		-- ##########################################
		-- Main Frame
		-- ##########################################
		---@class LFGFrame: Frame
		local frame = CreateFrame( "Frame", "CSLFGPopup", UIParent )
		frame:SetWidth( 352 ) --384 )
		frame:SetHeight( 468 ) --512 )
		frame:EnableMouse( true )
		frame:SetMovable( true )
		frame:RegisterForDrag( "LeftButton" )
		frame:SetPoint( "CENTER", UIParent, "CENTER", 0, 0 )
		tinsert( UISpecialFrames, frame:GetName() )
		--[[
		local tmp = frame:CreateTexture( nil, "BACKGROUND" )
		tmp:SetTexture( "Interface/Buttons/WHITE8x8" )
		tmp:SetVertexColor( 0,0.8,0,0.4)
		tmp:SetAllPoints()
]]
		frame:SetScript( "OnDragStart", function( self )
			if not self:IsMovable() then return end
			self:StartMoving()
		end )

		frame:SetScript( "OnDragStop", function( self )
			if not self:IsMovable() then return end
			self:StopMovingOrSizing()
		end )

		frame:SetScript( "OnHide", function()

		end )

		local portrait = frame:CreateTexture( nil, "BACKGROUND" )
		portrait:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-lfg-portrait]] )
		portrait:SetWidth( 64 )
		portrait:SetHeight( 64 )
		portrait:SetPoint( "TOPLEFT", frame, "TOPLEFT", 12, -6 )

		local btn_close = CreateFrame( "Button", nil, frame, "UIPanelCloseButton" )
		btn_close:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", 4, -8 )

		-- ##########################################
		-- LFG Frame
		-- ##########################################
		---@class Frame
		local frame_lfg = CreateFrame( "Frame", nil, frame )
		frame_lfg:SetAllPoints( frame )
		frame.frame_lfg = frame_lfg

		local title = frame_lfg:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		title:SetPoint( "TOP", frame_lfg, "TOP", 20, -18 )
		title:SetText( m.T[ 'Looking For Group' ] )

		local bgwall = frame_lfg:CreateTexture( nil, "BACKGROUND" )
		bgwall:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-lfg-background-dungeonwall]] )
		bgwall:SetWidth( 512 )
		bgwall:SetHeight( 256 )
		bgwall:SetPoint( "TOPLEFT", frame_lfg, "TOPLEFT", 22, -155 )

		local bgframe = frame_lfg:CreateTexture( nil, "ARTWORK" )
		bgframe:SetTexture( [[Interface\AddOns\CS_LFG\assets\images\ui-lfg-frame]] )
		bgframe:SetWidth( 512 )
		bgframe:SetHeight( 512 )
		bgframe:SetPoint( "TOPLEFT", frame_lfg, "TOPLEFT", 0, 0 )

		local btn_message = CreateFrame( "Button", nil, frame_lfg, "UIPanelButtonTemplate" )
		btn_message:SetWidth( 109 )
		btn_message:SetHeight( 22 )
		btn_message:SetPoint( "BOTTOMLEFT", frame_lfg, "BOTTOMLEFT", 20, 35 )
		btn_message:SetText( m.T[ "Edit message" ] )
		btn_message:SetScript( "OnClick", function( self )
			if dungeonsDisplayed == 9 then
				dungeonsDisplayed = 12
				self:SetText( m.T[ "Edit message" ] )
				popup.editbox_message:Hide()
				popup.line1:Hide()
				popup.line2:Hide()
			else
				dungeonsDisplayed = 9
				self:SetText( m.T[ "Hide message" ] )
				popup.editbox_message:Show()
				popup.line1:Show()
				popup.line2:Show()
			end
			popup.lfg_dungeons_scroll_frame.set_height( dungeonEntryHeight * dungeonsDisplayed )
			update_layout()
			update_dungeons()
		end )
		frame.btn_message = btn_message

		local btn_list = CreateFrame( "Button", nil, frame_lfg, "UIPanelButtonTemplate" )
		btn_list:SetWidth( 109 )
		btn_list:SetHeight( 22 )
		btn_list:SetPoint( "BOTTOMRIGHT", frame_lfg, "BOTTOMRIGHT", -6, 35 )
		btn_list:SetText( m.T[ "List Self" ] )
		btn_list:Disable()
		btn_list:SetScript( "OnClick", btn_list_on_click )
		frame.btn_list = btn_list
		m.F = btn_list

		local role1 = m.create_player_role_button( frame_lfg, "DPS", options, update_layout )
		role1:SetPoint( "TOPLEFT", frame_lfg, "TOPLEFT", 74, -52 )

		local role2 = m.create_player_role_button( frame_lfg, "Tank", options, update_layout )
		role2:SetPoint( "LEFT", role1, "RIGHT", 44, 0 )

		local role3 = m.create_player_role_button( frame_lfg, "Healer", options, update_layout )
		role3:SetPoint( "LEFT", role2, "RIGHT", 44, 0 )

		local not_leader = frame_lfg:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		not_leader:SetPoint( "CENTER", frame_lfg, "CENTER", 0, -30 )
		not_leader:SetText( m.T[ 'Only group leader can list group' ] )
		not_leader:Hide()
		frame.not_leader = not_leader

		-- ##########################################
		-- LFG Dungeons Frame
		local frame_lfg_dungeons = CreateFrame( "Frame", nil, frame_lfg )
		frame_lfg_dungeons:SetAllPoints()
		frame.lfg_dungeons = frame_lfg_dungeons

		-- Dungeon Type Dropdown
		local dd = CreateFrame( "Button", "CSLFGDungeonTypeDropDown", frame_lfg_dungeons, "UIDropDownMenuTemplate" )
		dd:SetPoint( "TOPRIGHT", frame_lfg_dungeons, "TOPRIGHT", -12, -125 )
		if m.isModern then
			UIDropDownMenu_SetWidth( dd, 150 )
			UIDropDownMenu_SetText( dd, dungeonTypes[ dungeonType ] )
		else
			UIDropDownMenu_SetWidth( 150, dd )
			UIDropDownMenu_SetText( dungeonTypes[ dungeonType ], dd )
		end
		UIDropDownMenu_Initialize( dd, dd_dungeon_type_init )
		frame.dropdown_dungeon_type = dd

		local dd_label = frame_lfg_dungeons:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		dd_label:SetPoint( "RIGHT", dd, "LEFT", 10, 1 )
		dd_label:SetText( m.T[ "Type:" ] )

		-- Dungeons ScrollFrame
		local scroll_frame = m.create_scroll_bar( frame_lfg_dungeons, "CSLFGScrollBar", 317, dungeonEntryHeight * dungeonsDisplayed, function()
			update_dungeons()
		end )
		scroll_frame:SetPoint( "TOPLEFT", frame_lfg_dungeons, "TOPLEFT", 25, -158 )
		scroll_frame.set_mousewheel_step( 5 )
		frame.lfg_dungeons_scroll_frame = scroll_frame
		frame.lfg_dungeons_scrollbar = scroll_frame.scroll_bar

		-- Dungeon Entries
		for i = 1, dungeonsDisplayed do
			local entry = create_dungeon_entry( frame_lfg_dungeons )
			entry:SetPoint( "TOPLEFT", frame_lfg_dungeons, "TOPLEFT", 25, -dungeonEntryHeight * (i - 1) - 157 )
		end

		local line1 = frame_lfg_dungeons:CreateTexture( nil, "ARTWORK" )
		line1:SetTexture( "Interface/Buttons/WHITE8x8" )
		line1:SetVertexColor( 0.5, 0.5, 0.5, 1 )
		line1:SetPoint( "TOPLEFT", frame_lfg_dungeons, "TOPLEFT", 22, -347 )
		line1:SetPoint( "BOTTOMRIGHT", frame_lfg_dungeons, "TOPRIGHT", -9, -348 )
		line1:Hide()
		frame.line1 = line1

		local line2 = frame_lfg_dungeons:CreateTexture( nil, "ARTWORK" )
		line2:SetTexture( "Interface/Buttons/WHITE8x8" )
		line2:SetVertexColor( 0.2, 0.2, 0.2, 1 )
		line2:SetPoint( "TOPLEFT", frame_lfg_dungeons, "TOPLEFT", 22, -348 )
		line2:SetPoint( "BOTTOMRIGHT", frame_lfg_dungeons, "TOPRIGHT", -9, -349 )
		line2:Hide()
		frame.line2 = line2

		local editbox_message = m.create_multiline_editbox( frame_lfg_dungeons, 170 )
		editbox_message:SetPoint( "TOPLEFT", frame_lfg_dungeons, "TOPLEFT", 32, -354 )
		editbox_message:SetWidth( 300 )
		editbox_message:SetHeight( 48 )
		editbox_message:Hide()
		frame.editbox_message = editbox_message

		-- ##########################################
		-- Search Frame
		-- ##########################################
		---@class Frame
		local frame_search = CreateFrame( "Frame", nil, frame )
		frame_search:SetAllPoints( frame )
		frame_search:Hide()
		frame.frame_search = frame_search

		title = frame_search:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
		title:SetPoint( "TOP", frame_search, "TOP", 20, -18 )
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
		edit_min:SetMaxLetters( 2 )
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
		edit_max:SetMaxLetters( 2 )
		edit_max:SetText( tostring( options.lvlmax ) )
		edit_max:SetScript( "OnTextChanged", handle_lvl_text_changed )
		edit_max:SetScript( "OnEnterPressed", handle_lvl_enter_pressed )

		local dd_search = CreateFrame( "Button", "CSLFGSearchDropDown", frame_search, "UIDropDownMenuTemplate" )
		dd_search:SetPoint( "TOPRIGHT", frame_search, "TOPRIGHT", 7, -40 )
		if m.isModern then
			UIDropDownMenu_SetWidth( dd_search, 110 )
			UIDropDownMenu_SetText( dd_search, browseTypes[ currentBrowseView ] )
		else
			UIDropDownMenu_SetWidth( 110, dd_search )
			UIDropDownMenu_SetText( browseTypes[ currentBrowseView ], dd_search )
		end
		UIDropDownMenu_Initialize( dd_search, dd_search_type_init )
		frame.dropdown_search_type = dd_search

		-- ##########################################
		-- Groups ScrollFrame
		scroll_frame = m.create_scroll_bar( frame_search, "CSLFGSearchScrollBar", 317, 333, function()
			update_browse_list()
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
		empty:SetPoint( "CENTER", frame_lfg, "CENTER", 0, 10 )
		empty:SetText( m.T[ 'No players are currently Looking for Group' ] )
		empty:Hide()
		frame.empty = empty

		-- Buttons
		for role in pairs( Types.Roles ) do
			local btn = CreateFrame( "Button", nil, frame_search, "UIPanelButtonTemplate" )
			btn:SetWidth( 109 )
			btn:SetHeight( 21 )
			btn:SetText( m.T[ "Join as " ] .. role )
			btn:Disable()
			btn:SetScript( "OnClick", function()

			end )

			frame[ "btn_join_" .. string.lower( role ) ] = btn
		end

		frame[ "btn_join_dps" ]:SetPoint( "BOTTOMLEFT", frame_lfg, "BOTTOMLEFT", 20, 36 )
		frame[ "btn_join_tank" ]:SetPoint( "BOTTOM", frame_lfg, "BOTTOM", 8, 36 )
		frame[ "btn_join_healer" ]:SetPoint( "BOTTOMRIGHT", frame_lfg, "BOTTOMRIGHT", -6, 36 )

		btn_close:SetFrameLevel( frame_lfg:GetFrameLevel() + 1 )
		-- ##########################################
		-- Tabs
		-- ##########################################
		local tab1 = CreateFrame( "Button", "CSLFGPopupTab1", frame, "CharacterFrameTabButtonTemplate" )
		tab1:SetID( 1 )
		tab1:SetPoint( "BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 0 )
		tab1:SetFrameLevel( frame:GetFrameLevel() + 1 )
		tab1:SetText( m.T[ "Create Listing" ] )
		tab1:SetScript( "OnClick", function()
			update_layout( Types.Tab.LFG )
			PanelTemplates_SetTab( frame, 1 )
			m.play_sound( "igCharacterInfoTab" )
		end )

		if m.isModern then
			PanelTemplates_TabResize( tab1, 5, 120 )
		else
			PanelTemplates_TabResize( 5, tab1, 120 )
		end

		local tab2 = CreateFrame( "Button", "CSLFGPopupTab2", frame, "CharacterFrameTabButtonTemplate" )
		tab2:SetID( 2 )
		tab2:SetPoint( "LEFT", tab1, "RIGHT", -17, 0 )
		tab2:SetFrameLevel( frame:GetFrameLevel() + 1 )
		tab2:SetText( m.T[ "Browse" ] )
		tab2:SetScript( "OnClick", function()
			update_layout( Types.Tab.Browse )
			update_browse_list()
			PanelTemplates_SetTab( frame, 2 )
			m.play_sound( "igCharacterInfoTab" )
			m.message_handler.lfg_list( options.lvlmin, options.lvlmax )
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

	local function show()
		if not popup then
			popup = create_frame()
		end

		if m.isGrouped and m.isLeader then
			m.scan_party()
		end

		update_layout()
		get_dungeons()
		update_dungeons()

		if currentTab == Types.Tab.Browse then
			m.message_handler.lfg_list( options.lvlmin, options.lvlmax )
		end

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

	local function is_visible()
		return popup and popup:IsVisible() or false
	end

	local function update()
		if popup and popup:IsVisible() then
			update_layout()
			if currentTab == m.Types.Tab.LFG then
				get_dungeons()
				update_dungeons()
			elseif currentTab == m.Types.Tab.Browse then
				update_browse_list()
			end
		end
	end

	---@type LFGPopup
	return {
		show = show,
		hide = hide,
		toggle = toggle,
		is_visible = is_visible,
		update = update
	}
end

m.LFGPopup = M
return M
