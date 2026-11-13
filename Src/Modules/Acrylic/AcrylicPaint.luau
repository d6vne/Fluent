local Root = script.Parent.Parent.Parent
local Creator = require(Root.Modules.Creator)
local AcrylicBlur = require(script.Parent.AcrylicBlur)

local New = Creator.New

-- One visible, theme-colored window surface. The old implementation stacked
-- three full-size backgrounds (one with a gradient), then set all of them
-- opaque when Transparency was disabled. That hid AcrylicMain behind the
-- gradient and made palette changes look inverted or inconsistent.
return function()
	local AcrylicPaint = {}

	-- Expose the real painted surface and its stroke so SetTheme can
	-- deterministically update the full-window background in the same call.
	local Border = New("UIStroke", {
		Thickness = 1,
		Transparency = 0.45,
		ThemeTag = { Color = "AcrylicBorder" },
	})
	local Background = New("Frame", {
		Name = "Background",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ThemeTag = { BackgroundColor3 = "AcrylicMain" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Border,
	})
	AcrylicPaint.Background = Background
	AcrylicPaint.Border = Border

	AcrylicPaint.Frame = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		New("ImageLabel", {
			Image = "rbxassetid://8992230677",
			ScaleType = "Slice",
			SliceCenter = Rect.new(Vector2.new(99, 99), Vector2.new(99, 99)),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(1, 120, 1, 116),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 1,
			ImageColor3 = Color3.new(0, 0, 0),
			ImageTransparency = 0.7,
		}),
		Background,
	})

	-- The optional blur still works, but never adds a second tinted surface.
	if require(Root).UseAcrylic then
		local Blur = AcrylicBlur()
		Blur.Frame.Parent = AcrylicPaint.Frame
		AcrylicPaint.Model = Blur.Model
		AcrylicPaint.AddParent = Blur.AddParent
		AcrylicPaint.SetVisibility = Blur.SetVisibility
	end

	return AcrylicPaint
end
