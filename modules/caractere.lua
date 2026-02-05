local Character = {}

-- Fonction pour créer un personnage de manière interactive
function Character.createCharacterInteractive(name, class, level)
    local classes = {
        guerrier = {
            attributes = {intelligence = 5, strength = 10, dexterity = 7, endurance = 12},
            spells = {"Coup puissant", "Cri de guerre"}
        },
        mage = {
            attributes = {intelligence = 12, strength = 5, dexterity = 7, endurance = 8},
            spells = {"Boule de feu", "Soin", "Téléportation"}
        },
        voleur = {
            attributes = {intelligence = 7, strength = 7, dexterity = 12, endurance = 8},
            spells = {"Vol", "Attaque sournoise", "Disparition"}
        },
    }

    class = class:lower()
    local template = classes[class] or {
        attributes = {intelligence = 8, strength = 8, dexterity = 8, endurance = 8},
        spells = {"Attaque basique"}
    }

    return {
        name = name,
        class = class:sub(1,1):upper() .. class:sub(2),
        level = level,
        attributes = template.attributes,
        spells = template.spells
    }
end

-- Fonction pour créer un personnage par défaut
function Character.new()
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

return Character

