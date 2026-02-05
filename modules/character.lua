local Character = {}
Character.__index = Character

function Character.new()
    return setmetatable({}, Character)
end

function Character:newCharacter()
    return {
        name = "Hero",
        class = "Guerrier",
        level = 1,
        attributes = {
            intelligence = 5,
            strength = 10,
            dexterity = 7,
            endurance = 12
        },
        spells = {"Coup puissant", "Cri de guerre"}
    }
end

function Character:createCharacterInteractive()
    return {
        name = "DefaultName",
        class = "Aventurier",
        level = 1,
        attributes = {
            intelligence = 8,
            strength = 8,
            dexterity = 8,
            endurance = 8
        },
        spells = {"Attaque basique"}
    }
end

return Character

