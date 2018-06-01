local sensorInfo = {
    name = "GetStrandedUnits",
    desc = "Returns array of units which need saving",
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

SpringGetUnitDefID = Spring.GetUnitDefID
SpringGetUnitPosition = Spring.GetUnitPosition

-- @description return current wind statistics
return function(safe_spot_place, safe_spot_radius)
    local stranded_units = {}
    for i = 1, #units do
        local unitDefId = SpringGetUnitDefID(units[i])
        local unitName = UnitDefs[unitDefId].name

        local x, y, z = SpringGetUnitPosition(units[i])
        local unit_pos = Vec3(x, y, z)

        if (unitName ~= "armrad" and unitName ~= "armwin" and unit_pos:Distance(safe_spot_place) > safe_spot_radius) then
            table.insert(stranded_units, units[i])
        end
    end
    return stranded_units
end