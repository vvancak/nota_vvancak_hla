local sensorInfo = {
    name = "Get Path",
    desc = "Finds a path from a unit to the start of grid",
    author = "vvancak",
    date = "2018-05-29",
    license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = -1 -- acutal, no caching

-- speed ups
local SpringGetGroundHeight = Spring.GetGroundHeight
local SpringGetUnitPosition = Spring.GetUnitPosition

function getInfo()
    return {
        period = EVAL_PERIOD_DEFAULT
    }
end

local function GetPos(unit_id)
    local x, y, z = SpringGetUnitPosition(unit_id)
    return Vec3(x, y, z)
end

local function GetNode(position, edge_size)
    local x = math.floor(position.x / edge_size) * edge_size
    local z = math.floor(position.z / edge_size) * edge_size
    local y = SpringGetGroundHeight(x, z)
    return Vec3(x, y, z)
end

local function GetPath(from_node, start, nav_graph, edge_size)

    local path = {}
    local current = from_node

    while current:Distance(start) > (edge_size * 2) do
        table.insert(path, current)
        current = nav_graph[current.x][current.z]
    end

    return path
end

-- @description return current wind statistics
return function(unit_id, start_pos, nav_graph, edge_size)
    local position = GetPos(unit_id)
    local node = GetNode(position, edge_size)

    if (nav_graph[node.x][node.z] == nil) then
        return nil
    end

    return GetPath(node, start_pos, nav_graph, edge_size)
end