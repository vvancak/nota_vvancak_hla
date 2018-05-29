local sensorInfo = {
    name = "GenerateScoutingStartingPos",
    desc = "Gets an array of points across the top line of the map",
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

MapSizeX = Game.mapSizeX

-- @description return current wind statistics
return function(unit_count)
    local result_positions = {}
    local position = Vec3(0, 0, 0)
    local shift = Vec3(MapSizeX, 0, 0) * (1 / unit_count)

    for i = 1, unit_count do
        table.insert(result_positions, position)
        position = position + shift
    end

    return result_positions
end