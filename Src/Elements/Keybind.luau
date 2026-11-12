local UserInputService = game:GetService("UserInputService")

local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)
local InputRouter = require(Root.Modules.InputRouter)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Keybind"

function Element:New(Idx, Config)
	local Library = self.Library

	local Keybind = {
		Value = Config.Default or Config.Value or Enum.KeyCode.Unknown,
		Toggled = false,
		Mode = Config.Mode or "Toggle",
		Type = "Keybind",
		Callback = Config.Callback or function(Value) end,
		ChangedCallback = Config.ChangedCallback or function(New) end,
	}

	local Picking = false
	local PendingKey
	local CaptureReadyAt = 0
	local Destroyed = false
	local KeybindSignals = {}

	local KeybindFrame = require(Components.Element)(Config.Title or "Keybind", Config.Description, self.Container, true)

	Keybind.SetTitle = KeybindFrame.SetTitle
	Keybind.SetDesc = KeybindFrame.SetDesc

	local KeybindDisplayLabel = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = Library.Utilities:Prettify(Keybind.Value),
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(0, 0, 0, 14),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	local KeybindDisplayFrame = New("TextButton", {
		Size = UDim2.fromOffset(0, 30),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 0.9,
		Parent = KeybindFrame.Frame,
		AutomaticSize = Enum.AutomaticSize.X,
		ThemeTag = {
			BackgroundColor3 = "Keybind",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		New("UIStroke", {
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
		KeybindDisplayLabel,
	}) :: TextButton

	function Keybind:GetState()
		if UserInputService:GetFocusedTextBox() and Keybind.Mode ~= "Always" then
			return false
		end

		if Keybind.Mode == "Always" then
			return true
		elseif Keybind.Mode == "Hold" then
			if Keybind.Value == "None" then
				return false
			end

			local Key = Keybind.Value

			if Key == "LeftMousebutton" or Key == "RightMousebutton" then
				return Key == "LeftMousebutton" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
					or Key == "RightMousebutton"
						and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			else
				local KeyName = typeof(Keybind.Value) == "EnumItem" and Keybind.Value.Name or Keybind.Value
				local KeyCode = typeof(KeyName) == "string" and Enum.KeyCode[KeyName] or nil
				return KeyCode ~= nil and UserInputService:IsKeyDown(KeyCode)
			end
		else
			return Keybind.Toggled
		end
	end

	function Keybind:SetValue(Key, Mode)
		Key = Key or Keybind.Value
		Mode = Mode or Keybind.Mode

		rawset(Keybind, "Value", Key)
		Keybind.Mode = Mode

		KeybindDisplayLabel.Text = Library.Utilities:Prettify(Keybind.Value)

		if typeof(Keybind.ChangedCallback) == "function" then
			Library:SafeCallback(Keybind.ChangedCallback, Key)
		end
		if typeof(Keybind.Changed) == "function" then
			Library:SafeCallback(Keybind.Changed, Key)
		end
	end

	function Keybind:OnClick(Callback)
		Keybind.Clicked = Callback
	end

	function Keybind:OnChanged(Callback)
		Keybind.Changed = Callback
		Library:SafeCallback(Callback, Keybind.Value, Keybind.Value)
	end

	function Keybind:SetVisibility(Bool)
		KeybindFrame.Frame.Visible = Bool
	end

	function Keybind:DoClick()
		if typeof(Keybind.Callback) == "function" then
			Library:SafeCallback(Keybind.Callback, Keybind.Toggled)
		end
		if typeof(Keybind.Clicked) == "function" then
			Library:SafeCallback(Keybind.Clicked, Keybind.Toggled)
		end
	end

	function Keybind:Destroy()
		if Destroyed then return end
		Destroyed = true
		Picking = false
		InputRouter.Unregister(Keybind)
		Creator.DisconnectOwner(KeybindSignals)
		Creator.RemoveThemeObject(KeybindFrame.Frame, true)
		KeybindFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Creator.AddSignal(KeybindDisplayFrame.InputBegan, function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		Picking = true
		PendingKey = nil
		CaptureReadyAt = os.clock() + 0.15
		KeybindDisplayLabel.Text = "..."
	end, KeybindSignals)

	local function MatchesInput(Input, Key)
		if Key == "LeftMousebutton" then
			return Input.UserInputType == Enum.UserInputType.MouseButton1
		elseif Key == "RightMousebutton" then
			return Input.UserInputType == Enum.UserInputType.MouseButton2
		end
		return Input.UserInputType == Enum.UserInputType.Keyboard and
			(Input.KeyCode.Name == Key or Input.KeyCode == Key)
	end

	InputRouter.Register(Keybind, function(Input)
		if Destroyed or Library.Unloaded then return end
		if Picking then
			if os.clock() < CaptureReadyAt then return end
			if Input.UserInputType == Enum.UserInputType.Keyboard then
				PendingKey = Input.KeyCode.Name
			elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
				PendingKey = "LeftMousebutton"
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
				PendingKey = "RightMousebutton"
			end
			return
		end

		if Keybind.Mode == "Toggle" and not UserInputService:GetFocusedTextBox()
			and MatchesInput(Input, Keybind.Value) then
			Keybind.Toggled = not Keybind.Toggled
			Keybind:DoClick()
		end
	end, function(Input)
		if Destroyed or not Picking or not PendingKey then return end
		if MatchesInput(Input, PendingKey) then
			local Key = PendingKey
			PendingKey = nil
			Picking = false
			Keybind:SetValue(Key)
		end
	end)

	Keybind:SetValue(Keybind.Value)

	Library.Options[Idx] = Keybind

	Keybind.Instance = KeybindFrame

	return setmetatable(Keybind, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				Creator.Spawn(Keybind.SetValue, Keybind, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element
