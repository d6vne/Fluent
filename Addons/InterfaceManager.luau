local HttpService = game:GetService("HttpService")

-- A compact, Obsidian-inspired interface manager. Keep the existing Fluent
-- theme engine and public Addon API; expose only five semantic palette colors.
local InterfaceManager = {
	Folder = "FluentSettings",
	Library = nil,
	Settings = {},
}

local PaletteOptions = {
	{ Key = "FontColor", Title = "Font color" },
	{ Key = "MainColor", Title = "Main color" },
	{ Key = "AccentColor", Title = "Accent color" },
	{ Key = "BackgroundColor", Title = "Background color" },
	{ Key = "OutlineColor", Title = "Outline color" },
}

local OriginalPalette

local function GetDefaultPalette(Library)
	local Custom = Library.Utilities.Themes.Custom
	return {
		FontColor = Custom.Text:ToHex(),
		MainColor = Custom.Element:ToHex(),
		AccentColor = Custom.Accent:ToHex(),
		BackgroundColor = Custom.Dialog:ToHex(),
		OutlineColor = Custom.ElementBorder:ToHex(),
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
	Custom.ElementBorder = Outline
	Custom.InElementBorder = Outline
	Custom.ToggleSlider = Main
	Custom.ToggleToggled = Background
	Custom.SliderRail = Main
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
	if typeof(Data.Theme) == "string" then Settings.Theme = Data.Theme end
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
end

function InterfaceManager:BuildInterfaceSection(Tab)
	assert(self.Library, "Must set InterfaceManager.Library")

	local Library = self.Library
	local Settings = self.Settings
	self:LoadSettings()

	if not table.find(Library.Themes, Settings.Theme) then
		Settings.Theme = Library.Theme
	end
	ApplyCustomPalette(Library, Settings.CustomPalette)
	Library:SetTheme(Settings.Theme)

	local Section = Tab:AddSection("Appearance")
	local ThemeOption = Section:AddDropdown("InterfaceManager_InterfaceTheme", {
		Title = "Theme",
		Values = Library.Themes,
		Searchable = true,
		Default = Settings.Theme,
		Callback = function(Value)
			if typeof(Value) ~= "string" or not table.find(Library.Themes, Value) then return end
			Library:SetTheme(Value)
			Settings.Theme = Value
			InterfaceManager:SaveSettings()
		end,
	})

	-- Five semantic colors instead of 35+ low-level engine properties.
	-- They remain hidden unless someone explicitly chooses to customize.
	local EditorOpen = false
	local Pickers = {}
	local IgnoreNextColor = {}
	local ResetButton

	local EditorButton = Section:AddButton({
		Title = "Customize colors",
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
		local FirstCallback = true
		local Picker = Section:AddColorpicker("InterfaceManager_" .. Key, {
			Title = Item.Title,
			Default = ReadPaletteColor(Settings.CustomPalette, Key, OriginalPalette[Key]),
			UpdateOnChange = false,
			Callback = function(Value)
				-- A colorpicker invokes its callback during creation. That is not
				-- a user edit and must not switch the theme or write settings.
				if FirstCallback then
					FirstCallback = false
					return
				end
				if IgnoreNextColor[Key] == Value then
					IgnoreNextColor[Key] = nil
					return
				end
				if typeof(Value) ~= "Color3" then return end

				Settings.CustomPalette[Key] = Value:ToHex()
				ApplyCustomPalette(Library, Settings.CustomPalette)
				Settings.Theme = "Custom"
				ThemeOption:SetValue("Custom")
				Library:SetTheme("Custom")
				InterfaceManager:SaveSettings()
			end,
		})
		Picker:SetVisibility(false)
		Pickers[Key] = Picker
	end

	ResetButton = Section:AddButton({
		Title = "Reset custom colors",
		Callback = function()
			Settings.CustomPalette = table.clone(OriginalPalette)
			ApplyCustomPalette(Library, Settings.CustomPalette)
			Settings.Theme = "Custom"
			for _, Item in ipairs(PaletteOptions) do
				local Color = Color3.fromHex(OriginalPalette[Item.Key])
				IgnoreNextColor[Item.Key] = Color
				Pickers[Item.Key]:SetValueRGB(Color, 0)
			end
			ThemeOption:SetValue("Custom")
			Library:SetTheme("Custom")
			InterfaceManager:SaveSettings()
		end,
	})
	ResetButton.Frame.Visible = false

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
		Title = "Minimize key",
		Default = Settings.MenuKeybind,
		ChangedCallback = function(Value)
			Settings.MenuKeybind = typeof(Value) == "EnumItem" and Value.Name or tostring(Value)
			InterfaceManager:SaveSettings()
		end,
	})
	Library.MinimizeKeybind = MenuKeybind
end

return InterfaceManager
