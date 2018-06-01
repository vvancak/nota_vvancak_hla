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
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit
local SpringGetUnitCommands = Spring.GetUnitCommands
local SpringGetUnitIsTransporting = Spring.GetUnitIsTransporting

-- states
local FREE = 1
local TARGET_PICKUP = 2
local TARGET_RETURN = 3
local TARGET_DROP = 4

local function GetNextTarget(self, stranded_units)
    local index = self.next_target
    if index > #stranded_units then
        self.finished = self.finished + 1
        return nil
    else
        self.next_target = index + 1
        return stranded_units[index]
    end
end

local function GoPickUpUnit(self, unit, parameter)
    local stranded_units = parameter.stranded_units
    local search_start_place = parameter.search_start_place

    local nav_graph = parameter.navigation_graph
    local edge_size = parameter.edge_size

    local target
    local path

    while not path do
        target = GetNextTarget(self, stranded_units)

        if target == nil then
            SpringGiveOrderToUnit(unit, CMD.MOVE, search_start_place:AsSpringVector(), {})
            SpringGiveOrderToUnit(unit, CMD.WAIT, {}, CMD.OPT_SHIFT)
            return
        end

        path = Sensors.GetPath(target, search_start_place, nav_graph, edge_size)
        self.unit_paths[unit] = path
    end

    for i = #path, 1, -1 do
        SpringGiveOrderToUnit(unit, CMD.MOVE, path[i]:AsSpringVector(), CMD.OPT_SHIFT)
    end
    SpringGiveOrderToUnit(unit, CMD.LOAD_UNITS, { target }, CMD.OPT_SHIFT)
end

local function ReturnToSafeSpot(self, unit, parameter)
    local path = self.unit_paths[unit]
    local safe_spot_place = parameter.safe_spot_place

    for i = 1, #path do
        SpringGiveOrderToUnit(unit, CMD.MOVE, path[i]:AsSpringVector(), CMD.OPT_SHIFT)
    end
    SpringGiveOrderToUnit(unit, CMD.MOVE, safe_spot_place:AsSpringVector(), CMD.OPT_SHIFT)
end

local function DropUnit(self, unit, parameter)
    local temp = parameter.safe_spot_place
    local safe_spot_place = Vec3(temp.x, temp.y, temp.z)
    local safe_spot_radius = parameter.safe_spot_radius

    SpringGiveOrderToUnit(unit, CMD.TIMEWAIT, { 500 }, CMD.OPT_SHIFT)
    SpringGiveOrderToUnit(unit, CMD.UNLOAD_UNITS, { safe_spot_place.x, safe_spot_place.y, safe_spot_place.z, safe_spot_radius * 0.8 }, CMD.OPT_SHIFT)
    SpringGiveOrderToUnit(unit, CMD.MOVE, safe_spot_place:AsSpringVector(), CMD.OPT_SHIFT)
end

local function SingleUnitSaving(self, unit, parameter)

    -- initialization
    if (self.unit_states[unit] == nil) then
        self.unit_states[unit] = FREE
    end

    -- TARGET PICKUP --
    if (self.unit_states[unit] == FREE) then
        GoPickUpUnit(self, unit, parameter)
        self.unit_states[unit] = TARGET_PICKUP

        -- RETURN TO THE SAFE PLACE --
    elseif (self.unit_states[unit] == TARGET_PICKUP) then
        ReturnToSafeSpot(self, unit, parameter)
        self.unit_states[unit] = TARGET_RETURN

        -- DROP UNITS --
    elseif (self.unit_states[unit] == TARGET_RETURN) then
        DropUnit(self, unit, parameter)
        self.unit_states[unit] = TARGET_DROP

        -- CHECK DROP & FREE UNIT (or retry) --
    elseif (self.unit_states[unit] == TARGET_DROP) then
        if #SpringGetUnitIsTransporting(unit) > 0 then
            self.unit_states[unit] = TARGET_RETURN
        else
            self.unit_states[unit] = FREE
        end
    end
end

local function AllFinished(self, units)
    return self.finished >= #units
end

local function ClearState(self)
    self.init = true

    self.unit_paths = {}
    self.unit_states = {}

    self.next_target = 1
    self.finished = 0
end

function Run(self, units, parameter)
    if not self.init then
        ClearState(self)
    end

    if AllFinished(self, units) then
        ClearState(self)
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
