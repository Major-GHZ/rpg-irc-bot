-- Game module
local GameModule = {}
local Game = {}
local Game_mt = { __index = Game }

-- Constructor for the game module
function GameModule.new()
    print("Start of the game!")
    return setmetatable({}, Game_mt)
end

-- Function to apply damage to a character
function Game:newDamage(character, damage)
    character.energy = character.energy - damage
end

-- Export the module
return GameModule

