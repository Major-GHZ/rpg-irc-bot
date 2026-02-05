-- game/stage_lua.lua
local Stage = {}
Stage.__index = Stage

function Stage.new()
    return setmetatable({}, Stage)
end

function Stage:newDamage(target, amount)
    target.energy = math.max(0, target.energy - amount)
end

return Stage

