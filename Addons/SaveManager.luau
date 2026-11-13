local httpService = game:GetService("HttpService")

type Dropdown = { Value: any, Values: { i: any }, Multi: boolean, Displayer: (v) -> n?, SetValue: (any) -> () }

local DisplayerParser = {
	Encode = function(Value)
		local Encoded = {}

		for Val: any, Bool: boolean in Value do
			table.insert(Encoded, Val)
		end

		return Encoded
	end,
}

local function TableEqual(Table, Reflect)
	for Index, Value in Table do
		if Reflect[Index] ~= Value then
			return false
		end
	end

	return true
end

local function SetDisplayerDropdownValue(Dropdown: Dropdown, Value)
	if Dropdown.Multi then
		local Values = {}

		for _, DataValue in Value do
			for _, DropdownValue in Dropdown.Values do
				if typeof(DropdownValue) ~= "table" or not TableEqual(DataValue, DropdownValue) then
					continue
				end

				Values[DropdownValue] = true
				break
			end
		end

		Dropdown:SetValue(Values)
	else
		for _, DropdownValue in Dropdown.Values do
			if typeof(DropdownValue) ~= "table" or not TableEqual(Value, DropdownValue) then
				continue
			end

			Dropdown:SetValue(DropdownValue)
			break
		end
	end
end

local SaveManager = {}
do
	SaveManager.Folder = "FluentSettings"
	SaveManager.Ignore = {}
	SaveManager.Options, SaveManager.Library =
		{} :: {
			[string]: {
				Type: string,
				Value: any,
				SetValues: (self: any, NewValue: { [any]: any }) -> nil,
				SetValue: (self: any, NewValue: any, ...any) -> nil,
				SetValueRGB: (self: any, NewValue: Color3, Transparency: number?) -> nil,
			},
		},
		{}
	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object)
				return { type = "Toggle", idx = idx, value = object.Value, Timestamp = object.Instance.CreatedAt }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then
					SaveManager.Options[idx]:SetValue(data.value)
				end
			end,
		},
		Slider = {
			Save = function(idx, object)
				return { type = "Slider", idx = idx, value = object.Value, Timestamp = object.Instance.CreatedAt }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then
					SaveManager.Options[idx]:SetValue(data.value)
				end
			end,
		},
		Dropdown = {
			Save = function(idx, object)
				local HasDisplayer = object.CustomDisplayer

				return {
					type = "Dropdown",
					idx = idx,
					value = (HasDisplayer and object.Multi and DisplayerParser.Encode(object.Value) or object.Value),
					mutli = object.Multi,
					Timestamp = object.Instance.CreatedAt,
					displayer = HasDisplayer,
				}
			end,
			Load = function(idx, data)
				if data.value == nil then
					return
				end

				local DropdownElement = SaveManager.Options[idx]
				if not DropdownElement then
					return
				end

				local Value = data.value
				if typeof(Value) ~= "table" or not data.displayer then
					DropdownElement:SetValue(Value)
					return
				end

				SetDisplayerDropdownValue(DropdownElement, Value)
			end,
		},
		Colorpicker = {
			Save = function(idx, object)
				return {
					type = "Colorpicker",
					idx = idx,
					value = object.Value:ToHex(),
					transparency = object.Transparency,
					Timestamp = object.Instance.CreatedAt,
				}
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then
					SaveManager.Options[idx]:SetValueRGB(Color3.fromHex(data.value), data.transparency)
				end
			end,
		},
		Keybind = {
			Save = function(idx, object)
				return {
					type = "Keybind",
					idx = idx,
					mode = object.Mode,
					key = object.Value,
					Timestamp = object.Instance.CreatedAt,
				}
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then
					SaveManager.Options[idx]:SetValue(data.key, data.mode)
				end
			end,
		},

		Input = {
			Save = function(idx, object)
				return { type = "Input", idx = idx, text = object.Value, Timestamp = object.Instance.CreatedAt }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] and type(data.text) == "string" then
					SaveManager.Options[idx]:SetValue(data.text)
				end
			end,
		},
	}

	local function ValidConfigName(Name)
		return type(Name) == "string"
			and Name:match("%S") ~= nil
			and Name ~= "."
			and Name ~= ".."
			and not Name:find("[/\\\\:%*%?%\"<>|]")
			and not Name:find("..", 1, true)
	end

	function SaveManager:Delete(Name): (boolean, string?)
		if not ValidConfigName(Name) then return false, "Invalid config name" end
		local Path = `{self.Folder}/settings/{Name}.json`
		if not isfile(Path) then return false, "Config does not exist" end
		local Success, Err = pcall(delfile, Path)
		if not Success then return false, tostring(Err) end
		local AutoloadPath = `{self.Folder}/settings/autoload.txt`
		if isfile(AutoloadPath) and readfile(AutoloadPath) == Name then
			pcall(delfile, AutoloadPath)
		end
		return true
	end

	function SaveManager:Rename(OldName, NewName): (boolean, string?)
		if not ValidConfigName(OldName) or not ValidConfigName(NewName) then
			return false, "Invalid config name"
		end
		if OldName == NewName then return false, "Choose a different name" end
		local OldPath = `{self.Folder}/settings/{OldName}.json`
		local NewPath = `{self.Folder}/settings/{NewName}.json`
		if not isfile(OldPath) then return false, "Config does not exist" end
		if isfile(NewPath) then return false, "A config with that name already exists" end
		local ReadSuccess, Data = pcall(readfile, OldPath)
		if not ReadSuccess then return false, tostring(Data) end
		local WriteSuccess, WriteError = pcall(writefile, NewPath, Data)
		if not WriteSuccess then return false, tostring(WriteError) end
		local DeleteSuccess, DeleteError = pcall(delfile, OldPath)
		if not DeleteSuccess then
			pcall(delfile, NewPath)
			return false, tostring(DeleteError)
		end
		local AutoloadPath = `{self.Folder}/settings/autoload.txt`
		if isfile(AutoloadPath) and readfile(AutoloadPath) == OldName then
			local AutoloadSuccess, AutoloadError = pcall(writefile, AutoloadPath, NewName)
			if not AutoloadSuccess then
				return false, "Renamed config, but failed to update autoload: " .. tostring(AutoloadError)
			end
		end
		return true
	end

	function SaveManager:SetIgnoreIndexes(list)
		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function SaveManager:Save(name): (boolean, string?)
		if not ValidConfigName(name) then
			return false, "No valid config file is selected"
		end

		local fullPath = `{self.Folder}/settings/{name}.json`

		local data = {
			objects = {},
		}

		for idx, option in next, SaveManager.Options do
			if not self.Parser[option.Type] then
				continue
			end
			if self.Ignore[idx] then
				continue
			end

			data.objects[#data.objects + 1] = self.Parser[option.Type].Save(idx, option)
		end

		table.sort(data.objects, function(v1: { Timestamp: number }, v2: { Timestamp: number })
			return v1.Timestamp < v2.Timestamp
		end)

		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then
			return false, "Failed to JSON-Encode data"
		end

		writefile(fullPath, encoded)
		return true
	end

	function SaveManager:Load(name): (boolean, string?)
		if not name then
			return false, "No config file is selected"
		end

		local file = `{self.Folder}/settings/{name}.json`
		if not isfile(file) then
			return false, "invalid file"
		end

		local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
		if not success then
			return false, "decode error"
		end

		if typeof(decoded) ~= "table" or typeof(decoded.objects) ~= "table" then
			return false, "invalid config contents"
		end

		for _, option in next, decoded.objects do
			-- IgnoreThemeSettings must also apply when LOADING old config files.
			-- Before this, legacy saved theme/color options were replayed
			-- asynchronously and could override the active Appearance theme.
			if typeof(option) == "table"
				and typeof(option.idx) == "string"
				and not self.Ignore[option.idx]
				and self.Parser[option.type] then
				task.spawn(self.Library.SafeCallback, self.Library, self.Parser[option.type].Load, option.idx, option)
			end
		end

		-- A gameplay configuration must never trigger a theme refresh.
		-- InterfaceManager owns that lifecycle independently.
		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({
			"InterfaceManager_InterfaceTheme",
			"InterfaceManager_AcrylicToggle",
			"InterfaceManager_TransparentToggle",
			"InterfaceManager_MenuKeybind",
			"InterfaceManager_FontColor",
			"InterfaceManager_MainColor",
			"InterfaceManager_AccentColor",
			"InterfaceManager_BackgroundColor",
			"InterfaceManager_OutlineColor",
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {
			self.Folder,
			`{self.Folder}/settings`,
		}

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function SaveManager:RefreshConfigList()
		local list = listfiles(`{self.Folder}/settings`)

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == ".json" then
				local pos = file:find(".json", 1, true)
				local start = pos

				if typeof(pos) == "number" and typeof(start) == "number" then
					local char = file:sub(pos, pos)
					while char ~= "/" and char ~= "\\" and char ~= "" do
						pos = pos - 1
						char = file:sub(pos, pos)
					end

					if char == "/" or char == "\\" then
						local name = file:sub(pos + 1, start - 1)
						if name ~= "options" then
							out[#out + 1] = name
						end
					end
				end
			end
		end

		return out
	end

	function SaveManager:SetLibrary(library)
		self.Library = library
		self.Options = library.Options
	end

	function SaveManager:LoadAutoloadConfig()
		if isfile(`{self.Folder}/settings/autoload.txt`) then
			local name = readfile(`{self.Folder}/settings/autoload.txt`)

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify({
					Title = "Interface",
					Content = "Config Loader",
					SubContent = `Failed to load autoload config: {err}`,
					Duration = 7,
				})
			end

			return self.Library:Notify({
				Title = "Interface",
				Content = "Config Loader",
				SubContent = string.format("Auto loaded config %q", name),
				Duration = 7,
			})
		end

		return nil
	end

	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, "Must set SaveManager.Library")

		local section = tab:AddSection("Configuration")

		section:AddInput("SaveManager_ConfigName", { Title = "Config Name" })
		section:AddDropdown(
			"SaveManager_ConfigList",
			{ Title = "Config List", Values = self:RefreshConfigList(), AllowNull = true }
		)

		section:AddButton({
			Title = "Create Config",
			Callback = function()
				local name = SaveManager.Options.SaveManager_ConfigName.Value

				if string.gsub(name, " ", "") == "" then
					return self.Library:Notify({
						Title = "Interface",
						Content = "Config Loader",
						SubContent = "Invalid config name (empty)",
						Duration = 7,
					})
				end

				local success, err = self:Save(name)
				if not success then
					return self.Library:Notify({
						Title = "Interface",
						Content = "Config Loader",
						SubContent = "Failed to save config: " .. err,
						Duration = 7,
					})
				end

				self.Library:Notify({
					Title = "Interface",
					Content = "Config Loader",
					SubContent = string.format("Created config %q", name),
					Duration = 7,
				})

				SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				SaveManager.Options.SaveManager_ConfigList:SetValue(nil)

				return nil
			end,
		})

		section:AddButton({
			Title = "Load Config",
			Callback = function()
				local name = SaveManager.Options.SaveManager_ConfigList.Value

				local success, err = self:Load(name)
				if not success then
					return self.Library:Notify({
						Title = "Interface",
						Content = "Config Loader",
						SubContent = "Failed to load config: " .. err,
						Duration = 7,
					})
				end

				return self.Library:Notify({
					Title = "Interface",
					Content = "Config Loader",
					SubContent = string.format("Loaded config %q", name),
					Duration = 7,
				})
			end,
		})

		section:AddButton({
			Title = "Overwrite Config",
			Callback = function()
				local name = SaveManager.Options.SaveManager_ConfigList.Value

				local success, err = self:Save(name)
				if not success then
					return self.Library:Notify({
						Title = "Interface",
						Content = "Config Loader",
						SubContent = "Failed to overwrite config: " .. err,
						Duration = 7,
					})
				end

				return self.Library:Notify({
					Title = "Interface",
					Content = "Config Loader",
					SubContent = string.format("Overwrote config %q", name),
					Duration = 7,
				})
			end,
		})

		section:AddButton({
			Title = "Rename Config",
			Description = "Rename selected config to the Config Name field",
			Callback = function()
				local OldName = SaveManager.Options.SaveManager_ConfigList.Value
				local NewName = SaveManager.Options.SaveManager_ConfigName.Value
				local Success, Err = self:Rename(OldName, NewName)
				self.Library:Notify({
					Title = "Interface",
					Content = "Config Loader",
					SubContent = Success and string.format("Renamed %q to %q", OldName, NewName) or "Failed to rename config: " .. Err,
					Duration = 7,
				})
				if Success then
					SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
					SaveManager.Options.SaveManager_ConfigList:SetValue(NewName)
				end
			end,
		})

		section:AddButton({
			Title = "Delete Config",
			Description = "Permanently delete the selected config",
			Callback = function()
				local Name = SaveManager.Options.SaveManager_ConfigList.Value
				local Success, Err = self:Delete(Name)
				self.Library:Notify({
					Title = "Interface",
					Content = "Config Loader",
					SubContent = Success and string.format("Deleted config %q", Name) or "Failed to delete config: " .. Err,
					Duration = 7,
				})
				if Success then
					SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
					SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
				end
			end,
		})

		section:AddButton({
			Title = "Refresh List",
			Callback = function()
				SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
			end,
		})

		local AutoloadButton
		AutoloadButton = section:AddButton({
			Title = "Set As Autoload",
			Description = "Current Autoload Config: None",
			Callback = function()
				local name = SaveManager.Options.SaveManager_ConfigList.Value
				writefile(`{self.Folder}/settings/autoload.txt`, name)
				AutoloadButton:SetDesc("Current Autoload Config: " .. name)
				self.Library:Notify({
					Title = "Interface",
					Content = "Config Loader",
					SubContent = string.format("Set %q to auto load", name),
					Duration = 7,
				})
			end,
		})

		if isfile(`{self.Folder}/settings/autoload.txt`) then
			local name = readfile(`{self.Folder}/settings/autoload.txt`)
			AutoloadButton:SetDesc("Current Autoload Config: " .. name)
		end

		SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
