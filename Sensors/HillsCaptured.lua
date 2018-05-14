local sensorInfo = {
	name = "HillsCaptured",
	desc = "Checks whether all hills are captured",
	author = "vvancak",
	date = "2018-05-14",
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
	local mission_info = Sensors.core.MissionInfo()
	local areasOccupied = mission_info.areasOccupied

	local return_value = true
	for i = 1, #areasOccupied do
		if not areasOccupied[i] then 
			return_value = false
		end
	end

	return return_value
end