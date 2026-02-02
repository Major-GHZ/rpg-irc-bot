local GameModule = {}
local Game = {}
local Game_mt = { __index = Game }

function GameModule.new()
    print("Start of the game !")
    return setmetatable({}, Game_mt)
end

function Game:newDamage(character, damage)
    character.energy = character.energy - damage
end

return GameModule

