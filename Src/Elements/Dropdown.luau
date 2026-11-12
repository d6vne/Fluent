local UserInputService = game:GetService("UserInputService")
local Camera = game:GetService("Workspace").CurrentCamera

local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Dropdown"

function Element:New(Idx, Config)
	local Library = self.Library
	local DropdownSignals = {}

	local Dropdown = {
		Values = (function()
			local Idxes = {}

			for i, v in next, Config.Values or {} do
				Idxes[#Idxes + 1] = v
			end

			return Idxes
		end)(),
		Value = Config.Multi and {} or (Config.Default or Config.Value),
		Multi = Config.Multi or false,
		AutoDeselect = Config.AutoDeselect or false,
		AutoRefresh = Config.AutoRefresh or false,
		Searchable = Config.Searchable or false,
		FocusSearch = Config.FocusSearch or false,
		SearchPlaceholder = Config.SearchPlaceholder or "Search...",
		Displayer = typeof(Config.Displayer) == "function" and Config.Displayer or function(Value)
			return typeof(Value) ~= "number" and tostring(Library.Utilities:Prettify(Value)) or Value
		end,
		CustomDisplayer = (typeof(Config.Displayer) == "function" and Config.Displayer and true) or false,
		Buttons = {},
		Opened = false,
		Type = "Dropdown",
		Callback = Config.Callback or function() end,
		Changed = Config.Changed or function() end,
	}

	local DropdownFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, false)
	DropdownFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

	Dropdown.SetTitle = DropdownFrame.SetTitle
	Dropdown.SetDesc = DropdownFrame.SetDesc

	local DropdownDisplay = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = "Value",
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -30, 0, 14),
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	local DropdownIco = New("ImageLabel", {
		Image = "rbxassetid://10709790948",
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundTransparency = 1,
		ThemeTag = {
			ImageColor3 = "SubText",
		},
	})

	local DropdownInner = New("TextButton", {
		Size = UDim2.fromOffset(160, 30),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 0.9,
		Parent = DropdownFrame.Frame,
		ThemeTag = {
			BackgroundColor3 = "DropdownFrame",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
		New("UIStroke", {
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
		DropdownIco,
		DropdownDisplay,
	})

	-- Fixed row heights allow a small, reusable viewport pool (no UIListLayout).
	local DropdownScrollFrame = New("ScrollingFrame", {
		Size = UDim2.new(1, -5, 1, Dropdown.Searchable and -40 or -10),
		Position = UDim2.fromOffset(5, Dropdown.Searchable and 40 or 5),
		BackgroundTransparency = 1,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 4,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})

	local DropdownHolderFrame = New("Frame", {
		Size = UDim2.fromScale(1, 0.6),
		ThemeTag = {
			BackgroundColor3 = "DropdownHolder",
		},
	}, {
		DropdownScrollFrame,
		New("UICorner", {
			CornerRadius = UDim.new(0, 7),
		}),
		New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "DropdownBorder",
			},
		}),
		New("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=5554236805",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(23, 23, 277, 277),
			Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30),
			Position = UDim2.fromOffset(-15, -15),
			ImageColor3 = Color3.fromRGB(0, 0, 0),
			ImageTransparency = 0.1,
		}),
	}) :: Frame

	-- Avoid constructing a search TextBox for non-searchable dropdowns.
	local SearchBox
	if Dropdown.Searchable then
		local SearchableTextbox = require(Components.Textbox)(DropdownHolderFrame, true)
		SearchableTextbox.Frame.AnchorPoint = Vector2.new(0.5, 0)
		SearchableTextbox.Frame.Position = UDim2.new(0.5, 0, 0, 5)
		SearchableTextbox.Frame.Size = UDim2.new(1, -5, 0, 32)
		SearchableTextbox.Input.PlaceholderText = Dropdown.SearchPlaceholder
		SearchableTextbox.Input.Text = ""
		SearchBox = SearchableTextbox.Input
	end

	-- The template is also created only on the first open, not at startup.
	local Button_BuildList
	local function EnsureButtonTemplate()
		if Button_BuildList then return end
		local ButtonSelector_BuildList = New("Frame", {
			Size = UDim2.fromOffset(4, 14),
			BackgroundColor3 = Color3.fromRGB(76, 194, 255),
			Position = UDim2.fromOffset(-1, 16),
			AnchorPoint = Vector2.new(0, 0.5),
			ThemeTag = {
				BackgroundColor3 = "Accent",
			},
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
		}) :: Frame
	
			local ButtonLabel_BuildList = New("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(10, 0),
			Name = "ButtonLabel",
			ThemeTag = {
				TextColor3 = "Text",
			},
		}) :: TextLabel
	
			Button_BuildList = New("TextButton", {
			Size = UDim2.new(1, -5, 0, 32),
			BackgroundTransparency = 1,
			ZIndex = 23,
			Text = "",
			ThemeTag = {
				BackgroundColor3 = "DropdownOption",
			},
		}, {
			ButtonSelector_BuildList,
			ButtonLabel_BuildList,
			New("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
		}) :: TextButton
	
	end

	local DropdownHolderCanvas = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(170, 300),
		Parent = self.Library.GUI,
		Visible = false,
	}, {
		DropdownHolderFrame,
		New("UISizeConstraint", {
			MinSize = Vector2.new(170, 0),
		}),
	})

	Library.OpenFrames[#Library.OpenFrames + 1] = DropdownHolderCanvas

	-- Obsidian uses a bounded pool of visible rows rather than allocating a
	-- GuiObject and listeners for every value. Implement the same architecture
	-- independently while preserving Fluent's public dropdown API and appearance.
	local RowHeight = 32
	local RowGap = 3
	local RowPitch = RowHeight + RowGap
	local MaxVisible = math.clamp(math.floor(tonumber(Config.MaxVisibleDropdownItems) or 11), 1, 30)
	local PoolLimit = MaxVisible + 3
	local Rows = {}
	local Entries = {}
	local FilteredEntries = {}
	local ListBuilt = false
	local ListDirty = true
	local ListSizeX = 170
	local LastFirstIndex = nil
	local OutsideClickConnection

	local function RecalculateListPosition()
		local Add = 0
		if Camera.ViewportSize.Y - DropdownInner.AbsolutePosition.Y < DropdownHolderCanvas.AbsoluteSize.Y - 5 then
			Add = DropdownHolderCanvas.AbsoluteSize.Y - 5
				- (Camera.ViewportSize.Y - DropdownInner.AbsolutePosition.Y) + 40
		end
		DropdownHolderCanvas.Position = UDim2.fromOffset(
			DropdownInner.AbsolutePosition.X - 1,
			DropdownInner.AbsolutePosition.Y - 5 - Add
		)
	end

	local function RecalculateListSize()
		local Subtract = Dropdown.Searchable and 42 or 0
		local Add = Dropdown.Searchable and 35 or 0
		local ContentHeight = #FilteredEntries > 0 and (#FilteredEntries * RowPitch - RowGap) or 0
		local MaxHeight = math.min(392 - Subtract, MaxVisible * RowPitch + 10 + Add)
		DropdownHolderCanvas.Size = UDim2.fromOffset(
			math.max(170, DropdownInner.AbsoluteSize.X, ListSizeX),
			math.min(MaxHeight, ContentHeight + 10 + Add)
		)
		DropdownScrollFrame.CanvasSize = UDim2.fromOffset(0, ContentHeight)
		if Dropdown.Opened then
			RecalculateListPosition()
		end
	end

	local function UpdateRowSelection(Row)
		local Entry = Row.Entry
		if not Entry then return end
		local Selected = Dropdown.Multi and Dropdown.Value[Entry.Value] or Dropdown.Value == Entry.Value
		Row.Selected = Selected and true or false
		Row.Button.BackgroundTransparency = Row.Selected and 0.89 or (Row.Hovered and 0.89 or 1)
		Row.Selector.Size = UDim2.fromOffset(4, Row.Selected and 14 or 6)
		Row.Selector.BackgroundTransparency = Row.Selected and 0 or 1
	end

	local function CreatePoolRow()
		EnsureButtonTemplate()
		local Button = Button_BuildList:Clone()
		local Selector = Button:FindFirstChild("Frame")
		local Label = Button:FindFirstChild("ButtonLabel")
		assert(Selector and Label, "Fluent dropdown template is incomplete")
		Label.AutomaticSize = Enum.AutomaticSize.None
		Label.Size = UDim2.new(1, -16, 1, 0)
		Label.TextWrapped = false
		Label.TextTruncate = Enum.TextTruncate.AtEnd
		Label.TextYAlignment = Enum.TextYAlignment.Center

		Creator.AddThemeObject(Button, { BackgroundColor3 = "DropdownOption" })
		Creator.AddThemeObject(Selector, { BackgroundColor3 = "Accent" })
		Creator.AddThemeObject(Label, { TextColor3 = "Text" })

		local Row = {
			Button = Button, Selector = Selector, Label = Label,
			Entry = nil, Hovered = false, Selected = false,
			Connections = {},
		}
		Creator.AddSignal(Button.MouseEnter, function()
			Row.Hovered = true
			if Row.Entry then Button.BackgroundTransparency = 0.89 end
		end, Row.Connections)
		Creator.AddSignal(Button.MouseLeave, function()
			Row.Hovered = false
			UpdateRowSelection(Row)
		end, Row.Connections)
		Creator.AddSignal(Button.MouseButton1Down, function()
			if Row.Entry then Button.BackgroundTransparency = 0.92 end
		end, Row.Connections)
		Creator.AddSignal(Button.MouseButton1Click, function()
			local Entry = Row.Entry
			if not Entry then return end
			local Value = Entry.Value
			local Selected = Dropdown.Multi and Dropdown.Value[Value] or Dropdown.Value == Value
			-- A multi-select should be able to clear its last item by default.
			-- Single-select preserves the existing AllowNull behavior; for a
			-- multi-select, only an explicit AllowNull = false requires one item.
			if Selected and not Dropdown.Multi and not Config.AllowNull then return end
			if Selected and Dropdown.Multi and Config.AllowNull == false then
				local Count = 0
				for _, Enabled in next, Dropdown.Value do
					if Enabled then Count += 1 end
					if Count > 1 then break end
				end
				if Count <= 1 then return end
			end
			if Dropdown.Multi then
				-- `Selected and nil or true` is always true in Luau: nil falls
				-- through the `or` branch and the item can never be deselected.
				if Selected then
					Dropdown.Value[Value] = nil
				else
					Dropdown.Value[Value] = true
				end
				Dropdown:RefreshButtons()
				Dropdown:Display()
				if typeof(Dropdown.Callback) == "function" then
					Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
				end
				if typeof(Dropdown.Changed) == "function" then
					Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
				end
			else
				Dropdown:SetValue(Selected and nil or Value)
			end
		end, Row.Connections)

		Button.Parent = DropdownScrollFrame
		Rows[#Rows + 1] = Row
		return Row
	end

	local function RefreshPool(Force)
		if not ListBuilt then return end
		local Count = #FilteredEntries
		local First = math.max(1, math.floor(DropdownScrollFrame.CanvasPosition.Y / RowPitch) + 1)
		First = math.min(First, math.max(1, Count - #Rows + 1))
		if not Force and First == LastFirstIndex then return end
		LastFirstIndex = First

		for Slot, Row in ipairs(Rows) do
			local EntryIndex = First + Slot - 1
			local Entry = FilteredEntries[EntryIndex]
			if Entry then
				Row.Entry = Entry
				Row.Hovered = false
				Row.Label.Text = Entry.Label
				Row.Button.Position = UDim2.fromOffset(0, (EntryIndex - 1) * RowPitch)
				UpdateRowSelection(Row)
				Row.Button.Visible = true
			else
				Row.Entry = nil
				Row.Button.Visible = false
			end
		end
	end

	local function Refilter()
		if not ListBuilt then return end
		local Query = Dropdown.Searchable and string.lower(SearchBox.Text) or ""
		table.clear(FilteredEntries)
		if Query == "" then
			for _, Entry in ipairs(Entries) do
				FilteredEntries[#FilteredEntries + 1] = Entry
			end
		else
			for _, Entry in ipairs(Entries) do
				if string.find(Entry.SearchText, Query, 1, true) then
					FilteredEntries[#FilteredEntries + 1] = Entry
				end
			end
		end
		DropdownScrollFrame.CanvasPosition = Vector2.zero
		LastFirstIndex = nil
		RecalculateListSize()
		RefreshPool(true)
	end

	function Dropdown:BuildDropdownList()
		if ListBuilt and not ListDirty and not Dropdown.AutoRefresh then
			Refilter()
			return
		end

		table.clear(Entries)
		local Longest = ""
		for _, Value in next, Dropdown.Values do
			local Label = tostring(Dropdown.Displayer(Value))
			Entries[#Entries + 1] = {
				Value = Value,
				Label = Label,
				SearchText = string.lower(Label),
			}
			if #Label > #Longest then Longest = Label end
		end
		-- Measure at most one long label, not every row's TextBounds.
		ListSizeX = math.clamp(#Longest * 7 + 30, 170, 440)

		local Needed = math.min(#Entries, PoolLimit)
		while #Rows < Needed do
			CreatePoolRow()
		end
		ListBuilt = true
		ListDirty = false
		Refilter()
	end

	function Dropdown:RefreshButtons()
		for _, Row in ipairs(Rows) do
			if Row.Entry then UpdateRowSelection(Row) end
		end
	end

	function Dropdown:Open()
		if Dropdown.Opened then return end
		Dropdown.Opened = true
		if not ListBuilt or ListDirty or Dropdown.AutoRefresh then
			Dropdown:BuildDropdownList()
		end
		DropdownHolderCanvas.Visible = true
		self:RefreshButtons()
		-- The tab's scroll is disabled while a popover has focus.
		if Dropdown.TabScrollFrame then Dropdown.TabScrollFrame.ScrollingEnabled = false end
		DropdownHolderFrame.Size = UDim2.fromScale(1, 1)
		if Dropdown.Searchable then
			SearchBox.Text = ""
			if Dropdown.FocusSearch then SearchBox:CaptureFocus() end
		end
		RecalculateListPosition()
		if not OutsideClickConnection then
			OutsideClickConnection = UserInputService.InputBegan:Connect(function(Input)
				if not Dropdown.Opened then return end
				if Input.UserInputType ~= Enum.UserInputType.MouseButton1
					and Input.UserInputType ~= Enum.UserInputType.Touch then return end
				local Pos = Input.Position
				local MenuPos, MenuSize = DropdownHolderFrame.AbsolutePosition, DropdownHolderFrame.AbsoluteSize
				local TriggerPos, TriggerSize = DropdownInner.AbsolutePosition, DropdownInner.AbsoluteSize
				local InsideMenu = Pos.X >= MenuPos.X and Pos.X <= MenuPos.X + MenuSize.X
					and Pos.Y >= MenuPos.Y and Pos.Y <= MenuPos.Y + MenuSize.Y
				local InsideTrigger = Pos.X >= TriggerPos.X and Pos.X <= TriggerPos.X + TriggerSize.X
					and Pos.Y >= TriggerPos.Y and Pos.Y <= TriggerPos.Y + TriggerSize.Y
				if not InsideMenu and not InsideTrigger then Dropdown:Close() end
			end)
		end
	end

	function Dropdown:Close()
		if not Dropdown.Opened then return end
		Dropdown.Opened = false
		DropdownHolderCanvas.Visible = false
		DropdownHolderFrame.Size = UDim2.fromScale(1, 0.6)
		if Dropdown.TabScrollFrame then Dropdown.TabScrollFrame.ScrollingEnabled = true end
		if OutsideClickConnection then
			OutsideClickConnection:Disconnect()
			OutsideClickConnection = nil
		end
		if Dropdown.Searchable then
			SearchBox.Text = ""
			SearchBox:ReleaseFocus()
		end
	end

	function Dropdown:Display()
		local Str = ""
		if Dropdown.Multi then
			local Selected = {}
			for _, Value in next, Dropdown.Values do
				if Dropdown.Value[Value] then Selected[#Selected + 1] = tostring(Dropdown.Displayer(Value)) end
			end
			Str = table.concat(Selected, ", ")
		else
			Str = Dropdown.Value and tostring(Dropdown.Displayer(Dropdown.Value)) or ""
		end
		DropdownDisplay.Text = Str == "" and "--" or Str
	end

	function Dropdown:GetActiveValues()
		if Dropdown.Multi then
			local Selected = {}
			for Value, Enabled in next, Dropdown.Value do
				if Enabled then Selected[#Selected + 1] = Value end
			end
			return Selected
		end
		return Dropdown.Value and 1 or 0
	end

	function Dropdown:SetValues(NewValues)
		if NewValues then rawset(Dropdown, "Values", NewValues) end
		ListDirty = true
		if Dropdown.Opened then Dropdown:BuildDropdownList() end
		Dropdown:Display()
	end

	function Dropdown:OnChanged(Func)
		Dropdown.Changed = Func
		Library:SafeCallback(Func, Dropdown.Value, Dropdown.Value)
	end

	function Dropdown:SetVisibility(Visible)
		DropdownFrame.Frame.Visible = Visible
		if not Visible then Dropdown:Close() end
	end

	function Dropdown:SetValue(Val)
		if Dropdown.Multi then
			local Selected = {}
			for Value, Enabled in next, Val or {} do
				if Enabled and table.find(Dropdown.Values, Value) then Selected[Value] = true end
			end
			rawset(Dropdown, "Value", Selected)
		elseif Val == nil or Val == false then
			rawset(Dropdown, "Value", nil)
		elseif table.find(Dropdown.Values, Val) then
			rawset(Dropdown, "Value", Val)
		end
		Dropdown:RefreshButtons()
		Dropdown:Display()
		if typeof(Dropdown.Callback) == "function" then
			if Config.ImmediateCallback then
				-- A theme switch should be reflected in the same input event; do
				-- not queue multiple asynchronous theme callbacks out of order.
				local Success, Err = pcall(Dropdown.Callback, Dropdown.Value)
				if not Success then warn("[Fluent] Dropdown callback:", Err) end
			else
				Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
			end
		end
		if typeof(Dropdown.Changed) == "function" then Library:SafeCallback(Dropdown.Changed, Dropdown.Value) end
	end

	function Dropdown:Destroy()
		Dropdown:Close()
		Creator.DisconnectOwner(DropdownSignals)
		for _, Row in ipairs(Rows) do
			Creator.DisconnectOwner(Row.Connections)
			Creator.RemoveThemeObject(Row.Button, true)
			Row.Button:Destroy()
		end
		table.clear(Rows)
		table.clear(Entries)
		table.clear(FilteredEntries)
		for Index, Frame in ipairs(Library.OpenFrames) do
			if Frame == DropdownHolderCanvas then
				table.remove(Library.OpenFrames, Index)
				break
			end
		end
		Creator.RemoveThemeObject(DropdownHolderCanvas, true)
		if Button_BuildList then Creator.RemoveThemeObject(Button_BuildList, true) end
		Creator.RemoveThemeObject(DropdownFrame.Frame, true)
		DropdownHolderCanvas:Destroy()
		if Button_BuildList then Button_BuildList:Destroy() end
		DropdownFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Dropdown.TabScrollFrame = self.ScrollFrame
	Creator.AddSignal(DropdownInner:GetPropertyChangedSignal("AbsolutePosition"), RecalculateListPosition, DropdownSignals)
	Creator.AddSignal(DropdownHolderCanvas:GetPropertyChangedSignal("AbsoluteSize"), RecalculateListPosition, DropdownSignals)
	if SearchBox then
		Creator.AddSignal(SearchBox:GetPropertyChangedSignal("Text"), function()
			if Dropdown.Opened then Refilter() end
		end, DropdownSignals)
	end
	Creator.AddSignal(DropdownScrollFrame:GetPropertyChangedSignal("CanvasPosition"), function()
		RefreshPool(false)
	end, DropdownSignals)
	Creator.AddSignal(DropdownInner.MouseButton1Click, function()
		if Dropdown.Opened then Dropdown:Close() else Dropdown:Open() end
	end, DropdownSignals)
	RecalculateListPosition()
	RecalculateListSize()

	-- Selection is initialized without allocating buttons for a closed dropdown.
	Dropdown:Display()

	local Defaults = {}

	if type(Config.Default) == "table" then
		for _, Value in next, Config.Default do
			local Indx = table.find(Dropdown.Values, Value)

			if Indx then
				Defaults[#Defaults + 1] = Indx
			end
		end
	elseif type(Config.Default) == "number" and Dropdown.Values[Config.Default] ~= nil then
		Defaults[#Defaults + 1] = Config.Default
	else
		local Indx = table.find(Dropdown.Values, Config.Default)
		if Indx then
			Defaults[#Defaults + 1] = Indx
		end
	end

	if next(Defaults) then
		for i = 1, #Defaults do
			local Index = Defaults[i]

			if Config.Multi then
				Dropdown.Value[Dropdown.Values[Index]] = true
			else
				Dropdown.Value = Dropdown.Values[Index]
				break
			end
		end

		Dropdown:Display()
	end

	Library.Options[Idx] = Dropdown

	Dropdown.Instance = DropdownFrame

	return setmetatable(Dropdown, {
		__newindex = function(self, index, newvalue)
			if index == "Value" then
				Creator.Spawn(Dropdown.SetValue, Dropdown, newvalue)
			elseif index == "Values" or index == "List" then
				Creator.Spawn(Dropdown.SetValues, Dropdown, newvalue)
			end
			rawset(self, index, newvalue)
		end,
	})
end

return Element
