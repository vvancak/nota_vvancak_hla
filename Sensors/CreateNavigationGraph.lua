local sensorInfo = {
    name = "GetNavigationGraph",
    desc = "Creates a graph of possible navigation across the map using a threat network",
    author = "vvancak",
    date = "2018-05-31",
    license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = -1 -- acutal, no caching

GameMapSizeX = Game.mapSizeX
GameMapSizeZ = Game.mapSizeZ
SpringGetGroundHeight = Spring.GetGroundHeight

function getInfo()
    return {
        period = EVAL_PERIOD_DEFAULT
    }
end

-- QUEUE - implementation from the LUA manual, see https://www.lua.org/pil/11.4.html
function ListNew()
    return { first = 0, last = -1 }
end

List = {}
function List.new()
    return { first = 0, last = -1 }
end

function List.pushleft(list, value)
    local first = list.first - 1
    list.first = first
    list[first] = value
end

function List.pushright(list, value)
    local last = list.last + 1
    list.last = last
    list[last] = value
end

function List.popleft(list)
    local first = list.first
    if first > list.last then error("list is empty") end
    local value = list[first]
    list[first] = nil -- to allow garbage collection
    list.first = first + 1
    return value
end

function List.popright(list)
    local last = list.last
    if list.first > last then error("list is empty") end
    local value = list[last]
    list[last] = nil -- to allow garbage collection
    list.last = last - 1
    return value
end

function List.size(list)
    return list.last - list.first + 1
end

function IsPosOnMap(position)
    return position.x >= 0 and position.z >= 0 and position.x <= GameMapSizeX and position.z <= GameMapSizeZ
end

-- DFS
dx = { 0, 0, 1, -1, 1, 1, -1, -1 }
dz = { 1, -1, 0, 0, 1, -1, 1, -1 }

function ExpandPosition(node, edge_size)
    neighbours = {}
    for i = 1, #dx do
        local next_node = node + (Vec3(dx[i], 0, dz[i]) * edge_size)
        next_node.y = SpringGetGroundHeight(next_node.x, next_node.z)

        if IsPosOnMap(next_node) then
            table.insert(neighbours, next_node)
        end
    end
    return neighbours
end

function DFS(from, threat_network, edge_size)
    local graph = {}

    local queue = List.new()
    List.pushleft(queue, from)

    -- main queue cycle
    while List.size(queue) > 0 do

        local current = List.popright(queue)
        local neighbours = ExpandPosition(current, edge_size)

        -- neighbours of the current node
        for i = 1, #neighbours do

            local neighbour = neighbours[i]
            local x = neighbour.x
            local z = neighbour.z

            -- check if that position is not dangerous
            if (threat_network[neighbour.x][neighbour.z]) then
                if (graph[x] == nil) then
                    graph[x] = {}
                end

                -- check if that position was not already discovered
                -- if not, graph at current node has the value of his predecesor
                if (graph[x][z] == nil) then
                    graph[x][z] = current
                    List.pushleft(queue, neighbour)

                    -- and debugging stuff
                    if (Script.LuaUI('drawCross_update')) then
                        Script.LuaUI.drawCross_update({
                            x = neighbour.x,
                            y = neighbour.y,
                            z = neighbour.z,
                            color = { r = 0, g = 1, b = 0 }
                        })
                    end
                end
            end
        end
    end

    return graph
end

-- MAIN
-- @description return navigation graph
return function(from, threat_network, edge_size)

    local from_x = math.floor(from.x / edge_size) * edge_size
    local from_z = math.floor(from.z / edge_size) * edge_size
    local from_y = SpringGetGroundHeight(from_x, from_z)
    local start = Vec3(from_x, from_y, from_z)

    return DFS(start, threat_network, edge_size)
end
