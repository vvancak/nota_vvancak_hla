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

MapSizeX = Game.mapSizeX
MapSizeZ = Game.mapSizeZ
SpringGetGroundHeight = Spring.GetGroundHeight
HILL_RADIUS = 200

-- @description return current wind statistics
return function()
	local mission_info = Sensors.core.MissionInfo()

	local hills = {}
	local max_hill_height = mission_info.areaHeight

	for x = 1, MapSizeX, 50 do
		for z = 1, MapSizeZ, 50 do

			local y = SpringGetGroundHeight(x,z)
			if (y == max_hill_height) then
				
				local potential_point = Vec3(x,y,z)
				local near_point_found = false

				-- check if a point in HILL_RADIUS is not already in return_points
				for i = 1, #hills do
					
					-- if yes, average the hill central point
					if (hills[i]:Distance(potential_point) < HILL_RADIUS) then
						hills[i] = hills[i] + (potential_point - hills[i]) * 1/4						
						near_point_found = true
					end
				end

				-- add to return_points if not
				if (not near_point_found) then
					table.insert(hills, potential_point)
				end
			end
		end
	end

	-- enemy position
	local enemy_pos = mission_info.enemyPositions[1]

	-- split hills into defended and undefended
	undefended_hills = {}
	defended_hills = {}

	for i = 1, #hills do
		if (hills[i]:Distance(enemy_pos) < HILL_RADIUS) then
			table.insert(defended_hills, hills[i])
		else
			table.insert(undefended_hills, hills[i])
		end
	end
	return { undefended = undefended_hills, defended = defended_hills }
end