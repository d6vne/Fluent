local HttpService = game:GetService("HttpService")

-- A compact, Obsidian-inspired interface manager. Keep the existing Fluent
-- theme engine and public Addon API; expose only five semantic palette colors.
local InterfaceManager = {
	Folder = "FluentSettings",
	Library = nil,
	Settings = {},
}

local PaletteOptions = {
	{ Key = "FontColor", Title = "Font Color" },
	{ Key = "MainColor", Title = "Main Color" },
	{ Key = "AccentColor", Title = "Accent Color" },
	{ Key = "BackgroundColor", Title = "Background Color" },
	{ Key = "OutlineColor", Title = "Outline Color" },
}

local OriginalPalette

local function GetDefaultPalette(Library)
	local Custom = Library.Utilities.Themes.Custom
	return {
		FontColor = Custom.Text:ToHex(),
		MainColor = Custom.Element:ToHex(),
		AccentColor = Custom.Accent:ToHex(),
		BackgroundColor = Custom.AcrylicMain:ToHex(),
		OutlineColor = Custom.AcrylicBorder:ToHex(),
	}
end

-- The editor swatches always describe the ACTIVE theme. Stored Custom colors
-- are deliberately separate so choosing a preset cannot overwrite them.
local function GetVisiblePalette(Library, ThemeName, CustomPalette)
	if ThemeName == "Custom" then
		return table.clone(CustomPalette)
	end

	local Theme = Library.Utilities.Themes[ThemeName] or Library.Utilities.Themes.Dark
	return {
		FontColor = Theme.Text:ToHex(),
		MainColor = Theme.Element:ToHex(),
		AccentColor = Theme.Accent:ToHex(),
		-- Use the actual window background/border tokens, not dialog colors.
		BackgroundColor = Theme.AcrylicMain:ToHex(),
		OutlineColor = Theme.AcrylicBorder:ToHex(),
	}
end

local function ReadPaletteColor(Palette, Key, Fallback)
	local Value = Palette and Palette[Key]
	if typeof(Value) == "string" then
		local Success, Color = pcall(Color3.fromHex, Value)
		if Success and typeof(Color) == "Color3" then
			return Color
		end
	end
	return Color3.fromHex(Fallback)
end

local function ApplyCustomPalette(Library, Palette)
	local Defaults = OriginalPalette or GetDefaultPalette(Library)
	local Font = ReadPaletteColor(Palette, "FontColor", Defaults.FontColor)
	local Main = ReadPaletteColor(Palette, "MainColor", Defaults.MainColor)
	local Accent = ReadPaletteColor(Palette, "AccentColor", Defaults.AccentColor)
	local Background = ReadPaletteColor(Palette, "BackgroundColor", Defaults.BackgroundColor)
	local Outline = ReadPaletteColor(Palette, "OutlineColor", Defaults.OutlineColor)
	local Custom = Library.Utilities.Themes.Custom

	-- Map the five user-facing roles to Fluent's detailed style tokens.
	Custom.Accent = Accent
	Custom.Text = Font
	Custom.SubText = Font:Lerp(Background, 0.27)
	Custom.Tab = Font:Lerp(Background, 0.25)
	Custom.AcrylicMain = Background
	Custom.AcrylicBorder = Outline
	Custom.AcrylicGradient = ColorSequence.new(Background, Background:Lerp(Main, 0.2))
	Custom.TitleBarLine = Outline
	Custom.Element = Main
	-- The five-color editor can be derived from a LIGHT preset too. Keeping
	-- the original dark Custom transparency (0.82) makes pale elements nearly
	-- invisible over a light window, even when the selected colors are right.
	local Luminance = Background.R * 0.2126 + Background.G * 0.7152 + Background.B * 0.0722
	Custom.ElementTransparency = Luminance > 0.62 and 0.18 or 0.82
	Custom.ElementBorder = Outline
	Custom.InElementBorder = Outline
	Custom.ToggleSlider = Main:Lerp(Font, 0.25)
	Custom.ToggleToggled = Background
	Custom.SliderRail = Main:Lerp(Font, 0.25)
	Custom.DropdownFrame = Main
	Custom.DropdownHolder = Background
	Custom.DropdownBorder = Outline
	Custom.DropdownOption = Main
	Custom.Keybind = Main
	Custom.Input = Main
	Custom.InputFocused = Accent
	Custom.InputIndicator = Font:Lerp(Background, 0.32)
	Custom.Dialog = Background
	Custom.DialogHolder = Background:Lerp(Main, 0.3)
	Custom.DialogHolderLine = Outline
	Custom.DialogButton = Main
	Custom.DialogButtonBorder = Outline
	Custom.DialogBorder = Outline
	Custom.DialogInput = Main
	Custom.DialogInputLine = Accent
	Custom.Hover = Main:Lerp(Accent, 0.1)
end

function InterfaceManager:SetFolder(Folder)
	self.Folder = Folder
	self:BuildFolderTree()
end

function InterfaceManager:SetLibrary(Library)
	self.Library = Library
	OriginalPalette = GetDefaultPalette(Library)
	self.Settings = {
		Theme = Library.Theme or "Dark",
		-- Last explicitly selected preset survives legacy accidental Custom saves.
		LastPreset = table.find(Library.Themes, Library.Theme) and Library.Theme or "Dark",
		Acrylic = Library.UseAcrylic == true,
		Transparency = Library.Transparency ~= false,
		MenuKeybind = typeof(Library.MinimizeKey) == "EnumItem"
			and Library.MinimizeKey.Name or (Library.MinimizeKey or "RightControl"),
		CustomPalette = table.clone(OriginalPalette),
	}
end

function InterfaceManager:BuildFolderTree()
	local Parts = self.Folder:split("/")
	local Current = ""
	for _, Part in ipairs(Parts) do
		Current = Current == "" and Part or Current .. "/" .. Part
		if not isfolder(Current) then makefolder(Current) end
	end
	local SettingsFolder = self.Folder .. "/settings"
	if not isfolder(SettingsFolder) then makefolder(SettingsFolder) end
end

function InterfaceManager:SaveSettings()
	local Success, Encoded = pcall(HttpService.JSONEncode, HttpService, self.Settings)
	if not Success then
		warn("[Fluent] Failed to encode interface settings:", Encoded)
		return
	end
	local Wrote, Err = pcall(writefile, self.Folder .. "/options.json", Encoded)
	if not Wrote then warn("[Fluent] Failed to save interface settings:", Err) end
end

function InterfaceManager:LoadSettings()
	local Path = self.Folder .. "/options.json"
	if not isfile(Path) then return end
	local ReadSuccess, Content = pcall(readfile, Path)
	if not ReadSuccess then return end
	local Success, Data = pcall(HttpService.JSONDecode, HttpService, Content)
	if not Success or typeof(Data) ~= "table" then return end

	local Settings = self.Settings
	local HasValidLastPreset = typeof(Data.LastPreset) == "string"
		and table.find(self.Library.Themes, Data.LastPreset) ~= nil
	if HasValidLastPreset then
		Settings.LastPreset = Data.LastPreset
	end
	if typeof(Data.Theme) == "string" then
		Settings.Theme = Data.Theme
	end
	-- Before LastPreset existed, startup colorpicker initialization could
	-- inadvertently overwrite a previously selected preset with "Custom".
	-- Migrate that ambiguous legacy value to the Window's configured theme,
	-- but retain its saved palette for later explicit Custom selection.
	local MigratedLegacyCustom = Settings.Theme == "Custom" and not HasValidLastPreset
	if MigratedLegacyCustom then
		Settings.Theme = Settings.LastPreset
	end
	if typeof(Data.Acrylic) == "boolean" then Settings.Acrylic = Data.Acrylic end
	if typeof(Data.Transparency) == "boolean" then Settings.Transparency = Data.Transparency end
	if typeof(Data.MenuKeybind) == "string" then Settings.MenuKeybind = Data.MenuKeybind end
	if typeof(Data.CustomPalette) == "table" then
		for _, Item in ipairs(PaletteOptions) do
			if typeof(Data.CustomPalette[Item.Key]) == "string" then
				Settings.CustomPalette[Item.Key] = Data.CustomPalette[Item.Key]
			end
		end
	end
	return MigratedLegacyCustom
end

function InterfaceManager:BuildInterfaceSection(Tab)
	assert(self.Library, "Must set InterfaceManager.Library")

	local Library = self.Library
	local Settings = self.Settings
	local MigratedLegacyCustom = self:LoadSettings()

	-- Legacy presets that were removed migrate cleanly to Dark.
	if Settings.Theme ~= "Custom" and not table.find(Library.Themes, Settings.Theme) then
		Settings.Theme = table.find(Library.Themes, Settings.LastPreset) and Settings.LastPreset or "Dark"
	end
	ApplyCustomPalette(Library, Settings.CustomPalette)
	Library:SetTheme(Settings.Theme)
	-- Saved settings must take effect immediately, not only after the
	-- next toggle click or a later configuration reload.
	Library:ToggleTransparency(Settings.Transparency)
	if Library.UseAcrylic then Library:ToggleAcrylic(Settings.Acrylic) end

	local Presets = table.clone(Library.Themes)
	if Settings.Theme == "Custom" then Presets[#Presets + 1] = "Custom" end

	local Section = Tab:AddSection("Appearance")
	local Pickers = {}
	local SyncingPickers = false
	local InitialPalette = GetVisiblePalette(Library, Settings.Theme, Settings.CustomPalette)

	local function SyncPalettePickers(ThemeName)
		local Palette = GetVisiblePalette(Library, ThemeName, Settings.CustomPalette)
		SyncingPickers = true
		for _, Item in ipairs(PaletteOptions) do
			local Picker = Pickers[Item.Key]
			if Picker then
				local Color = ReadPaletteColor(Palette, Item.Key, OriginalPalette[Item.Key])
				if Picker.Value:ToHex() ~= Color:ToHex() then
					Picker:SetValueRGB(Color, 0)
				end
			end
		end
		SyncingPickers = false
	end

	local ThemeOption = Section:AddDropdown("InterfaceManager_InterfaceTheme", {
		Title = "Theme",
		Values = Presets,
		Searchable = false,
		ImmediateCallback = true,
		Default = Settings.Theme,
		Callback = function(Value)
			if typeof(Value) ~= "string" then return end
			if Value ~= "Custom" and not table.find(Library.Themes, Value) then return end
			Settings.Theme = Value
			if Value ~= "Custom" then
				Settings.LastPreset = Value
			end
			if Value == "Custom" then
				ApplyCustomPalette(Library, Settings.CustomPalette)
			end
			Library:SetTheme(Value)
			SyncPalettePickers(Value)
			InterfaceManager:SaveSettings()
		end,
	})

	local function ShowCustomTheme()
		if not table.find(ThemeOption.Values, "Custom") then
			local Values = table.clone(Library.Themes)
			Values[#Values + 1] = "Custom"
			ThemeOption:SetValues(Values)
		end
		ThemeOption:SetValue("Custom")
	end

	-- Five semantic colors instead of 35+ low-level engine properties.
	-- They remain hidden unless someone explicitly chooses to customize.
	local EditorOpen = false
	local ResetButton

	local EditorButton = Section:AddButton({
		Title = "Edit Custom Palette",
		Callback = function()
			EditorOpen = not EditorOpen
			for _, Picker in pairs(Pickers) do
				Picker:SetVisibility(EditorOpen)
			end
			if ResetButton then ResetButton.Frame.Visible = EditorOpen end
		end,
	})

	for _, Item in ipairs(PaletteOptions) do
		local Key = Item.Key
		-- Colorpicker:New calls Display() before returning. Its initial callback
		-- must never be mistaken for a real edit or persist "Custom".
		local PickerReady = false
		local Picker = Section:AddColorpicker("InterfaceManager_" .. Key, {
			Title = Item.Title,
			Default = ReadPaletteColor(InitialPalette, Key, OriginalPalette[Key]),
			UpdateOnChange = false,
			ImmediateCallback = true,
			Callback = function(Value)
				if not PickerReady or SyncingPickers or typeof(Value) ~= "Color3" then return end
				local Hex = Value:ToHex()
				local ActivePalette = GetVisiblePalette(Library, Settings.Theme, Settings.CustomPalette)
				-- Initial, programmatic, and canceled edits must never change the
				-- selected theme or overwrite the saved Custom palette.
				if string.upper(ActivePalette[Key] or "") == Hex then return end

				-- Editing a preset starts a NEW Custom palette based on the colors
				-- the user actually sees, not an unrelated previously saved palette.
				if Settings.Theme ~= "Custom" then
					Settings.CustomPalette = table.clone(ActivePalette)
				end
				Settings.CustomPalette[Key] = Hex
				ApplyCustomPalette(Library, Settings.CustomPalette)
				ShowCustomTheme()
			end,
		})
		Picker:SetVisibility(false)
		Pickers[Key] = Picker
		PickerReady = true
	end

	ResetButton = Section:AddButton({
		Title = "Reset Custom Colors",
		Callback = function()
			Settings.CustomPalette = table.clone(OriginalPalette)
			ApplyCustomPalette(Library, Settings.CustomPalette)
			-- Switching to Custom synchronizes all five controls in one pass.
			ShowCustomTheme()
		end,
	})
	ResetButton.Frame.Visible = false
	SyncPalettePickers(Settings.Theme)

	if Library.UseAcrylic then
		Section:AddToggle("InterfaceManager_AcrylicToggle", {
			Title = "Acrylic",
			Default = Settings.Acrylic,
			Callback = function(Value)
				Library:ToggleAcrylic(Value)
				Settings.Acrylic = Value
				InterfaceManager:SaveSettings()
			end,
		})
	end

	Section:AddToggle("InterfaceManager_TransparentToggle", {
		Title = "Transparency",
		Default = Settings.Transparency,
		Callback = function(Value)
			Library:ToggleTransparency(Value)
			Settings.Transparency = Value
			InterfaceManager:SaveSettings()
		end,
	})

	local MenuKeybind = Section:AddKeybind("InterfaceManager_MenuKeybind", {
		Title = "Minimize Key",
		Default = Settings.MenuKeybind,
		ChangedCallback = function(Value)
			Settings.MenuKeybind = typeof(Value) == "EnumItem" and Value.Name or tostring(Value)
			InterfaceManager:SaveSettings()
		end,
	})
	Library.MinimizeKeybind = MenuKeybind

	if MigratedLegacyCustom then
		-- One-time migration: stop reloading an accidentally saved Custom mode.
		self:SaveSettings()
	end
end

return InterfaceManager
