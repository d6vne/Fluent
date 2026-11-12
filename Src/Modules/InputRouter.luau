-- Shared input bus: N keybinds use one pair of UserInputService connections.
-- Owners explicitly unregister on destruction to release their callback closures.
local UserInputService = game:GetService("UserInputService")

local Router = {}
local Listeners = {}
local ListenerCount = 0
local BeganConnection, EndedConnection

local function Dispatch(Key, ...)
	for _, Listener in next, Listeners do
		local Callback = Listener[Key]
		if Callback then
			Callback(...)
		end
	end
end

local function DisconnectIdle()
	if ListenerCount ~= 0 then
		return
	end
	if BeganConnection then
		BeganConnection:Disconnect()
		BeganConnection = nil
	end
	if EndedConnection then
		EndedConnection:Disconnect()
		EndedConnection = nil
	end
end

function Router.Register(Owner, OnBegan, OnEnded)
	assert(Owner ~= nil, "InputRouter.Register requires an owner")
	if not Listeners[Owner] then
		ListenerCount += 1
	end
	Listeners[Owner] = { Began = OnBegan, Ended = OnEnded }

	if not BeganConnection then
		BeganConnection = UserInputService.InputBegan:Connect(function(...)
			Dispatch("Began", ...)
		end)
		EndedConnection = UserInputService.InputEnded:Connect(function(...)
			Dispatch("Ended", ...)
		end)
	end
end

function Router.Unregister(Owner)
	if Listeners[Owner] then
		Listeners[Owner] = nil
		ListenerCount -= 1
		DisconnectIdle()
	end
end

function Router.Destroy()
	table.clear(Listeners)
	ListenerCount = 0
	DisconnectIdle()
end

return Router
