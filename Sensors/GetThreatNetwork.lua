local sensorInfo = {
    name = "Get Threat Network",
    desc = "Creates a net across the map with positions marked either as safe or as threatened by enemy",
    author = "vvancak",
    date = "2018-05-29",
    license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = -1 -- acutal, no caching

function getInfo()
    return {
        period = EVAL_PERIOD_DEFAULT
    }
end

mapSizeX = Game.mapSizeX
mapSizeZ = Game.mapSizeZ
SpringGetGroundHeight = Spring.GetGroundHeight

RANGE = 1000

HEIGHT_LIMIT = 250
HEIGHT_RANGE = 750

local function IsWithinRange(from, to)
    local height_diff = from.y - to.y

    if (height_diff > HEIGHT_LIMIT) then
        return from:Distance(to) < HEIGHT_RANGE
    else
        return from:Distance(to) < RANGE
    end
end

local function IsInEnemyRange(enemy_positions, my_position)
    local found_in_range_enemy = false
    for id, position in pairs(enemy_positions) do
        if IsWithinRange(position, my_position) then
            found_in_range_enemy = true

            if (Script.LuaUI('drawCross_update')) then
                Script.LuaUI.drawCross_update({
                    x = my_position.x,
                    y = my_position.y,
                    z = my_position.z,
                    color = { r = 1, g = 0, b = 0 }
                })
            end
        end
    end
    return found_in_range_enemy
end

-- @description return current wind statistics
return function(enemy_positions, fly_height, edge_size)
    local network = {}
    for x = 0, mapSizeX, edge_size do
        network[x] = {}
        for z = 0, mapSizeZ, edge_size do
            network[x][z] = not IsInEnemyRange(enemy_positions, Vec3(x, fly_height + SpringGetGroundHeight(x, z), z))
        end
    end
    return network
end