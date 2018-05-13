function getInfo()
	return {
		onNoUnits = SUCCESS, -- instant success
		tooltip = "Move group in a specified direction",
		parameterDefs = {
			{ 
				name = "targets",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "<array of Vec3, size >= size of units>",
			}
		}
	}
end

-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit
local SpringGetUnitCommands = Spring.GetUnitCommands

local function ClearState(self)
	self.target_set = false
end

function Run(self, units, parameter)
	local targets = parameter.targets -- Vec3
	
	-- collect commands for units
	local cmds = 0
	for i = 1, #units do
		local unit_cmds = SpringGetUnitCommands(units[i])
		cmds = cmds + (#unit_cmds)
	end
	
	-- has target set and commands
	if (self.target_set and cmds == 0) then
		self.target_set = false
		return SUCCESS
	
	-- has taret set
	elseif (self.target_set) then
		return RUNNING

	-- no target set => set new targets
	else
		self.target_set = true
		for i=1, #units do
			local unit = units[i]
			local target = targets[i]
		
			-- set unit's command
			SpringGiveOrderToUnit(unit, CMD.MOVE, target:AsSpringVector(), {})
		end
		return RUNNING
	end
end

function Reset(self)
	ClearState(self)
end
