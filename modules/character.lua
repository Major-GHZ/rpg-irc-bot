local Character = {}
Character.__index = Character

-- Charger les classes de personnages
local CharacterClasses = require("character_classes")

function Character.new()
    return setmetatable({}, Character)
end

-- Crée un personnage par défaut
function Character:newCharacter()
    local default_class = CharacterClasses.getClass("humain")
    return {
        name = "Hero",
        class = default_class.name,
        level = 1,
        attributes = default_class.base_attributes,
        spells = default_class.base_spells,
        energy = default_class.base_energy,
        energieMax = default_class.base_energy_max
    }
end

-- Crée un personnage avec des attributs personnalisés
function Character:createCharacterWithAttributes(name, class, level, attributes)
    local character_class = CharacterClasses.getClass(class)
    if not character_class then
        character_class = CharacterClasses.getClass("humain")
    end

    local character = {}
    character.name = name
    character.class = character_class.name
    character.level = level or 1
    character.attributes = attributes or character_class.base_attributes
    character.spells = character_class.base_spells
    character.energy = character_class.base_energy
    character.energieMax = character_class.base_energy_max

    return character
end

return Character
