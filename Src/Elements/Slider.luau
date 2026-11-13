local UserInputService = game:GetService("UserInputService")
local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Slider"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Max, "Slider - Missing maximum value.")

	local Slider = {
		Value = nil,
		Min = typeof(Config.Min) == "number" and Config.Min or 0,
		Max = Config.Max,
		Rounding = typeof(Config.Rounding) == "number" and Config.Rounding or 0,
		Ranged = typeof(Config.Ranged) == "boolean" and Config.Ranged or false,
		Callback = typeof(Config.Callback) == "function" and Config.Callback or function(Value, OldValue) end,
		Changed = Config.Changed or function() end,
		Type = "Slider"
	}

	

	local SliderFrame = require(Components.Element)(Config.Title or "Slider", Config.Description, self.Container, false)
	SliderFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

	Slider.SetTitle = SliderFrame.SetTitle
	Slider.SetDesc = SliderFrame.SetDesc
	
	local Null = table.freeze({})
	
	local DotCount = Slider.Ranged and 2 or 1
	
	local SliderDots = table.create(DotCount, Null)
	local Dragging = table.create(DotCount, Null)
	local SliderSignals = {}
	local onInputChanged
	local ActiveTouch, ActiveChange, ActiveEnd

	local function StopDragging()
		for Index = 1, DotCount do
			Dragging[Index] = false
		end
		ActiveTouch = nil
		if ActiveChange then
			ActiveChange:Disconnect()
			ActiveChange = nil
		end
		if ActiveEnd then
			ActiveEnd:Disconnect()
			ActiveEnd = nil
		end
	end
	
	for i = 1, DotCount do
		
		Dragging[i] = false
		
		-- A real themed shape instead of an asset-tinted image. ImageColor3
		-- multiplies source pixel colors and can never guarantee the exact
		-- accent chosen by the active theme.
		local SliderDot = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -7, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			Active = true,
			ZIndex = 2,
			ThemeTag = {
				BackgroundColor3 = "Accent",
			},
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			New("UIStroke", {
				Thickness = 1,
				Transparency = 0.3,
				ThemeTag = { Color = "AcrylicBorder" },
			}),
		})
		
		Creator.AddSignal(SliderDot.InputBegan, function(Input)
			if
				Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch
			then
				Dragging[i] = true
				ActiveTouch = Input.UserInputType == Enum.UserInputType.Touch and Input or nil
				if not ActiveChange then
					ActiveChange = UserInputService.InputChanged:Connect(function(Changed)
						if (ActiveTouch and Changed == ActiveTouch)
							or (not ActiveTouch and Changed.UserInputType == Enum.UserInputType.MouseMovement) then
							onInputChanged(Changed)
						end
					end)
					ActiveEnd = UserInputService.InputEnded:Connect(function(Ended)
						if (ActiveTouch and Ended == ActiveTouch)
							or (not ActiveTouch and Ended.UserInputType == Enum.UserInputType.MouseButton1) then
							StopDragging()
						end
					end)
				end
			end
		end, SliderSignals)

		Creator.AddSignal(SliderDot.InputEnded, function(Input)
			if
				Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch
			then
				StopDragging()
			end
		end, SliderSignals)
		
		SliderDots[i] = SliderDot
	end

	local SliderRail = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(7, 0),
		Size = UDim2.new(1, -14, 1, 0)
	}, SliderDots)

	local SliderFill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		ThemeTag = {
			BackgroundColor3 = "Accent",
		}
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(1, 0),
		})
	})

	local SliderDisplay = New("TextBox", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = "Value",
		ClearTextOnFocus = true,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 100, 0, 14),
		Position = UDim2.new(0, -4, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ThemeTag = {
			TextColor3 = "SubText",
		}
	})

	local SliderTrack = New("Frame", {
		Size = UDim2.new(1, 0, 0, 4),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		BackgroundTransparency = 0.4,
		Parent = SliderFrame.Frame,
		ThemeTag = {
			BackgroundColor3 = "SliderRail",
		}
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		New("UISizeConstraint", {
			MaxSize = Vector2.new(150, math.huge),
		}),
		SliderDisplay,
		SliderFill,
		SliderRail
	})

	-- Reapply the visible slider colors in the same theme-change event.
	-- The Creator registry handles the initial paint; this keeps the track,
	-- fill and thumbs consistent even after interactions with their GUI state.
	Creator.AddSignal(Library.ThemeChanged, function()
		local Accent = Creator.GetThemeProperty("Accent")
		local Rail = Creator.GetThemeProperty("SliderRail")
		local Text = Creator.GetThemeProperty("SubText")
		if Accent then
			SliderFill.BackgroundColor3 = Accent
			for _, Dot in ipairs(SliderDots) do
				Dot.BackgroundColor3 = Accent
			end
		end
		if Rail then SliderTrack.BackgroundColor3 = Rail end
		if Text then SliderDisplay.TextColor3 = Text end
	end, SliderSignals)

	function Slider:OnChanged(Func)
		Slider.Changed = Func
		Library:SafeCallback(Func, Slider.Value, Slider.Value)
	end

	function Slider:SetVisibility(Bool)
		SliderFrame.Frame.Visible = Bool
	end

	function Slider:SetValue(Value: number | NumberRange)
		local OldValue = self.Value or Value
		
		if Slider.Ranged then
			rawset(self, "Value", NumberRange.new(Library.Utilities:Round(math.clamp(Value.Min, Slider.Min, Slider.Max), Slider.Rounding), Library.Utilities:Round(math.clamp(Value.Max, Slider.Min, Slider.Max), Slider.Rounding)))
			local min = math.map(self.Value.Min, Slider.Min, Slider.Max, 0, 1)
			local max = math.map(self.Value.Max, Slider.Min, Slider.Max, 0, 1)
			SliderDots[1].Position = UDim2.new(min, -7, 0.5, 0)
			SliderDots[2].Position = UDim2.new(max, -7, 0.5, 0)
			SliderFill.Position = UDim2.new((min * SliderRail.AbsoluteSize.X) / (SliderRail.AbsoluteSize.X + 14), 7, SliderFill.Position.Y.Scale, SliderFill.Position.Y.Offset)
			SliderFill.Size = UDim2.new(0, SliderDots[2].AbsolutePosition.X - SliderDots[1].AbsolutePosition.X, 1, 0)
			SliderDisplay.Text = tostring(self.Value)
		else
			rawset(self, "Value", Library.Utilities:Round(math.clamp(Value, Slider.Min, Slider.Max), Slider.Rounding))
			SliderDots[1].Position = UDim2.new(math.map(self.Value, Slider.Min, Slider.Max, 0, 1), -7, 0.5, 0)
			SliderFill.Size = UDim2.fromScale(math.map(self.Value, Slider.Min, Slider.Max, 0, 1), 1)
			SliderDisplay.Text = tostring(self.Value)
		end

		if typeof(Slider.Callback) == "function" then
			Library:SafeCallback(Slider.Callback, self.Value, OldValue)
		end
		
		if typeof(Slider.Changed) == "function" then
			Library:SafeCallback(Slider.Changed, self.Value, OldValue)
		end
	end
	
	if Slider.Ranged then
		function onInputChanged(Input: InputObject)
			if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
				if Dragging[1] or Dragging[2] then
					local SizeScale = math.clamp((Input.Position.X - SliderRail.AbsolutePosition.X) / math.max(SliderRail.AbsoluteSize.X, 1), 0, 1)
					local Value
					if Dragging[1] then
						local Min = Slider.Min + ((Slider.Max - Slider.Min) * SizeScale)
						local Max = math.max(Min, Slider.Value.Max)
						Value = NumberRange.new(Min, Max)
						Slider:SetValue(Value)
					elseif Dragging[2] then
						local Max = Slider.Min + ((Slider.Max - Slider.Min) * SizeScale)
						local Min = math.min(Max, Slider.Value.Min)
						Value = NumberRange.new(Min, Max)
						Slider:SetValue(Value)
					end
				end
			end
		end
	else
		function onInputChanged(Input: InputObject)
			if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
				if Dragging[1] then
					local SizeScale =
						math.clamp((Input.Position.X - SliderRail.AbsolutePosition.X) / math.max(SliderRail.AbsoluteSize.X, 1), 0, 1)
					Slider:SetValue(Slider.Min + ((Slider.Max - Slider.Min) * SizeScale))
				end
			end
		end
	end
	
	Creator.AddSignal(SliderDisplay.FocusLost, function()
		if Slider.Ranged then
			local Split = string.split(SliderDisplay.Text, " ")
			local Min = tonumber(Split[1])
			local Max = tonumber(Split[2])
			if Min and Max then
				Slider:SetValue(NumberRange.new(math.min(Min, Max), math.max(Min, Max)))
			else
				SliderDisplay.Text = tostring(Slider.Value)
			end
		else
			Slider:SetValue(tonumber(SliderDisplay.Text) or Slider.Value)
		end
	end, SliderSignals)

	function Slider:Destroy()
		StopDragging()
		Creator.DisconnectOwner(SliderSignals)
		Creator.RemoveThemeObject(SliderFrame.Frame, true)
		SliderFrame:Destroy()
		Library.Options[Idx] = nil
	end
	
	if Slider.Ranged then
		Slider:SetValue(typeof(Config.Default) == "NumberRange" and Config.Default or NumberRange.new(Slider.Min))
	else
		Slider:SetValue(typeof(Config.Default) == "number" and Config.Default or Slider.Min)
	end

	Library.Options[Idx] = Slider

	Slider.Instance = SliderFrame

	return setmetatable(Slider, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				Creator.Spawn(Slider.SetValue, Slider, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element
