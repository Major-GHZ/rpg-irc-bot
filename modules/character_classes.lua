-- File: modules/character_classes.lua
local config = require("config")

local M = {}

-- Definition of character classes
local classes = {
    -- Mage
    magicien = {
        name = "Mage",
        description = "A powerful magic user.",
        base_attributes = {
            intelligence = 8,
            strength = 2,
            dexterity = 4,
            endurance = 3,
            magic = 10
        },
        base_spells = {"Fireball", "Lightning", "Magic Shield"},
        base_energy = config.game.starting_energy,
        base_energy_max = config.game.starting_energy
    },
    
    -- Human
    humain = {
        name = "Human",
        description = "A versatile character.",
        base_attributes = {
            intelligence = 5,
            strength = 5,
            dexterity = 5,
            endurance = 5,
            magic = 5
        },
        base_spells = {"Sword Strike", "Shield"},
        base_energy = 80,
        base_energy_max = 80
    },
    
    -- Hobbit
    hobbite = {
        name = "Hobbit",
        description = "An agile and stealthy character.",
        base_attributes = {
            intelligence = 4,
            strength = 2,
            dexterity = 8,
            endurance = 3,
            magic = 3
        },
        base_spells = {"Vanish", "Quick Strike"},
        base_energy = 60,
        base_energy_max = 60
    },
    
    -- Elf
    elfe = {
        name = "Elf",
        description = "A fast and precise character.",
        base_attributes = {
            intelligence = 6,
            strength = 3,
            dexterity = 7,
            endurance = 4,
            magic = 6
        },
        base_spells = {"Precise Shot", "Magic Arrow"},
        base_energy = 70,
        base_energy_max = 70
    },
    
    -- Dwarf
    nain = {
        name = "Dwarf",
        description = "A robust and resistant character.",
        base_attributes = {
            intelligence = 3,
            strength = 8,
            dexterity = 3,
            endurance = 8,
            magic = 3
        },
        base_spells = {"Axe Strike", "Resistance"},
        base_energy = 90,
        base_energy_max = 90
    },
    
    -- Troll
    troll = {
        name = "Troll",
        description = "A powerful but slow character.",
        base_attributes = {
            intelligence = 2,
            strength = 10,
            dexterity = 2,
            endurance = 9,
            magic = 2
        },
        base_spells = {"Powerful Strike", "Regeneration"},
        base_energy = 110,
        base_energy_max = 110
    },
    
    -- Orc
    orc = {
        name = "Orc",
        description = "A brutal and resistant character.",
        base_attributes = {
            intelligence = 3,
            strength = 7,
            dexterity = 4,
            endurance = 7,
            magic = 4
        },
        base_spells = {"Brutal Strike", "War Cry"},
        base_energy = 85,
        base_energy_max = 85
    }
}

-- Function to get a class by name
function M.getClass(class_name)
    return classes[class_name:lower()]
end

-- Function to get the list of available classes
function M.getAvailableClasses()
    local class_list = {}
    for class_name, class_info in pairs(classes) do
        table.insert(class_list, class_name)
    end
    return class_list
end

return M