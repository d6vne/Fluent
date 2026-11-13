local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New

-- Share one update listener across all section headings. Weak keys avoid
-- keeping removed GUI labels alive, even when sections are rebuilt.
local SectionLabels = setmetatable({}, { __mode = "k" })
local ThemeListenerConnected = false

local function TrackHeading(Label)
	SectionLabels[Label] = true
	if ThemeListenerConnected then return end
	ThemeListenerConnected = true

	Creator.AddSignal(require(Root).ThemeChanged, function()
		local TextColor = Creator.GetThemeProperty("Text")
		if not TextColor then return end
		for Heading in next, SectionLabels do
			if Heading.Parent and Heading.TextColor3 ~= TextColor then
				Heading.TextColor3 = TextColor
			end
		end
	end)
end

return function(Title, Parent)
	local Section = {}

	Section.Layout = New("UIListLayout", {
		Padding = UDim.new(0, 5),
	})

	Section.Container = New("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.fromOffset(0, 24),
		BackgroundTransparency = 1,
	}, {
		Section.Layout,
	})

	-- Always initialize from the active theme, never Roblox's default
	-- TextLabel color. The ThemeTag also covers standard theme updates.
	local Heading = New("TextLabel", {
		RichText = true,
		Text = Title,
		TextColor3 = Creator.GetThemeProperty("Text"),
		TextTransparency = 0,
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		TextSize = 18,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		Size = UDim2.new(1, -16, 0, 18),
		Position = UDim2.fromOffset(0, 2),
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	Section.Root = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 7,
		Parent = Parent,
	}, {
		Heading,
		Section.Container,
	})

	Section.Heading = Heading
	TrackHeading(Heading)

	Creator.AddSignal(Section.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		if Section.Container.Size ~= UDim2.new(1, 0, 0, Section.Layout.AbsoluteContentSize.Y) or Section.Root.Size ~= UDim2.new(1, 0, 0, Section.Layout.AbsoluteContentSize.Y + 25) then
			Section.Container.Size = UDim2.new(1, 0, 0, Section.Layout.AbsoluteContentSize.Y)
			Section.Root.Size = UDim2.new(1, 0, 0, Section.Layout.AbsoluteContentSize.Y + 25)
		end
	end)

	return Section
end
