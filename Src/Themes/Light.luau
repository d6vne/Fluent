return {
	Accent = Color3.fromHex("2563EB"),

	AcrylicMain = Color3.fromHex("F1F5F9"),
	AcrylicBorder = Color3.fromHex("CBD5E1"),
	AcrylicGradient = ColorSequence.new(Color3.fromHex("F8FAFC"), Color3.fromHex("E2E8F0")),
	AcrylicNoise = 0.96,

	TitleBarLine = Color3.fromHex("CBD5E1"),
	Tab = Color3.fromHex("475569"),

	Element = Color3.fromHex("FFFFFF"),
	ElementBorder = Color3.fromHex("CBD5E1"),
	InElementBorder = Color3.fromHex("94A3B8"),
	ElementTransparency = 0.25,

	-- Dark inactive switch and distinct white knob on the blue active track.
	ToggleSlider = Color3.fromHex("1E293B"),
	ToggleToggled = Color3.fromRGB(255, 255, 255),
	ToggleOffTransparency = 0.1,
	ToggleOnTransparency = 0,
	ToggleBorderTransparency = 0.15,

	SliderRail = Color3.fromHex("64748B"),

	DropdownFrame = Color3.fromHex("F1F5F9"),
	DropdownHolder = Color3.fromHex("FFFFFF"),
	DropdownBorder = Color3.fromHex("CBD5E1"),
	DropdownOption = Color3.fromHex("F1F5F9"),

	Keybind = Color3.fromHex("E2E8F0"),

	Input = Color3.fromHex("E2E8F0"),
	InputFocused = Color3.fromHex("DBEAFE"),
	InputIndicator = Color3.fromHex("64748B"),

	Dialog = Color3.fromHex("FFFFFF"),
	DialogHolder = Color3.fromHex("F8FAFC"),
	DialogHolderLine = Color3.fromHex("E2E8F0"),
	DialogButton = Color3.fromHex("F1F5F9"),
	DialogButtonBorder = Color3.fromHex("CBD5E1"),
	DialogBorder = Color3.fromHex("CBD5E1"),
	DialogInput = Color3.fromHex("F8FAFC"),
	DialogInputLine = Color3.fromHex("94A3B8"),

	-- Consistent black text across titles, labels, sliders and placeholders.
	Text = Color3.fromRGB(0, 0, 0),
	SubText = Color3.fromRGB(0, 0, 0),
	-- 0 alpha makes the subtitle actual black, not gray composited text.
	SubtitleTransparency = 0,
	Hover = Color3.fromHex("E2E8F0"),
	HoverChange = 0.06
}
