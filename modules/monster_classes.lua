-- Fichier : modules/monster_classes.lua
local M = {}

-- Définition des classes de monstres
local monster_classes = {
    -- Loup-garou
    loup_garou = {
        name = "Loup-garou",
        description = "Un monstre rapide et puissant, capable de se transformer.",
        base_attributes = {
            intelligence = 4,
            strength = 8,
            dexterity = 7,
            endurance = 6,
            magic = 3
        },
        base_spells = {"Griffes acérées", "Hurlement terrifiant", "Transformation"},
        base_health = 60,
        base_health_max = 60,
        base_damage = 10,
        base_armor = 5
    },
    
    -- Vampire
    vampire = {
        name = "Vampire",
        description = "Un monstre immortel avec des capacités de régénération.",
        base_attributes = {
            intelligence = 7,
            strength = 6,
            dexterity = 8,
            endurance = 5,
            magic = 7
        },
        base_spells = {"Morsure vampirique", "Régénération", "Hypnose"},
        base_health = 70,
        base_health_max = 70,
        base_damage = 9,
        base_armor = 4
    },
    
    -- Licorne
    licorne = {
        name = "Licorne",
        description = "Un monstre magique avec des capacités de guérison.",
        base_attributes = {
            intelligence = 6,
            strength = 5,
            dexterity = 7,
            endurance = 6,
            magic = 8
        },
        base_spells = {"Corne de guérison", "Bénédiction", "Purification"},
        base_health = 80,
        base_health_max = 80,
        base_damage = 8,
        base_armor = 6
    },
    
    -- Minotaure
    minotaure = {
        name = "Minotaure",
        description = "Un monstre puissant et résistant.",
        base_attributes = {
            intelligence = 3,
            strength = 9,
            dexterity = 4,
            endurance = 8,
            magic = 2
        },
        base_spells = {"Charge puissante", "Résistance", "Coup de corne"},
        base_health = 90,
        base_health_max = 90,
        base_damage = 12,
        base_armor = 7
    },
    
    -- Phénix
    phenix = {
        name = "Phénix",
        description = "Un monstre magique capable de renaître de ses cendres.",
        base_attributes = {
            intelligence = 8,
            strength = 6,
            dexterity = 6,
            endurance = 7,
            magic = 9
        },
        base_spells = {"Souffle de feu", "Renaissance", "Vol"},
        base_health = 100,
        base_health_max = 100,
        base_damage = 11,
        base_armor = 5
    },
    
    -- Kraken
    kraken = {
        name = "Kraken",
        description = "Un monstre marin géant avec des tentacules puissants.",
        base_attributes = {
            intelligence = 5,
            strength = 10,
            dexterity = 5,
            endurance = 9,
            magic = 4
        },
        base_spells = {"Étouffement", "Vague géante", "Résistance aquatique"},
        base_health = 120,
        base_health_max = 120,
        base_damage = 14,
        base_armor = 8
    }
}

-- Fonction pour obtenir une classe de monstre par son nom
function M.getMonsterClass(monster_class_name)
    return monster_classes[monster_class_name:lower()]
end

-- Fonction pour obtenir la liste des classes de monstres disponibles
function M.getAvailableMonsterClasses()
    local class_list = {}
    for class_name, class_info in pairs(monster_classes) do
        table.insert(class_list, class_name)
    end
    return class_list
end

return M