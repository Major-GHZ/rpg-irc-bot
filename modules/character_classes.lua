-- Fichier : modules/character_classes.lua
local M = {}

-- Définition des classes de personnages
local classes = {
    -- Magicien
    magicien = {
        name = "Magicien",
        description = "Un utilisateur de magie puissante.",
        base_attributes = {
            intelligence = 8,
            strength = 2,
            dexterity = 4,
            endurance = 3,
            magic = 10
        },
        base_spells = {"Boule de feu", "Éclair", "Bouclier magique"},
        base_energy = 100,
        base_energy_max = 100
    },
    
    -- Humain
    humain = {
        name = "Humain",
        description = "Un personnage polyvalent.",
        base_attributes = {
            intelligence = 5,
            strength = 5,
            dexterity = 5,
            endurance = 5,
            magic = 5
        },
        base_spells = {"Coup d'épée", "Bouclier"},
        base_energy = 80,
        base_energy_max = 80
    },
    
    -- Hobbite
    hobbite = {
        name = "Hobbite",
        description = "Un personnage agile et discret.",
        base_attributes = {
            intelligence = 4,
            strength = 2,
            dexterity = 8,
            endurance = 3,
            magic = 3
        },
        base_spells = {"Disparition", "Coup rapide"},
        base_energy = 60,
        base_energy_max = 60
    },
    
    -- Elfe
    elfe = {
        name = "Elfe",
        description = "Un personnage rapide et précis.",
        base_attributes = {
            intelligence = 6,
            strength = 3,
            dexterity = 7,
            endurance = 4,
            magic = 6
        },
        base_spells = {"Tir précis", "Fléche magique"},
        base_energy = 70,
        base_energy_max = 70
    },
    
    -- Nain
    nain = {
        name = "Nain",
        description = "Un personnage robuste et résistant.",
        base_attributes = {
            intelligence = 3,
            strength = 8,
            dexterity = 3,
            endurance = 8,
            magic = 3
        },
        base_spells = {"Coup de hache", "Résistance"},
        base_energy = 90,
        base_energy_max = 90
    },
    
    -- Troll
    troll = {
        name = "Troll",
        description = "Un personnage puissant mais lent.",
        base_attributes = {
            intelligence = 2,
            strength = 10,
            dexterity = 2,
            endurance = 9,
            magic = 2
        },
        base_spells = {"Coup puissant", "Régénération"},
        base_energy = 110,
        base_energy_max = 110
    },
    
    -- Orc
    orc = {
        name = "Orc",
        description = "Un personnage brutal et résistant.",
        base_attributes = {
            intelligence = 3,
            strength = 7,
            dexterity = 4,
            endurance = 7,
            magic = 4
        },
        base_spells = {"Coup brutal", "Cri de guerre"},
        base_energy = 85,
        base_energy_max = 85
    }
}

-- Fonction pour obtenir une classe par son nom
function M.getClass(class_name)
    return classes[class_name:lower()]
end

-- Fonction pour obtenir la liste des classes disponibles
function M.getAvailableClasses()
    local class_list = {}
    for class_name, class_info in pairs(classes) do
        table.insert(class_list, class_name)
    end
    return class_list
end

return M