local sensorInfo = {
	name = "WindDebug",
	desc = "Draws wind pointer from the unit",
	author = "vvancak",
	date = "2017-05-16",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = 0 -- acutal, no caching

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- @description return current wind statistics
return function()
	local unitID = units[1]
	if (Script.LuaUI('windPointer_update')) then
		Script.LuaUI.windPointer_update(unitID)
	end	
end

