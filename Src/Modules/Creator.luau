local Root = script.Parent.Parent
local Themes = require(Root.Themes)
local Flipper = require(Root.Packages.Flipper)
local Signal = require(Root.Packages.Signal)

local Library
local function getLibrary()
	if not Library then
		Library = require(Root)
	end
	return Library
end

local Creator = {
	Registry = setmetatable({}, { __mode = "k" }),
	ActiveTheme = "Dark",
	Signals = {},
	Threads = {},
	TransparencyMotors = setmetatable({}, { __mode = "k" }),
	DefaultProperties = {
		ScreenGui = {
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		},
		Frame = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		},
		ScrollingFrame = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			ScrollBarImageColor3 = Color3.new(0, 0, 0),
		},
		TextLabel = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			Font = Enum.Font.SourceSans,
			Text = "",
			TextColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			TextSize = 14,
			RichText = true,
		},
		TextButton = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			AutoButtonColor = false,
			Font = Enum.Font.SourceSans,
			Text = "",
			TextColor3 = Color3.new(0, 0, 0),
			TextSize = 14,
			RichText = true,
		},
		TextBox = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			ClearTextOnFocus = false,
			Font = Enum.Font.SourceSans,
			Text = "",
			TextColor3 = Color3.new(0, 0, 0),
			TextSize = 14,
			RichText = true,
		},
		ImageLabel = {
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		},
		ImageButton = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			AutoButtonColor = false,
		},
		CanvasGroup = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		},
	},
	Theme = {
		Updating = false,
		Updated = Signal.new(),
	},
}

local function ReusableThreadCall(Function, Thread: thread, ...)
	Function(...)
	table.insert(Creator.Threads, Thread)
end

local function ReusableThread()
	while true do
		ReusableThreadCall(coroutine.yield())
	end
end

local function ApplyCustomProps(Object, Props: { [string]: any }?)
	if typeof(Props) == "table" and Props.ThemeTag then
		Creator.AddThemeObject(Object, Props.ThemeTag)
	end
end

function Creator.Spawn(Function, ...)
	local length = #Creator.Threads
	if length == 0 then
		local thread = coroutine.create(ReusableThread)
		coroutine.resume(thread)
		return task.spawn(thread, Function, thread, ...)
	else
		local thread = Creator.Threads[length]
		Creator.Threads[length] = nil -- Remove from free threads list.
		return task.spawn(thread, Function, thread, ...)
	end
end

function Creator.Defer(Function, ...)
	local length = #Creator.Threads
	if length == 0 then
		local thread = coroutine.create(ReusableThread)
		coroutine.resume(thread)
		return task.defer(thread, Function, thread, ...)
	else
		local thread = Creator.Threads[length]
		Creator.Threads[length] = nil -- Remove from free threads list.
		return task.defer(thread, Function, thread, ...)
	end
end

function Creator.Delay(Delay, Function, ...)
	local length = #Creator.Threads
	if length == 0 then
		local thread = coroutine.create(ReusableThread)
		coroutine.resume(thread)
		return task.delay(Delay, thread, Function, thread, ...)
	else
		local thread = Creator.Threads[length]
		Creator.Threads[length] = nil -- Remove from free threads list.
		return task.delay(Delay, thread, Function, thread, ...)
	end
end

function Creator.AddSignal(Signal: RBXScriptSignal, Function, Owner: { RBXScriptConnection }?)
	local Connection = Signal:Connect(Function)
	table.insert(Owner or Creator.Signals, Connection)
	return Connection
end

function Creator.DisconnectOwner(Connections: { RBXScriptConnection })
	for Index = #Connections, 1, -1 do
		local Connection = Connections[Index]
		Connection:Disconnect()
		Connections[Index] = nil
	end
end

function Creator.Disconnect()
	for Idx = #Creator.Signals, 1, -1 do
		local Connection = table.remove(Creator.Signals, Idx)

		if Connection then
			Connection:Disconnect()
		end
	end
end

function Creator.GetThemeProperty(Property)
	local CurrentTheme = Themes[Creator.ActiveTheme]

	if CurrentTheme and CurrentTheme[Property] ~= nil then
		return CurrentTheme[Property]
	end

	return Themes["Dark"][Property]
end

local function ApplyThemeProperties(Object: Instance, Properties)
	for Property, ThemeKey in next, Properties do
		local Value = Creator.GetThemeProperty(ThemeKey)
		if Value ~= nil and Object[Property] ~= Value then
			Object[Property] = Value
		end
	end
end

function Creator.UpdateTheme(RegistryIndex: Instance?)
	if Creator.Theme.Updating then
		Creator.Theme.Updated:Wait()
	end

	Creator.Theme.Updating = true
	Creator.ActiveTheme = getLibrary().Theme

	if typeof(RegistryIndex) == "Instance" then
		local Properties = Creator.Registry[RegistryIndex]
		if Properties then
			ApplyThemeProperties(RegistryIndex, Properties)
		end
	else
		for Object, Properties in next, Creator.Registry do
			ApplyThemeProperties(Object, Properties)
		end

		local Transparency = Creator.GetThemeProperty("ElementTransparency")
		if Transparency ~= nil then
			for _, Motor in next, Creator.TransparencyMotors do
				Motor:setGoal(Flipper.Instant.new(Transparency))
			end
		end
	end

	Creator.Theme.Updating = false
	Creator.Theme.Updated:Fire()
end

function Creator.AddThemeObject(Object: Instance, Properties: { [string]: any })
	Creator.Registry[Object] = Properties
	ApplyThemeProperties(Object, Properties)
	return Object
end

function Creator.RemoveThemeObject(Object: Instance, IncludeDescendants: boolean?)
	Creator.Registry[Object] = nil
	Creator.TransparencyMotors[Object] = nil

	if IncludeDescendants then
		for _, Descendant in ipairs(Object:GetDescendants()) do
			Creator.Registry[Descendant] = nil
			Creator.TransparencyMotors[Descendant] = nil
		end
	end
end

function Creator.OverrideTag(Object, Properties)
	Creator.Registry[Object] = Properties
	Creator.UpdateTheme(Object)
end

function Creator.New(Name, Properties: { [string]: any }?, Children: { [number]: Instance }?): Instance
	local Object = Instance.new(Name)

	-- Default properties
	for Name, Value in next, Creator.DefaultProperties[Name] or {} do
		Object[Name] = Value
	end

	-- Properties
	for Name, Value in next, Properties or {} do
		if Name ~= "ThemeTag" then
			Object[Name] = Value
		end
	end

	-- Children
	for _, Child in next, Children or {} do
		Child.Parent = Object
	end

	ApplyCustomProps(Object, Properties)

	return Object
end

function Creator.SpringMotor(
	Initial: any,
	Instance: Object,
	Prop: string,
	IgnoreDialogCheck: boolean?,
	ResetOnThemeChange: boolean?
)
	IgnoreDialogCheck = IgnoreDialogCheck or false
	ResetOnThemeChange = ResetOnThemeChange or false
	local Motor = Flipper.SingleMotor.new(Initial)
	Motor:onStep(function(value)
		Instance[Prop] = value
	end)

	if ResetOnThemeChange then
		Creator.TransparencyMotors[Instance] = Motor
	end

	local function SetValue(Value, Ignore: boolean?)
		Ignore = Ignore or false
		if not IgnoreDialogCheck then
			if not Ignore then
				if Prop == "BackgroundTransparency" and getLibrary().DialogOpen then
					return
				end
			end
		end
		Motor:setGoal(Flipper.Spring.new(Value, { frequency = 8 }))
	end

	return Motor, SetValue
end

return Creator
