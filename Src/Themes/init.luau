-- The five curated public presets. "Custom" stays available internally for
-- the five-color editor, but is not another built-in theme in the picker.
local Themes = {
	Names = { "Dark", "Darker", "Midnight", "Light", "Nord" },
}

setmetatable(Themes, {
	__index = function(self, Name)
		local Module = script:FindFirstChild(Name)
		if not Module then return nil end
		local Theme = require(Module)
		self[Name] = Theme
		return Theme
	end,
})

return Themes
