local sensorInfo = {
    name = "IsNodeInEnemyRange",
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

RANGE = 500

local function IsInEnemyRange(enemy_positions, my_position)
    local found_in_range_enemy = false
    for id, position in pairs(enemy_positions) do
        if (position:Distance(my_position) < RANGE) then
            found_in_range_enemy = true
        end
    end
    return found_in_range_enemy
end

-- @description return current wind statistics
return function(enemy_positions, x, z)
    if (self.network == nil) then
        self.network = {}
    end

    if (self.network[x] == nil) then
        self.network[x] = {}
    end

    if (self.network[x][z] == nil) then
        local my_pos = Vec3(x, SpringGetGroundHeight(x, z), z)
        self.network[x][z] = IsInEnemyRange(enemy_positions, my_pos)
    end

    return self.network[x][z]
end