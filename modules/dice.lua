-- Fichier : modules/dice.lua
local M = {}

-- Fonction pour simuler un jet de dé à 6 faces
function M.roll_d6()
    return math.random(1, 6)
end

-- Fonction pour simuler plusieurs jets de dés à 6 faces
function M.roll_dice(num_dice)
    local results = {}
    local total = 0
    
    for i = 1, num_dice do
        local roll = M.roll_d6()
        table.insert(results, roll)
        total = total + roll
    end
    
    return results, total
end

-- Fonction pour formater les résultats des jets de dés
function M.format_dice_roll(results, total)
    return table.concat(results, " + ") .. " = " .. total
end

return M