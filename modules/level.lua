local Level = {}
Level.__index = Level

function Level.new()
    return setmetatable({}, Level)
end

function Level:newDamage(target, amount)
    target.energy = (target.energy or 100) - amount
    if target.energy < 0 then
        target.energy = 0
    end
end

return Level

