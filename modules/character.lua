local Character = {}
Character.__index = Character

function Character.new()
    return setmetatable({}, Character)
end

-- Crée un personnage par défaut
function Character:newCharacter()
    return {
        name = "Hero",
        class = "Guerrier",
        level = 1,
        attributes = {
            intelligence = 8,
            strength = 8,
            dexterity = 7,
            endurance = 7,
            magic = 0
        },
        spells = {"Coup puissant", "Cri de guerre", "Défense solide"},
        energy = 120,
        energieMax = 120
    }
end

-- Crée un personnage avec des attributs personnalisés
function Character:createCharacterWithAttributes(name, class, level, attributes)
    local character = {}
    character.name = name
    character.class = class
    character.level = level or 1
    character.attributes = attributes
    character.spells = {}

    -- Sorts par défaut selon la classe
    if class == "guerrier" then
        character.spells = {"Coup puissant", "Cri de guerre", "Défense solide"}
        character.energy = 120
        character.energieMax = 120
    elseif class == "mage" then
        character.spells = {"Boule de feu", "Soin", "Bouclier magique"}
        character.energy = 80
        character.energieMax = 80
    elseif class == "voleur" then
        character.spells = {"Attaque furtive", "Piège", "Évasion"}
        character.energy = 90
        character.energieMax = 90
    else  -- aventurier
        character.spells = {"Attaque basique", "Soin léger"}
        character.energy = 100
        character.energieMax = 100
    end

    return character
end

return Character
