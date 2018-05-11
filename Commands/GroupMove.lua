function getInfo()
	return {
		onNoUnits = SUCCESS, -- instant success
		tooltip = "Move group in a specified direction",
		parameterDefs = {
			{ 
				name = "direction",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "Vec3(0,0,0)",
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
	local direction = parameter.direction -- Vec3
	local cmds = SpringGetUnitCommands(units[1])
	
	-- has target set and commands
	if (self.target_set and #cmds == 0) then
		self.target_set = false
		return SUCCESS
	-- check if movement is still running (i.e. leader not at his target position)
	--[[if (self.target_set) then
		local leader = units[1]
		local unit_x, unit_y, unit_z = SpringGetUnitPosition(leader)
		local leader_pos = Vec3(unit_x, unit_y, unit_z)

		if (leader_pos:Distance(self.target_pos) > 10) then
			Spring.Echo(leader_pos:Distance(self.target_pos))
			return RUNNING;
		end]]
	
	-- has taret set
	elseif (self.target_set) then
		return RUNNING

	-- no target set => set new targets
	else
		self.target_set = true
		for i=1, #units do
			local unit = units[i]
		
			-- compute next position
			local unit_x, unit_y, unit_z = SpringGetUnitPosition(unit)
			local next_pos = Vec3(unit_x, unit_y, unit_z) + direction
		
			-- set unit's command
			SpringGiveOrderToUnit(unit, CMD.MOVE, next_pos:AsSpringVector(), {})
		end
		return RUNNING
	end
end

function Reset(self)
	ClearState(self)
end
