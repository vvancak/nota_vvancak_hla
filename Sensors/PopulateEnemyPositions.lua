local sensorInfo = {
    name = "PopulateEnemyPositions",
    desc = "Populates hash table with current enemy positions",
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

SpringGetUnitPosition = Spring.GetUnitPosition

-- @description return current wind statistics
return function(enemy_positions, new_enemies)
    for i = 1, #new_enemies do
        local enemy_id = new_enemies[i]
        if (enemy_positions[enemy_id] == nil) then
            local x,y,z = SpringGetUnitPosition(enemy_id)
            enemy_positions[enemy_id] = Vec3(x,y,z)
        end
    end
end