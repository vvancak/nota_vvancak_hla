function getInfo()
    return {
        onNoUnits = SUCCESS, -- instant success
        tooltip = "Rescue stranded units",
        parameterDefs = {
            {
                name = "navigation_graph",
                variableType = "expression",
                componentType = "editBox",
                defaultValue = "<none>",
            },
            {
                name = "edge_size",
                variableType = "expression",
                componentType = "editBox",
                defaultValue = "150",
            },
            {
                name = "search_start_place",
                variableType = "expression",
                componentType = "editBox",
                defaultValue = "<none>",
            },
            {
                name = "safe_spot_place",
                variableType = "expression",
                componentType = "editBox",
                defaultValue = "<none>",
            },
            {
                name = "safe_spot_radius",
                variableType = "expression",
                componentType = "editBox",
                defaultValue = "100",
            },
            {
                name = "stranded_units",
                variableType = "expression",
                componentType = "editBox",
                defaultValue = "<none>",
            }
        }
    }
end

-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit
local SpringGetUnitCommands = Spring.GetUnitCommands
local SpringGetGroundHeight = Spring.GetGroundHeight
local SpringGetUnitIsTransporting = Spring.GetUnitIsTransporting

-- states
local FREE = 1
local TARGET_PICKUP = 2
local TARGET_RETURN = 3

local function GetNode(position, edge_size)
    local x = math.floor(position.x / edge_size) * edge_size
    local z = math.floor(position.z / edge_size) * edge_size
    local y = SpringGetGroundHeight(x, z)
    return Vec3(x, y, z)
end

local function GetPath(from, start, nav_graph, edge_size)

    local path = {}
    local current = GetNode(from, edge_size)

    while current:Distance(start) > (edge_size * 2) do
        table.insert(path, current)

        if (Script.LuaUI('drawCross_update')) then
            Script.LuaUI.drawCross_update(
                {
                    x = current.x,
                    y = current.y,
                    z = current.z,
                    color = {r = 0, g = 0, b = 1}
                }
            )
        end

        current = nav_graph[current.x][current.z]
    end

    return path
end

local function GoPickUpUnit(unit, target, path)
    for i = #path, 1, -1 do
        SpringGiveOrderToUnit(unit, CMD.MOVE, path[i]:AsSpringVector(), { "shift" })
    end
    SpringGiveOrderToUnit(unit, CMD.LOAD_UNITS, { target }, { "shift" })
end

local function ReturnToSafeSpot(unit, path, safe_spot_place)
    for i = 1, #path do
        SpringGiveOrderToUnit(unit, CMD.MOVE, path[i]:AsSpringVector(), { "shift" })
    end
    SpringGiveOrderToUnit(unit, CMD.MOVE, safe_spot_place:AsSpringVector(), { "shift" })
end

local function DropUnit(unit, safe_spot_place, safe_spot_radius)
    local rnd_range = 0.35 * safe_spot_radius

    local dx = math.random(-rnd_range, rnd_range)
    local dz = math.random(-rnd_range, rnd_range)

    local position = safe_spot_place + Vec3(dx, 0, dz)
    SpringGiveOrderToUnit(unit, CMD.MOVE, position:AsSpringVector(), { "shift" })
    SpringGiveOrderToUnit(unit, CMD.TIMEWAIT, { 500 }, { "shift" })

    SpringGiveOrderToUnit(unit, CMD.UNLOAD_UNITS, position:AsSpringVector(), { "shift" })
    SpringGiveOrderToUnit(unit, CMD.MOVE, position:AsSpringVector(), { "shift" })
end

local function GetNextTarget(self, stranded_units)
    local index = self.next_target
    if index > #stranded_units then
        return nil
    else
        self.next_target = index + 1
        return stranded_units[index]
    end
end

local function GetPos(unit_id)
    local x, y, z = SpringGetUnitPosition(unit_id)
    return Vec3(x, y, z)
end

local function CanNavigate(position, nav_graph, edge_size)
    if (position == nil) then
        return false
    end

    local node = GetNode(position, edge_size)
    return nav_graph[node.x][node.z] ~= nil
end

local function SingleUnitSaving(self, unit, parameter)
    local stranded_units = parameter.stranded_units
    local search_start_place = parameter.search_start_place

    local nav_graph = parameter.navigation_graph
    local edge_size = parameter.edge_size

    local temp = parameter.safe_spot_place
    local safe_spot_place = Vec3(temp.x, temp.y, temp.z)
    local safe_spot_radius = parameter.safe_spot_radius

    -- initialization
    if (self.unit_states[unit] == nil) then

        self.unit_states[unit] = FREE
    end

    -- pick up next target
    if (self.unit_states[unit] == FREE) then

        local target
        local target_pos

        while not CanNavigate(target_pos, nav_graph, edge_size) do
            target = GetNextTarget(self, stranded_units)
            if not target then return end
            target_pos = GetPos(target)
        end

        local path = GetPath(target_pos, search_start_place, nav_graph, edge_size)
        self.unit_paths[unit] = path

        GoPickUpUnit(unit, target, path)
        self.unit_states[unit] = TARGET_PICKUP

        -- return to the safe spot
    elseif (self.unit_states[unit] == TARGET_PICKUP) then

        ReturnToSafeSpot(unit, self.unit_paths[unit], safe_spot_place)
        self.unit_states[unit] = TARGET_RETURN

        -- dropping unit
    elseif (self.unit_states[unit] == TARGET_RETURN) then

        if #SpringGetUnitIsTransporting(unit) == 0 then
            self.finished_targets = self.finished_targets + 1
            self.unit_states[unit] = FREE
        else
            DropUnit(unit, safe_spot_place, safe_spot_radius)
        end
    end
end

local function AllSaved(self, stranded_units)
    return self.finished_targets == #stranded_units
end

local function ClearState(self)
    self.init = true

    self.unit_paths = {}
    self.unit_states = {}

    self.next_target = 1
    self.finished_targets = 0
end

function Run(self, units, parameter)
    if not self.init then
        ClearState(self)
    end

    if AllSaved(units, parameter.stranded_units) then
        return SUCCESS
    end

    for i = 1, #units do
        local unit = units[i]

        local cmds = SpringGetUnitCommands(unit, 1)

        if #cmds == 0 then
            SingleUnitSaving(self, unit, parameter)
        end
    end

    return RUNNING
end

function Reset(self)
    ClearState(self)
end
